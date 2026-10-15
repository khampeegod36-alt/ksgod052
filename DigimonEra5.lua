print("[Digimon Era] SCRIPT STARTED")
-- ================================================
-- DIGIMON ERA AUTO FARM + AUTO FEED + AUTO EXPLORE + DUNGEON LOOP
-- (FIXED FOR MOBILE CONTROLLER UI LAYOUT)
-- ================================================

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
-- CONFIG
local DIGIMON_SCRIPT_URL =
    "https://raw.githubusercontent.com/khampeegod36-alt/ksgod052/refs/heads/main/DigimonEra5.lua"

local UI_NAME = "DigimonEra5_MultiUI"
local MIN_DISTANCE = 30
local ARRIVAL_DISTANCE = 4
local MAX_WALK_TIME = 10
local SEARCH_RADIUS = 500

local AUTO_FARM = false
local AUTO_CHEST = false
local AUTO_DROPS = false
local AUTO_HEAL = false
local AUTO_FEED = false
local AUTO_FEED_BUSY = false
local AUTO_FEED_WORKER_RUNNING = false
local AUTO_EXPLORE = false

local HEAL_DROP_AMOUNT = 500

local visited = {}
local openedChests = {}
local collectedDrops = {}

local function removeOldUI(parent)
    if not parent then return end
    local oldUI = parent:FindFirstChild(UI_NAME)
    if oldUI then oldUI:Destroy() end
end

removeOldUI(CoreGui)
removeOldUI(player:FindFirstChild("PlayerGui"))

if type(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then removeOldUI(hui) end
end

-- TELEPORT QUEUE
local function setupTeleportQueue()
    local q = queue_on_teleport or queueonteleport or queue_on_tp or queueontp
    if type(q) ~= "function" then return end

    local code = [[
        task.wait(10)
        local Players = game:GetService("Players")
        local CoreGui = game:GetService("CoreGui")
        local player = Players.LocalPlayer
        local UI_NAME = "DigimonEra4_MultiUI"

        local function hasUI(parent)
            return parent ~= nil and parent:FindFirstChild(UI_NAME) ~= nil
        end

        if hasUI(CoreGui) then return end
        local pGui = player and player:FindFirstChild("PlayerGui")
        if hasUI(pGui) then return end

        pcall(function()
            local url = "https://raw.githubusercontent.com/khampeegod36-alt/ksgod052/refs/heads/main/DigimonEra5.lua"
            local src = game:HttpGet(url, true)
            local fn = loadstring(src)
            if fn then fn() end
        end)
    ]]
    pcall(q, code)
end

setupTeleportQueue()

player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

local function sendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 2 })
    end)
end

-- ================================================
-- UI SETUP
-- ================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true

local parentSuccess = false
if type(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then
        pcall(function() screenGui.Parent = hui parentSuccess = true end)
    end
end

if not parentSuccess then
    pcall(function() screenGui.Parent = CoreGui parentSuccess = true end)
end

if not parentSuccess then
    pcall(function() screenGui.Parent = player:WaitForChild("PlayerGui") parentSuccess = true end)
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 210, 0, 420)
mainFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 0, 30)
titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Digimon Era Control"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(0.85, 0, 0.02, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.Text = "-"
minimizeBtn.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeBtn

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 0, 385)
contentContainer.Position = UDim2.new(0, 0, 0, 30)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 210, 0, 30)
        contentContainer.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 210, 0, 420)
        contentContainer.Visible = true
        minimizeBtn.Text = "-"
    end
end)

local function createToggleButton(name, pos, defaultText)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.9, 0, 0, 34)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = defaultText
    btn.Parent = contentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

