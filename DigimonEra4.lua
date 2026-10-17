print("[Digimon Era] SCRIPT STARTED - GUI FIXED & VISIBLE")
-- ================================================
-- DIGIMON ERA AUTO FARM + AUTO FEED + AUTO EXPLORE + DUNGEON LOOP
-- (FULL VERSION 100% - GUI FIX)
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
    "https://raw.githubusercontent.com/khampeegod36-alt/ksgod052/refs/heads/main/DigimonEra4.lua"

local UI_NAME ="DigimonEra4_MultiUI"
local MIN_DISTANCE = 30
local ARRIVAL_DISTANCE = 4
local MAX_WALK_TIME = 10
local SEARCH_RADIUS = 500

local AUTO_FARM = false
local AUTO_CHEST = false
local AUTO_DROPS = false
local AUTO_HEAL = false -- legacy compatibility
local AUTO_HEAL_PC = false
local AUTO_HEAL_MOBILE = false -- disabled: this script is PC-only
local AUTO_EQUIP_POTION = false -- independent from Auto Heal; equips selected potion to slot 4
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
        local UI_NAME = "DigimonEra4_MultiUI"

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
            local url = "https://raw.githubusercontent.com/khampeegod36-alt/ksgod052/refs/heads/main/DigimonEra4.lua"
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
mainFrame.Size = UDim2.new(0, 210, 0, 480)
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
contentContainer.Size = UDim2.new(1, 0, 0, 445)
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
        mainFrame.Size = UDim2.new(0, 210, 0, 480)
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
local chestBtn = createToggleButton("ChestBtn", UDim2.new(0.05, 0, 0.11, 0), "Auto Chest: OFF")
local dropBtn = createToggleButton("DropBtn", UDim2.new(0.05, 0, 0.21, 0), "Auto Drops: OFF")
local healPCBtn = createToggleButton("HealPCBtn", UDim2.new(0.05, 0, 0.31, 0), "Auto Heal: OFF")
local potionSelectBtn = createToggleButton("PotionSelectBtn", UDim2.new(0.05, 0, 0.40, 0), "Potion to Equip: S")
local potionEquipBtn = createToggleButton("PotionEquipBtn", UDim2.new(0.05, 0, 0.48, 0), "Auto Equip Potion: OFF")
-- PC-only script: no Mobile Auto Heal toggle.
local healBtn = healPCBtn
local feedBtn = createToggleButton("FeedBtn", UDim2.new(0.05, 0, 0.56, 0), "Auto Feed: OFF")
local exploreBtn = createToggleButton("ExploreBtn", UDim2.new(0.05, 0, 0.64, 0), "Auto Explore: OFF")
local dungeonBtn = createToggleButton("DungeonLoopBtn", UDim2.new(0.05, 0, 0.72, 0), "Dungeon Loop: OFF")

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
env.DigimonEraDungeonLoop = true -- เปิด Dungeon Loop เป็นค่าเริ่มต้นทุกครั้งที่เริ่มสคริปต์
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

if healPCBtn then updateButton(healPCBtn, AUTO_HEAL_PC, "Auto Heal") end
if potionEquipBtn then updateButton(potionEquipBtn, AUTO_EQUIP_POTION, "Auto Equip Potion") end
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

    -- Preserve the original behavior: Auto Farm turns on automatically in the dungeon.
    AUTO_FARM = true
    updateButton(farmBtn, true, "Auto Farm")

    AUTO_CHEST = true
    updateButton(chestBtn, true, "Auto Chest")

    AUTO_DROPS = true
    updateButton(dropBtn, true, "Auto Drops")

    AUTO_HEAL_PC = true
    AUTO_HEAL_MOBILE = false
    AUTO_HEAL = true
    updateButton(healPCBtn, true, "Auto Heal")

    AUTO_EQUIP_POTION = true
    updateButton(potionEquipBtn, true, "Auto Equip Potion")

    -- Auto Feed stays OFF by default; the user can enable it manually.
    AUTO_FEED = false
    updateButton(feedBtn, false, "Auto Feed")

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

if healPCBtn then
    healPCBtn.MouseButton1Click:Connect(function()
        AUTO_HEAL_PC = not AUTO_HEAL_PC
        AUTO_HEAL = AUTO_HEAL_PC
        updateButton(healPCBtn, AUTO_HEAL_PC, "Auto Heal")
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

local function getActiveController(hud)
    if not hud then return nil end

    local mobile = hud:FindFirstChild("Mobile_Controller")
    local pc = hud:FindFirstChild("PC_Controller")

    -- Prefer the controller that is actually visible on the current device.
    if mobile and mobile.Visible then
        return mobile
    end
    if pc and pc.Visible then
        return pc
    end

    -- Fallback for interfaces that have not finished updating Visible yet.
    return mobile or pc
end

enableFarmModes = function()
    local pGui = player:WaitForChild("PlayerGui")
    local hud = pGui:WaitForChild("HUD")
    local controller = getActiveController(hud)
    if not controller then
        warn("[Auto Farm] ไม่พบ PC_Controller หรือ Mobile_Controller")
        return
    end

    local partyFrame = controller:FindFirstChild("PartyFrame", true)
    local status = partyFrame and partyFrame:FindFirstChild("StatusFrame", true)
    if not status then
        warn("[Auto Farm] ไม่พบ StatusFrame ใน Controller ที่เลือก")
        return
    end

    -- Keep the existing Aggressive behavior unchanged, as requested.
    local aggressive = status:FindFirstChild("Aggressive", true)
    if aggressive and aggressive.Visible and aggressive.Active then
        pcall(function()
            firesignal(aggressive.Activated)
        end)
    end

    -- Auto Skill: locate its status under the active controller and only enable OFF.
    local autoSkill = status:FindFirstChild("AutoSkill", true)
    local state = autoSkill and autoSkill:FindFirstChild("Status", true)
    local stateText = state and state:IsA("TextLabel")
        and tostring(state.Text):match("^%s*(.-)%s*$")

    if autoSkill and stateText and stateText:upper() == "OFF"
        and autoSkill.Visible and autoSkill.Active then
        pcall(function()
            firesignal(autoSkill.Activated)
        end)
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
local EXPLORE_MAX_MAP = 3

local lastInvestigateTime = tick()
local exploringNow = false

local EXPLORE_DUNGEON_PLACE_ID = 112998674138179
local lastExplorePlaceId = game.PlaceId

if game.PlaceId == EXPLORE_DUNGEON_PLACE_ID then
    lastInvestigateTime = 0
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

local hasPendingRoomLoot -- assigned after chest/drop helpers are defined

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
        if enemy:IsA("Model") and enemy.Parent == enemies then
            local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")

            if not enemyHumanoid or enemyHumanoid.Health > 0 then
                local ok, enemyPos = pcall(function()
                    return enemy:GetPivot().Position
                end)

                if ok and (enemyPos - root.Position).Magnitude <= maxDistance then
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2.5,
                        AgentHeight = 5,
                        AgentCanJump = true,
                        WaypointSpacing = 4
                    })

                    local pathOk = pcall(function()
                        path:ComputeAsync(root.Position, enemyPos)
                    end)

                    if pathOk and path.Status == Enum.PathStatus.Success then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Auto Explore: only move on when no living enemy remains in the current room.
-- Unlike hasReachableLivingEnemy(), this does not ignore enemies just because
-- Pathfinding cannot currently reach them (for example, a monster behind a wall).
local function hasLivingEnemyInCurrentRoom(maxDistance)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local digimons = workspace:FindFirstChild("Digimons")
    local enemies = digimons and digimons:FindFirstChild("Enemies")

    if not root or not enemies then
        -- Unknown state: do not claim the room is clear.
        return true
    end

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:IsA("Model") and enemy.Parent == enemies then
            local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
            local alive = not enemyHumanoid or enemyHumanoid.Health > 0

            if alive then
                local ok, enemyPos = pcall(function()
                    return enemy:GetPivot().Position
                end)
                if ok and (enemyPos - root.Position).Magnitude <= maxDistance then
                    return true
                end
            end
        end
    end

    return false
end

local function findNextRoom(currentLayer, currentRoom, scrolling)
    local function getAvailableRoom(layer, excludeRoom)
        local mapNumber = tonumber(layer.Name:match("^Map(%d+)$"))

        if not mapNumber or mapNumber > EXPLORE_MAX_MAP then
            return nil
        end

        local rooms = {}

        for _, room in ipairs(layer:GetChildren()) do
            if room:IsA("TextButton")
                and room.Name:match("^Layer_%d+_SmallMap_%d+$")
                and room ~= excludeRoom then

                local locked = room:FindFirstChild("LockedFrame")

                if not (locked and locked.Visible) then
                    table.insert(rooms, room)
                end
            end
        end

        table.sort(rooms, function(a, b)
            local aNum = tonumber(a.Name:match("SmallMap_(%d+)$")) or math.huge
            local bNum = tonumber(b.Name:match("SmallMap_(%d+)$")) or math.huge
            return aNum < bNum
        end)

        for _, room in ipairs(rooms) do
            local degree = readExplorePercent(room)

            if degree == nil or degree < 100 then
                return room
            end
        end

        return nil
    end

    local room = getAvailableRoom(currentLayer, currentRoom)
    if room then
        return room
    end

    local currentMapNumber = tonumber(currentLayer.Name:match("^Map(%d+)$"))
    if not currentMapNumber or not scrolling then
        return nil
    end

    local layers = {}

    for _, layer in ipairs(scrolling:GetChildren()) do
        local mapNumber = tonumber(layer.Name:match("^Map(%d+)$"))

        if mapNumber
            and mapNumber > currentMapNumber
            and mapNumber <= EXPLORE_MAX_MAP then

            table.insert(layers, {
                layer = layer,
                number = mapNumber
            })
        end
    end

    table.sort(layers, function(a, b)
        return a.number < b.number
    end)

    for _, entry in ipairs(layers) do
        room = getAvailableRoom(entry.layer, nil)

        if room then
            print("[Auto Explore] เลือกห้องจาก", entry.layer.Name)
            return room
        end
    end

    return nil
