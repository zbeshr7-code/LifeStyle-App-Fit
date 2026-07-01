import { createClient } from "npm:@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const moyasarSecretKey = Deno.env.get("MOYASAR_SECRET_KEY");

    if (!moyasarSecretKey) {
      return json({ error: "Moyasar is not configured on the server" }, 500);
    }

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
    const subscriptionId = body?.subscriptionId as string | undefined;
    const paymentId = body?.paymentId as string | undefined;

    if (!subscriptionId || !paymentId) {
      return json({ error: "subscriptionId and paymentId are required" }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: subscription, error: subError } = await adminClient
      .from("trainee_subscriptions")
      .select("*")
      .eq("id", subscriptionId)
      .eq("trainee_id", user.id)
      .maybeSingle();

    if (subError || !subscription) {
      return json({ error: "Subscription not found" }, 404);
    }

    if (
      subscription.payment_status === "paid" &&
      subscription.status === "active"
    ) {
      return json({ subscription, alreadyActive: true });
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
      const errText = await paymentRes.text();
      console.error("Moyasar fetch failed:", errText);
      return json({ error: "Failed to verify payment with Moyasar" }, 502);
    }

    const payment = (await paymentRes.json()) as MoyasarPayment;

    const expectedHalalas = Math.round(Number(subscription.plan_price) * 100);

    if (payment.status !== "paid") {
      return json({ error: "Payment is not completed" }, 400);
    }
    if (payment.currency !== "SAR") {
      return json({ error: "Invalid payment currency" }, 400);
    }
    if (payment.amount !== expectedHalalas) {
      return json({ error: "Payment amount mismatch" }, 400);
    }

    const metaSubId = payment.metadata?.subscription_id as string | undefined;
    if (metaSubId && metaSubId !== subscriptionId) {
      return json({ error: "Payment metadata mismatch" }, 400);
    }

    const { data: activated, error: activateError } = await adminClient.rpc(
      "activate_paid_subscription",
      {
        p_subscription_id: subscriptionId,
        p_moyasar_payment_id: payment.id,
        p_amount_paid: subscription.plan_price,
      },
    );

    if (activateError) {
      console.error("activate_paid_subscription error:", activateError);
      return json({ error: activateError.message }, 500);
    }

    return json({ subscription: activated });
  } catch (error) {
    console.error("verify-moyasar-payment error:", error);
    return json({ error: "Internal server error" }, 500);
  }
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