local farmBtn = createToggleButton("FarmBtn", UDim2.new(0.05, 0, 0.01, 0), "Auto Farm: OFF")
local chestBtn = createToggleButton("ChestBtn", UDim2.new(0.05, 0, 0.13, 0), "Auto Chest: OFF")
local dropBtn = createToggleButton("DropBtn", UDim2.new(0.05, 0, 0.25, 0), "Auto Drops: OFF")
local healBtn = createToggleButton("HealBtn", UDim2.new(0.05, 0, 0.37, 0), "Auto Heal: OFF")
local feedBtn = createToggleButton("FeedBtn", UDim2.new(0.05, 0, 0.49, 0), "Auto Feed: OFF")
local exploreBtn = createToggleButton("ExploreBtn", UDim2.new(0.05, 0, 0.61, 0), "Auto Explore: OFF")
local dungeonBtn = createToggleButton("DungeonLoopBtn", UDim2.new(0.05, 0, 0.73, 0), "Dungeon Loop: OFF")

-- DUNGEON SETTINGS
local env = getgenv and getgenv() or _G
local DungeonSettings = env.DigimonEraDungeonSettings or { Map = "Forest", Level = "61-100", LockMap = false, LockLevel = false }
env.DigimonEraDungeonSettings = DungeonSettings

local DungeonLevels = {
    Forest = {"1-10", "11-30", "31-60", "61-100", "101-150", "151-220"},
    Volcano = {"1-30", "31-60", "61-110", "111-170", "171-240"},
    Snowland = {"20-40", "41-70", "71-140", "141-190", "191-260"}
}

local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 24, 0, 24)
settingsBtn.Position = UDim2.new(0.69, 0, 0.02, 0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
settingsBtn.TextColor3 = Color3.new(1, 1, 1)
settingsBtn.TextSize = 14
settingsBtn.Font = Enum.Font.SourceSansBold
settingsBtn.Text = "D"
settingsBtn.Parent = mainFrame

local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 220, 0, 205)
settingsFrame.Position = UDim2.new(1, 8, 0, 30)
settingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
settingsFrame.Visible = false
settingsFrame.Parent = mainFrame