end

task.spawn(function()
    local stuckLastPosition = nil
    local stuckSince = tick()
    local lastSameRoomReselect = 0
    local pendingLootWaitStarted = nil
    while screenGui.Parent do
        if game.PlaceId ~= lastExplorePlaceId then
            lastExplorePlaceId = game.PlaceId

            if game.PlaceId == EXPLORE_DUNGEON_PLACE_ID then
                lastInvestigateTime = 0
            
                print("[Auto Explore] เข้า Dungeon รอบใหม่ — รีเซ็ตตัวนับห้อง")
            end
        end

        if AUTO_EXPLORE and not exploringNow then
            exploringNow = true

            local ok, err = pcall(function()
                if game.PlaceId ~= EXPLORE_DUNGEON_PLACE_ID then
                    return
                end

                if tick() - lastInvestigateTime < INVESTIGATE_COOLDOWN then
                    return
                end

                if not openMapForExplore() then
                    return
                end

                local mapFrame = getMapFrame()
                local scrolling = mapFrame
                    and mapFrame:FindFirstChild("ScrollingFrame")

                if not scrolling then
                    return
                end

                local currentRoom, currentLayer, percent =
                    findCurrentRoom(scrolling)

                -- Recovery for getting wedged against a wall: if the character
                -- barely moves for 18 seconds in an unfinished room, reselect
                -- that same room button once (cooldown 30s). This asks the game
                -- to reposition at the room spawn instead of blindly teleporting.
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root then
                    if stuckLastPosition and (root.Position - stuckLastPosition).Magnitude >= 3 then
                        stuckSince = tick()
                    elseif not stuckLastPosition then
                        stuckSince = tick()
                    end
                    stuckLastPosition = root.Position

                    local stuckLongEnough = tick() - stuckSince >= 18
                    local roomIncomplete = currentRoom and percent and percent < 100
                    local noNearbyEnemy = not hasReachableLivingEnemy(120)
                    local noPendingLoot = not (hasPendingRoomLoot and hasPendingRoomLoot())
                    if stuckLongEnough and roomIncomplete and noNearbyEnemy and noPendingLoot
                        and tick() - lastSameRoomReselect >= 30 then
                        lastSameRoomReselect = tick()
                        warn("[Auto Explore] ตรวจพบว่าอาจติดกำแพง — ลองเลือกห้องเดิมเพื่อกลับจุดเกิด")
                        if fireButton(currentRoom) then
                            task.wait(2)
                            closeMapForExplore()
                            stuckSince = tick()
                            stuckLastPosition = nil
                            return
                        end
                    end
                end

                if not currentRoom or not percent or percent < 100 then
                    return
                end

                local currentMapNumber =
                    tonumber(currentLayer.Name:match("^Map(%d+)$"))

                if not currentMapNumber or currentMapNumber > EXPLORE_MAX_MAP then
                    return
                end

                -- Wait for every living monster in the current room to be cleared.
                -- This intentionally does not depend on pathfinding reachability.
                if hasLivingEnemyInCurrentRoom(120) then
                    return
                end

                -- Wait briefly for pending loot/chests, but do not block progression forever.
                if hasPendingRoomLoot and hasPendingRoomLoot() then
                    if not pendingLootWaitStarted then
                        pendingLootWaitStarted = tick()
                        print("[Auto Explore] รอเก็บของ/หีบก่อนย้ายห้อง")
                        return
                    end
                    if tick() - pendingLootWaitStarted < 8 then
                        return
                    end
                    warn("[Auto Explore] รอของ/หีบครบ 8 วินาทีแล้ว จะลองย้ายห้องต่อ")
                else
                    pendingLootWaitStarted = nil
                end

                local nextRoom =
                    findNextRoom(currentLayer, currentRoom, scrolling)

                if nextRoom then
                    local oldRoomKey = currentLayer.Name .. "/" .. currentRoom.Name
                    sendNotification(
                        "Auto Explore",
                        "กำลังเข้าห้อง " .. nextRoom.Name
                    )

                    local clicked = false
                    for attempt = 1, 2 do
                        if not nextRoom.Parent then break end
                        clicked = fireButton(nextRoom)
                        print("[Auto Explore] กดห้องถัดไป ครั้งที่", attempt,
                            ":", nextRoom.Name, "signal=", clicked)

                        if clicked then
                            local verifyStarted = tick()
                            repeat
                                task.wait(0.5)
                                local checkFrame = getMapFrame()
                                local checkScrolling = checkFrame
                                    and checkFrame:FindFirstChild("ScrollingFrame")
                                local checkRoom, checkLayer = checkScrolling
                                    and findCurrentRoom(checkScrolling)
                                local newKey = checkRoom and checkLayer
                                    and (checkLayer.Name .. "/" .. checkRoom.Name) or nil
                                if newKey and newKey ~= oldRoomKey then
                                    print("[Auto Explore] ยืนยันว่าเปลี่ยนห้องแล้ว:", newKey)
                                    pendingLootWaitStarted = nil
                                    lastInvestigateTime = tick()
                                    task.wait(1)
                                    closeMapForExplore()
                                    return
                                end
                            until tick() - verifyStarted >= 4
                        end
                        task.wait(0.5)
                    end

                    warn("[Auto Explore] ส่งสัญญาณเลือกห้องแล้ว แต่ยังยืนยันการเปลี่ยนห้องไม่ได้:", nextRoom.Name)
                    lastInvestigateTime = tick()
                    -- Keep the map open so a later loop can retry.
                else
                    print(
                        "[Auto Explore] ไม่พบห้องถัดไปใน Map1 ถึง Map3"
                    )
                end
            end)

            if not ok then
                warn("[Auto Explore]", err)
            end

            exploringNow = false
        end

        task.wait(EXPLORE_CHECK_INTERVAL)
    end
end)


-- ================================================
-- POTION SHARED HELPERS
-- Selection state and helper functions used by Auto Equip Potion and Auto Heal
-- ================================================

local HEAL_COOLDOWN = 3
local HEAL_CHECK_INTERVAL = 0.5
local lastHealTime = 0
local lastEquipAttempt = 0
local isHealing = false
local isEquipping = false
local lastHealDebugAt = 0
local function healDebug(message)
    if tick() - lastHealDebugAt >= 4 then
        lastHealDebugAt = tick()
        warn("[Auto Heal] " .. tostring(message))
    end
end

-- Keep the original working UI object name first; some UI versions display
-- "Single Healing Potion S" while the instance is still named "Single Heal Potion S".
local HEAL_POTION_TIERS = {"S", "M", "L"}
local selectedHealPotionTier = "S"
local function getSelectedHealPotionNames()
    return {
        "Single Heal Potion " .. selectedHealPotionTier,
        "Single Healing Potion " .. selectedHealPotionTier,
    }
end
local function refreshPotionSelectionButton()
    if potionSelectBtn then
        potionSelectBtn.Text = "Potion to Equip: " .. selectedHealPotionTier
    end
end
local ensureHealPotionEquipped -- forward declaration for the separate Equip UI

