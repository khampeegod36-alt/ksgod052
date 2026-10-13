-- ================================================
-- DIGIMON ERA AUTO FARM + AUTO FEED + AUTO EXPLORE + DUNGEON LOOP
-- SINGLE UI + TELEPORT QUEUE (FULL VERSION)
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
-- UI
-- ================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.ResetOnSpawn = false

if gethui then
    local ok, hui = pcall(gethui)
    if ok and hui then
        screenGui.Parent = hui
    else
        screenGui.Parent = CoreGui
    end
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    local ok = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not ok then
        screenGui.Parent = player:WaitForChild("PlayerGui")
    end
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 210, 0, 420)
mainFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
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

local farmBtn = createToggleButton(
    "FarmBtn", UDim2.new(0.05, 0, 0.01, 0), "Auto Farm: OFF"
)
local chestBtn = createToggleButton(
    "ChestBtn", UDim2.new(0.05, 0, 0.13, 0), "Auto Chest: OFF"
)
local dropBtn = createToggleButton(
    "DropBtn", UDim2.new(0.05, 0, 0.25, 0), "Auto Drops: OFF"
)
local healBtn = createToggleButton(
    "HealBtn", UDim2.new(0.05, 0, 0.37, 0), "Auto Heal: OFF"
)
local feedBtn = createToggleButton(
    "FeedBtn", UDim2.new(0.05, 0, 0.49, 0), "Auto Feed: OFF"
)

local exploreBtn = createToggleButton(
    "ExploreBtn",
    UDim2.new(0.05, 0, 0.61, 0),
    "Auto Explore: OFF"
)
local dungeonBtn = createToggleButton(
    "DungeonLoopBtn",
    UDim2.new(0.05, 0, 0.73, 0),
    "Dungeon Loop: OFF"
)

local env = getgenv and getgenv() or _G
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
    if autoAlreadyEnabled then
        return
    end

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
    if game.PlaceId ~= DUNGEON_PLACE_ID then
        return
    end

    if autoEnableRunning or autoAlreadyEnabled then
        return
    end

    autoEnableRunning = true

    task.spawn(function()
        task.wait(UI_LOAD_DELAY)

        if game.PlaceId == DUNGEON_PLACE_ID then
            enableAllAutoButtons()
        end

        autoEnableRunning = false
    end)
end

-- ตรวจสอบ Dungeon หลังระบบ Auto พร้อมทำงาน
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

    local controller = hud:WaitForChild("PC_Controller")
    local partyFrame = controller:WaitForChild("PartyFrame")
    local status = partyFrame:WaitForChild("StatusFrame")

    local aggressive = status:FindFirstChild("Aggressive")

    if aggressive and aggressive.Visible and aggressive.Active then
        local ok, err = pcall(function()
            firesignal(aggressive.Activated)
        end)

        if ok then
            print("[Auto Farm] กด Aggressive แล้ว")
        else
            warn("[Auto Farm] กด Aggressive ไม่สำเร็จ:", err)
        end
    else
        warn("[Auto Farm] ไม่พบปุ่ม Aggressive ที่พร้อมใช้งาน")
    end

    local autoSkill = status:FindFirstChild("AutoSkill")
    local state = autoSkill and autoSkill:FindFirstChild("Status")

    if not autoSkill or not state or not state:IsA("TextLabel") then
        warn("[Auto Farm] ไม่พบสถานะ Auto Skill")
        return
    end

    if state.Text == "OFF" then
        if autoSkill.Visible and autoSkill.Active then
            local ok, err = pcall(function()
                firesignal(autoSkill.Activated)
            end)

            if ok then
                print("[Auto Farm] ส่งคำสั่งเปิด Auto Skill แล้ว")
            else
                warn("[Auto Farm] เปิด Auto Skill ไม่สำเร็จ:", err)
            end
        else
            warn("[Auto Farm] ปุ่ม Auto Skill ยังไม่พร้อมใช้งาน")
        end
    else
        print("[Auto Farm] Auto Skill เปิดอยู่แล้ว")
    end
end
checkDungeonAndEnableAutos()

task.spawn(function()
    while screenGui.Parent do
        task.wait(2)
        checkDungeonAndEnableAutos()
    end
end)
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

