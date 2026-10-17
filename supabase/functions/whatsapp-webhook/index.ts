// @ts-nocheck
declare const Deno: any;

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const VERIFY_TOKEN = "Gds123";

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);

  // 1. Meta Webhook Verification (GET Request)
  if (req.method === "GET") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      return new Response(challenge ?? "", { status: 200 });
    }
    return new Response("Verification failed", { status: 403 });
  }

  // 2. Incoming WhatsApp Message Handler (POST Request)
  if (req.method === "POST") {
    try {
      const body = await req.json();

      const entry = body?.entry?.[0];
      const change = entry?.changes?.[0];
      const value = change?.value;
      const message = value?.messages?.[0];
      const contact = value?.contacts?.[0];
      const phoneNumberId = value?.metadata?.phone_number_id;

      if (message) {
        const fromPhone = String(message.from ?? "");
        const senderName = String(contact?.profile?.name ?? "WhatsApp Lead");
        const textMessage = String(message?.text?.body ?? message?.type ?? "New lead message");

        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
        const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
        const metaToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
        const supabase = createClient(supabaseUrl, supabaseKey);

        // Active organization fetch karein
        const { data: org, error: orgError } = await supabase
          .from("organizations")
          .select("id")
          .limit(1)
          .maybeSingle();

        if (org && !orgError) {
          let leadId: string | null = null;

          // Check if lead already exists
          const { data: existingLead } = await supabase
            .from("leads")
            .select("id, notes")
            .eq("organization_id", org.id)
            .eq("phone", fromPhone)
            .maybeSingle();

          if (existingLead) {
            leadId = existingLead.id;
            const currentNotes = existingLead.notes ? `${existingLead.notes}\n` : "";
            await supabase
              .from("leads")
              .update({
                notes: `${currentNotes}[WhatsApp ${new Date().toLocaleTimeString()}]: ${textMessage}`,
                updated_at: new Date().toISOString(),
              })
              .eq("id", existingLead.id);
          } else {
            const { data: newLead } = await supabase
              .from("leads")
              .insert({
                organization_id: org.id,
                name: senderName,
                phone: fromPhone,
                source: "WhatsApp",
                status_key: "new",
                notes: `[Initial Message]: ${textMessage}`,
              })
              .select("id")
              .single();

            if (newLead) {
              leadId = newLead.id;
            }
          }

          // 3. Customer message ko lead_messages table me save karein
          if (leadId) {
            await supabase.from("lead_messages").insert({
              lead_id: leadId,
              sender_type: "customer",
              channel: "whatsapp",
              message_text: textMessage,
            });

            // 4. Meta Cloud API se Customer ko WhatsApp Auto-Reply bhejein
            if (metaToken && phoneNumberId) {
              const autoReplyBody = "Namaste! Aapka message mil gaya hai. Hamari team aapse jald sampark karegi.";

              const metaRes = await fetch(
                `https://graph.facebook.com/v21.0/${phoneNumberId}/messages`,
                {
                  method: "POST",
                  headers: {
                    Authorization: `Bearer ${metaToken}`,
                    "Content-Type": "application/json",
                  },
                  body: JSON.stringify({
                    messaging_product: "whatsapp",
                    to: fromPhone,
                    type: "text",
                    text: { body: autoReplyBody },
                  }),
                }
              );

              if (metaRes.ok) {
                // Bot reply ko bhi lead_messages me record karein
                await supabase.from("lead_messages").insert({
                  lead_id: leadId,
                  sender_type: "bot",
                  channel: "whatsapp",
                  message_text: autoReplyBody,
                });
              } else {
                console.error("Meta API Error:", await metaRes.text());
              }
            }
          }
        }
      }

      return new Response(JSON.stringify({ status: "success" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      return new Response(JSON.stringify({ error: errorMessage }), {
        headers: { "Content-Type": "application/json" },
        status: 500,
      });
    }
  }

  return new Response("Method not allowed", { status: 405 });
});