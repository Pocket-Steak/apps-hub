(function () {
  const STORAGE_KEY = "pocketsteak_tst_display_settings";

  const themes = {
    commandCenterBlue: {
      bg: "#06131d",
      panel: "#0f2233",
      panel2: "#173147",
      text: "#f7fbff",
      muted: "#c8d7e6",
    },
    harborBlue: {
      bg: "#071823",
      panel: "#112b40",
      panel2: "#1a3c57",
      text: "#f7fbff",
      muted: "#c7d8e7",
    },
    glacierBlue: {
      bg: "#081723",
      panel: "#102638",
      panel2: "#1b3950",
      text: "#f7fbff",
      muted: "#cad9e7",
    },
  };

  function readSettings() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
    } catch {
      return {};
    }
  }

  function saveSettings(settings) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
  }

  const CORE_STYLES = `
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { min-height: 100%; }

    body {
      font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
      color: var(--text);
      padding: 16px;
      transition: background 0.3s ease;
    }

    .page {
      max-width: 1320px;
      margin: 0 auto;
      display: grid;
      gap: 12px;
      min-height: calc(100dvh - 32px);
    }

    .topbar, .hero, .panel, .card, .status-pill {
      background:
        radial-gradient(circle at top left, rgba(255, 255, 255, .05), transparent 34%),
        linear-gradient(180deg, var(--panel), var(--panel-2));
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
    }

    .topbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      padding: 10px 14px;
    }

    .top-btn, .nav-link, .action-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      text-decoration: none;
      border: none;
      color: var(--text);
      min-height: 40px;
      padding: 8px 14px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      border-radius: 16px;
      background: rgba(255, 255, 255, .08);
      transition: transform .18s ease, background .18s ease, filter .18s ease;
    }

    .top-btn:hover, .nav-link:hover, .action-btn:hover {
      background: rgba(255, 255, 255, .14);
      transform: translateY(-1px);
    }

    .top-btn.accent, .action-btn.accent {
      background: var(--accent);
      color: #fff;
    }

    .hero { padding: 18px 20px; display: grid; gap: 4px; }
    .eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: .12em;
      text-transform: uppercase;
      color: var(--accent-2);
      text-shadow: 0 0 18px color-mix(in srgb, var(--accent-2) 22%, transparent);
    }

    .title { font-size: clamp(1.6rem, 2.5vw, 2.2rem); font-weight: 800; letter-spacing: -.02em; line-height: 1.1; }
    .panel { padding: 14px; display: grid; gap: 12px; }
    .panel-title { font-size: 18px; font-weight: 800; letter-spacing: -.01em; }

    .card {
      padding: var(--card-pad);
      display: flex;
      flex-direction: column; /* Stack content vertically */
      justify-content: center; /* Vertically center content */
      align-items: center; /* Horizontally center content */
      text-align: center; /* Center text lines */
      word-break: break-word; /* Ensures long words break and wrap */
      overflow-wrap: break-word; /* Modern equivalent for word breaking */
    }

    .select-shell { position: relative; }
    .select-shell::after {
      content: "";
      position: absolute;
      right: 16px;
      top: 50%;
      width: 9px;
      height: 9px;
      border-right: 2px solid var(--accent);
      border-bottom: 2px solid var(--accent);
      transform: translateY(-70%) rotate(45deg);
      pointer-events: none;
    }

    .color-dot {
      width: 22px;
      height: 22px;
      flex: 0 0 auto;
      border-radius: 999px;
      border: 2px solid rgba(255, 255, 255, .5);
      background: var(--accent);
      box-shadow: 0 0 0 4px color-mix(in srgb, var(--accent) 12%, transparent);
    }

    @media (max-width: 720px) {
      body { padding-bottom: 88px; }
      .exit-app-link { left: 14px; right: 14px; }
    }
  `;

  function applySettings(nextSettings = readSettings()) {
    const settings = {
      theme: "commandCenterBlue",
      accent: "#4fd1ff",
      density: "comfortable",
      ...nextSettings,
    };

    if (["arctic", "midnight", "slate"].includes(settings.theme)) {
      settings.theme = "commandCenterBlue";
    }

    if (["#ff8a1f", "#ff7a18"].includes(settings.accent)) {
      settings.accent = "#4fd1ff";
    }

    const theme = themes[settings.theme] || themes.commandCenterBlue;
    const root = document.documentElement;

    // Core Variables from design request
    root.style.setProperty("--surface", "rgba(255, 255, 255, .045)", "important");
    root.style.setProperty("--surface-strong", "rgba(255, 255, 255, .075)", "important");
    root.style.setProperty("--border", "rgba(255, 255, 255, .08)", "important");
    root.style.setProperty("--border-strong", "rgba(255, 255, 255, .12)", "important");
    root.style.setProperty("--shadow", "0 16px 40px rgba(0, 0, 0, .35)", "important");
    root.style.setProperty("--shadow-soft", "0 8px 20px rgba(0, 0, 0, .22)", "important");
    root.style.setProperty("--radius", "22px", "important");
    root.style.setProperty("--card-pad", "16px", "important");

    // Dynamic Theme Variables
    root.style.setProperty("--bg", theme.bg, "important");
    root.style.setProperty("--panel", theme.panel, "important");
    root.style.setProperty("--panel-2", theme.panel2, "important");
    root.style.setProperty("--text", theme.text, "important");
    root.style.setProperty("--muted", theme.muted, "important");
    root.style.setProperty("--accent", settings.accent, "important");
    root.style.setProperty("--accent-2", `color-mix(in srgb, ${settings.accent}, white 20%)`, "important");
    root.style.setProperty("--accent-hover", `color-mix(in srgb, ${settings.accent}, black 10%)`, "important");

    root.dataset.themeDensity = settings.density;

    // Inject/Update the structural CSS
    let styleEl = document.getElementById("pocketsteak-theme-core");
    if (!styleEl) {
      styleEl = document.createElement("style");
      styleEl.id = "pocketsteak-theme-core";
      document.head.appendChild(styleEl);
    }
    styleEl.textContent = CORE_STYLES;

    if (document.body) {
      document.body.style.background = `
        radial-gradient(900px 500px at 0% 0%, color-mix(in srgb, ${settings.accent} 18%, transparent), transparent 55%),
        linear-gradient(180deg, ${theme.bg}, ${theme.panel} 35%, ${theme.panel2} 100%)
      `;
    }

    return settings;
  }

  window.PocketSteakTheme = {
    applySettings,
    readSettings,
    saveSettings,
    themes,
  };

  applySettings();
})();
