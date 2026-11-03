import { checkPasscode, isUnlocked, issueCookie } from "./_auth.js";

// Countdown targets live in the HQ Supabase project. Anyone may read a target;
// changing one needs the vault passcode (or an unlocked vault cookie), and the
// write goes through countdown_set(), which checks a server-only key.
const SUPABASE_URL = "https://vmmdskviwqddgalccoyc.supabase.co";
const SUPABASE_KEY = "sb_publishable_Y95c2qYSmD8YKdaIeOZYWA_6GmC2OHM";
const SLUGS = new Set(["nichol-27b568bc2f"]);

const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILS = 8;
const fails = new Map();

function clientIp(req) {
  return String(req.headers["x-forwarded-for"] || "").split(",")[0].trim() || "unknown";
}

function readBody(req) {
  if (req.body && typeof req.body === "object") return Promise.resolve(req.body);
  return new Promise((resolve) => {
    let data = "";
    req.on("data", (c) => { data += c; if (data.length > 4096) req.destroy(); });
    req.on("end", () => { try { resolve(JSON.parse(data || "{}")); } catch { resolve({}); } });
    req.on("error", () => resolve({}));
  });
}

function send(res, status, payload) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Robots-Tag", "noindex, nofollow");
  res.end(JSON.stringify(payload));
}

function supabase(path, init = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: SUPABASE_KEY, "Content-Type": "application/json", ...(init.headers || {}) },
  });
}

export default async function handler(req, res) {
  const slug = String(req.query?.slug || "");
  if (!SLUGS.has(slug)) return send(res, 404, { error: "Not found" });

  if (req.method === "GET") {
    const r = await supabase(`countdown_targets?slug=eq.${slug}&select=target_at`);
    if (!r.ok) return send(res, 502, { error: "Couldn't load the time." });
    const rows = await r.json();
    return send(res, 200, { target: rows[0]?.target_at || null, editor: isUnlocked(req) });
  }

  if (req.method !== "POST") return send(res, 405, { error: "Method not allowed" });
  if (!process.env.COUNTDOWN_WRITE_KEY) return send(res, 503, { error: "Editing isn't configured yet." });

  const body = await readBody(req);
  if (!isUnlocked(req)) {
    const ip = clientIp(req);
    const now = Date.now();
    const rec = fails.get(ip);
    if (rec && now - rec.first < WINDOW_MS && rec.count >= MAX_FAILS) {
      return send(res, 429, { error: "Too many tries. Wait 15 minutes." });
    }
    if (!checkPasscode(body.passcode)) {
      if (!rec || now - rec.first >= WINDOW_MS) fails.set(ip, { first: now, count: 1 });
      else rec.count += 1;
      return send(res, 401, { error: "Wrong passcode." });
    }
    fails.delete(ip);
    res.setHeader("Set-Cookie", issueCookie());
  }

  const target = new Date(body.target);
  if (Number.isNaN(target.getTime())) return send(res, 400, { error: "That time didn't make sense." });

  const r = await supabase("rpc/countdown_set", {
    method: "POST",
    body: JSON.stringify({ p_slug: slug, p_key: process.env.COUNTDOWN_WRITE_KEY, p_target: target.toISOString() }),
  });
  if (!r.ok) return send(res, 502, { error: "Couldn't save the time." });
  return send(res, 200, { target: target.toISOString() });
}
