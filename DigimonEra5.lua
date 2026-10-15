print("[Digimon Era] SCRIPT STARTED - ERROR FIXED FINAL")
-- ================================================
-- DIGIMON ERA AUTO FARM + AUTO FEED + AUTO EXPLORE + DUNGEON LOOP
-- (FULL VERSION 100% - BUG FIXED)
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

local UI_NAME ="DigimonEra5_MultiUI"
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

-- SINGLE INSTANCE: CLEAR OLD UI BEFORE REBUILDING
local function removeOldUI(parent)
    if not parent then return end

    local oldUI = parent:FindFirstChild(UI_NAME)
    if oldUI then
        oldUI:Destroy()
    end
end

removeOldUI(CoreGui)
removeOldUI(player:FindFirstChild("PlayerGui"))

if type(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then
        removeOldUI(hui)
    end
end

-- TELEPORT QUEUE
local function setupTeleportQueue()
    local q = queue_on_teleport or queueonteleport
        or queue_on_tp or queueontp

    if type(q) ~= "function" then
        warn("[Digimon Era] ไม่พบ queue_on_teleport")
        return
    end

    local code = [[
        task.wait(10)

        local Players = game:GetService("Players")
        local CoreGui = game:GetService("CoreGui")
        local player = Players.LocalPlayer
        local UI_NAME = "DigimonEra5_MultiUI"

        local function hasUI(parent)
            return parent ~= nil
                and parent:FindFirstChild(UI_NAME) ~= nil
        end

        if hasUI(CoreGui) then return end

        local pGui = player and player:FindFirstChild("PlayerGui")
        if hasUI(pGui) then return end

        if type(gethui) == "function" then
            local ok, hui = pcall(gethui)
            if ok and hasUI(hui) then return end
        end

        local ok, err = pcall(function()
            local url = "https://raw.githubusercontent.com/khampeegod36-alt/ksgod052/refs/heads/main/DigimonEra5.lua"
            local src = game:HttpGet(url, true)
            local fn, loadErr = loadstring(src)

            if not fn then
                error(loadErr or "โหลดสคริปต์ไม่สำเร็จ")
            end

            fn()
        end)

        if not ok then
            warn("[Digimon Era] Teleport load error:", err)
        end
    ]]

    local ok, err = pcall(q, code)
    if not ok then
        warn("[Digimon Era] ตั้งคิว Teleport ไม่สำเร็จ:", err)
    end
end

setupTeleportQueue()

-- ANTI AFK
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(
            Vector2.new(0, 0),
            workspace.CurrentCamera.CFrame
        )
        task.wait(1)
        VirtualUser:Button2Up(
            Vector2.new(0, 0),
            workspace.CurrentCamera.CFrame
        )
    end)
end)

-- NOTIFICATION
local function sendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2
        })
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
        local pOk = pcall(function()
            screenGui.Parent = hui
        end)
        if pOk then parentSuccess = true end
    end
end

if not parentSuccess and syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
        parentSuccess = true
    end)
end

if not parentSuccess then
    local ok = pcall(function()
        screenGui.Parent = CoreGui
        parentSuccess = true
    end)
end

if not parentSuccess then
    pcall(function()
        screenGui.Parent = player:WaitForChild("PlayerGui")
        parentSuccess = true
    end)
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 210, 0, 420)
mainFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = false
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
minimizeBtn.Name = "MinimizeBtn"
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
contentContainer.Name = "ContentContainer"
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

-- ================================================
-- DUNGEON SETTINGS
-- ================================================

local env = getgenv and getgenv() or _G

local DungeonSettings = env.DigimonEraDungeonSettings or {
    Map = "Forest",
    Level = "61-100",
    LockMap = false,
    LockLevel = false
}

env.DigimonEraDungeonSettings = DungeonSettings

local DungeonLevels = {
    Forest = {"1-10", "11-30", "31-60", "61-100", "101-150", "151-220"},
    Volcano = {"1-30", "31-60", "61-110", "111-170", "171-240"},
    Snowland = {"20-40", "41-70", "71-140", "141-190", "191-260"}
}

