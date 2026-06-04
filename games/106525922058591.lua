-- // Satire | Airflow UI | Glass Bridge Cleaned & Fixed

local Airflow = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/4lpaca-pin/Airflow/refs/heads/main/src/source.luau"))()

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer

-- ════════════════════════════════════════
--   WINDOW
-- ════════════════════════════════════════
local Window = Airflow:Init({
    Name        = "Satire",
    Keybind     = "RightControl",
    Highlight   = Color3.fromRGB(255, 255, 255),
    Resizable   = false,
    UnlockMouse = false,
    IconSize    = 0,
})

-- ════════════════════════════════════════
--   NEON WHITE OUTLINE
-- ════════════════════════════════════════
task.defer(function()
    task.wait(0.35)
    local CoreGui = game:GetService("CoreGui")
    local function PatchStroke(parent)
        for _, gui in ipairs(parent:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:sub(1,8) == ".Airflow" then
                for _, frame in ipairs(gui:GetChildren()) do
                    if frame:IsA("Frame") then
                        local stroke = frame:FindFirstChildOfClass("UIStroke")
                        if stroke then
                            local grad = stroke:FindFirstChildOfClass("UIGradient")
                            if grad then grad:Destroy() end
                            stroke.Color           = Color3.fromRGB(255,255,255)
                            stroke.Thickness       = 3
                            stroke.Transparency    = 0
                            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        end
                        return
                    end
                end
            end
        end
    end
    PatchStroke(CoreGui)
    CoreGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child.Name:sub(1,8) == ".Airflow" then
            task.wait(0.2); PatchStroke(CoreGui)
        end
    end)
end)

-- ════════════════════════════════════════
--   SERVICES / REFS
-- ════════════════════════════════════════
local Tiles            = workspace:WaitForChild("Tiles")
local GameFolder       = workspace:WaitForChild("Game")
local MiniGlassBridge  = GameFolder:WaitForChild("MiniGlassBridge")
local MiniGlassFolder  = MiniGlassBridge:WaitForChild("Glass") -- Added deep nested Glass folder configuration
local CorrectTiles     = ReplicatedStorage:WaitForChild("ClientConfiguration"):WaitForChild("CorrectTiles")
local WinEvent         = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Win")
local CrateEvent       = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Crate")

-- ════════════════════════════════════════
--   HELPERS & STATE TRACKING
-- ════════════════════════════════════════
local Connections = {}
local OriginalProperties = {} 

local function Disconnect(key)
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

local function GetChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function GetHRP()  local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function colorModel(model, color)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not OriginalProperties[obj] then
                OriginalProperties[obj] = {
                    Color = obj.Color,
                    Material = obj.Material,
                    Transparency = obj.Transparency
                }
            end
            obj.Color    = color
            obj.Material = Enum.Material.Plastic
        end
    end
end

local function ResetVisuals()
    for obj, props in pairs(OriginalProperties) do
        if obj and obj.Parent then
            obj.Color = props.Color
            obj.Material = props.Material
            obj.Transparency = props.Transparency
        end
    end
    OriginalProperties = {}
end

local function getTileCFrame(bridgeIndex)
    local valueObj = CorrectTiles:FindFirstChild(tostring(bridgeIndex))
    if not valueObj then return nil end
    
    local bridge = nil
    if bridgeIndex >= 100 and bridgeIndex <= 107 then
        bridge = MiniGlassFolder:FindFirstChild(tostring(bridgeIndex)) -- Targets workspace.Game.MiniGlassBridge.Glass
    else
        bridge = Tiles:FindFirstChild(tostring(bridgeIndex))
    end
    
    if not bridge then return nil end
    
    local correctSide = tostring(valueObj.Value)
    local sideModel   = bridge:FindFirstChild(correctSide)
    if not sideModel then return nil end
    
    local part = sideModel:IsA("BasePart") and sideModel or sideModel:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

-- ════════════════════════════════════════
--   TABS
-- ════════════════════════════════════════
local MainTab   = Window:DrawTab({ Name = "Main"   })
local TargetTab = Window:DrawTab({ Name = "Target", Icon = "crosshair" })
local MiscTab   = Window:DrawTab({ Name = "Misc",   Icon = "folder"    })

local WinSection   = MainTab:AddSection({ Name = "Win",   Position = "left"  })
local CoinSection  = MainTab:AddSection({ Name = "Coins", Position = "left"  })
local GlassSection = MainTab:AddSection({ Name = "Glass Bridge", Position = "left" })

