-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local highlightsEnabled = false
local trackingEnabled = false

--------------------------------------------------------------------------------
-- 1. UI CREATION (Modern Floating Menu)
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevTargetingMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 140)
mainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- Makes the UI easy to move around
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 70)
stroke.Thickness = 1
stroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Target System Controls"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- Helper function to generate clean control buttons
local function createToggleButton(text, position, onClick)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.85, 0, 0, 32)
    button.Position = position
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    button.Text = text .. ": OFF"
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 13
    button.BorderSizePixel = 0
    button.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button

    local isActive = false
    button.MouseButton1Click:Connect(function()
        isActive = not isActive
        if isActive then
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Text = text .. ": ON"
        else
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
            button.TextColor3 = Color3.fromRGB(200, 200, 200)
            button.Text = text .. ": OFF"
        end
        onClick(isActive)
    end)
end

createToggleButton("Highlights (ESP)", UDim2.new(0.5, 0, 0, 40), function(state)
    highlightsEnabled = state
    if not state then
        -- Clear existing highlights when disabled
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("TargetHighlight") then
                player.Character.TargetHighlight:Destroy()
            end
        end
    end
end)

createToggleButton("Lock Camera", UDim2.new(0.5, 0, 0, 80), function(state)
    trackingEnabled = state
end)

--------------------------------------------------------------------------------
-- 2. HIGHLIGHT & TARGETING LOGIC
--------------------------------------------------------------------------------
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (mousePos - targetPos).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Render loop updating visual state every frame
RunService.RenderStepped:Connect(function()
    -- Manage Highlights
    if highlightsEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("TargetHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "TargetHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 60, 60)
                    highlight.FillTransparency = 0.6
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.Parent = player.Character
                end
            end
        end
    end

    -- Manage Camera Lock
    if trackingEnabled then
        local target = getClosestPlayerToCursor()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)