local function validateDungeonSettings()
    if not DungeonLevels[DungeonSettings.Map] then
        DungeonSettings.Map = "Forest"
    end

    local valid = false
    for _, level in ipairs(DungeonLevels[DungeonSettings.Map]) do
        if level == DungeonSettings.Level then
            valid = true
            break
        end
    end

    if not valid then
        DungeonSettings.Level = DungeonLevels[DungeonSettings.Map][1]
    end
end

validateDungeonSettings()

local settingsBtn = Instance.new("TextButton")
settingsBtn.Name = "DungeonSettingsBtn"
settingsBtn.Size = UDim2.new(0, 24, 0, 24)
settingsBtn.Position = UDim2.new(0.69, 0, 0.02, 0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
settingsBtn.TextColor3 = Color3.new(1, 1, 1)
settingsBtn.TextSize = 14
settingsBtn.Font = Enum.Font.SourceSansBold
settingsBtn.Text = "D"
settingsBtn.Parent = mainFrame

local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "DungeonSettingsFrame"
settingsFrame.Size = UDim2.new(0, 220, 0, 205)
settingsFrame.Position = UDim2.new(1, 8, 0, 30)
settingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
settingsFrame.Visible = false
settingsFrame.Parent = mainFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 8)
settingsCorner.Parent = settingsFrame

local function makeSettingsButton(name, y, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.Parent = settingsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    return btn
end

local mapBtn = makeSettingsButton("MapSelectBtn", 10, "")
local levelBtn = makeSettingsButton("LevelSelectBtn", 48, "")
local lockMapBtn = makeSettingsButton("LockMapBtn", 86, "")
local lockLevelBtn = makeSettingsButton("LockLevelBtn", 124, "")
local closeSettingsBtn = makeSettingsButton("CloseSettingsBtn", 162, "Close")

local function refreshDungeonSettingsUI()
    mapBtn.Text = "Map: " .. DungeonSettings.Map
    levelBtn.Text = "Level: " .. DungeonSettings.Level
    lockMapBtn.Text = "Lock Map: " .. (DungeonSettings.LockMap and "ON" or "OFF")
    lockLevelBtn.Text = "Lock Level: " .. (DungeonSettings.LockLevel and "ON" or "OFF")

    mapBtn.BackgroundColor3 = DungeonSettings.LockMap
        and Color3.fromRGB(100, 70, 70)
        or Color3.fromRGB(55, 55, 55)

    levelBtn.BackgroundColor3 = DungeonSettings.LockLevel
        and Color3.fromRGB(100, 70, 70)
        or Color3.fromRGB(55, 55, 55)
end

settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

mapBtn.MouseButton1Click:Connect(function()
    if DungeonSettings.LockMap then
        sendNotification("Dungeon Settings", "ปลดล็อก Map ก่อนเปลี่ยน")
        return
    end

    local maps = {"Forest", "Volcano", "Snowland"}
    local currentIndex = table.find(maps, DungeonSettings.Map) or 1
    currentIndex = currentIndex % #maps + 1
    DungeonSettings.Map = maps[currentIndex]

    if not DungeonSettings.LockLevel then
        DungeonSettings.Level = DungeonLevels[DungeonSettings.Map][1]
    else
        local found = false
        for _, level in ipairs(DungeonLevels[DungeonSettings.Map]) do
            if level == DungeonSettings.Level then
                found = true
                break
            end
        end

        if not found then
            DungeonSettings.Level = DungeonLevels[DungeonSettings.Map][1]
        end
    end

    refreshDungeonSettingsUI()
end)

levelBtn.MouseButton1Click:Connect(function()
    if DungeonSettings.LockLevel then
        sendNotification("Dungeon Settings", "ปลดล็อก Level ก่อนเปลี่ยน")
        return
    end

    local levels = DungeonLevels[DungeonSettings.Map]
    local currentIndex = table.find(levels, DungeonSettings.Level) or 0
    currentIndex = currentIndex % #levels + 1
    DungeonSettings.Level = levels[currentIndex]

    refreshDungeonSettingsUI()
end)

lockMapBtn.MouseButton1Click:Connect(function()
    DungeonSettings.LockMap = not DungeonSettings.LockMap
    refreshDungeonSettingsUI()
end)

lockLevelBtn.MouseButton1Click:Connect(function()
    DungeonSettings.LockLevel = not DungeonSettings.LockLevel
    refreshDungeonSettingsUI()
end)

closeSettingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = false
end)