-- ════════════════════════════════════════
--   WIN FARM
-- ════════════════════════════════════════
WinSection:AddToggle({
    Name     = "Win Farm",
    Default  = false,
    Callback = function(state)
        if state then
            Connections["WinFarm"] = RunService.Heartbeat:Connect(function()
                pcall(function() WinEvent:FireServer() end)
            end)
            Airflow:Notify({ Title = "Satire", Content = "Win Farm started", Duration = 3 })
        else
            Disconnect("WinFarm")
            Airflow:Notify({ Title = "Satire", Content = "Win Farm stopped", Duration = 3 })
        end
    end,
})

WinSection:AddButton({
    Name = "Instant Win",
    Callback = function()
        pcall(function() WinEvent:FireServer() end)
        Airflow:Notify({ Title = "Satire", Content = "Instant Win fired", Duration = 3 })
    end,
})

-- ════════════════════════════════════════
--   COINS
-- ════════════════════════════════════════
local FarmConnection = nil
local FarmActive     = false

local function StartFarm()
    if FarmActive then return end
    FarmActive = true
    FarmConnection = RunService.Heartbeat:Connect(function()
        pcall(function() CrateEvent:InvokeServer("x1", "Cash Crate") end)
    end)
end
local function StopFarm()
    FarmActive = false
    if FarmConnection then FarmConnection:Disconnect(); FarmConnection = nil end
end

CoinSection:AddButton({
    Name = "Free Cash",
    Callback = function()
        pcall(function() CrateEvent:InvokeServer("x1", "Cash Crate") end)
        Airflow:Notify({ Title = "Satire", Content = "Free Cash Claimed", Duration = 3 })
    end,
})

