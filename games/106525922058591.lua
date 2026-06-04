-- // Satire | Airflow UI | Free Cash + Cash Farm

local Airflow = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/4lpaca-pin/Airflow/refs/heads/main/src/source.luau"))()

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrateEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Crate")

local FarmConnection = nil
local FarmActive     = false

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
--   kill the UIGradient on UIStroke too
-- ════════════════════════════════════════
task.defer(function()
    task.wait(0.35)
    local CoreGui = game:GetService("CoreGui")

    local function PatchStroke(parent)
        for _, gui in ipairs(parent:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:sub(1, 8) == ".Airflow" then
                for _, frame in ipairs(gui:GetChildren()) do
                    if frame:IsA("Frame") then
                        local stroke = frame:FindFirstChildOfClass("UIStroke")
                        if stroke then
                            -- kill the gradient that overrides color
                            local gradient = stroke:FindFirstChildOfClass("UIGradient")
                            if gradient then
                                gradient:Destroy()
                            end
                            stroke.Color        = Color3.fromRGB(255, 255, 255)
                            stroke.Thickness    = 3
                            stroke.Transparency = 0
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
        if child:IsA("ScreenGui") and child.Name:sub(1, 8) == ".Airflow" then
            task.wait(0.2)
            PatchStroke(CoreGui)
        end
    end)
end)

local CashTab = Window:DrawTab({ Name = "Cash" })

local Section = CashTab:AddSection({
    Name     = "Controls",
    Position = "left",
})

local function StartFarm()
    if FarmActive then return end
    FarmActive = true
    FarmConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            CrateEvent:InvokeServer("x1", "Cash Crate")
        end)
    end)
end

local function StopFarm()
    FarmActive = false
    if FarmConnection then
        FarmConnection:Disconnect()
        FarmConnection = nil
    end
end

Section:AddButton({
    Name = "Free Cash",
    Callback = function()
        pcall(function()
            CrateEvent:InvokeServer("x1", "Cash Crate")
        end)
        Airflow:Notify({
            Title    = "Satire",
            Content  = "Free Cash Claimed                    ",
            Duration = 3,
        })
    end,
})

Section:AddToggle({
    Name     = "Cash Farm",
    Default  = false,
    Callback = function(state)
        if state then
            StartFarm()
            Airflow:Notify({
                Title    = "Satire",
                Content  = "Cash Farm Started                    ",
                Duration = 3,
            })
        else
            StopFarm()
            Airflow:Notify({
                Title    = "Satire",
                Content  = "Cash Farm Stopped                    ",
                Duration = 3,
            })
        end
    end,
})