refreshDungeonSettingsUI()
env.DigimonEraDungeonLoop = env.DigimonEraDungeonLoop == true
local AUTO_DUNGEON_LOOP = env.DigimonEraDungeonLoop

-- HEAL SETTING UI
local healFrame = Instance.new("Frame")
healFrame.Name = "HealSettingsFrame"
healFrame.Size = UDim2.new(0.9, 0, 0, 30)
healFrame.Position = UDim2.new(0.05, 0, 0.85, 0)
healFrame.BackgroundTransparency = 1
healFrame.Parent = contentContainer

local healLabel = Instance.new("TextLabel")
healLabel.Size = UDim2.new(0.65, 0, 1, 0)
healLabel.BackgroundTransparency = 1
healLabel.Text = "Heal Drop >= :"
healLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
healLabel.TextSize = 12
healLabel.Font = Enum.Font.SourceSansBold
healLabel.TextXAlignment = Enum.TextXAlignment.Left
healLabel.Parent = healFrame

local healInput = Instance.new("TextBox")
healInput.Name = "HealInput"
healInput.Size = UDim2.new(0.32, 0, 1, 0)
healInput.Position = UDim2.new(0.68, 0, 0, 0)
healInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
healInput.TextColor3 = Color3.new(1, 1, 1)
healInput.TextSize = 13
healInput.Font = Enum.Font.SourceSansBold
healInput.Text = tostring(HEAL_DROP_AMOUNT)
healInput.ClearTextOnFocus = false
healInput.Parent = healFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = healInput

healInput.FocusLost:Connect(function()
    local val = tonumber(healInput.Text)

    if val and val > 0 then
        HEAL_DROP_AMOUNT = math.floor(val)
        healInput.Text = tostring(HEAL_DROP_AMOUNT)
        sendNotification("Auto Heal Setup", "ตั้งค่า HP ที่ต้องการแล้ว")
    else
        healInput.Text = tostring(HEAL_DROP_AMOUNT)
        sendNotification("Error", "กรุณากรอกตัวเลขที่ถูกต้อง")
    end
end)

local function updateButton(btn, enabled, label)
    btn.Text = label .. (enabled and ": ON" or ": OFF")
    btn.BackgroundColor3 = enabled
        and Color3.fromRGB(40, 167, 69)
        or Color3.fromRGB(220, 53, 69)
end

if exploreBtn then updateButton(exploreBtn, AUTO_EXPLORE, "Auto Explore") end
if dungeonBtn then updateButton(dungeonBtn, AUTO_DUNGEON_LOOP, "Dungeon Loop") end

-- AUTO ENABLE ALL AFTER ENTERING DUNGEON
local DUNGEON_PLACE_ID = 112998674138179
local UI_LOAD_DELAY = 10

local autoEnableRunning = false
local autoAlreadyEnabled = false

local function enableAllAutoButtons()
    if autoAlreadyEnabled then return end
    autoAlreadyEnabled = true

    AUTO_FARM = true
    updateButton(farmBtn, true, "Auto Farm")

    AUTO_CHEST = true
    updateButton(chestBtn, true, "Auto Chest")

    AUTO_DROPS = true
    updateButton(dropBtn, true, "Auto Drops")

    AUTO_HEAL = true
    updateButton(healBtn, true, "Auto Heal")

    AUTO_FEED = true
    updateButton(feedBtn, true, "Auto Feed")

    AUTO_EXPLORE = true
    updateButton(exploreBtn, true, "Auto Explore")

    if not _G.EnableFarmModesRunning then
        _G.EnableFarmModesRunning = true

        task.spawn(function()
            local ok, err = pcall(function()
                enableFarmModes()
            end)

            _G.EnableFarmModesRunning = false

            if not ok then
                warn("[Auto Farm] Error:", err)
            end
        end)
    end

    sendNotification("Digimon Era", "เปิด Auto ทั้งหมดเรียบร้อย")
end

