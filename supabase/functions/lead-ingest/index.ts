// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS Preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get("token");

    // 1. Validate Secret Webhook Token
    if (!token) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing token parameter in query string" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const payload = await req.json();
    let name = "Unknown";
    let phone = "";
    let source = "Webhook";
    let customFields: Record<string, unknown> = {};

    // 2. Format Detection & Normalization

    // Case A: Google Ads Lead Form Extension Payload
    if (payload.user_column_data && Array.isArray(payload.user_column_data)) {
      source = "Google Ads";
      for (const col of payload.user_column_data) {
        if (col.column_id === "FULL_NAME") name = col.string_value ?? name;
        if (col.column_id === "PHONE_NUMBER") phone = col.string_value ?? phone;
      }
      customFields = {
        campaign_id: payload.campaign_id,
        form_id: payload.form_id,
        google_key: payload.google_key,
      };
    }
    // Case B: Meta Ads (Facebook / Instagram Lead Ads) Payload
    else if (payload.field_data && Array.isArray(payload.field_data)) {
      source = "Meta Ads";
      for (const field of payload.field_data) {
        if (field.name === "full_name" || field.name === "name") {
          name = field.values?.[0] ?? name;
        }
        if (field.name === "phone_number" || field.name === "phone") {
          phone = field.values?.[0] ?? phone;
        }
      }
      customFields = {
        ad_id: payload.ad_id,
        form_id: payload.leadgen_id,
        page_id: payload.page_id,
      };
    }
    // Case C: Generic Webhook (Landing Pages, Elementor, WhatsApp Cloud API, ManyChat)
    else {
      name = payload.name ?? payload.full_name ?? payload.customer_name ?? "Unknown Inquirer";
      phone = payload.phone ?? payload.phone_number ?? payload.mobile ?? payload.from ?? "";
      source = payload.source ?? "Website Form";
      customFields = payload.custom_fields ?? payload.data ?? {};
    }

    if (!phone) {
      return new Response(
        JSON.stringify({ success: false, error: "Phone number is required in payload" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Supabase Database Service Role Client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 4. Ingest Lead via Stored Procedure
    const { data, error } = await supabaseClient.rpc("ingest_external_lead", {
      p_webhook_key: token,
      p_name: name,
      p_phone: phone,
      p_source: source,
      p_custom_fields: customFields,
    });

    if (error || !data?.success) {
      return new Response(
        JSON.stringify({ success: false, error: error?.message ?? data?.error ?? "Ingestion failed" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 5. Success Response
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});