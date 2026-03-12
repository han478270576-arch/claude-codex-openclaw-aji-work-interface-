(function () {
  const STORAGE_KEY = "openclaw.control.settings.v1";

  function readSettings() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  }

  function buildGatewayUrl() {
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    return protocol + "//" + window.location.host;
  }

  try {
    const url = new URL(window.location.href);
    const token = url.searchParams.get("token") || "";
    const sessionKey = url.searchParams.get("session") || "";

    if (!token && !sessionKey) {
      return;
    }

    const current = readSettings();
    const next = {
      ...current,
      gatewayUrl: buildGatewayUrl(),
      baseUrl: window.location.origin
    };

    if (token) {
      next.token = token;
    }

    if (sessionKey) {
      next.sessionKey = sessionKey;
      next.lastActiveSessionKey = sessionKey;
    }

    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    // Ignore preboot sync failures and let the app continue booting.
  }
})();
