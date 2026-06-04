const SUPPORTED_GAMES = {
  "106525922058591": true
};

function isAdmin(request) {
  const cookie = request.headers.get("Cookie") || "";
  return cookie.includes("pulse_admin=loggedin");
}

function isBrowser(request) {
  const ua = (request.headers.get("User-Agent") || "").toLowerCase();
  return ua.includes("mozilla");
}

function loaderLua() {
  return `
local BASE_URL = "https://pulseware.lol/server/script"
local gameId = tostring(game.PlaceId)

local supported = {
    ["106525922058591"] = true,
}

if not supported[gameId] then
    warn("[Pulse.xd] Unsupported game id: " .. gameId)
    return
end

local ok, code = pcall(function()
    return game:HttpGet(BASE_URL .. "?game=" .. gameId .. "&t=" .. tostring(os.time()))
end)

if not ok or not code or code == "" or code == "UNSUPPORTED" then
    warn("[Pulse.xd] Game script failed for game id: " .. gameId)
    return
end

local fn, err = loadstring(code)
if not fn then
    warn("[Pulse.xd] Loadstring error: " .. tostring(err))
    return
end

fn()
`;
}

export async function onRequestGet(context) {
  const request = context.request;
  const url = new URL(request.url);
  const gameId = url.searchParams.get("game");

  const browser = isBrowser(request);
  const admin = isAdmin(request);

  if (browser && !admin) {
    return new Response("Access Denied", {
      status: 403,
      headers: { "Content-Type": "text/plain" }
    });
  }

  // Main buyer loader:
  // https://pulseware.lol/server/script
  if (!gameId) {
    return new Response(loaderLua(), {
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store"
      }
    });
  }

  if (!SUPPORTED_GAMES[gameId]) {
    return new Response("UNSUPPORTED", {
      headers: { "Content-Type": "text/plain" }
    });
  }

  // Loads from your Cloudflare Pages static games folder:
  // /games/106525922058591.lua
  const gameFileUrl = new URL(`/games/${gameId}.lua`, request.url);
  const res = await fetch(gameFileUrl.toString(), {
    headers: { "Cache-Control": "no-store" }
  });

  if (!res.ok) {
    return new Response("UNSUPPORTED", {
      headers: { "Content-Type": "text/plain" }
    });
  }

  const code = await res.text();

  return new Response(code, {
    headers: {
      "Content-Type": "text/plain",
      "Cache-Control": "no-store"
    }
  });
}