local function checkDungeonAndEnableAutos()
    if game.PlaceId ~= DUNGEON_PLACE_ID then return end
    if autoEnableRunning or autoAlreadyEnabled then return end

    autoEnableRunning = true

    task.spawn(function()
        task.wait(UI_LOAD_DELAY)
        if game.PlaceId == DUNGEON_PLACE_ID then
            enableAllAutoButtons()
        end
        autoEnableRunning = false
    end)
end

checkDungeonAndEnableAutos()

task.spawn(function()
    while screenGui.Parent do
        task.wait(2)
        checkDungeonAndEnableAutos()
    end
end)

-- ================================================
-- TOGGLE BUTTON EVENTS
-- ================================================

if farmBtn then
    farmBtn.MouseButton1Click:Connect(function()
        AUTO_FARM = not AUTO_FARM
        updateButton(farmBtn, AUTO_FARM, "Auto Farm")

        if AUTO_FARM then
            task.spawn(enableFarmModes)
        else
            table.clear(visited)
        end
    end)
end

if chestBtn then
    chestBtn.MouseButton1Click:Connect(function()
        AUTO_CHEST = not AUTO_CHEST
        updateButton(chestBtn, AUTO_CHEST, "Auto Chest")

        if not AUTO_CHEST then
            table.clear(openedChests)
        end
    end)
end

if dropBtn then
    dropBtn.MouseButton1Click:Connect(function()
        AUTO_DROPS = not AUTO_DROPS
        updateButton(dropBtn, AUTO_DROPS, "Auto Drops")

        if not AUTO_DROPS then
            table.clear(collectedDrops)
        end
    end)
end

if healBtn then
    healBtn.MouseButton1Click:Connect(function()
        AUTO_HEAL = not AUTO_HEAL
        updateButton(healBtn, AUTO_HEAL, "Auto Heal")
    end)
end

if feedBtn then
    feedBtn.MouseButton1Click:Connect(function()
        AUTO_FEED = not AUTO_FEED
        updateButton(feedBtn, AUTO_FEED, "Auto Feed")
    end)
end

if exploreBtn then
    exploreBtn.MouseButton1Click:Connect(function()
        AUTO_EXPLORE = not AUTO_EXPLORE
        updateButton(exploreBtn, AUTO_EXPLORE, "Auto Explore")
        sendNotification(
            "Auto Explore",
            AUTO_EXPLORE and "เปิดแล้ว" or "ปิดแล้ว"
        )
    end)
end

if dungeonBtn then
    dungeonBtn.MouseButton1Click:Connect(function()
        AUTO_DUNGEON_LOOP = not AUTO_DUNGEON_LOOP
        env.DigimonEraDungeonLoop = AUTO_DUNGEON_LOOP
        updateButton(dungeonBtn, AUTO_DUNGEON_LOOP, "Dungeon Loop")

        sendNotification(
            "Dungeon Loop",
            AUTO_DUNGEON_LOOP and "เปิดระบบวนดันเจี้ยน" or "ปิดระบบวนดันเจี้ยน"
        )
    end)
end

sendNotification("Digimon Era Control", "โหลด UI สำเร็จแล้ว!")

-- ================================================
-- AUTO FARM MODES
-- ================================================

enableFarmModes = function()
    local pGui = player:WaitForChild("PlayerGui")
    local hud = pGui:WaitForChild("HUD")

    local controller = hud:FindFirstChild("PC_Controller") or hud:FindFirstChild("Mobile_Controller")
    if not controller then return end

    local partyFrame = controller:FindFirstChild("PartyFrame")
    local status = partyFrame and partyFrame:FindFirstChild("StatusFrame")

    if status then
        local aggressive = status:FindFirstChild("Aggressive")
        if aggressive and aggressive.Visible and aggressive.Active then
            pcall(function()
                firesignal(aggressive.Activated)
            end)
        end

        local autoSkill = status:FindFirstChild("AutoSkill")
        local state = autoSkill and autoSkill:FindFirstChild("Status")

        if autoSkill and state and state:IsA("TextLabel") and state.Text == "OFF" then
            if autoSkill.Visible and autoSkill.Active then
                pcall(function()
                    firesignal(autoSkill.Activated)
                end)
            end
        end
    end
end

