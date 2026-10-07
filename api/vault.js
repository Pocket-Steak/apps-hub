import { isUnlocked, readTemplate, sendHtml } from "./_auth.js";

export default async function handler(req, res) {
  if (isUnlocked(req)) return sendHtml(res, 200, await readTemplate("vault.html"));
  return sendHtml(res, 401, await readTemplate("gate.html"));
}
