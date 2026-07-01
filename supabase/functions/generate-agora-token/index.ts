import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { RtcRole, RtcTokenBuilder } from "npm:agora-token@2.0.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const roomId = body?.roomId as string | undefined;
    const channelName = body?.channelName as string | undefined;

    if (!roomId || !channelName) {
      return json({ error: "roomId and channelName are required" }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: member, error: memberError } = await adminClient
      .from("chat_room_members")
      .select("user_id")
      .eq("room_id", roomId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (memberError || !member) {
      return json({ error: "Not a member of this chat room" }, 403);
    }

    const appId = Deno.env.get("AGORA_APP_ID");
    const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE");

    if (!appId || !appCertificate) {
      return json({ error: "Agora is not configured on the server" }, 500);
    }

    const expireSeconds = 3600;
    const privilegeExpiredTs = Math.floor(Date.now() / 1000) + expireSeconds;

    const token = RtcTokenBuilder.buildTokenWithUserAccount(
      appId,
      appCertificate,
      channelName,
      user.id,
      RtcRole.PUBLISHER,
      privilegeExpiredTs,
      privilegeExpiredTs,
    );

    return json({
      token,
      channelName,
      userAccount: user.id,
      appId,
      expiresAt: new Date(Date.now() + expireSeconds * 1000).toISOString(),
    });
  } catch (error) {
    console.error("generate-agora-token error:", error);
    return json({ error: "Internal server error" }, 500);
  }
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
