(function () {
  const STORAGE_KEY = "pocketsteak_tst_display_settings";

  const themes = {
    arctic: {
      bg: "#06131d",
      panel: "#0f2233",
      panel2: "#173147",
      text: "#f3f4f6",
      muted: "#b8bcc8",
    },
    midnight: {
      bg: "#050b16",
      panel: "#0b1a2b",
      panel2: "#102642",
      text: "#f5f9ff",
      muted: "#b9c7da",
    },
    slate: {
      bg: "#0b151c",
      panel: "#13232d",
      panel2: "#1d3341",
      text: "#f4f8fb",
      muted: "#c0ccd5",
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

  function applySettings(nextSettings = readSettings()) {
    const settings = {
      theme: "arctic",
      accent: "#ff7a18",
      density: "comfortable",
      ...nextSettings,
    };

    // If the accent is still the old default blue, force it to orange
    if (settings.accent === "#4fd1ff") {
      settings.accent = "#ff7a18";
    }

    const theme = themes[settings.theme] || themes.arctic;
    const root = document.documentElement;

    root.style.setProperty("--bg", theme.bg, "important");
    root.style.setProperty("--panel", theme.panel, "important");
    root.style.setProperty("--panel-2", theme.panel2, "important");
    root.style.setProperty("--text", theme.text, "important");
    root.style.setProperty("--muted", theme.muted, "important");
    root.style.setProperty("--accent", settings.accent, "important");
    root.style.setProperty("--accent-2", settings.accent, "important");
    root.style.setProperty("--accent-hover", settings.accent, "important");
    root.dataset.themeDensity = settings.density;

    if (document.body) {
      document.body.style.background = `
        radial-gradient(1200px 650px at 8% 0%, color-mix(in srgb, ${settings.accent} 18%, transparent), transparent 58%),
        radial-gradient(900px 500px at 100% 0%, color-mix(in srgb, ${settings.accent} 12%, transparent), transparent 42%),
        linear-gradient(180deg, ${theme.bg} 0%, ${theme.panel} 42%, ${theme.panel2} 100%)
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
