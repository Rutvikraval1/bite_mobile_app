// send-push — delivers a row from public.notifications as an FCM push.
//
// Wire it up with a Database Webhook (Dashboard → Database → Webhooks):
//   table: public.notifications, event: INSERT, type: Supabase Edge Function,
//   function: send-push.
//
// Secrets (supabase secrets set ...):
//   FIREBASE_SERVICE_ACCOUNT  — the Firebase service-account JSON (one line)
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are provided automatically.
import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

type NotificationRow = {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string;
  emoji: string;
  action_dest: string | null;
  data: Record<string, unknown>;
};

const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

let cachedToken: { value: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.value;
  const key = await importPKCS8(serviceAccount.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const json = await res.json();
  cachedToken = { value: json.access_token, exp: now + (json.expires_in ?? 3600) };
  return cachedToken.value;
}

Deno.serve(async (req) => {
  const payload = await req.json();
  const row: NotificationRow | undefined = payload.record;
  if (!row) return new Response("no record", { status: 400 });

  // Respect the user's push preference.
  const { data: profile } = await supabase
    .from("profiles")
    .select("push_enabled")
    .eq("id", row.user_id)
    .maybeSingle();
  if (profile && profile.push_enabled === false) {
    return new Response("push disabled", { status: 200 });
  }

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", row.user_id);
  if (!tokens?.length) return new Response("no tokens", { status: 200 });

  const bearer = await accessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
  const stale: string[] = [];

  await Promise.all(tokens.map(async ({ token }) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: `${row.emoji} ${row.title}`, body: row.body },
          data: {
            notification_id: row.id,
            type: row.type,
            action_dest: row.action_dest ?? "",
            payload: JSON.stringify(row.data ?? {}),
          },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    });
    if (res.status === 404 || res.status === 400) {
      const err = await res.text();
      if (err.includes("UNREGISTERED") || err.includes("INVALID_ARGUMENT")) stale.push(token);
    }
  }));

  if (stale.length) {
    await supabase.from("device_tokens").delete().in("token", stale);
  }
  return new Response(JSON.stringify({ sent: tokens.length - stale.length }), {
    headers: { "Content-Type": "application/json" },
  });
});
