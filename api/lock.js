import { clearCookie } from "./_auth.js";

export default function handler(req, res) {
  res.setHeader("Set-Cookie", clearCookie());
  res.statusCode = 303;
  res.setHeader("Location", "/apps/");
  res.end();
}
