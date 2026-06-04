-- Satire Hub | hubhandler.lua

local SCRIPT_URL = "https://pulseware.lol/server/script?game="

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

local gameId = tostring(game.PlaceId)
local gameScript = ""

local ok, result = pcall(function()
    return game:HttpGetAsync(SCRIPT_URL .. gameId)
end)

if ok then
    gameScript = result
end

if not ok or gameScript == "" or gameScript == "UNSUPPORTED" then
    local Window = Airflow:Init({
        Name = "Satire",
        Keybind = "RightControl",
        Highlight = Color3.fromRGB(255,255,255),
        Resizable = false,
        UnlockMouse = false,
        IconSize = 0,
    })

    PatchStroke()

    task.wait(0.5)

    Airflow:Notify({
        Title = "Satire",
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
    warn("[Satire] Failed to load game script: " .. tostring(err))
end
