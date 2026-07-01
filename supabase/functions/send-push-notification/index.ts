import { cert, getApps, initializeApp } from "npm:firebase-admin@12.7.0/app";
import { getMessaging } from "npm:firebase-admin@12.7.0/messaging";
import { createClient } from "npm:@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

type PushType = "chat_message" | "call_invite";

type AuthContext =
  | { type: "service_role" }
  | { type: "webhook" }
  | { type: "user"; userId: string };

type SendPushResult = {
  delivered: boolean;
  reason?: string;
};

class PushConfigError extends Error {
  override name = "PushConfigError";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const auth = await resolveAuthContext(req);
    if (!auth) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const adminClient = createAdminClient();

    if (body?.type === "INSERT" && body?.table === "chat_messages") {
      if (auth.type !== "service_role" && auth.type !== "webhook") {
        return json({ error: "Unauthorized" }, 401);
      }
      const result = await handleChatInsert(adminClient, body.record);
      return json({ ok: true, ...result });
    }

    const pushType = body?.type as PushType | undefined;
    if (pushType === "call_invite") {
      if (auth.type === "user") {
        const callerId = body.callerId as string | undefined;
        if (!callerId || callerId !== auth.userId) {
          return json({ error: "Forbidden" }, 403);
        }
      } else if (auth.type !== "service_role" && auth.type !== "webhook") {
        return json({ error: "Unauthorized" }, 401);
      }

      const result = await handleCallInvite(adminClient, body);
      return json({ ok: true, ...result });
    }

    if (pushType === "chat_message") {
      if (auth.type !== "service_role" && auth.type !== "webhook") {
        return json({ error: "Unauthorized" }, 401);
      }
      const result = await handleChatInsert(adminClient, body.record ?? body);
      return json({ ok: true, ...result });
    }

    return json({ error: "Unsupported payload" }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("send-push-notification error:", message, error);
    if (error instanceof PushConfigError) {
      return json({ error: message, code: "push_not_configured" }, 503);
    }
    return json({ error: "Internal server error", detail: message }, 500);
  }
});

async function resolveAuthContext(req: Request): Promise<AuthContext | null> {
  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (webhookSecret && req.headers.get("x-webhook-secret") === webhookSecret) {
    return { type: "webhook" };
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return null;

  const token = authHeader.slice("Bearer ".length);
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (token === serviceRoleKey) {
    return { type: "service_role" };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    console.error("resolveAuthContext getUser:", error?.message);
    return null;
  }

  return { type: "user", userId: data.user.id };
}

function createAdminClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  return createClient(supabaseUrl, serviceRoleKey);
}

function loadServiceAccount(): Record<string, unknown> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")?.trim();
  if (!raw) {
    throw new PushConfigError(
      "FIREBASE_SERVICE_ACCOUNT_JSON is not configured in Edge Function secrets",
    );
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    throw new PushConfigError(
      "FIREBASE_SERVICE_ACCOUNT_JSON is invalid JSON. Paste the full service account file as one line.",
    );
  }

  if (typeof parsed.private_key === "string") {
    parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
  }

  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new PushConfigError(
      "FIREBASE_SERVICE_ACCOUNT_JSON is missing project_id, client_email, or private_key",
    );
  }

  return parsed;
}

function ensureFirebaseApp() {
  if (getApps().length > 0) return;

  const serviceAccount = loadServiceAccount();
  initializeApp({
    credential: cert(serviceAccount as Parameters<typeof cert>[0]),
  });
}

