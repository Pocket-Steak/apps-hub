(function setupPocketSteakSupabaseHelpers() {
  const URL_KEY = "pocketsteak_supabase_url";
  const ANON_KEY_KEY = "pocketsteak_supabase_anon_key";
  const DEFAULT_MEMBERS = [
    { name: "Andrew", color: "#ff9d2f" },
    { name: "Nichol", color: "#8b5cf6" },
    { name: "Jolie", color: "#22c55e" },
  ];

  function normalizeText(value) {
    return String(value || "").trim();
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
    const url = normalizeText(localStorage.getItem(URL_KEY));
    const anonKey = normalizeText(localStorage.getItem(ANON_KEY_KEY));

    return {
      url,
      anonKey,
      configured: Boolean(url && anonKey),
    };
  }

  function saveConfig(url, anonKey) {
    localStorage.setItem(URL_KEY, normalizeText(url));
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
