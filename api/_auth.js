import { createHmac, timingSafeEqual } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";

export const COOKIE = "ps_vault";
const MAX_AGE = 60 * 60 * 24 * 30; // 30 days

// Changing the passcode changes the signing key, which signs everyone out.
function key() {
  const secret = process.env.VAULT_SECRET;
  const pass = process.env.VAULT_PASSCODE;
  if (!secret || !pass) return null;
  return `${secret}:${pass}`;
}

function sign(payload, k) {
  return createHmac("sha256", k).update(payload).digest("base64url");
}

function safeEqual(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

export function checkPasscode(input) {
  const pass = process.env.VAULT_PASSCODE;
  if (!pass || typeof input !== "string") return false;
  // Compare HMACs so the length of the real passcode doesn't leak.
  const k = "ps-vault-compare";
  return safeEqual(sign(input, k), sign(pass, k));
}

export function issueCookie() {
  const k = key();
  const exp = Math.floor(Date.now() / 1000) + MAX_AGE;
  const payload = `v1.${exp}`;
  const value = `${payload}.${sign(payload, k)}`;
  return `${COOKIE}=${value}; Path=/; Max-Age=${MAX_AGE}; HttpOnly; Secure; SameSite=Strict`;
}

export function clearCookie() {
  return `${COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Strict`;
}

export function isUnlocked(req) {
  const k = key();
  if (!k) return false;
  const raw = (req.headers.cookie || "")
    .split(";")
    .map((c) => c.trim())
    .find((c) => c.startsWith(`${COOKIE}=`));
  if (!raw) return false;
  const parts = raw.slice(COOKIE.length + 1).split(".");
  if (parts.length !== 3 || parts[0] !== "v1") return false;
  const [v, exp, mac] = parts;
  if (!(Number(exp) > Date.now() / 1000)) return false;
  return safeEqual(mac, sign(`${v}.${exp}`, k));
}

export function readTemplate(name) {
  return readFile(path.join(process.cwd(), "vault", name), "utf8");
}

export function sendHtml(res, status, html) {
  res.statusCode = status;
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "private, no-store");
  res.setHeader("X-Robots-Tag", "noindex, nofollow");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.end(html);
}