local function fireButton(btn)
    if not btn or not btn.Parent or not btn.Visible then
        return false
    end

    local fired = false

    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.Activated)) do
                if conn.Enabled ~= false then
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                if conn.Enabled ~= false then
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
        end
    end)

    if not fired then
        pcall(function()
            if firesignal then
                firesignal(btn.Activated)
                firesignal(btn.MouseButton1Click)
                fired = true
            end
        end)
    end

    return fired
end

-- ================================================
-- AUTO FEED
-- ================================================

local function getCaptureFolder()
    return workspace:FindFirstChild("ClientCaptures")
end

local function getCapturePosition(capture)
    if not capture or not capture.Parent then return nil end

    local ok, pos = pcall(function()
        return capture:GetPivot().Position
    end)

    return ok and pos or nil
end

local function getCaptureName(capture)
    local gui = capture and capture:FindFirstChild("CatchableGui", true)
    local label = gui and gui:FindFirstChild("DigimonName", true)

    if label and label:IsA("TextLabel") then
        return label.Text
    end

    return capture and capture.Name or "Unknown"
end

local function findNearestCapture(rootPart)
    local folder = getCaptureFolder()
    if not folder or not rootPart then return nil end

    local nearest, nearestDistance = nil, math.huge

    for _, capture in ipairs(folder:GetChildren()) do
        local gui = capture:FindFirstChild("CatchableGui", true)
        local nameLabel = gui and gui:FindFirstChild("DigimonName", true)
        local pos = getCapturePosition(capture)

        if nameLabel and pos then
            local distance = (pos - rootPart.Position).Magnitude

            if distance < nearestDistance then
                nearest = capture
                nearestDistance = distance
            end
        end
    end

    return nearest
end

local function getCaptureMain()
    local pGui = player:FindFirstChild("PlayerGui")
    local billboard = pGui and pGui:FindFirstChild("CaptureBillboard")

    return billboard and billboard:FindFirstChild("MainFrame")
end

local function teleportToCapture(capture, rootPart)
    local pos = getCapturePosition(capture)
    if not pos or not rootPart then return false end

    if (rootPart.Position - pos).Magnitude > 7 then
        local ok = pcall(function()
            rootPart.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
        end)

        if not ok then return false end
        task.wait(0.2)
    end

    return true
end

