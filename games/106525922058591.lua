-- // Satire | Impossible Math Bridge Obby
-- // Rename this file to the actual PlaceId
-- // Airflow and PatchStroke are passed in from hubhandler

-- ════════════════════════════════════════
--   SERVICES
-- ════════════════════════════════════════
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local LocalPlayer   = Players.LocalPlayer

-- ════════════════════════════════════════
--   INIT AIRFLOW WINDOW
-- ════════════════════════════════════════
local Window = Airflow:Init({
    Name        = "Satire",
    Keybind     = "RightControl",
    Highlight   = Color3.fromRGB(255, 255, 255),
    Resizable   = false,
    UnlockMouse = false,
    IconSize    = 0,
})

PatchStroke()

-- ════════════════════════════════════════
--   TABS
-- ════════════════════════════════════════
local MainTab   = Window:DrawTab({ Name = "Main" })
local PlayerTab = Window:DrawTab({ Name = "Player" })
local MiscTab   = Window:DrawTab({ Name = "Misc" })

-- ════════════════════════════════════════
--   SECTIONS
-- ════════════════════════════════════════
local AutoSection   = MainTab:AddSection({ Name = "Automation",  Position = "left"  })
local VisualSection = MainTab:AddSection({ Name = "Visuals",     Position = "right" })
local MovSection    = PlayerTab:AddSection({ Name = "Movement",  Position = "left"  })
local CharSection   = PlayerTab:AddSection({ Name = "Character", Position = "right" })
local MiscSection   = MiscTab:AddSection({ Name = "Misc",        Position = "left"  })

-- ════════════════════════════════════════
--   STATE
-- ════════════════════════════════════════
local State = {
    AutoAnswer    = false,
    AutoJump      = false,
    InfJump       = false,
    SpeedValue    = 16,
    JumpValue     = 50,
    NoClip        = false,
    ESP           = false,
    AutoRespawn   = false,
    FlyActive     = false,
    FlySpeed      = 40,
}

local Connections = {}

local function Disconnect(key)
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

-- ════════════════════════════════════════
--   HELPERS
-- ════════════════════════════════════════
local function GetChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ════════════════════════════════════════
--   AUTO ANSWER — reads math guis
-- ════════════════════════════════════════
local function SolveMathQuestion(text)
    -- parse simple expressions like "5 + 3 = ?" or "12 × 4"
    text = text:gsub("×","*"):gsub("÷","/"):gsub("%?",""):gsub("=","")
    local fn = loadstring("return " .. text)
    if fn then
        local ok, result = pcall(fn)
        if ok then return tostring(math.floor(result + 0.5)) end
    end
    return nil
end

