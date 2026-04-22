(function setupPocketSteakSupabaseHelpers() {
  const URL_KEY = "pocketsteak_supabase_url";
  const ANON_KEY_KEY = "pocketsteak_supabase_anon_key";
  const DEFAULT_URL = "https://vmmdskvivqddgalccoyc.supabase.co";
  const DEFAULT_ANON_KEY = "sb_publishable_Y95c2qYSmD8YKdaIe0ZYWA_6GmC2OHM";
  const DEFAULT_MEMBERS = [
    { name: "Andrew", color: "#ff9d2f" },
    { name: "Nichol", color: "#8b5cf6" },
    { name: "Jolie", color: "#22c55e" },
  ];

  function normalizeText(value) {
    return String(value || "")
      .replace(/[\u200B-\u200D\uFEFF]/g, "")
      .trim();
  }

  function normalizeUrl(value) {
    const text = normalizeText(value);
    if (!text) return "";

    try {
      const url = new URL(text);
      url.pathname = url.pathname
        .replace(/\/rest\/v1\/?$/i, "/")
        .replace(/\/auth\/v1\/?$/i, "/");
      url.search = "";
      url.hash = "";
      return url.toString().replace(/\/$/, "");
    } catch (error) {
      return text.replace(/\/$/, "");
    }
  }

  function isLikelySupabaseUrl(value) {
    try {
      const url = new URL(normalizeUrl(value));
      return Boolean(url.hostname && url.hostname.includes("supabase.co"));
    } catch (error) {
      return false;
    }
  }

  function isLikelyPublishableKey(value) {
    const text = normalizeText(value);
    return text.startsWith("sb_publishable_") || text.startsWith("sb_anon_");
  }

  function formatDateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  function getStartOfDay(dateInput = new Date()) {
    const date = new Date(dateInput);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  function getWeekStartDateFor(dateInput = new Date()) {
    const date = getStartOfDay(dateInput);
    const day = date.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    date.setDate(date.getDate() + diff);
    return date;
  }

  function getConfig() {
    const storedUrl = normalizeText(localStorage.getItem(URL_KEY));
    const storedAnonKey = normalizeText(localStorage.getItem(ANON_KEY_KEY));
    const url = isLikelySupabaseUrl(storedUrl) ? normalizeUrl(storedUrl) : DEFAULT_URL;
    const anonKey = isLikelyPublishableKey(storedAnonKey) ? storedAnonKey : DEFAULT_ANON_KEY;

    return {
      url,
      anonKey,
      configured: Boolean(url && anonKey),
      usingDefaultConfig: url === DEFAULT_URL && anonKey === DEFAULT_ANON_KEY,
    };
  }

  function saveConfig(url, anonKey) {
    localStorage.setItem(URL_KEY, normalizeUrl(url));
    localStorage.setItem(ANON_KEY_KEY, normalizeText(anonKey));
    return getConfig();
  }

  function clearConfig() {
    localStorage.removeItem(URL_KEY);
    localStorage.removeItem(ANON_KEY_KEY);
    return getConfig();
  }

  function createClient() {
    const config = getConfig();
    if (!config.configured) {
      return null;
    }

    if (!window.supabase || typeof window.supabase.createClient !== "function") {
      throw new Error("Supabase client library is not loaded.");
    }

    return window.supabase.createClient(config.url, config.anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }

  function normalizeOwner(value) {
    return normalizeText(value)
      .split(/\s+/)
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
      .join(" ");
  }

  window.PocketSteakSupabase = {
    defaultMembers: DEFAULT_MEMBERS,
    getConfig,
    saveConfig,
    clearConfig,
    createClient,
    normalizeOwner,
    normalizeUrl,
    formatDateKey,
    getStartOfDay,
    getWeekStartDateFor,
    getCurrentDayKey() {
      return formatDateKey(getStartOfDay());
    },
    getCurrentWeekKey() {
      return formatDateKey(getWeekStartDateFor(new Date()));
    },
  };
})();
