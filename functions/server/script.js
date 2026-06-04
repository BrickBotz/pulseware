const RAW_BASE = "https://raw.githubusercontent.com/BrickBotz/Pulze/refs/heads/main/games";

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
local SCRIPT_URL = "https://pulseware.lol/server/script?game="
local gameId = tostring(game.PlaceId)

local supported = {
    ["106525922058591"] = true,
}

if not supported[gameId] then
    warn("[Pulse.xd] Unsupported game: " .. gameId)
    return
end

local Airflow = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/4lpaca-pin/Airflow/refs/heads/main/src/source.luau"
))()

local function PatchStroke()
    task.defer(function()
        task.wait(0.35)
        local CoreGui = game:GetService("CoreGui")

        local function Patch(parent)
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:sub(1,8) == ".Airflow" then
                    for _, frame in ipairs(gui:GetChildren()) do
                        if frame:IsA("Frame") then
                            local stroke = frame:FindFirstChildOfClass("UIStroke")
                            if stroke then
                                local grad = stroke:FindFirstChildOfClass("UIGradient")
                                if grad then grad:Destroy() end
                                stroke.Color = Color3.fromRGB(255,255,255)
                                stroke.Thickness = 3
                                stroke.Transparency = 0
                                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            end
                            return
                        end
                    end
                end
            end
        end

        Patch(CoreGui)

        CoreGui.ChildAdded:Connect(function(c)
            if c:IsA("ScreenGui") and c.Name:sub(1,8) == ".Airflow" then
                task.wait(0.2)
                Patch(CoreGui)
            end
        end)
    end)
end

local ok, gameScript = pcall(function()
    return game:HttpGetAsync(SCRIPT_URL .. gameId)
end)

if not ok or not gameScript or gameScript == "" or gameScript == "UNSUPPORTED" then
    Airflow:Notify({
        Title = "Pulse.xd",
        Content = "Game is not supported                    ",
        Duration = false,
    })
    return
end

local env = setmetatable({
    Airflow = Airflow,
    PatchStroke = PatchStroke,
}, { __index = getfenv() })

local fn, err = loadstring(gameScript)

if fn then
    setfenv(fn, env)
    fn()
else
    warn("[Pulse.xd] Failed to load game script: " .. tostring(err))
end
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

  // Main loader: https://pulseware.lol/server/script
  if (!gameId) {
    return new Response(loaderLua(), {
      status: 200,
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store"
      }
    });
  }

  // Game-specific script
  if (!SUPPORTED_GAMES[gameId]) {
    return new Response("UNSUPPORTED", {
      status: 200,
      headers: { "Content-Type": "text/plain" }
    });
  }

  const rawUrl = `${RAW_BASE}/${gameId}.lua`;
  const res = await fetch(rawUrl);

  if (!res.ok) {
    return new Response("UNSUPPORTED", {
      status: 200,
      headers: { "Content-Type": "text/plain" }
    });
  }

  const code = await res.text();

  return new Response(code, {
    status: 200,
    headers: {
      "Content-Type": "text/plain",
      "Cache-Control": "no-store"
    }
  });
}