AutoSection:AddToggle({
    Name     = "Auto Answer",
    Default  = false,
    Callback = function(val)
        State.AutoAnswer = val
        if val then
            Connections["AutoAnswer"] = RunService.Heartbeat:Connect(function()
                -- scan for answer prompts in the game's UI
                local gui = LocalPlayer.PlayerGui
                for _, screen in ipairs(gui:GetChildren()) do
                    for _, obj in ipairs(screen:GetDescendants()) do
                        if obj:IsA("TextLabel") and obj.Text:find("[0-9]") then
                            local answer = SolveMathQuestion(obj.Text)
                            if answer then
                                -- look for nearby TextBox/Button to submit
                                local parent = obj.Parent
                                if parent then
                                    local box = parent:FindFirstChildOfClass("TextBox")
                                    local btn = parent:FindFirstChildOfClass("TextButton")
                                    if box then
                                        box.Text = answer
                                        -- fire FocusLost to submit
                                        local ok2 = pcall(function()
                                            box:ReleaseFocus()
                                        end)
                                    end
                                    if btn then
                                        pcall(function()
                                            btn:Activate()
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            Airflow:Notify({ Title = "Satire", Content = "Auto Answer enabled                    ", Duration = 3 })
        else
            Disconnect("AutoAnswer")
            Airflow:Notify({ Title = "Satire", Content = "Auto Answer disabled                    ", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   AUTO JUMP — jumps over incoming blocks
-- ════════════════════════════════════════
AutoSection:AddToggle({
    Name     = "Auto Jump",
    Default  = false,
    Callback = function(val)
        State.AutoJump = val
        if val then
            Connections["AutoJump"] = RunService.Heartbeat:Connect(function()
                local hrp = GetHRP()
                local hum = GetHum()
                if not hrp or not hum then return end
                -- detect parts moving toward player
                for _, part in ipairs(workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored then
                        local dist = (part.Position - hrp.Position).Magnitude
                        if dist < 10 and part.Velocity.Magnitude > 5 then
                            if hum.FloorMaterial ~= Enum.Material.Air then
                                hum.Jump = true
                            end
                        end
                    end
                end
            end)
            Airflow:Notify({ Title = "Satire", Content = "Auto Jump enabled                    ", Duration = 3 })
        else
            Disconnect("AutoJump")
            Airflow:Notify({ Title = "Satire", Content = "Auto Jump disabled                    ", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   AUTO RESPAWN
-- ════════════════════════════════════════
AutoSection:AddToggle({
    Name     = "Auto Respawn",
    Default  = false,
    Callback = function(val)
        State.AutoRespawn = val
        if val then
            Connections["AutoRespawn"] = RunService.Heartbeat:Connect(function()
                local hum = GetHum()
                if hum and hum.Health <= 0 then
                    task.wait(0.1)
                    LocalPlayer:LoadCharacter()
                end
            end)
        else
            Disconnect("AutoRespawn")
        end
    end,
})

-- ════════════════════════════════════════
--   CHECKPOINT TELEPORT
-- ════════════════════════════════════════
AutoSection:AddButton({
    Name = "Teleport to Last Checkpoint",
    Callback = function()
        local hrp = GetHRP()
        if not hrp then return end
        -- look for checkpoint parts
        local best, bestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("checkpoint") or name:find("stage") or name:find("spawn") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = obj
                    end
                end
            end
        end
        if best then
            hrp.CFrame = best.CFrame + Vector3.new(0, 5, 0)
            Airflow:Notify({ Title = "Satire", Content = "Teleported to checkpoint                    ", Duration = 3 })
        else
            Airflow:Notify({ Title = "Satire", Content = "No checkpoint found                    ", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   ESP — highlight all players
-- ════════════════════════════════════════
local ESPBoxes = {}

local function RemoveESP()
    for _, h in pairs(ESPBoxes) do
        if h then pcall(function() h:Remove() end) end
    end
    ESPBoxes = {}
end

local function AddESP(player)
    if player == LocalPlayer then return end
    local function Build()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local highlight = Instance.new("Highlight")
        highlight.FillColor      = Color3.fromRGB(255,255,255)
        highlight.OutlineColor   = Color3.fromRGB(255,255,255)
        highlight.FillTransparency    = 0.7
        highlight.OutlineTransparency = 0
        highlight.Adornee = char
        highlight.Parent  = char
        ESPBoxes[player.UserId] = highlight
    end
    Build()
    player.CharacterAdded:Connect(function()
        task.wait(0.5); Build()
    end)
end

VisualSection:AddToggle({
    Name     = "Player ESP",
    Default  = false,
    Callback = function(val)
        State.ESP = val
        if val then
            for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
            Connections["ESPAdded"] = Players.PlayerAdded:Connect(AddESP)
            Airflow:Notify({ Title = "Satire", Content = "ESP enabled                    ", Duration = 3 })
        else
            RemoveESP()
            Disconnect("ESPAdded")
            Airflow:Notify({ Title = "Satire", Content = "ESP disabled                    ", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   WALKSPEED
-- ════════════════════════════════════════
MovSection:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 250,
    Default  = 16,
    Round    = 0,
    Callback = function(val)
        State.SpeedValue = val
        local hum = GetHum()
        if hum then hum.WalkSpeed = val end
        -- reapply on respawn
        LocalPlayer.CharacterAdded:Connect(function(char)
            local h = char:WaitForChild("Humanoid", 5)
            if h then h.WalkSpeed = State.SpeedValue end
        end)
    end,
})

-- ════════════════════════════════════════
--   JUMP POWER
-- ════════════════════════════════════════
MovSection:AddSlider({
    Name     = "Jump Power",
    Min      = 50,
    Max      = 500,
    Default  = 50,
    Round    = 0,
    Callback = function(val)
        State.JumpValue = val
        local hum = GetHum()
        if hum then
            hum.JumpPower = val
            hum.UseJumpPower = true
        end
        LocalPlayer.CharacterAdded:Connect(function(char)
            local h = char:WaitForChild("Humanoid", 5)
            if h then
                h.UseJumpPower = true
                h.JumpPower = State.JumpValue
            end
        end)
    end,
})

-- ════════════════════════════════════════
--   INFINITE JUMP
-- ════════════════════════════════════════
MovSection:AddToggle({
    Name     = "Infinite Jump",
    Default  = false,
    Callback = function(val)
        State.InfJump = val
        if val then
            Connections["InfJump"] = game:GetService("UserInputService").JumpRequest:Connect(function()
                local hum = GetHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            Disconnect("InfJump")
        end
    end,
})

-- ════════════════════════════════════════
--   FLY
-- ════════════════════════════════════════
local FlyBV, FlyBG
MovSection:AddToggle({
    Name     = "Fly",
    Default  = false,
    Callback = function(val)
        State.FlyActive = val
        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum then return end

        if val then
            hum.PlatformStand = true

            FlyBV = Instance.new("BodyVelocity")
            FlyBV.Velocity       = Vector3.zero
            FlyBV.MaxForce       = Vector3.new(1e5,1e5,1e5)
            FlyBV.Parent         = hrp

            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque      = Vector3.new(1e5,1e5,1e5)
            FlyBG.P              = 1e4
            FlyBG.Parent         = hrp

            local UIS = game:GetService("UserInputService")
            local cam = workspace.CurrentCamera

            Connections["Fly"] = RunService.Heartbeat:Connect(function()
                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space)   then dir = dir + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end

                FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.zero
                FlyBG.CFrame   = cam.CFrame
            end)
            Airflow:Notify({ Title = "Satire", Content = "Fly enabled                    ", Duration = 3 })
        else
            Disconnect("Fly")
            if FlyBV then FlyBV:Destroy(); FlyBV = nil end
            if FlyBG then FlyBG:Destroy(); FlyBG = nil end
            if hum   then hum.PlatformStand = false end
            Airflow:Notify({ Title = "Satire", Content = "Fly disabled                    ", Duration = 3 })
        end
    end,
})

MovSection:AddSlider({
    Name     = "Fly Speed",
    Min      = 10,
    Max      = 200,
    Default  = 40,
    Round    = 0,
    Callback = function(val) State.FlySpeed = val end,
})

-- ════════════════════════════════════════
--   NOCLIP
-- ════════════════════════════════════════
CharSection:AddToggle({
    Name     = "NoClip",
    Default  = false,
    Callback = function(val)
        State.NoClip = val
        if val then
            Connections["NoClip"] = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            Disconnect("NoClip")
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

-- ════════════════════════════════════════
--   GOD MODE (fake — sets max health)
-- ════════════════════════════════════════
CharSection:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Callback = function(val)
        if val then
            Connections["God"] = RunService.Heartbeat:Connect(function()
                local hum = GetHum()
                if hum then
                    hum.Health    = hum.MaxHealth
                end
            end)
            Airflow:Notify({ Title = "Satire", Content = "God Mode enabled                    ", Duration = 3 })
        else
            Disconnect("God")
            Airflow:Notify({ Title = "Satire", Content = "God Mode disabled                    ", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════
--   MISC
-- ════════════════════════════════════════
MiscSection:AddButton({
    Name = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscSection:AddButton({
    Name = "Copy Game ID",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        Airflow:Notify({ Title = "Satire", Content = "Game ID copied                    ", Duration = 3 })
    end,
})

-- ════════════════════════════════════════
--   CLEANUP ON CHAR REMOVING
-- ════════════════════════════════════════
LocalPlayer.CharacterRemoving:Connect(function()
    RemoveESP()
    if FlyBV then FlyBV:Destroy(); FlyBV = nil end
    if FlyBG then FlyBG:Destroy(); FlyBG = nil end
end)
