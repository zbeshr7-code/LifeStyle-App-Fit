import { createClient } from "npm:@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-moyasar-signature",
};

interface WebhookPayload {
  type?: string;
  id?: string;
  data?: {
    id?: string;
    status?: string;
    amount?: number;
    currency?: string;
    metadata?: Record<string, unknown>;
  };
}

interface MoyasarPayment {
  id: string;
  status: string;
  amount: number;
  currency: string;
  metadata?: Record<string, unknown>;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const webhookSecret = Deno.env.get("MOYASAR_WEBHOOK_SECRET");
    const moyasarSecretKey = Deno.env.get("MOYASAR_SECRET_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!moyasarSecretKey) {
      return json({ error: "Moyasar is not configured" }, 500);
    }

    const rawBody = await req.text();
    const signature = req.headers.get("x-moyasar-signature") ??
      req.headers.get("X-Moyasar-Signature");

    if (webhookSecret && signature) {
      const valid = await verifySignature(rawBody, signature, webhookSecret);
      if (!valid) {
        return json({ error: "Invalid webhook signature" }, 401);
      }
    }

    const payload = JSON.parse(rawBody) as WebhookPayload;
    const eventType = payload.type ?? "";
    const paymentId = payload.data?.id ?? payload.id;

    if (!paymentId) {
      return json({ error: "Missing payment id" }, 400);
    }

    if (eventType && eventType !== "payment_paid" && eventType !== "payment.captured") {
      return json({ received: true, skipped: true });
    }

    const paymentRes = await fetch(
      `https://api.moyasar.com/v1/payments/${paymentId}`,
      {
        headers: {
          Authorization: `Basic ${btoa(`${moyasarSecretKey}:`)}`,
        },
      },
    );

    if (!paymentRes.ok) {
      return json({ error: "Failed to fetch payment" }, 502);
    }

    const payment = (await paymentRes.json()) as MoyasarPayment;

    if (payment.status !== "paid") {
      return json({ received: true, skipped: true });
    }

    const subscriptionId = payment.metadata?.subscription_id as string | undefined;
    if (!subscriptionId) {
      return json({ error: "Missing subscription_id in metadata" }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: subscription, error: subError } = await adminClient
      .from("trainee_subscriptions")
      .select("*")
      .eq("id", subscriptionId)
      .maybeSingle();

    if (subError || !subscription) {
      return json({ error: "Subscription not found" }, 404);
    }

    if (
      subscription.payment_status === "paid" &&
      subscription.status === "active"
    ) {
      return json({ received: true, alreadyActive: true });
    }

    const expectedHalalas = Math.round(Number(subscription.plan_price) * 100);
    if (payment.currency !== "SAR" || payment.amount !== expectedHalalas) {
      return json({ error: "Payment validation failed" }, 400);
    }

    const { error: activateError } = await adminClient.rpc(
      "activate_paid_subscription",
      {
        p_subscription_id: subscriptionId,
        p_moyasar_payment_id: payment.id,
        p_amount_paid: subscription.plan_price,
      },
    );

    if (activateError) {
      console.error("webhook activate error:", activateError);
      return json({ error: activateError.message }, 500);
    }

    return json({ received: true, activated: true });
  } catch (error) {
    console.error("moyasar-webhook error:", error);
    return json({ error: "Internal server error" }, 500);
  }
});

async function verifySignature(
  body: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(body),
  );
  const expected = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return expected === signature.toLowerCase();
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