CoinSection:AddToggle({
    Name     = "Cash Farm",
    Default  = false,
    Callback = function(state)
        if state then
            StartFarm()
            Airflow:Notify({ Title = "Satire", Content = "Cash Farm Started", Duration = 3 })
        else
            StopFarm()
            Airflow:Notify({ Title = "Satire", Content = "Cash Farm Stopped", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   GLASS BRIDGE (1 - 50)
-- ════════════════════════════════════════
local PathHighlights = {}
local function ClearPath()
    for _, h in pairs(PathHighlights) do pcall(function() h:Destroy() end) end
    PathHighlights = {}
end

local function DrawPath()
    ClearPath()
    for i = 1, 50 do
        local bridge   = Tiles:FindFirstChild(tostring(i))
        local valueObj = CorrectTiles:FindFirstChild(tostring(i))
        if bridge and valueObj then
            local correctSide = tostring(valueObj.Value)
            for _, side in ipairs({"1","2"}) do
                local sideModel = bridge:FindFirstChild(side)
                if sideModel then
                    local color = (side == correctSide) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                    colorModel(sideModel, color)

                    if side == correctSide then
                        for _, part in ipairs(sideModel:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local h = Instance.new("SelectionBox")
                                h.Adornee       = part
                                h.Color3        = Color3.fromRGB(0,255,0)
                                h.LineThickness = 0.05
                                h.SurfaceTransparency = 0.7
                                h.SurfaceColor3 = Color3.fromRGB(0,255,0)
                                h.Parent        = part
                                table.insert(PathHighlights, h)
                            end
                        end
                    end
                end
            end
        end
    end
end

GlassSection:AddToggle({
    Name     = "Show Path",
    Default  = false,
    Callback = function(state)
        if state then
            DrawPath()
            Connections["ShowPath"] = RunService.Heartbeat:Connect(DrawPath)
            Airflow:Notify({ Title = "Satire", Content = "Show Path enabled", Duration = 3 })
        else
            Disconnect("ShowPath")
            ClearPath()
            ResetVisuals()
            Airflow:Notify({ Title = "Satire", Content = "Show Path disabled", Duration = 3 })
        end
    end,
})

GlassSection:AddTextbox({
    Name        = "Teleport to Glass",
    Placeholder = "Enter glass number (1-50)...",
    Default     = "",
    Numeric     = true,
    Finished    = true,
    Callback    = function(val)
        if not val or val == "" then return end
        local idx = tonumber(val)
        local cf  = getTileCFrame(idx)
        if cf then
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = cf + Vector3.new(0,4,0)
                Airflow:Notify({ Title = "Satire", Content = "Teleported to glass "..val, Duration = 3 })
            end
        else
            Airflow:Notify({ Title = "Satire", Content = "Tile "..val.." not found", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   TARGET PLAYER
-- ════════════════════════════════════════
local TargetSection = TargetTab:AddSection({ Name = "Target Player", Position = "left" })
local TargetName     = ""

TargetSection:AddTextbox({
    Name        = "Username",
    Placeholder = "Enter username...",
    Default     = "",
    Finished    = false,
    Callback    = function(val) TargetName = val end,
})

local function GetTargetChar()
    local p = Players:FindFirstChild(TargetName)
    return p and p.Character
end

local function GetTargetHRP()
    local c = GetTargetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

TargetSection:AddButton({
    Name = "Fling",
    Callback = function()
        local hrp    = GetHRP()
        local target = GetTargetHRP()
        if not hrp or not target then
            Airflow:Notify({ Title = "Satire", Content = "Target not found", Duration = 3 })
            return
        end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = (target.Position - hrp.Position).Unit * 500
        bv.MaxForce  = Vector3.new(1e5,1e5,1e5)
        bv.Parent    = target
        task.delay(0.15, function() pcall(function() bv:Destroy() end) end)
        Airflow:Notify({ Title = "Satire", Content = "Flinged "..TargetName, Duration = 3 })
    end,
})

TargetSection:AddToggle({
    Name     = "Loop Fling",
    Default  = false,
    Callback = function(state)
        if state then
            Connections["LoopFling"] = RunService.Heartbeat:Connect(function()
                local hrp    = GetHRP()
                local target = GetTargetHRP()
                if not hrp or not target then return end
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = (target.Position - hrp.Position).Unit * 500
                bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                bv.Parent   = target
                task.delay(0.1, function() pcall(function() bv:Destroy() end) end)
            end)
            Airflow:Notify({ Title = "Satire", Content = "Loop Fling started", Duration = 3 })
        else
            Disconnect("LoopFling")
            Airflow:Notify({ Title = "Satire", Content = "Loop Fling stopped", Duration = 3 })
        end
    end,
})

TargetSection:AddToggle({
    Name     = "View",
    Default  = false,
    Callback = function(state)
        local cam = workspace.CurrentCamera
        if state then
            Connections["View"] = RunService.RenderStepped:Connect(function()
                local target = GetTargetHRP()
                if target then cam.CameraSubject = target end
            end)
            Airflow:Notify({ Title = "Satire", Content = "Viewing "..TargetName, Duration = 3 })
        else
            Disconnect("View")
            local hum = GetHum()
            if hum then cam.CameraSubject = hum end
            Airflow:Notify({ Title = "Satire", Content = "View stopped", Duration = 3 })
        end
    end,
})

TargetSection:AddButton({
    Name = "Teleport",
    Callback = function()
        local hrp    = GetHRP()
        local target = GetTargetHRP()
        if not hrp or not target then
            Airflow:Notify({ Title = "Satire", Content = "Target not found", Duration = 3 })
            return
        end
        hrp.CFrame = target.CFrame + Vector3.new(0,3,0)
        Airflow:Notify({ Title = "Satire", Content = "Teleported to "..TargetName, Duration = 3 })
    end,
})

-- ════════════════════════════════════════
--   MISC TAB (MINI GLASS ESP 100-107 & MOVEMENT)
-- ════════════════════════════════════════
local MiscLeft  = MiscTab:AddSection({ Name = "Glass",    Position = "left"  })
local MiscRight = MiscTab:AddSection({ Name = "Movement", Position = "right" })

local MiniHighlights = {}
local function ClearMiniESP()
    for _, h in pairs(MiniHighlights) do pcall(function() h:Destroy() end) end
    MiniHighlights = {}
end

local function DrawMiniESP()
    ClearMiniESP()
    for i = 100, 107 do
        local bridge   = MiniGlassFolder:FindFirstChild(tostring(i)) -- Pointed straight into the new 'Glass' folder
        local valueObj = CorrectTiles:FindFirstChild(tostring(i))
        if bridge and valueObj then
            local correctSide = tostring(valueObj.Value)
            for _, side in ipairs({"1","2"}) do
                local sideModel = bridge:FindFirstChild(side)
                if sideModel then
                    local color = (side == correctSide) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                    colorModel(sideModel, color)
                    
                    if side == correctSide then
                        for _, part in ipairs(sideModel:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local h = Instance.new("SelectionBox")
                                h.Adornee            = part
                                h.Color3             = Color3.fromRGB(0,255,0)
                                h.LineThickness      = 0.05
                                h.SurfaceTransparency = 0.7
                                h.SurfaceColor3     = Color3.fromRGB(0,255,0)
                                h.Parent            = part
                                table.insert(MiniHighlights, h)
                            end
                        end
                    end
                end
            end
        end
    end
end

MiscLeft:AddToggle({
    Name     = "Mini Glass ESP",
    Default  = false,
    Callback = function(state)
        if state then
            DrawMiniESP()
            Connections["MiniESP"] = RunService.Heartbeat:Connect(DrawMiniESP)
            Airflow:Notify({ Title = "Satire", Content = "Mini Glass ESP enabled", Duration = 3 })
        else
            Disconnect("MiniESP")
            ClearMiniESP()
            ResetVisuals()
            Airflow:Notify({ Title = "Satire", Content = "Mini Glass ESP disabled", Duration = 3 })
        end
    end,
})

MiscLeft:AddDropdown({
    Name   = "Teleport Upon Correct",
    Values = {"100","101","102","103","104","105","106","107"},
    Multi  = false,
    Default = nil,
    Callback = function(val)
        if not val then return end
        local cf = getTileCFrame(tonumber(val))
        if cf then
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = cf + Vector3.new(0,4,0)
                Airflow:Notify({ Title = "Satire", Content = "Teleported to mini glass "..val, Duration = 3 })
            end
        else
            Airflow:Notify({ Title = "Satire", Content = "Tile "..val.." not found", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   MOVEMENT MECHANICS
-- ════════════════════════════════════════
MiscRight:AddToggle({
    Name     = "NoClip",
    Default  = false,
    Callback = function(state)
        if state then
            Connections["NoClip"] = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        else
            Disconnect("NoClip")
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end,
})

MiscRight:AddToggle({
    Name     = "Float",
    Default  = false,
    Callback = function(state)
        local hrp = GetHRP()
        if not hrp then return end
        if state then
            local bv = Instance.new("BodyVelocity")
            bv.Name      = "FloatBV"
            bv.Velocity  = Vector3.zero
            bv.MaxForce  = Vector3.new(0,4000,0)
            bv.Parent    = hrp
        else
            local bv = hrp:FindFirstChild("FloatBV")
            if bv then bv:Destroy() end
        end
    end,
})

local FlySpeedValue = 40
local FlyBV, FlyBG
MiscRight:AddToggle({
    Name     = "Fly",
    Default  = false,
    Callback = function(state)
        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum then return end

        if state then
            hum.PlatformStand = true
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.Velocity  = Vector3.zero
            FlyBV.MaxForce  = Vector3.new(1e5,1e5,1e5)
            FlyBV.Parent    = hrp

            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            FlyBG.P         = 1e4
            FlyBG.Parent    = hrp

            local cam = workspace.CurrentCamera
            Connections["Fly"] = RunService.Heartbeat:Connect(function()
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
                FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * FlySpeedValue or Vector3.zero
                FlyBG.CFrame   = cam.CFrame
            end)
        else
            Disconnect("Fly")
            if FlyBV then FlyBV:Destroy(); FlyBV = nil end
            if FlyBG then FlyBG:Destroy(); FlyBG = nil end
            if hum   then hum.PlatformStand = false end
        end
    end,
})

local SpeedEnabled = false
local SpeedValue   = 16
MiscRight:AddTextbox({
    Name        = "Speed",
    Placeholder = "16",
    Default     = "16",
    Numeric     = true,
    Finished    = true,
    Callback    = function(val)
        SpeedValue = tonumber(val) or 16
        if SpeedEnabled then
            local hum = GetHum()
            if hum then hum.WalkSpeed = SpeedValue end
        end
    end,
})

MiscRight:AddToggle({
    Name     = "Speed Enabled",
    Default  = false,
    Callback = function(state)
        SpeedEnabled = state
        local hum = GetHum()
        if hum then hum.WalkSpeed = state and SpeedValue or 16 end
        if state then
            Connections["Speed"] = LocalPlayer.CharacterAdded:Connect(function(char)
                local h = char:WaitForChild("Humanoid", 5)
                if h and SpeedEnabled then h.WalkSpeed = SpeedValue end
            end)
        else
            Disconnect("Speed")
        end
    end,
})