local function tryOpenCapture(capture, rootPart)
    if not capture or not capture.Parent then return end

    pcall(function()
        if fireproximityprompt then
            for _, obj in ipairs(capture:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    fireproximityprompt(obj)
                end
            end
        end
    end)

    pcall(function()
        if not firetouchinterest or not rootPart then return end

        local parts = {}

        if capture:IsA("BasePart") then
            table.insert(parts, capture)
        else
            for _, obj in ipairs(capture:GetDescendants()) do
                if obj:IsA("BasePart") then
                    table.insert(parts, obj)
                end
            end
        end

        local part = parts[1]

        if part then
            firetouchinterest(rootPart, part, 0)
            task.wait(0.03)
            firetouchinterest(rootPart, part, 1)
        end
    end)
end

local function selectFoodAndFeed()
    local main = getCaptureMain()
    if not main or not main.Visible then return false end

    local scrolling = main:FindFirstChild("ScrollingFrame", true)
    local feedButton = main:FindFirstChild("FeedButton", true)

    if not scrolling or not feedButton then return false end

    local chosen = nil

    for _, obj in ipairs(scrolling:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local itemName = obj:FindFirstChild("ItemName", true)
            local amountLabel = obj:FindFirstChild("ItemAmount", true)
            local amount = amountLabel
                and tonumber(tostring(amountLabel.Text):match("%d+"))

            if itemName and amount and amount > 0 and obj.Visible then
                chosen = obj
                break
            end
        end
    end

    if not chosen then return false end
    if not fireButton(chosen) then return false end

    task.wait(0.15)

    if not AUTO_FEED then return false end

    main = getCaptureMain()
    feedButton = main and main:FindFirstChild("FeedButton", true)

    if not main or not main.Visible or not feedButton then
        return false
    end

    return fireButton(feedButton)
end

local function processAutoFeed(capture)
    if not AUTO_FEED or not capture or not capture.Parent then return false end

    local targetName = getCaptureName(capture)
    sendNotification("Auto Feed", "กำลังไปหา " .. targetName)

    while AUTO_FEED and capture.Parent do
        local character = player.Character
        local currentRoot = character
            and character:FindFirstChild("HumanoidRootPart")

        if not currentRoot then break end

        teleportToCapture(capture, currentRoot)

        local main = getCaptureMain()

        if not main or not main.Visible then
            tryOpenCapture(capture, currentRoot)
            task.wait(0.25)
        else
            local ok, result = pcall(selectFoodAndFeed)

            if not ok then
                warn("[Auto Feed]", result)
            end

            task.wait(0.6)
        end
    end

    sendNotification("Auto Feed", "เป้าหมายหายไปแล้ว")
    return true
end

-- ================================================
-- AUTO EXPLORE
-- ================================================

local EXPLORE_CHECK_INTERVAL = 5
local INVESTIGATE_COOLDOWN = 5
local EXPLORE_MAX_ROOM_SELECTIONS = 3
local EXPLORE_MAX_MAP = 3

local exploreRoomSelections = 0
local lastInvestigateTime = tick()
local exploringNow = false

local EXPLORE_DUNGEON_PLACE_ID = 112998674138179
local lastExplorePlaceId = game.PlaceId

if game.PlaceId == EXPLORE_DUNGEON_PLACE_ID then
    lastInvestigateTime = 0
    exploreRoomSelections = 0
    print("[Auto Explore] เข้า Dungeon — รีเซ็ตตัวนับห้อง")
end

local function getMapFrame()
    local pg = player:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    return main and main:FindFirstChild("MapFrame")
end

local function readExplorePercent(room)
    local label = room:FindFirstChild("ExploreDegree")
    if not label then return nil end

    return tonumber(tostring(label.Text):match("(%d+)%s*%%"))
end

local function openMapForExplore()
    local pg = player:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("HUD")
    local buttons = hud and hud:FindFirstChild("ButtonsFrame")
    local teleport = buttons and buttons:FindFirstChild("TeleportButton")
    local imageButton = teleport and teleport:FindFirstChild("ImageButton")
    local mapFrame = getMapFrame()

    if not mapFrame then return false end
    if mapFrame.Visible then return true end
    if not imageButton then return false end

    fireButton(imageButton)
    task.wait(0.5)

    return mapFrame.Visible
end

local function closeMapForExplore()
    local mapFrame = getMapFrame()
    if not mapFrame or not mapFrame.Visible then return true end

    local pg = player:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("HUD")
    local buttons = hud and hud:FindFirstChild("ButtonsFrame")
    local teleport = buttons and buttons:FindFirstChild("TeleportButton")
    local imageButton = teleport and teleport:FindFirstChild("ImageButton")

    if not imageButton then
        warn("[Auto Explore] ไม่พบปุ่มปิดแผนที่")
        return false
    end

    if not fireButton(imageButton) then
        warn("[Auto Explore] กดปิดแผนที่ไม่สำเร็จ")
        return false
    end

    task.wait(0.5)
    return not mapFrame.Visible
end

local function findCurrentRoom(scrolling)
    for _, layer in ipairs(scrolling:GetChildren()) do
        local mapNumber = tonumber(layer.Name:match("^Map(%d+)$"))

        if mapNumber and mapNumber <= EXPLORE_MAX_MAP then
            for _, room in ipairs(layer:GetChildren()) do
                if room:IsA("TextButton")
                    and room.Name:match("^Layer_%d+_SmallMap_%d+$") then

                    local degree = readExplorePercent(room)
                    local investigate = room:FindFirstChild("Investigate")

                    if degree ~= nil and investigate
                        and not investigate.Visible then
                        return room, layer, degree
                    end
                end
            end
        end
    end

    return nil, nil, nil
end

local function getCurrentRoomKey()
    local mapFrame = getMapFrame()
    local scrolling = mapFrame and mapFrame:FindFirstChild("ScrollingFrame")
    if not scrolling then return nil end

    local room, layer = findCurrentRoom(scrolling)
    if room and layer then
        return layer.Name .. "/" .. room.Name
    end

    return nil
end

local function hasReachableLivingEnemy(maxDistance)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local digimons = workspace:FindFirstChild("Digimons")
    local enemies = digimons and digimons:FindFirstChild("Enemies")

    if not root or not character or not enemies then
        return false
    end

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:Is