async function handleChatInsert(
  adminClient: ReturnType<typeof createClient>,
  record: Record<string, unknown>,
): Promise<SendPushResult> {
  const roomId = record.room_id as string | undefined;
  const senderId = record.sender_id as string | undefined;
  const messageType = (record.type as string | undefined) ?? "text";
  const content = (record.content as string | undefined) ?? "";

  if (!roomId || !senderId) return { delivered: false, reason: "invalid_record" };

  const { data: members, error: membersError } = await adminClient
    .from("chat_room_members")
    .select("user_id")
    .eq("room_id", roomId);

  if (membersError || !members) {
    console.error("handleChatInsert members:", membersError?.message);
    return { delivered: false, reason: "members_lookup_failed" };
  }

  const recipientId = members
    .map((m) => m.user_id as string)
    .find((id) => id !== senderId);

  if (!recipientId) return { delivered: false, reason: "no_recipient" };

  const { data: sender } = await adminClient
    .from("profiles")
    .select("first_name, last_name")
    .eq("id", senderId)
    .maybeSingle();

  const senderName = sender
    ? `${sender.first_name ?? ""} ${sender.last_name ?? ""}`.trim()
    : "New message";

  const preview = messagePreview(messageType, content);

  return await sendPush(adminClient, {
    recipientId,
    title: senderName,
    body: preview,
    data: {
      type: "chat_message",
      room_id: roomId,
      peer_id: senderId,
      peer_name: senderName,
    },
  });
}

async function handleCallInvite(
  adminClient: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
): Promise<SendPushResult> {
  const recipientId = body.recipientId as string | undefined;
  const roomId = body.roomId as string | undefined;
  const callerId = body.callerId as string | undefined;
  const callerName = (body.callerName as string | undefined) ?? "Incoming call";
  const callId = body.callId as string | undefined;
  const callType = (body.callType as string | undefined) ?? "audio";

  if (!recipientId || !roomId || !callerId || !callId) {
    return { delivered: false, reason: "missing_fields" };
  }

  const isVideo = callType === "video";
  return await sendPush(adminClient, {
    recipientId,
    title: isVideo ? "Incoming video call" : "Incoming audio call",
    body: callerName,
    data: {
      type: "call_invite",
      room_id: roomId,
      peer_id: callerId,
      peer_name: callerName,
      call_id: callId,
      call_type: callType,
    },
    highPriority: true,
  });
}

async function sendPush(
  adminClient: ReturnType<typeof createClient>,
  args: {
    recipientId: string;
    title: string;
    body: string;
    data: Record<string, string>;
    highPriority?: boolean;
  },
): Promise<SendPushResult> {
  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("fcm_token")
    .eq("id", args.recipientId)
    .maybeSingle();

  if (profileError) {
    console.error("sendPush profile:", profileError.message);
    return { delivered: false, reason: "profile_lookup_failed" };
  }

  const token = profile?.fcm_token as string | undefined;
  if (!token) {
    console.log(`sendPush: no fcm_token for user ${args.recipientId}`);
    return { delivered: false, reason: "no_fcm_token" };
  }

  try {
    ensureFirebaseApp();
    const messaging = getMessaging();

    await messaging.send({
      token,
      notification: {
        title: args.title,
        body: args.body,
      },
      data: stringifyData(args.data),
      android: {
        priority: args.highPriority ? "high" : "normal",
        notification: {
          channelId: "lifestyle_fit_default",
          priority: args.highPriority ? "max" : "high",
        },
      },
      apns: {
        headers: {
          "apns-priority": args.highPriority ? "10" : "5",
        },
        payload: {
          aps: {
            alert: {
              title: args.title,
              body: args.body,
            },
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    });

    return { delivered: true };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`sendPush FCM failed for ${args.recipientId}:`, message);
    return { delivered: false, reason: "fcm_send_failed", detail: message };
  }
}

/** FCM data payload values must be strings. */
function stringifyData(data: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    out[key] = value == null ? "" : String(value);
  }
  return out;
}

function messagePreview(type: string, content: string): string {
  switch (type) {
    case "image":
      return "Photo";
    case "audio":
      return "Voice message";
    case "video":
      return "Video";
    case "file":
      return "File";
    case "call":
      return "Call";
    default:
      return content.trim().isEmpty ? "New message" : content.trim();
  }
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
