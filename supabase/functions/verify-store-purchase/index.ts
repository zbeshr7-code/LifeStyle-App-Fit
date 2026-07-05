import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization" }, 401);
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

    const {
      subscriptionId,
      productId,
      transactionId,
      platform,
      purchaseToken,
      verificationData,
    } = await req.json();

    if (!subscriptionId || !productId || !transactionId || !platform) {
      return json({ error: "Missing purchase fields" }, 400);
    }

    const { data: sub, error: subError } = await userClient
      .from("trainee_subscriptions")
      .select("id, trainee_id, status, payment_status, store_product_id, plan_price")
      .eq("id", subscriptionId)
      .maybeSingle();

    if (subError || !sub) {
      return json({ error: "Subscription not found" }, 404);
    }

    if (sub.trainee_id !== user.id) {
      return json({ error: "Forbidden" }, 403);
    }

    if (
      sub.store_product_id &&
      sub.store_product_id !== productId
    ) {
      return json({ error: "Product ID mismatch" }, 400);
    }

    // TODO: verify receipt with Apple App Store Server API / Google Play Developer API.
    // For now we trust the native store purchase + idempotent transaction id.
    void purchaseToken;
    void verificationData;

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: activated, error: activateError } = await adminClient.rpc(
      "activate_store_purchase",
      {
        p_subscription_id: subscriptionId,
        p_store_product_id: productId,
        p_store_transaction_id: transactionId,
        p_store_platform: platform,
        p_amount_paid: sub.plan_price,
      },
    );

    if (activateError) {
      console.error("activate_store_purchase error:", activateError);
      return json({ error: activateError.message }, 400);
    }

    return json({ subscription: activated });
  } catch (error) {
    console.error("verify-store-purchase error:", error);
    return json({ error: "Internal server error" }, 500);
  }
});
