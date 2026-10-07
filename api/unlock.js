import { checkPasscode, issueCookie } from "./_auth.js";

// Best-effort guess limiting: counts live per function instance, so this slows
// a guesser down rather than hard-capping them.
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
  res.end(JSON.stringify(payload));
}

export default async function handler(req, res) {
  if (req.method !== "POST") return send(res, 405, { error: "Method not allowed" });
  if (!process.env.VAULT_PASSCODE || !process.env.VAULT_SECRET) {
    return send(res, 503, { error: "Vault isn't configured yet." });
  }

  const ip = clientIp(req);
  const now = Date.now();
  const rec = fails.get(ip);
  if (rec && now - rec.first < WINDOW_MS && rec.count >= MAX_FAILS) {
    return send(res, 429, { error: "Too many tries. Wait 15 minutes." });
  }

  const { passcode } = await readBody(req);
  if (checkPasscode(passcode)) {
    fails.delete(ip);
    res.setHeader("Set-Cookie", issueCookie());
    return send(res, 200, { ok: true });
  }

  if (!rec || now - rec.first >= WINDOW_MS) fails.set(ip, { first: now, count: 1 });
  else rec.count += 1;
  await new Promise((r) => setTimeout(r, 700));
  return send(res, 401, { error: "Wrong passcode." });
}