-- ค้นหา HP จาก TextLabel ที่แสดง current/max
local function getDigimonHP()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return nil, nil end

    for _, gui in ipairs(pGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
            local text = gui.Text:gsub(",", "")
            local cur, max = text:match("(%d+)%s*/%s*(%d+)")
            local currentHP = tonumber(cur)
            local maximumHP = tonumber(max)

            if currentHP and maximumHP
                and maximumHP > 50
                and currentHP <= maximumHP then
                return currentHP, maximumHP
            end
        end
    end

    return nil, nil
end

-- ดึงปุ่มและสถานะ Equip/Remove
local function getHealItemControls()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end

    -- PC and mobile UI can place the inventory controls at different depths.
    -- Search descendants rather than assuming ItemBox/ScrollingFrame are direct children.
    local main = pg:FindFirstChild("Main")
    local itemBox = main and main:FindFirstChild("ItemBox", true)
    if not itemBox then
        -- Inventory UI names/parents differ between PC and mobile builds.
        itemBox = pg:FindFirstChild("ItemBox", true)
    end

    -- Fallback: locate the inventory panel by its Equip/Remove control instead
    -- of relying on the literal name ItemBox.
    if not itemBox then
        for _, node in ipairs(pg:GetDescendants()) do
            if (node:IsA("Frame") or node:IsA("ScrollingFrame"))
                and node:FindFirstChild("ItemEquip", true)
                and node:FindFirstChild("ModeName", true) then
                itemBox = node
                break
            end
        end
    end

    local scrolling = itemBox and itemBox:FindFirstChild("ScrollingFrame", true)

    -- Inventory item Instances are often named generic IDs; the potion name is
    -- displayed by a descendant TextLabel. Match both Instance.Name and UI text.
    local function normalizeItemName(value)
        return tostring(value or ""):lower():gsub("[%p%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    end

    local function isPotionName(value)
        local name = normalizeItemName(value)
        for _, potionName in ipairs(getSelectedHealPotionNames()) do
            if name == normalizeItemName(potionName) then return true end
        end
        return false
    end

    local function findPotion(container)
        if not container then return nil end
        if isPotionName(container.Name) then return container end

        for _, obj in ipairs(container:GetDescendants()) do
            local matched = isPotionName(obj.Name)
            if not matched and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
                matched = isPotionName(obj.Text)
            end
            if matched then
                -- IMPORTANT: return the inventory row/container, not its TextLabel.
                -- Returning the label made the old code search for clickable children
                -- inside a label (there are none), so the potion was never selected.
                local ancestor = obj
                while ancestor and ancestor ~= container do
                    if ancestor:IsA("GuiButton") then return ancestor end
                    if ancestor:IsA("Frame") or ancestor:IsA("ScrollingFrame") then
                        local hasItemName = false
                        for _, sub in ipairs(ancestor:GetDescendants()) do
                            if (sub:IsA("TextLabel") or sub:IsA("TextButton")) and isPotionName(sub.Text) then
                                hasItemName = true
                                break
                            end
                        end
                        if hasItemName then return ancestor end
                    end
                    ancestor = ancestor.Parent
                end
                return obj
            end
        end
        return nil
    end

    local item = findPotion(scrolling) or findPotion(itemBox) or findPotion(pg)

    -- If the potion was found outside the expected panel, walk upward to the
    -- nearest container that owns the Equip/Remove controls.
    if not itemBox and item then
        local ancestor = item.Parent
        while ancestor and ancestor ~= pg do
            if ancestor:FindFirstChild("ItemEquip", true)
                and ancestor:FindFirstChild("ModeName", true) then
                itemBox = ancestor
                break
            end
            ancestor = ancestor.Parent
        end
    end
    if not itemBox then return nil end

    local info = itemBox:FindFirstChild("InfoFrame", true) or itemBox
    local equip = info and info:FindFirstChild("ItemEquip", true)
    local modeName = equip and equip:FindFirstChild("ModeName", true)

    return {
        itemBox = itemBox,
        item = item,
        equip = equip,
        modeName = modeName,
    }
end

-- คลิกปุ่ม GUI แบบเมาส์จริงสำหรับ Auto Heal เท่านั้น.
-- ไม่แก้ fireButton กลาง เพราะระบบอื่นใช้งานอยู่แล้ว.
local function clickHealGuiButton(button)
    if not button or not button.Parent or not button.Visible or not button.Active then
        return false
    end

    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize
    local x = math.floor(pos.X + size.X / 2)
    local y = math.floor(pos.Y + size.Y / 2)

    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game)
        task.wait(0.06)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game)
    end)
    return ok
end

-- Mobile: ส่ง touch จริงก่อน เพราะ firesignal/MouseButton อาจเรียก callback
-- แต่ไม่ทำให้ UI มือถือรับเหตุการณ์แตะช่องยา.
local function clickHealMobileButton(button)
    if not button or not button.Parent or not button.Visible or not button.Active then
        return false
    end
    local pos, size = button.AbsolutePosition, button.AbsoluteSize
    local x = math.floor(pos.X + size.X / 2)
    local y = math.floor(pos.Y + size.Y / 2)
    local sentTouch = false
    pcall(function()
        -- VirtualInputManager touch states: begin -> end.
        if VirtualInputManager.SendTouchEvent then
            -- Correct touch lifecycle: 0 = begin, 1 = end.
            VirtualInputManager:SendTouchEvent(0, 0, x, y)
            task.wait(0.08)
            VirtualInputManager:SendTouchEvent(0, 1, x, y)
            sentTouch = true
        end
    end)
    if sentTouch then
        task.wait(0.15)
        return true
    end
    -- Fallback for clients/executors that do not expose SendTouchEvent.
    return clickHealGuiButton(button)
end

-- Mobile inventory controls may be Frames; tap the real child GuiButton when present.
local function clickMobileTarget(target)
    if not target or not target.Parent then return false end
    if target:IsA("GuiButton") and target.Visible and target.Active then
        return clickHealMobileButton(target)
    end
    for _, child in ipairs(target:GetDescendants()) do
        if child:IsA("GuiButton") and child.Visible and child.Active then
            if clickHealMobileButton(child) then return true end
        end
    end
    if target:IsA("GuiObject") and target.Visible and target.Active then
        return clickHealMobileButton(target)
    end
    return false
end

-- Detect the actual visible controller separately from the selected Auto Heal mode.
-- PC Auto Heal may be enabled while the game is displaying the Mobile UI; inventory
-- selection must use the input method that matches the visible UI, while potion use
-- remains tied to the selected heal mode (PC keyboard 4 vs Mobile slot button).
local function isMobileHealUIVisible()
    local pg = player:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("HUD")
    local mobileController = hud and hud:FindFirstChild("Mobile_Controller")
    return mobileController ~= nil and mobileController.Visible == true
end

local function shouldUseMobileHealInput(mode)
    return tostring(mode) == "Mobile" or isMobileHealUIVisible()
end

-- เปิดหน้ารายการไอเทมผ่าน UI ชื่อ "Item" ก่อนค้นหายา
-- ปุ่ม Item ใช้ร่วมกันทั้ง PC และ Mobile; ไม่เดาปุ่มจากคำว่า Bag/Inventory
local function openHealBagIfNeeded(mode, controls)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return controls end

    local function isVisibleThroughParents(obj)
        if not obj then return false end
        local node = obj
        while node and node ~= pg do
            if node:IsA("GuiObject") and not node.Visible then return false end
            node = node.Parent
        end
        return true
    end

    -- หากแผง รายการยา และปุ่ม Equip ที่ค้นพบแสดงอยู่จริง ไม่กด Item ซ้ำ
    if controls and controls.itemBox and controls.item and controls.equip
        and controls.modeName
        and isVisibleThroughParents(controls.itemBox)
        and isVisibleThroughParents(controls.item)
        and isVisibleThroughParents(controls.equip) then
        return controls
    end

    -- หา UI ที่ชื่อ Item ก่อน โดยให้ความสำคัญกับชื่อ Instance ตรงตัว
    local exactName = {}
    local textMatch = {}
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Active then
            if tostring(obj.Name):lower() == "item" then
                table.insert(exactName, obj)
            elseif obj:IsA("TextButton") and tostring(obj.Text):match("^%s*[Ii]tem%s*$") then
                table.insert(textMatch, obj)
            end
        end
    end

    local target = exactName[1] or textMatch[1]
    -- บาง UI ตั้งชื่อ Frame ว่า Item แล้ววางปุ่มกดไว้ข้างใน
    if not target then
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("GuiObject") and tostring(obj.Name):lower() == "item"
                and isVisibleThroughParents(obj) then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("GuiButton") and child.Visible and child.Active then
                        target = child
                        break
                    end
                end
                if target then break end
            end
        end
    end

    if not target then
        warn("[Auto Heal " .. tostring(mode or "PC") .. "] หา UI ชื่อ Item ไม่พบ; ไม่คลิกปุ่มอื่นแบบสุ่ม")
        return controls
    end

    local clicked = false
    if shouldUseMobileHealInput(mode) then
        clicked = clickHealMobileButton(target)
        if not clicked then clicked = fireButton(target) end
    else
        clicked = fireButton(target)
        if not clicked then clicked = clickHealGuiButton(target) end
    end
    print("[Auto Heal " .. tostring(mode or "PC") .. "] กด UI Item ก่อนค้นหายา:", clicked, target:GetFullName())
    task.wait(0.5)
    return getHealItemControls()
end