local function fireButton(btn)
    if not btn or not btn.Parent or not btn.Visible then
        return false
    end

    local fired = false

    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.Activated)) do
                if conn.Enabled ~= false then
                    local ok = pcall(function()
                        conn:Fire()
                    end)

                    if ok then
                        fired = true
                    end
                end
            end
        end
    end)

    if not fired then
        pcall(function()
            if firesignal then
                firesignal(btn.Activated)
                fired = true
            end
        end)
    end

    return fired
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

-- ตรวจจับ Dungeon และรีเซ็ตเมื่อเข้า Dungeon รอบใหม่
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

-- ปิดแผนที่หลังเลือกห้อง
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

-- ตรวจว่ามีศัตรูที่ยังมีชีวิตและหาเส้นทางไปถึงได้หรือไม่
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

local function findNextRoom(currentLayer, currentRoom, scrolling)
    local function getAvailableRoom(layer, excludeRoom)
        local mapNumber = tonumber(layer.Name:match("^Map(%d+)$"))

        -- ห้ามเลือกห้องนอก Map1 ถึง Map3
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

    -- ลองหาห้องใน Map ปัจจุบันก่อน
    local room = getAvailableRoom(currentLayer, currentRoom)
    if room then
        return room
    end

    -- หากไม่มีห้องต่อ ให้ค้นหาเฉพาะ Map ถัดไปจนถึง Map3
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
    while screenGui.Parent do
        -- รีเซ็ตตัวนับเมื่อเข้า Dungeon จาก Place อื่น
        if game.PlaceId ~= lastExplorePlaceId then
            lastExplorePlaceId = game.PlaceId

            if game.PlaceId == EXPLORE_DUNGEON_PLACE_ID then
                lastInvestigateTime = 0
                exploreRoomSelections = 0

                print("[Auto Explore] เข้า Dungeon รอบใหม่ — รีเซ็ตตัวนับห้อง")
            end
        end

        if AUTO_EXPLORE and not exploringNow then
            exploringNow = true

            local ok, err = pcall(function()
                if game.PlaceId ~= EXPLORE_DUNGEON_PLACE_ID then
                    return
                end

                if exploreRoomSelections >= EXPLORE_MAX_ROOM_SELECTIONS then
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

                if not currentRoom or not percent or percent < 100 then
                    return
                end

                local currentMapNumber =
                    tonumber(currentLayer.Name:match("^Map(%d+)$"))

                if not currentMapNumber or currentMapNumber > EXPLORE_MAX_MAP then
                    return
                end

                -- ไม่เปลี่ยนห้องถ้ายังมีศัตรูที่เดินไปถึงได้
                if hasReachableLivingEnemy(120) then
                    return
                end

                local nextRoom =
                    findNextRoom(currentLayer, currentRoom, scrolling)

                if nextRoom then
                    sendNotification(
                        "Auto Explore",
                        "กำลังเข้าห้อง " .. nextRoom.Name
                    )

                    if fireButton(nextRoom) then
                        exploreRoomSelections += 1
                        lastInvestigateTime = tick()

                        print(
                            "[Auto Explore] เลือกห้องแล้ว",
                            exploreRoomSelections,
                            "/",
                            EXPLORE_MAX_ROOM_SELECTIONS
                        )

                        -- รอ 5 วินาทีหลังเลือกห้อง
                        task.wait(5)
                        closeMapForExplore()

                        lastInvestigateTime = tick()
                    end
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
-- AUTO HEAL
-- ================================================

local HEAL_COOLDOWN = 5
local HEAL_CHECK_INTERVAL = 1
local lastHealTime = 0
local isHealing = false

-- ลำดับความสำคัญของยา
local POTION_PRIORITY = {
    "Single Healing Potion L",
    "Single Healing Potion M",
    "Single Healing Potion S"
}

-- ตรวจสอบ HP จากข้อความรูปแบบ Current / Max
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
                and maximumHP > 100
                and currentHP <= maximumHP then
                return currentHP, maximumHP
            end
        end
    end

    return nil, nil
end

-- ค้นหายาใน Backpack ก่อน แล้วค่อยตรวจ Character
local function findPotion()
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character

    for _, potionName in ipairs(POTION_PRIORITY) do
        if backpack then
            local potion = backpack:FindFirstChild(potionName)
            if potion and potion:IsA("Tool") then
                return potion
            end
        end

        if character then
            local potion = character:FindFirstChild(potionName)
            if potion and potion:IsA("Tool") then
                return potion
            end
        end
    end

    return nil
end

-- ใช้ยาเพียงช่องทางเดียวต่อครั้ง
local function usePotion()
    local potion = findPotion()
    if not potion then
        return false, "ไม่พบยาใน Backpack หรือ Character"
    end

    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if not character or not humanoid or humanoid.Health <= 0 then
        return false, "ตัวละครยังไม่พร้อม"
    end

    local backpack = player:FindFirstChildOfClass("Backpack")

    if potion.Parent == backpack then
        local ok = pcall(function()
            humanoid:EquipTool(potion)
        end)

        if not ok then
            return false, "ใส่ยาไม่สำเร็จ"
        end

        task.wait(0.2)
    end

    if potion.Parent ~= character then
        return false, "ไม่สามารถใส่ยาได้"
    end

    local ok = pcall(function()
        potion:Activate()
    end)

    if not ok then
        return false, "เรียกใช้ยาไม่สำเร็จ"
    end

    return true, potion.Name
end

task.spawn(function()
    while screenGui.Parent do
        if AUTO_HEAL and not isHealing then
            local ok, err = pcall(function()
                local curHP, maxHP = getDigimonHP()

                if not curHP or not maxHP then
                    return
                end

                local missingHP = maxHP - curHP

                -- ใช้ยาเมื่อ HP ขาดตั้งแต่ 500 ขึ้นไป
                if missingHP < HEAL_DROP_AMOUNT then
                    return
                end

                -- ป้องกันการใช้ยาถี่เกินไป
                if tick() - lastHealTime < HEAL_COOLDOWN then
                    return
                end

                isHealing = true
                lastHealTime = tick()

                local used, result = usePotion()

                if used then
                    sendNotification(
                        "Auto Heal",
                        "ใช้ " .. result
                            .. " | HP ขาด " .. math.floor(missingHP)
                    )
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

-- ================================================
-- AUTO CHEST
-- ================================================

local chestRetryAt = {}
local CHEST_RETRY_COOLDOWN = 3
local CHEST_ENEMY_CHECK_DISTANCE = 60

local function findAndTeleportToChest(rootPart)
    if not AUTO_CHEST or not rootPart then
        return false
    end

    local closestChest, closestDist = nil, SEARCH_RADIUS
    local now = tick()

    -- ค้นหาหีบที่ยังไม่ได้ยืนยันว่าเปิดแล้ว
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
            and not openedChests[obj]
            and (not chestRetryAt[obj] or now >= chestRetryAt[obj]) then

            local name = obj.Name:lower()

            if name:find("chest")
                or name:find("rewardbox")
                or name:find("treasure") then

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

    -- ถ้ามีศัตรูใกล้หีบ ให้ Auto Farm จัดการก่อน
    local digimons = workspace:FindFirstChild("Digimons")
    local enemies = digimons and digimons:FindFirstChild("Enemies")

    if enemies then
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:IsA("Model") then
                local humanoid = enemy:FindFirstChildOfClass("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    local enemyOk, enemyPos = pcall(function()
                        return enemy:GetPivot().Position
                    end)

                    if enemyOk
                        and (enemyPos - chestPos).Magnitude
                            <= CHEST_ENEMY_CHECK_DISTANCE then

                        chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
                        return false
                    end
                end
            end
        end
    end

    sendNotification("Auto Chest", "กำลังลองเปิดหีบ...")

    -- ลองเปิดหีบ โดยยังไม่ตั้ง openedChests เป็น true
    for i = 1, 12 do
        if not AUTO_CHEST or not chest.Parent then
            break
        end

        pcall(function()
            rootPart.CFrame = CFrame.new(
                chest:GetPivot().Position + Vector3.new(0, 0.5, 0)
            )
        end)

        for _, obj in ipairs(chest:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                pcall(function()
                    obj.RequiresLineOfSight = false
                    obj.MaxActivationDistance = 500
                    obj.HoldDuration = 0

                    if fireproximityprompt then
                        fireproximityprompt(obj)
                    end
                end)
            end
        end

        task.wait(0.1)
    end

    -- ยืนยันว่าเปิดแล้วเฉพาะเมื่อหีบหายไป
    -- หรือไม่มี ProximityPrompt ที่ยังเปิดใช้งานเหลืออยู่
    if not chest.Parent then
        openedChests[chest] = true
        chestRetryAt[chest] = nil
        sendNotification("Auto Chest", "หีบถูกเก็บแล้ว")
        return true
    end

    local hasEnabledPrompt = false

    for _, obj in ipairs(chest:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            hasEnabledPrompt = true
            break
        end
    end

    if not hasEnabledPrompt then
        openedChests[chest] = true
        chestRetryAt[chest] = nil
        sendNotification("Auto Chest", "ตรวจพบว่าปุ่มเปิดหีบปิดใช้งานแล้ว")
        return true
    end

    -- ยังยืนยันไม่ได้ว่าเปิดสำเร็จ ให้ลองใหม่ภายหลัง
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

    collectedDrops[closestDrop] = true
    sendNotification("Auto Drops", "วาร์ปไปเก็บ " .. closestDrop.Name)

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

    task.wait(0.2)
    return true
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

    -- ถ้าหาเส้นทางไม่ได้ ห้าม MoveTo ตรง ๆ เพราะอาจวิ่งชนกำแพงไม่หยุด
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
local DUNGEON_DURATION = 60

-- ใช้การตั้งค่าที่บันทึกไว้
local DungeonSettings = env.DigimonEraDungeonSettings or {
    Map = "Forest",
    Level = "61-100",
    LockMap = false,
    LockLevel = false
}
env.DigimonEraDungeonSettings = DungeonSettings

-- รายการเลเวลของแต่ละแผนที่
local DungeonLevels = {
    Forest = {
        "1-10", "11-30", "31-60",
        "61-100", "101-150", "151-220"
    },
    Volcano = {
        "1-30", "31-60", "61-110",
        "111-170", "171-240"
    },
    Snowland = {
        "20-40", "41-70", "71-140",
        "141-190", "191-260"
    }
}

local function walkIntoNearestLift()
    local folder = workspace:FindFirstChild("MatchmakingZones")
    if not folder then return false end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then return false end

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

    if not nearest then return false end

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

    -- ตรวจสอบแผนที่ที่ตั้งไว้
    local mapName = DungeonSettings.Map
    if not DungeonLevels[mapName] then
        warn("[Dungeon Loop] ชื่อแผนที่ไม่ถูกต้อง:", tostring(mapName))
        return false
    end

    -- ตรวจสอบเลเวลที่ตั้งไว้
    local selectedLevel = DungeonSettings.Level
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

    -- เลือกแผนที่
    local mapList = chooseMap:FindFirstChild("MapChooseScrolling")
    local mapButton = mapList and mapList:FindFirstChild(mapName)

    if not mapButton or not mapButton:IsA("GuiButton") then
        warn("[Dungeon Loop] ไม่พบปุ่มแผนที่:", mapName)
        return false
    end

    if not fireButton(mapButton) then
        warn("[Dungeon Loop] กดเลือกแผนที่ไม่สำเร็จ:", mapName)
        return false
    end

    task.wait(0.5)

    -- อ่านรายการเลเวลหลังเลือกแผนที่
    chooseMap = main:FindFirstChild("ChooseMap")
    local levelList = chooseMap
        and chooseMap:FindFirstChild("LevelChooseScrolling")

    if not levelList then
        warn("[Dungeon Loop] ไม่พบ LevelChooseScrolling")
        return false
    end

    -- ค้นหาด้วย Name เพราะ Text ของปุ่มว่าง
    local levelButton

    for _, obj in ipairs(levelList:GetDescendants()) do
        if obj:IsA("GuiButton")
            and obj.Visible
            and obj.Name == selectedLevel then
            levelButton = obj
            break
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

    -- กด Start
    local mapInfo = main:FindFirstChild("MapInfo")
    local startButton = mapInfo and mapInfo:FindFirstChild("StartButton")

    if not startButton or not fireButton(startButton) then
        warn("[Dungeon Loop] กด Start ไม่สำเร็จ")
        return false
    end

    -- กด Start ในหน้ารอยืนยัน
    local waiting = main:WaitForChild("TeleportWaiting", 15)
    local secondStart = waiting and waiting:WaitForChild("StartButton", 10)

    if not secondStart then
        warn("[Dungeon Loop] ไม่พบปุ่ม Start ใน TeleportWaiting")
        return false
    end

    task.wait(0.5)
    return fireButton(secondStart)
end

local function runDungeonRound()
    if game.PlaceId == LOBBY_PLACE_ID then
        sendNotification(
            "Dungeon Loop",
            "กำลังหาลิฟต์เข้า " .. tostring(DungeonSettings.Map)
        )

        if not walkIntoNearestLift() then
            warn("[Dungeon Loop] เดินเข้าลิฟต์ไม่สำเร็จ")
            return
        end

        task.wait(1)

        if not selectForestAndStart() then
            warn("[Dungeon Loop] เลือกแผนที่หรือกด Start ไม่สำเร็จ")
        end

        return
    end

    if game.PlaceId == DUNGEON_PLACE_ID then
        sendNotification("Dungeon Loop", "เริ่มฟาร์ม 60 วินาที")

        enableAllAutoButtons()

        local started = tick()

        while AUTO_DUNGEON_LOOP
            and tick() - started < DUNGEON_DURATION do
            task.wait(0.25)
        end

        if not AUTO_DUNGEON_LOOP then return end

        sendNotification("Dungeon Loop", "ครบเวลา กำลังกลับล็อบบี้")

        local pg = player:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("HUD")
        local buttons = hud and hud:FindFirstChild("ButtonsFrame")
        local evacuate = buttons and buttons:FindFirstChild("EvacuateButton")
        local imageButton = evacuate and evacuate:FindFirstChild("ImageButton")

        if imageButton then
            fireButton(imageButton)
        else
            warn("[Dungeon Loop] ไม่พบ EvacuateButton")
        end
    end
end

-- ป้องกันการรันรอบดันเจี้ยนซ้ำซ้อน
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
-- MAIN LOOP (WITH DYNAMIC ENEMIES FOLDER)
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

        -- ค้นหาโฟลเดอร์ศัตรูใหม่ทุกรอบเพื่อป้องกันกรณีฉากเปลี่ยน
        local digimons = workspace:FindFirstChild("Digimons")
        local enemiesFolder = digimons and digimons:FindFirstChild("Enemies")
        local roomKey = getCurrentRoomKey()

        -- ห้องหรือโฟลเดอร์ศัตรูเปลี่ยน: ล้างรายการเป้าหมายเก่า
        if (roomKey and lastRoomKey and roomKey ~= lastRoomKey)
            or (lastEnemiesFolder and enemiesFolder ~= lastEnemiesFolder) then
            table.clear(visited)
            sendNotification("Auto Farm", "ตรวจพบห้องใหม่ กำลังเลือกเป้าหมายใหม่")
        end
        if roomKey then lastRoomKey = roomKey end
        lastEnemiesFolder = enemiesFolder

        if character and humanoid and rootPart and humanoid.Health > 0 then
            -- Auto Feed ทำงานแยก thread เพื่อไม่บล็อกลูปหลักของ Auto Farm
            -- ระหว่างวาร์ป/ให้อาหาร จะพักการเคลื่อนที่ชั่วคราว ป้องกันระบบแย่งตำแหน่งกัน
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

            -- Farm / Chest / Drops กลับมาทำงานได้ทันทีเมื่อ Auto Feed เสร็จ
            if not AUTO_FEED_BUSY then
                local foundChest = findAndTeleportToChest(rootPart)
                local foundDrop = false

                if not foundChest then
                    foundDrop = findAndTeleportToDrop(rootPart)
                end

                if not foundChest and not foundDrop
                    and AUTO_FARM and enemiesFolder then

                    -- เลือกม่อนที่ใกล้ที่สุดก่อน ลดการวิ่งข้ามห้องไปหาเป้าหมายไกล
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

                            -- ยกเลิกทันทีถ้าห้องเปลี่ยนหรือเป้าหมายไม่อยู่ในโฟลเดอร์ห้องนี้แล้ว
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

                        -- จำเป้าหมายที่ไปไม่ถึงไว้ เพื่อให้รอบถัดไปเลือกม่อนตัวอื่น
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
