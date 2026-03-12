(function () {
  const STORAGE_KEY = "openclaw.control.settings.v1";
  const SESSION_TOKEN_KEY = "openclaw.control.token.v1";
  const SESSION_TOKEN_PREFIX = "openclaw.control.token.v1:";
  const DEVICE_IDENTITY_KEY = "openclaw-device-identity-v1";
  const DEVICE_AUTH_KEY = "openclaw.device.auth.v1";
  const TEST_HOST = "test.ajiclaw.com";
  const TEST_TOKEN = "21b91dedc2411853d2257b3241672c7139e8dfb64ab97a50";

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

  function normalizeGatewayUrl(raw) {
    const value = (raw || "").trim();
    if (!value) return "default";
    try {
      const base = typeof window !== "undefined" ? `${window.location.protocol}//${window.location.host}${window.location.pathname || "/"}` : undefined;
      const parsed = base ? new URL(value, base) : new URL(value);
      const pathname = parsed.pathname === "/" ? "" : parsed.pathname.replace(/\/+$/g, "") || parsed.pathname;
      return `${parsed.protocol}//${parsed.host}${pathname}`;
    } catch {
      return value;
    }
  }

  function writeSessionToken(gatewayUrl, token) {
    try {
      const storage = window.sessionStorage;
      if (!storage) return;
      storage.removeItem(SESSION_TOKEN_KEY);
      const scopedKey = `${SESSION_TOKEN_PREFIX}${normalizeGatewayUrl(gatewayUrl)}`;
      if (token) {
        storage.setItem(scopedKey, token);
      } else {
        storage.removeItem(scopedKey);
      }
    } catch {
      // ignore
    }
  }

  try {
    const url = new URL(window.location.href);
    const isTestHost = url.host === TEST_HOST;
    const token = isTestHost ? TEST_TOKEN : url.searchParams.get("token") || "";
    const sessionKey = url.searchParams.get("session") || "";

    if (!token && !sessionKey) {
      return;
    }

    const current = readSettings();
    const gatewayUrl = buildGatewayUrl();
    const next = {
      ...current,
      gatewayUrl,
      baseUrl: window.location.origin
    };

    if (token) {
      next.token = token;
    }

    if (sessionKey) {
      next.sessionKey = sessionKey;
      next.lastActiveSessionKey = sessionKey;
    }

    if (isTestHost) {
      next.password = "";
      window.localStorage.removeItem(DEVICE_IDENTITY_KEY);
      window.localStorage.removeItem(DEVICE_AUTH_KEY);
    }

    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    writeSessionToken(gatewayUrl, token);
  } catch {
    // Ignore preboot sync failures and let the app continue booting.
  }
})();