local function makeSettingsButton(y, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.Parent = settingsFrame
    return btn
end

local mapBtn = makeSettingsButton(10, "Map: Forest")
local levelBtn = makeSettingsButton(48, "Level: 61-100")
local closeSettingsBtn = makeSettingsButton(162, "Close")

settingsBtn.MouseButton1Click:Connect(function() settingsFrame.Visible = not settingsFrame.Visible end)
closeSettingsBtn.MouseButton1Click:Connect(function() settingsFrame.Visible = false end)

local function updateButton(btn, enabled, label)
    btn.Text = label .. (enabled and ": ON" or ": OFF")
    btn.BackgroundColor3 = enabled and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
end

if exploreBtn then updateButton(exploreBtn, AUTO_EXPLORE, "Auto Explore") end
if dungeonBtn then updateButton(dungeonBtn, env.DigymonEraDungeonLoop or false, "Dungeon Loop") end

-- TOGGLE EVENTS
farmBtn.MouseButton1Click:Connect(function() AUTO_FARM = not AUTO_FARM updateButton(farmBtn, AUTO_FARM, "Auto Farm") end)
chestBtn.MouseButton1Click:Connect(function() AUTO_CHEST = not AUTO_CHEST updateButton(chestBtn, AUTO_CHEST, "Auto Chest") end)
dropBtn.MouseButton1Click:Connect(function() AUTO_DROPS = not AUTO_DROPS updateButton(dropBtn, AUTO_DROPS, "Auto Drops") end)
healBtn.MouseButton1Click:Connect(function() AUTO_HEAL = not AUTO_HEAL updateButton(healBtn, AUTO_HEAL, "Auto Heal") end)
feedBtn.MouseButton1Click:Connect(function() AUTO_FEED = not AUTO_FEED updateButton(feedBtn, AUTO_FEED, "Auto Feed") end)
exploreBtn.MouseButton1Click:Connect(function() AUTO_EXPLORE = not AUTO_EXPLORE updateButton(exploreBtn, AUTO_EXPLORE, "Auto Explore") end)

sendNotification("Digimon Era Control", "โหลด UI สำเร็จแล้ว!")

local function fireButton(btn)
    if not btn or not btn.Parent or not btn.Visible then return false end
    pcall(function() firesignal(btn.Activated) end)
    pcall(function() firesignal(btn.MouseButton1Click) end)
    return true
end

-- ================================================
-- AUTO HEAL (FIXED FOR MOBILE CONTROLLER SLOT 4)
-- ================================================

local HEAL_COOLDOWN = 5
local HEAL_CHECK_INTERVAL = 1
local lastHealTime = 0
local isHealing = false

local function getDigimonHP()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return nil, nil end

    for _, gui in ipairs(pGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
            local text = gui.Text:gsub(",", "")
            local cur, max = text:match("(%d+)%s*/%s*(%d+)")
            local currentHP = tonumber(cur)
            local maximumHP = tonumber(max)

            if currentHP and maximumHP and maximumHP > 100 and currentHP <= maximumHP then
                return currentHP, maximumHP
            end
        end
    end
    return nil, nil
end

local function clickMobileSlot4Potion()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return false, "ไม่พบ PlayerGui" end

    local slot4Btn = nil

    -- ค้นหาเจาะจงผ่าน Mobile_Controller ตามโครงสร้างใหม่ในภาพ Console
    local hud = pGui:FindFirstChild("HUD")
    local mobileController = hud and hud:FindFirstChild("Mobile_Controller")
    if mobileController then
        for _, obj in ipairs(mobileController:GetDescendants()) do
            if obj.Name == "QuickButton" or obj.Name == "Move4" or obj.Name:lower():find("slot4") then
                slot4Btn = obj
                break
            end
        end
    end

    -- หากไม่เจอใน Mobile_Controller ให้ค้นหาจากทุกที่ที่มีคำว่า 4 หรือ Move4 / Slot4
    if not slot4Btn then
        for _, obj in ipairs(pGui:GetDescendants()) do
            if (obj:IsA("GuiButton") or obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
                local name = obj.Name:lower()
                if name == "move4" or name == "slot4" or name == "4" or name:find("move4") then
                    slot4Btn = obj
                    break
                end
            end
        end
    end

    if slot4Btn then
        fireButton(slot4Btn)
        pcall(function()
            if slot4Btn.AbsolutePosition and slot4Btn.AbsoluteSize then
                local x = slot4Btn.AbsolutePosition.X + (slot4Btn.AbsoluteSize.X / 2)
                local y = slot4Btn.AbsolutePosition.Y + (slot4Btn.AbsoluteSize.Y / 2) + 36
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end
        end)
        return true, "กดปุ่มยาผ่าน Mobile UI สำเร็จ"
    end

    -- ระบบสำรอง: ใช้พิกัดหน้าจอด้านขวาล่างที่เป็นตำแหน่งช่องสกิล/ยาของ Mobile Layout
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            local size = cam.ViewportSize
            local x = size.X - 120
            local y = size.Y - 150
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end
    end)

    return true, "กดพิกัดสำรอง Mobile Layout สำเร็จ"
end

task.spawn(function()
    while screenGui.Parent do
        if AUTO_HEAL and not isHealing then
            local ok, err = pcall(function()
                local curHP, maxHP = getDigimonHP()
                if not curHP or not maxHP then return end

                local missingHP = maxHP - curHP
                if missingHP < HEAL_DROP_AMOUNT then return end
                if tick() - lastHealTime < HEAL_COOLDOWN then return end

                isHealing = true
                lastHealTime = tick()

                local used, result = clickMobileSlot4Potion()
                if used then
                    sendNotification("Auto Heal", result .. " | HP ขาด " .. math.floor(missingHP))
                else
                    warn("[Auto Heal] " .. result)
                end
                isHealing = false
            end)

            if not ok then
                isHealing = false
                warn("[Auto Heal] Error:", err)
            end
        end
        task.wait(HEAL_CHECK_INTERVAL)
    end
end)
```[cite: 3]