-- เลือกยาและ Equip เฉพาะเมื่อสถานะเป็น Equip
ensureHealPotionEquipped = function(mode)
    if isEquipping then return false end
    if tick() - lastEquipAttempt < 2 then return false end

    local controls = getHealItemControls()
    controls = openHealBagIfNeeded(mode, controls)
    if not controls or not controls.item or not controls.equip or not controls.modeName then
        healDebug("หาแผง Inventory/รายการ Single Healing Potion S/ปุ่ม Equip ไม่ครบ; เปิดหน้ากระเป๋าไว้แล้วลองอีกครั้ง")
        return false
    end

    local function modeText(c)
        return c and c.modeName and tostring(c.modeName.Text):match("^%s*(.-)%s*$") or ""
    end
    if modeText(controls):lower() == "remove" then
        return true
    end
    if modeText(controls):lower() ~= "equip" then
        healDebug("พบยาแต่สถานะปุ่มไม่ใช่ Equip: " .. modeText(controls))
        return false
    end

    isEquipping = true
    lastEquipAttempt = tick()
    -- Inventory item/equip controls follow the visible UI, not the heal toggle.
    -- This lets PC Auto Heal equip a potion when the game is currently showing Mobile UI.
    local mobileMode = shouldUseMobileHealInput(mode)
    local ok, err = pcall(function()
        local selected = false
        -- On mobile, prioritize actual touch input. Firing a GuiButton signal
        -- can report success without the game's inventory selection handler running.
        if mobileMode then
            if controls.item:IsA("GuiButton") then
                selected = clickMobileTarget(controls.item)
            else
                for _, child in ipairs(controls.item:GetDescendants()) do
                    if child:IsA("GuiButton") and child.Visible and child.Active then
                        selected = clickMobileTarget(child)
                        if selected then break end
                    end
                end
                if not selected and controls.item:IsA("GuiObject") and controls.item.Active then
                    selected = clickMobileTarget(controls.item)
                end
            end
        else
            -- PC inventory method confirmed by the user's live test:
            -- fire the potion TextButton's Activated connections, then verify UI state.
            -- Use an actual visible click only if the callback method is unavailable.
            local function fireActivatedConnections(button)
                if not button or not button:IsA("GuiButton") then return false end
                local okConnections, connections = pcall(function()
                    return getconnections(button.Activated)
                end)
                if not okConnections or type(connections) ~= "table" or #connections == 0 then
                    return false
                end
                local fired = false
                for _, conn in ipairs(connections) do
                    if conn.Enabled then
                        local okFire = pcall(function() conn:Fire() end)
                        if okFire then fired = true end
                    end
                end
                return fired
            end

            if controls.item:IsA("GuiButton") then
                selected = fireActivatedConnections(controls.item)
                if not selected then selected = clickHealGuiButton(controls.item) end
                if not selected then selected = fireButton(controls.item) end
            else
                for _, child in ipairs(controls.item:GetDescendants()) do
                    if child:IsA("GuiButton") and child.Visible and child.Active then
                        selected = fireActivatedConnections(child)
                        if not selected then selected = clickHealGuiButton(child) end
                        if not selected then selected = fireButton(child) end
                        if selected then break end
                    end
                end
                if not selected and controls.item:IsA("GuiObject") and controls.item.Active then
                    selected = clickHealGuiButton(controls.item)
                end
            end
        end
        if not selected then
            warn("[Auto Heal " .. tostring(mode or "PC") .. "] พบรายการยา แต่ส่งการเลือกไอเทมไม่สำเร็จ")
        end

        -- Wait for the selected potion to populate InfoFrame before touching Equip.
        task.wait(mobileMode and 0.4 or 0.5)
        local updated = getHealItemControls()
        if updated and updated.modeName and modeText(updated):lower() == "equip"
            and updated.equip and updated.equip.Visible and updated.equip.Active then
            local equipClicked = false
            if mobileMode then
                equipClicked = clickMobileTarget(updated.equip)
                print("[Auto Heal " .. tostring(mode or "PC") .. "] แตะ Equip:", equipClicked, updated.equip:GetFullName())
            else
                -- PC method from the confirmed standalone test: fire Activated,
                -- wait, then re-read ModeName. If it did not react, use a real UI click.
                local okConnections, connections = pcall(function()
                    return getconnections(updated.equip.Activated)
                end)
                if okConnections and type(connections) == "table" then
                    for _, conn in ipairs(connections) do
                        if conn.Enabled then
                            local okFire = pcall(function() conn:Fire() end)
                            if okFire then equipClicked = true end
                        end
                    end
                end
                print("[Auto Heal PC] ส่ง callback Equip:", equipClicked, updated.equip:GetFullName())
                task.wait(0.45)
                local afterCallback = getHealItemControls()
                if afterCallback and afterCallback.modeName
                    and modeText(afterCallback):lower() == "remove" then
                    updated = afterCallback
                elseif afterCallback and afterCallback.modeName
                    and modeText(afterCallback):lower() == "equip"
                    and afterCallback.equip and afterCallback.equip.Visible and afterCallback.equip.Active then
                    local clickSent = clickHealGuiButton(afterCallback.equip)
                    if not clickSent then clickSent = fireButton(afterCallback.equip) end
                    print("[Auto Heal PC] Fallback คลิก Equip:", clickSent)
                end
            end
        end
    end)

    task.wait(0.3)
    local updated = getHealItemControls()
    local equipped = updated and updated.modeName and modeText(updated):lower() == "remove"
    isEquipping = false

    if not ok then warn("[Auto Heal] Equip error:", err) end
    if equipped then
        print("[Auto Heal " .. tostring(mode or "PC") .. "] ยาอยู่ในช่องแล้ว")
        return true
    end
    healDebug("เลือก/Equip ยาไม่สำเร็จ; โหมด=" .. tostring(mode or "PC") .. "; สถานะ=" .. modeText(updated or {}))
    return false
end

-- ใช้ยาผ่านปุ่ม QuickItem; บาง UI มือถือ QuickItem เป็น Frame
-- และปุ่มกดจริงอยู่ข้างใน ไม่ใช่ตัว QuickItem เอง.
local function triggerSlot4Potion(mode, forceGui)
    -- PC: ยึดวิธีจาก Auto Heal ใน digimonEra3.lua
    -- ขั้นแรกส่งปุ่มคีย์บอร์ด 4; หากต้อง fallback ให้หา GuiButton ที่ Text == "4" ทั่ว PlayerGui.
    -- Mobile-only path: target the actual visible slot button whose own Text is "4".
    -- This block is isolated from the PC keyboard/UI behavior below.
    if tostring(mode) == "Mobile" then
        local mobilePg = player:FindFirstChild("PlayerGui")
        if mobilePg then
            local function visibleThroughParents(obj)
                local node = obj
                while node and node ~= mobilePg do
                    if node:IsA("GuiObject") and not node.Visible then return false end
                    node = node.Parent
                end
                return true
            end

            local candidates = {}
            for _, obj in ipairs(mobilePg:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local buttonText = ""
                    pcall(function() buttonText = tostring(obj.Text) end)
                    local hasFourLabel = buttonText:match("^%s*4%s*$") ~= nil
                    if not hasFourLabel then
                        for _, child in ipairs(obj:GetDescendants()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") then
                                local labelText = ""
                                pcall(function() labelText = tostring(child.Text) end)
                                if labelText:match("^%s*4%s*$") then
                                    hasFourLabel = true
                                    break
                                end
                            end
                        end
                    end
                    if hasFourLabel and obj.Visible and obj.Active
                        and visibleThroughParents(obj) then
                        table.insert(candidates, obj)
                    end
                end
            end

            local mobileHud = mobilePg:FindFirstChild("HUD")
            local mobileQuickItem = mobileHud and mobileHud:FindFirstChild("QuickItem", true)
            local mobileTarget = nil
            if mobileQuickItem then
                for _, candidate in ipairs(candidates) do
                    if candidate == mobileQuickItem or candidate:IsDescendantOf(mobileQuickItem) then
                        mobileTarget = candidate
                        break
                    end
                end
            end
            if not mobileTarget and #candidates == 1 then
                mobileTarget = candidates[1]
            end

            if mobileTarget then
                -- MOBILE-ONLY CHANGE:
                -- Prefer the connected UI callback first. The detected InventoryUI
                -- connection is named useEquippedItem; sending a synthetic touch can
                -- return success without the game's item-use callback actually running.
                -- The existing PC branch below is deliberately unchanged.
                if fireButton(mobileTarget) then
                    print("[Auto Heal Mobile] เรียก callback ปุ่มช่อง 4 ก่อน Touch:", mobileTarget:GetFullName())
                    return true, "เรียก callback ช่อง 4 แล้ว; กำลังตรวจ HP"
                end

                if forceGui then
                    local activated = pcall(function() mobileTarget:Activate() end)
                    if activated then
                        print("[Auto Heal Mobile] Fallback Activate ช่อง 4:", mobileTarget:GetFullName())
                        return true, "Activate ช่อง 4 แล้ว; กำลังตรวจ HP"
                    end
                    warn("[Auto Heal Mobile] Fallback ช่อง 4 ไม่สำเร็จ:", mobileTarget:GetFullName())
                    return false, "Fallback ช่อง 4 ไม่สำเร็จ"
                end

                -- Touch is only attempted if firing the connected callback failed.
                if clickHealMobileButton(mobileTarget) then
                    print("[Auto Heal Mobile] ส่ง Touch ช่อง 4 ตาม UI Text=4:", mobileTarget:GetFullName())
                    return true, "ส่ง Touch ช่อง 4 แล้ว; กำลังตรวจ HP"
                end
                warn("[Auto Heal Mobile] พบปุ่ม Text=4 แต่ callback และ Touch ไม่สำเร็จ:", mobileTarget:GetFullName())
            end
        end
    end

    local pg = player:FindFirstChild("PlayerGui")
    local pcKeyFallback = false
    if tostring(mode) ~= "Mobile" then
        -- PC Auto Heal: try the actual keyboard 4 input first, matching the
        -- reference method. HP is checked by the caller; a successful API call
        -- alone is not treated as proof that the potion was consumed.
        if not forceGui then
            local keySent = pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
                task.wait(0.08)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
            end)
            if keySent then
                print("[Auto Heal PC] ส่งปุ่มคีย์บอร์ด 4 ก่อนตรวจผลการใช้ยา")
                return true, "ส่งปุ่ม 4 แล้ว; กำลังตรวจ HP"
            end
        end
        -- If keyboard use did not heal, the caller retries with forceGui=true.
        -- In that retry, activate a visible GUI button explicitly labeled 4.
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local text = ""
                    pcall(function() text = tostring(obj.Text) end)
                    if text == "4" and obj.Visible and obj.Active then
                        local ok = pcall(function() obj:Activate() end)
                        if ok then
                            print("[Auto Heal PC] กดปุ่ม UI Text=4 ตามวิธี digimonEra3:", obj:GetFullName())
                            return true, "Activate ปุ่ม UI Text=4 แล้ว; กำลังตรวจ HP"
                        end
                    end
                end
            end
        end
        -- หากไม่พบปุ่มที่มี Text == "4" อย่าเพิ่งจบการทำงาน:
        -- บาง UI ใช้ HUD.QuickItem เป็นปุ่มช่อง 4 โดยตรง หรือมีข้อความ 4 อยู่ในลูก
        -- ให้ไหลต่อไปตรวจ HUD.QuickItem ด้านล่าง โดยเฉพาะตอน forceGui fallback
        -- เพื่อไม่ให้ Auto Heal หยุดก่อนลองกดปุ่มช่อง 4 จริง
    end
    local hud = pg and pg:FindFirstChild("HUD")
    local quickItem = hud and hud:FindFirstChild("QuickItem", true)
    if not quickItem then
        return false, "ไม่พบ HUD.QuickItem (ช่องยา 4)"
    end

    -- In the user's current UI, HUD.QuickItem itself is a TextButton.
    -- Treat the object itself as the candidate only when it is a visible, active
    -- GuiButton and it has no usable child buttons. Do not reject it just because
    -- it has no GuiButton descendants.
    local buttons = {}
    for _, child in ipairs(quickItem:GetDescendants()) do
        if child:IsA("GuiButton") and child.Visible and child.Active then
            table.insert(buttons, child)
        end
    end

    if #buttons == 0 then
        if quickItem:IsA("GuiButton") and quickItem.Visible and quickItem.Active then
            buttons[1] = quickItem
        else
            return false, "QuickItem ไม่มีปุ่มที่มองเห็นและ Active; QuickItem=" .. quickItem.ClassName
        end
    end

    local function markerFor(obj)
        local bits = {obj.Name}
        if obj:IsA("TextButton") then table.insert(bits, obj.Text) end
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                table.insert(bits, d.Name)
                table.insert(bits, tostring(d.Text or ""))
            end
        end
        return table.concat(bits, " "):lower()
    end

    local target = nil
    -- The log from the current game explicitly reports HUD.QuickItem as a
    -- TextButton with zero GuiButton children. In that exact case, use the
    -- QuickItem TextButton itself instead of requiring a child named Slot4.
    if #buttons == 1 and buttons[1] == quickItem and quickItem:IsA("TextButton") then
        target = quickItem
    end

    -- ชื่อปุ่ม/ข้อความที่ระบุช่อง 4 ชัดเจนมาก่อน
    if not target then
    for _, b in ipairs(buttons) do
        local marker = markerFor(b)
        if marker:match("slot%s*4") or marker:match("item%s*4")
            or marker:match("button%s*4") or marker:match("quickitem%s*4")
            or marker:match("^%s*4%s*$") or marker:match("[%s_%-]4[%s_%-]") then
            target = b
            break
        end
    end
    end

    -- ถ้า UI ไม่ตั้งชื่อช่องไว้ ให้เรียงปุ่มในแถบเดียวกันจากซ้ายไปขวา
    -- แล้วเลือกปุ่มลำดับที่ 4 เฉพาะเมื่อมีอย่างน้อย 4 ปุ่มในแถบเดียวกัน.
    if not target then
        local rows = {}
        for _, b in ipairs(buttons) do
            local pos, size = b.AbsolutePosition, b.AbsoluteSize
            if size.X > 0 and size.Y > 0 then
                local rowKey = math.floor((pos.Y + size.Y / 2) / 25)
                rows[rowKey] = rows[rowKey] or {}
                table.insert(rows[rowKey], b)
            end
        end
        local bestRow, bestCount = nil, 0
        for _, row in pairs(rows) do
            table.sort(row, function(a, b)
                return a.AbsolutePosition.X < b.AbsolutePosition.X
            end)
            if #row > bestCount then bestRow, bestCount = row, #row end
        end
        if bestRow and #bestRow >= 4 then
            target = bestRow[4]
        -- Do not guess when only one unlabeled child exists: it may be a
        -- container/other slot. Require an explicit slot marker or a row of 4+.
        end
    end

    if not target then
        local details = {}
        for i, b in ipairs(buttons) do
            if i > 12 then break end
            table.insert(details, b.Name .. "(" .. b.ClassName .. ")")
        end
        return false, "หยุดเพื่อไม่แตะผิดปุ่ม: ระบุช่อง 4 ใน QuickItem ไม่ได้; ปุ่มลูกที่พบ: " .. table.concat(details, ", ")
    end

    if not target.Visible or not target.Active then
        return false, "ปุ่มช่อง 4 ยังไม่พร้อมใช้งาน: " .. target:GetFullName()
    end

    if tostring(mode) == "Mobile" then
        if clickHealMobileButton(target) then
            print("[Auto Heal Mobile] ส่ง Touch ไปปุ่มช่อง 4 โดยตรง:", target:GetFullName())
            return true, "แตะปุ่มช่อง 4 แล้ว; กำลังตรวจ HP"
        end
        if fireButton(target) then
            print("[Auto Heal Mobile] Fired callback ช่อง 4:", target:GetFullName())
            return true, "เรียก callback ช่อง 4 แล้ว; กำลังตรวจ HP"
        end
    else
        if fireButton(target) then
            print("[Auto Heal PC] Fired slot 4 button:", target:GetFullName())
            return true, "ส่งคำสั่งช่อง 4 แล้ว; กำลังตรวจ HP"
        end
        if clickHealGuiButton(target) then
            print("[Auto Heal PC] Clicked slot 4 button:", target:GetFullName())
            return true, "คลิกช่อง 4 แล้ว; กำลังตรวจ HP"
        end
    end
    return false, "กดปุ่มช่อง 4 ไม่สำเร็จ: " .. tostring(target and target:GetFullName() or "ไม่พบปุ่มช่อง 4")
end

local function confirmHealIncrease(previousHP, timeout)
    local deadline = tick() + (timeout or 2)
    while tick() < deadline do
        task.wait(0.25)
        local currentHP = getDigimonHP()
        if currentHP and previousHP and currentHP > previousHP then
            return true, currentHP
        end
    end
    local currentHP = getDigimonHP()
    return false, currentHP
end

-- ================================================
-- AUTO EQUIP POTION + POTION SELECTION
-- เลือกยา S/M/L และ Equip เข้าช่อง 4 แยกจาก Auto Heal
-- ระบบนี้ไม่กดใช้ยา และทำงานได้แม้ HP เต็ม
-- ================================================
refreshPotionSelectionButton()
if potionSelectBtn then
    potionSelectBtn.MouseButton1Click:Connect(function()
        local index = table.find(HEAL_POTION_TIERS, selectedHealPotionTier) or 1
        index = index % #HEAL_POTION_TIERS + 1
        selectedHealPotionTier = HEAL_POTION_TIERS[index]
        refreshPotionSelectionButton()
        sendNotification("Potion Selection", "เลือกยา Single Healing Potion " .. selectedHealPotionTier)
    end)
end
if potionEquipBtn then
    updateButton(potionEquipBtn, AUTO_EQUIP_POTION, "Auto Equip Potion")
    potionEquipBtn.MouseButton1Click:Connect(function()
        AUTO_EQUIP_POTION = not AUTO_EQUIP_POTION
        updateButton(potionEquipBtn, AUTO_EQUIP_POTION, "Auto Equip Potion")
        sendNotification("Auto Equip Potion", AUTO_EQUIP_POTION
            and ("เปิดแล้ว: จะพยายามใส่ยา " .. selectedHealPotionTier .. " เข้าช่อง 4 อัตโนมัติ")
            or "ปิดแล้ว")
    end)
end

-- Auto Equip is independent of Auto Heal/HP. It only runs inside the dungeon,
-- retries on a cooldown, and never presses slot 4 to consume the potion.
task.spawn(function()
    local lastAutoEquipTry = 0
    while screenGui and screenGui.Parent do
        if AUTO_EQUIP_POTION and game.PlaceId == DUNGEON_PLACE_ID
            and not isEquipping and tick() - lastAutoEquipTry >= 5 then
            lastAutoEquipTry = tick()
            local ok, equipped = pcall(function()
                return ensureHealPotionEquipped and ensureHealPotionEquipped("PC")
            end)
            if ok and equipped then
                -- Quiet success: don't spam notifications every retry.
            elseif not ok then
                warn("[Auto Equip Potion]", equipped)
            end
        end
        task.wait(1)
    end
end)

-- ================================================
-- AUTO HEAL
-- ================================================

local function triggerHealKeyboard()
    pcall(function()
        VirtualInputManager:SendKeyEvent(
            true, Enum.KeyCode.Four, false, game
        )
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(
            false, Enum.KeyCode.Four, false, game
        )
    end)
end

local function triggerHealUI()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return false end

    for _, obj in ipairs(pGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local text = ""

            pcall(function()
                text = tostring(obj.Text)
            end)

            if text == "4" then
                local ok = pcall(function()
                    obj:Activate()
                end)

                if ok then return true end
            end
        end
    end

    return false
end

local function getDigimonHP()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return nil, nil end

    for _, gui in ipairs(pGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
            local text = gui.Text:gsub(",", "")
            local cur, max = text:match("(%d+)%s*/%s*(%d+)")

            if cur and max then
                local cVal, mVal = tonumber(cur), tonumber(max)

                if cVal and mVal and mVal > 100 then
                    return cVal, mVal
                end
            end
        end
    end

    return nil, nil
end

task.spawn(function()
    local lastHealTime = 0

    while screenGui.Parent do
        if AUTO_HEAL then
            pcall(function()
                local curHP, maxHP = getDigimonHP()

                if curHP and maxHP then
                    local missingHP = maxHP - curHP

                    if missingHP >= HEAL_DROP_AMOUNT
                        and tick() - lastHealTime >= 2 then

                        triggerHealKeyboard()
                        task.wait(0.15)
                        triggerHealUI()
                        lastHealTime = tick()

                        sendNotification(
                            "Auto Heal",
                            "HP ลด " .. math.floor(missingHP)
                        )
                    end
                end
            end)
        end

        task.wait(0.2)
    end
end)
-- ================================================
-- AUTO CHEST
-- ================================================

local chestRetryAt = {}
local CHEST_RETRY_COOLDOWN = 15
local CHEST_ENEMY_CHECK_DISTANCE = 60
local CHEST_STANDOFF_DISTANCE = 5

-- In the dungeon, only allow Auto Chest to target objects belonging to
-- the physical room currently shown by Auto Explore. This prevents a chest
-- left in an earlier room from pulling the player backwards.
local function getChestWorldRoomName(obj)
    local gameMap = workspace:FindFirstChild("GameMap")
    if not gameMap or not obj then return nil end

    local ancestor = obj.Parent
    while ancestor and ancestor ~= gameMap do
        if ancestor.Name:match("^Layer_%d+_SmallMap_%d+$") then
            return ancestor.Name
        end
        ancestor = ancestor.Parent
    end
    return nil
end

local function chestLooksOpened(chest)
    if not chest or not chest.Parent then return true end
    local partCount, transparentCount = 0, 0
    for _, obj in ipairs(chest:GetDescendants()) do
        if obj:IsA("BasePart") then
            partCount += 1
            if obj.Transparency >= 0.85 then
                transparentCount += 1
            end
        elseif obj:IsA("ProximityPrompt") and not obj.Enabled then
            return true
        end
    end
    -- User confirmed opened chests keep their model but become transparent.
    return partCount > 0 and transparentCount >= math.max(1, math.ceil(partCount * 0.6))
end

local function findAndTeleportToChest(rootPart)
    if not AUTO_CHEST or not rootPart then
        return false
    end

    local isDungeon = game.PlaceId == EXPLORE_DUNGEON_PLACE_ID
    local currentRoomKey = isDungeon and getCurrentRoomKey() or nil
    local currentWorldRoomName = currentRoomKey
        and currentRoomKey:match("([^/]+)$") or nil

    -- If we cannot identify the current room in the dungeon, fail closed:
    -- do not use a workspace-wide chest search that could revisit old rooms.
    if isDungeon and not currentWorldRoomName then
        return false
    end

    local closestChest, closestDist = nil, SEARCH_RADIUS
    local now = tick()

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not openedChests[obj] then
            local name = obj.Name:lower()
            if name:find("chest") or name:find("rewardbox") or name:find("treasure") then
                if chestLooksOpened(obj) then
                    openedChests[obj] = true
                    chestRetryAt[obj] = nil
                elseif not chestRetryAt[obj] or now >= chestRetryAt[obj] then
                    local inCurrentRoom = true
                    if isDungeon then
                        inCurrentRoom = getChestWorldRoomName(obj) == currentWorldRoomName
                    end
                    if inCurrentRoom then
                        local ok, pos = pcall(function()
                            return obj:GetPivot().Position
                        end)
                        if ok then
                            local dist = (pos - rootPart.Position).Magnitude
                            if dist < closestDist then
                                closestChest = obj
                                closestDist = dist
                            end
                        end
                    end
                end
            end
        end
    end

    if not closestChest or not AUTO_CHEST then
        return false
    end

    local chest = closestChest
    local ok, chestPos = pcall(function()
        return chest:GetPivot().Position
    end)
    if not ok then
        chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
        return false
    end

    -- Chest has priority when Auto Chest is enabled. Nearby enemies should not
    -- cause this function to abandon the chest and leave movement to Auto Farm.

    local prompts = {}
    for _, obj in ipairs(chest:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            table.insert(prompts, obj)
        end
    end

    if #prompts == 0 then
        -- Avoid repeatedly selecting objects that only look like chests.
        chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
        return false
    end

    sendNotification("Auto Chest", "กำลังลองเปิดหีบ...")

    -- Stand beside the chest, never inside its pivot. Preserve the current
    -- approach direction so the character is less likely to get trapped.
    local offset = rootPart.Position - chestPos
    local flatOffset = Vector3.new(offset.X, 0, offset.Z)
    if flatOffset.Magnitude < 0.1 then
        flatOffset = Vector3.new(1, 0, 0)
    else
        flatOffset = flatOffset.Unit
    end
    local standPos = chestPos + flatOffset * CHEST_STANDOFF_DISTANCE

    pcall(function()
        rootPart.CFrame = CFrame.new(standPos, chestPos)
    end)
    task.wait(0.15)

    -- Make only a small number of attempts; don't keep teleporting onto the chest.
    for i = 1, 3 do
        if not AUTO_CHEST or not chest.Parent then
            break
        end
        for _, prompt in ipairs(prompts) do
            if prompt.Parent and prompt.Enabled and type(fireproximityprompt) == "function" then
                pcall(function()
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = 20
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                end)
            end
        end
        task.wait(0.15)
    end

    if not chest.Parent then
        openedChests[chest] = true
        chestRetryAt[chest] = nil
        sendNotification("Auto Chest", "หีบถูกเก็บแล้ว")
        return true
    end

    local anyEnabledPrompt = false
    for _, obj in ipairs(chest:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            anyEnabledPrompt = true
            break
        end
    end

    if not anyEnabledPrompt then
        -- A disabled prompt alone is not proof the chest opened. The game keeps
        -- opened chest models but makes their parts transparent; require that signal.
        if chestLooksOpened(chest) then
            openedChests[chest] = true
            chestRetryAt[chest] = nil
            sendNotification("Auto Chest", "ยืนยันว่าหีบเปิดแล้วจากความโปร่งแสง/สถานะ Prompt")
            return true
        end
        chestRetryAt[chest] = tick() + math.min(CHEST_RETRY_COOLDOWN, 5)
        warn("[Auto Chest] ไม่พบ Prompt ที่เปิดใช้งาน แต่หีบยังดูไม่เปิด จะตรวจซ้ำ")
        return false
    end

    -- Skip this chest for a while if it didn't open, letting Auto Farm continue.
    chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
    return false
end

-- ================================================
-- AUTO DROPS
-- ================================================

local function findAndTeleportToDrop(rootPart)
    if not AUTO_DROPS or not rootPart then return false end

    local container = workspace:FindFirstChild("ClientDrops")
        or workspace:FindFirstChild("Drops")

    if not container then return false end

    local closestDrop, closestDist = nil, SEARCH_RADIUS

    for _, item in ipairs(container:GetChildren()) do
        if (item:IsA("Model") or item:IsA("BasePart")
            or item:IsA("Tool")) and not collectedDrops[item] then

            local name = item.Name:lower()

            if not name:find("orb") and not name:find("chest")
                and not name:find("rewardbox") then

                local ok, pos = pcall(function()
                    return item:GetPivot().Position
                end)

                if ok then
                    local dist = (pos - rootPart.Position).Magnitude

                    if dist < closestDist then
                        closestDrop, closestDist = item, dist
                    end
                end
            end
        end
    end

    if not closestDrop or not AUTO_DROPS then return false end

    local dropName = closestDrop.Name
    sendNotification("Auto Drops", "วาร์ปไปเก็บ " .. dropName)

    local ok, pos = pcall(function()
        return closestDrop:GetPivot().Position
    end)

    if not ok then return false end

    pcall(function()
        rootPart.CFrame = CFrame.new(pos)
    end)

    task.wait(0.1)

    local parts = {}

    if closestDrop:IsA("BasePart") then
        table.insert(parts, closestDrop)
    else
        for _, obj in ipairs(closestDrop:GetDescendants()) do
            if obj:IsA("BasePart") then
                table.insert(parts, obj)
            end
        end
    end

    for _, part in ipairs(parts) do
        pcall(function()
            part.CanCollide = false

            if firetouchinterest then
                firetouchinterest(rootPart, part, 0)
                task.wait(0.02)
                firetouchinterest(rootPart, part, 1)
            end
        end)
    end

    for _, obj in ipairs(closestDrop:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                obj.RequiresLineOfSight = false
                obj.HoldDuration = 0

                if fireproximityprompt then
                    fireproximityprompt(obj)
                end
            end)
        end
    end

    task.wait(0.35)
    -- Only mark as collected after the object actually disappears from the drop folder.
    if not closestDrop.Parent then
        collectedDrops[closestDrop] = true
        return true
    end

    -- Keep it eligible for a later scan if touch/prompt did not collect it.
    return false
end

-- Auto Explore must not switch rooms while current-room drops or unopened chests remain.
hasPendingRoomLoot = function()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local isDungeon = game.PlaceId == EXPLORE_DUNGEON_PLACE_ID
    local roomKey = isDungeon and getCurrentRoomKey() or nil
    local currentWorldRoomName = roomKey and roomKey:match("([^/]+)$") or nil

    if AUTO_DROPS then
        local container = workspace:FindFirstChild("ClientDrops") or workspace:FindFirstChild("Drops")
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Tool"))
                    and not collectedDrops[item] then
                    local name = item.Name:lower()
                    if not name:find("orb") and not name:find("chest") and not name:find("rewardbox") then
                        local ok, pos = pcall(function() return item:GetPivot().Position end)
                        if ok and (pos - rootPart.Position).Magnitude <= 100 then
                            return true
                        end
                    end
                end
            end
        end
    end

    if AUTO_CHEST then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and not openedChests[obj] then
                local name = obj.Name:lower()
                if name:find("chest") or name:find("rewardbox") or name:find("treasure") then
                    if chestLooksOpened(obj) then
                        openedChests[obj] = true
                    else
                        local inRoom = true
                        if isDungeon then
                            inRoom = currentWorldRoomName ~= nil
                                and getChestWorldRoomName(obj) == currentWorldRoomName
                        end
                        if inRoom then
                            -- Any unopened chest assigned to the current room blocks
                            -- room progression, even if it is across the room or outside
                            -- the current pickup radius. Auto Chest must keep retrying it.
                            local ok = pcall(function() return obj:GetPivot().Position end)
                            if ok then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ================================================
-- PATHFINDING (AUTO FARM)
-- ================================================

local function walkToTarget(character, humanoid, targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.5,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })

    local success = pcall(function()
        path:ComputeAsync(character:GetPivot().Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(character:GetPivot().Position)
        return false
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not AUTO_FARM or AUTO_FEED_BUSY or not character.Parent or humanoid.Health <= 0 then
            humanoid:MoveTo(character:GetPivot().Position)
            return false
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local finished, reached = false, false
        local conn = humanoid.MoveToFinished:Connect(function(didReach)
            finished = true
            reached = didReach
        end)

        local started = tick()
        while not finished and tick() - started < 1.2
            and AUTO_FARM and not AUTO_FEED_BUSY do
            task.wait(0.05)
        end
        conn:Disconnect()

        if not finished or not reached then
            humanoid:MoveTo(character:GetPivot().Position)
            return false
        end
    end

    return true
end

-- ================================================
-- AUTO DUNGEON LOOP (WITH GUARD LOCK)
-- ================================================

local LOBBY_PLACE_ID = 84773733171614
local DUNGEON_PLACE_ID = 112998674138179
local DUNGEON_MAX_DURATION = 900 -- safety timeout: 15 minutes

local function walkIntoNearestLift()
    local folder = workspace:FindFirstChild("MatchmakingZones")
    if not folder then
        warn("[Dungeon Loop] ไม่พบ MatchmakingZones")
        return false
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        warn("[Dungeon Loop] ไม่พบตัวละครหรือ Humanoid")
        return false
    end

    local nearest, bestDistance

    for i = 1, 4 do
        local lift = folder:FindFirstChild("StartLift" .. i)

        if lift then
            local ok, pos = pcall(function()
                return lift:GetPivot().Position
            end)

            if ok then
                local distance = (root.Position - pos).Magnitude
                if not bestDistance or distance < bestDistance then
                    nearest = lift
                    bestDistance = distance
                end
            end
        end
    end

    if not nearest then
        warn("[Dungeon Loop] ไม่พบลิฟต์")
        return false
    end

    local targetPos = nearest:GetPivot().Position
    humanoid:MoveTo(targetPos)

    local started = tick()

    while AUTO_DUNGEON_LOOP and tick() - started < 15 do
        if not root.Parent then return false end

        if (root.Position - targetPos).Magnitude < 8 then
            return true
        end

        task.wait(0.25)
    end

    return false
end

local function selectForestAndStart()
    local pg = player:WaitForChild("PlayerGui", 10)
    local main = pg and pg:WaitForChild("Main", 10)
    local chooseMap = main and main:WaitForChild("ChooseMap", 20)

    if not chooseMap then
        warn("[Dungeon Loop] ไม่พบ ChooseMap")
        return false
    end

    local mapName = DungeonSettings.Map
    local selectedLevel = DungeonSettings.Level

    if not DungeonLevels[mapName] then
        warn("[Dungeon Loop] ชื่อแผนที่ไม่ถูกต้อง:", tostring(mapName))
        return false
    end

    local validLevel = false
    for _, levelName in ipairs(DungeonLevels[mapName]) do
        if levelName == selectedLevel then
            validLevel = true
            break
        end
    end

    if not validLevel then
        warn("[Dungeon Loop] เลเวลไม่ตรงกับแผนที่:", mapName, selectedLevel)
        return false
    end

    local mapList = chooseMap:FindFirstChild("MapChooseScrolling", true)
    local mapButton = mapList and mapList:FindFirstChild(mapName, true)

    if not mapButton or not mapButton:IsA("GuiButton") then
        warn("[Dungeon Loop] ไม่พบปุ่มแผนที่:", mapName)
        return false
    end

    if not fireButton(mapButton) then
        warn("[Dungeon Loop] กดเลือกแผนที่ไม่สำเร็จ:", mapName)
        return false
    end

    task.wait(0.5)

    chooseMap = main:FindFirstChild("ChooseMap")
    local levelList = chooseMap
        and chooseMap:FindFirstChild("LevelChooseScrolling")

    if not levelList then
        warn("[Dungeon Loop] ไม่พบ LevelChooseScrolling")
        return false
    end

    local levelButton
    local wantedLevel = tostring(selectedLevel):gsub("%s+", ""):lower()

    for _, obj in ipairs(levelList:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible then
            local nameMatch = tostring(obj.Name):gsub("%s+", ""):lower() == wantedLevel
            local textMatch = obj:IsA("TextButton")
                and tostring(obj.Text):gsub("%s+", ""):lower() == wantedLevel
            if nameMatch or textMatch then
                levelButton = obj
                break
            end
        end
    end

    if not levelButton then
        warn("[Dungeon Loop] ไม่พบปุ่มเลเวล:", selectedLevel)
        return false
    end

    if not fireButton(levelButton) then
        warn("[Dungeon Loop] กดเลือกเลเวลไม่สำเร็จ:", selectedLevel)
        return false
    end

    task.wait(0.5)

    local mapInfo = chooseMap:FindFirstChild("MapInfo", true)
        or main:FindFirstChild("MapInfo", true)
    local startButton = mapInfo and mapInfo:FindFirstChild("StartButton", true)

    if not startButton then
        warn("[Dungeon Loop] ไม่พบ MapInfo.StartButton")
        return false
    end

    local startOK = fireButton(startButton)

    if not startOK then
        warn("[Dungeon Loop] กด Start ไม่สำเร็จ")
        return false
    end

    local waiting = main:WaitForChild("TeleportWaiting", 15)
    local secondStart = waiting and waiting:WaitForChild("StartButton", 10)

    if not secondStart then
        warn("[Dungeon Loop] ไม่พบปุ่ม Start ใน TeleportWaiting")
        return false
    end

    task.wait(0.5)
    return fireButton(secondStart)
end

-- Auto Evacuate is allowed only after the actual final room of Floor 3
-- has reached 100%, and the HUD confirms evacuation progress is complete.
local function isMapThreeComplete()
    local mapFrame = getMapFrame()
    local scrolling = mapFrame and mapFrame:FindFirstChild("ScrollingFrame")
    local mapThree = scrolling and scrolling:FindFirstChild("Map3")
    local finalRoom = mapThree and mapThree:FindFirstChild("Layer_3_SmallMap_7")

    if not finalRoom or not finalRoom:IsA("TextButton") then
        return false
    end

    local roomPercent = readExplorePercent(finalRoom)
    if roomPercent == nil or roomPercent < 100 then
        return false
    end

    local pg = player:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("HUD")
    local stability = hud and hud:FindFirstChild("StabilityPointFrame")
    local progressFrame = stability and stability:FindFirstChild("ProgressFrame")
    local progressLabel = progressFrame and progressFrame:FindFirstChild("Progress")
    local progressText = progressLabel and progressLabel:IsA("TextLabel")
        and tostring(progressLabel.Text) or ""

    -- The user's in-game check confirmed the room cannot be evacuated before 100%.
    return progressText:match("100%s*%%") ~= nil
end

local function autoEvacuateToLobby()
    local pg = player:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("HUD")
    local buttons = hud and hud:FindFirstChild("ButtonsFrame")
    local evacuate = buttons and buttons:FindFirstChild("EvacuateButton")
    local imageButton = evacuate and evacuate:FindFirstChild("ImageButton")

    if not imageButton or not fireButton(imageButton) then
        warn("[Auto Evacuate] กด EvacuateButton ไม่สำเร็จ")
        return false
    end
    print("[Auto Evacuate] กด Evacuate แล้ว กำลังรอประตูชั้น 1")

    -- The extraction portal appears after Evacuate sends the player back to Floor 1.
    local portal
    local waitStarted = tick()
    repeat
        local gameMap = workspace:FindFirstChild("GameMap")
        local layer1 = gameMap and gameMap:FindFirstChild("Layer_1_SmallMap_1")
        local decorations = layer1 and layer1:FindFirstChild("Decorations")
        portal = decorations and decorations:FindFirstChild("ExtractionPortal")
        if portal then break end
        if not AUTO_DUNGEON_LOOP then return false end
        task.wait(0.25)
    until tick() - waitStarted >= 15

    if not portal then
        warn("[Auto Evacuate] ไม่พบ ExtractionPortal หลังอพยพ")
        return false
    end

    local mainPart = portal:FindFirstChild("MainPart")
    local prompt = portal:FindFirstChildWhichIsA("ProximityPrompt", true)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not mainPart or not prompt or not root then
        warn("[Auto Evacuate] ขาด MainPart, ProximityPrompt หรือตัวละคร")
        return false
    end

    -- Match the tested method: overlap the portal center and raise the character 3 studs.
    root.CFrame = CFrame.new(mainPart.Position + Vector3.new(0, 3, 0))
    task.wait(0.5)

    if not prompt.Enabled or type(fireproximityprompt) ~= "function" then
        warn("[Auto Evacuate] Prompt ไม่พร้อม หรือไม่มี fireproximityprompt")
        return false
    end

    local promptOK = pcall(function()
        fireproximityprompt(prompt)
    end)
    if not promptOK then
        warn("[Auto Evacuate] เรียก Rotating Prompt ไม่สำเร็จ")
        return false
    end

    local model = pg and pg:FindFirstChild("Model")
    local extractFrame = model and model:FindFirstChild("ExtractFrame")
    waitStarted = tick()
    while AUTO_DUNGEON_LOOP and tick() - waitStarted < 12 do
        if extractFrame and extractFrame.Visible then break end
        task.wait(0.25)
    end

    if not extractFrame or not extractFrame.Visible then
        warn("[Auto Evacuate] หน้า Extract Rewards ไม่เปิด")
        return false
    end

    local backButton = extractFrame:FindFirstChild("BackToLooby")
    if not backButton or not backButton.Visible or not backButton.Active then
        warn("[Auto Evacuate] ไม่พบปุ่ม BackToLooby ที่พร้อมใช้งาน")
        return false
    end

    -- This exact button signal was already tested successfully by the user.
    local backOK = false
    if type(firesignal) == "function" then
        backOK = pcall(function()
            firesignal(backButton.Activated)
        end)
    end
    if not backOK then
        backOK = fireButton(backButton)
    end

    if not backOK then
        warn("[Auto Evacuate] เรียก BackToLooby ไม่สำเร็จ")
        return false
    end

    print("[Auto Evacuate] เรียก BackToLooby แล้ว กำลังกลับล็อบบี้")
    return true
end

local function runDungeonRound()
    if game.PlaceId == LOBBY_PLACE_ID then
        sendNotification(
            "Dungeon Loop",
            "กำลังหาลิฟต์เข้า " .. tostring(DungeonSettings.Map)
        )

        if not walkIntoNearestLift() then
            warn("[Dungeon Loop] เดินเข้าลิฟต์ไม่สำเร็จ จะลองใหม่อัตโนมัติ")
            return
        end

        task.wait(1)

        local startedOK = selectForestAndStart()
        if not startedOK then
            warn("[Dungeon Loop] เลือกแผนที่หรือกด Start ไม่สำเร็จ จะลองใหม่อัตโนมัติ")
            task.wait(3)
            return
        end

        -- Wait for teleport to finish before the outer loop attempts another start.
        local waitStarted = tick()
        while AUTO_DUNGEON_LOOP and tick() - waitStarted < 120 do
            if game.PlaceId == DUNGEON_PLACE_ID then
                print("[Dungeon Loop] เข้า Dungeon สำเร็จ เริ่มรอบฟาร์ม")
                return
            end
            task.wait(1)
        end

        if AUTO_DUNGEON_LOOP then
            warn("[Dungeon Loop] รอเข้า Dungeon เกิน 120 วินาที จะลองเริ่มใหม่")
        end
        return
    end

    if game.PlaceId == DUNGEON_PLACE_ID then
        sendNotification("Dungeon Loop", "เริ่มฟาร์มจนเคลียร์ Map3")

        enableAllAutoButtons()

        local started = tick()
        local completed = false
        while AUTO_DUNGEON_LOOP
            and tick() - started < DUNGEON_MAX_DURATION do
            if isMapThreeComplete() and not hasReachableLivingEnemy(120) then
                completed = true
                break
            end
            task.wait(1)
        end

        if not AUTO_DUNGEON_LOOP then return end

        if not completed then
            warn("[Dungeon Loop] ยังไม่ยืนยัน Layer_3_SmallMap_7 ที่ 100% จะตรวจต่อในรอบถัดไป")
            sendNotification("Dungeon Loop", "ยังไม่ครบชั้น 3 ที่ 100% — ฟาร์มต่อ")
            return
        end

        sendNotification("Dungeon Loop", "ชั้น 3 ห้อง 7 ครบ 100% แล้ว กำลังอพยพกลับล็อบบี้")
        local evacuated = autoEvacuateToLobby()
        if not evacuated then
            warn("[Dungeon Loop] อพยพไม่สำเร็จ จะตรวจใหม่ในรอบถัดไป")
            task.wait(3)
            return
        end

        -- Do not start another round until the game confirms the return to lobby.
        local waitStarted = tick()
        while AUTO_DUNGEON_LOOP and tick() - waitStarted < 120 do
            if game.PlaceId == LOBBY_PLACE_ID then
                print("[Dungeon Loop] กลับล็อบบี้แล้ว จะเริ่มดันเจี้ยนรอบใหม่อัตโนมัติ")
                return
            end
            task.wait(1)
        end

        if AUTO_DUNGEON_LOOP then
            warn("[Dungeon Loop] ยังไม่กลับล็อบบี้ จะรอตรวจสถานะใหม่")
        end
    end
end

local dungeonRoundRunning = false

task.spawn(function()
    while screenGui.Parent do
        if AUTO_DUNGEON_LOOP and not dungeonRoundRunning then
            dungeonRoundRunning = true

            local ok, err = pcall(runDungeonRound)
            if not ok then
                warn("[Dungeon Loop]", err)
            end

            dungeonRoundRunning = false
        end

        task.wait(1)
    end
end)

-- ================================================
-- MAIN LOOP (FARM, FEED, DROPS, CHESTS, EXPLORE)
-- ================================================

task.spawn(function()
    local lastRoomKey = nil
    local lastEnemiesFolder = nil

    while screenGui.Parent do
        local character = player.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character
            and character:FindFirstChild("HumanoidRootPart")

        local digimons = workspace:FindFirstChild("Digimons")
        local enemiesFolder = digimons and digimons:FindFirstChild("Enemies")
        local roomKey = getCurrentRoomKey()

        if (roomKey and lastRoomKey and roomKey ~= lastRoomKey)
            or (lastEnemiesFolder and enemiesFolder ~= lastEnemiesFolder) then
            table.clear(visited)
            -- Chest retry delays are room-specific; don't carry a failed attempt
            -- from the previous room into the room we just entered.
            table.clear(chestRetryAt)
            sendNotification("Auto Farm", "ตรวจพบห้องใหม่ กำลังเลือกเป้าหมายใหม่")
        end
        if roomKey then lastRoomKey = roomKey end
        lastEnemiesFolder = enemiesFolder

        if character and humanoid and rootPart and humanoid.Health > 0 then
            if AUTO_FEED and not AUTO_FEED_WORKER_RUNNING then
                local capture = findNearestCapture(rootPart)
                if capture then
                    AUTO_FEED_WORKER_RUNNING = true
                    AUTO_FEED_BUSY = true
                    task.spawn(function()
                        local ok, result = pcall(processAutoFeed, capture)
                        if not ok then
                            warn("[Auto Feed]", result)
                        end
                        AUTO_FEED_BUSY = false
                        AUTO_FEED_WORKER_RUNNING = false
                    end)
                end
            end

            if not AUTO_FEED_BUSY then
                local foundChest = findAndTeleportToChest(rootPart)
                local foundDrop = false

                if not foundChest then
                    foundDrop = findAndTeleportToDrop(rootPart)
                end

                if not foundChest and not foundDrop
                    and AUTO_FARM and enemiesFolder then

                    local target, targetDistance = nil, math.huge
                    local myPos = rootPart.Position

                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                        if enemy:IsA("Model") and enemy.Parent == enemiesFolder
                            and not visited[enemy] then

                            local enemyHumanoid =
                                enemy:FindFirstChildOfClass("Humanoid")

                            if not enemyHumanoid or enemyHumanoid.Health > 0 then
                                local ok, enemyPos = pcall(function()
                                    return enemy:GetPivot().Position
                                end)

                                if ok then
                                    local distance = (enemyPos - myPos).Magnitude
                                    if distance < targetDistance then
                                        target = enemy
                                        targetDistance = distance
                                    end
                                end
                            end
                        end
                    end

                    if target and AUTO_FARM then
                        visited[target] = true

                        sendNotification(
                            "เดินไปตีมอนสเตอร์",
                            target.Name
                        )

                        local started = tick()
                        local targetRoomKey = roomKey
                        local pathFailed = false

                        while AUTO_FARM and not AUTO_FEED_BUSY
                            and target.Parent == enemiesFolder
                            and tick() - started < MAX_WALK_TIME do

                            local currentRoomKey = getCurrentRoomKey()
                            if (targetRoomKey and currentRoomKey
                                and currentRoomKey ~= targetRoomKey)
                                or target.Parent ~= enemiesFolder then
                                table.clear(visited)
                                break
                            end

                            local enemyHumanoid =
                                target:FindFirstChildOfClass("Humanoid")

                            if enemyHumanoid and enemyHumanoid.Health <= 0 then
                                break
                            end

                            local ok, targetPos = pcall(function()
                                return target:GetPivot().Position
                            end)
                            if not ok then break end

                            local distance = (targetPos - rootPart.Position).Magnitude

                            if distance <= ARRIVAL_DISTANCE then
                                pcall(function()
                                    VirtualUser:ClickButton1(Vector2.new())
                                end)
                                task.wait(0.2)
                            else
                                local reached = walkToTarget(character, humanoid, targetPos)
                                if not reached then
                                    pathFailed = true
                                    break
                                end
                            end
                        end

                        if pathFailed then
                            visited[target] = true
                            sendNotification("Auto Farm", "ไปไม่ถึงเป้าหมาย ข้ามไปหาม่อนตัวอื่น")
                        end
                    elseif AUTO_FARM then
                        table.clear(visited)
                        task.wait(1)
                    end
                end
            end
        end

        task.wait(0.2)
    end
end)
