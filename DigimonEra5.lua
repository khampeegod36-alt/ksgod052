print("[Digimon Era] SCRIPT STARTED - DUAL UI AUTO HEAL FIX")
-- ================================================
-- DIGIMON ERA AUTO FARM + AUTO FEED + AUTO EXPLORE + DUNGEON LOOP
-- (FULL VERSION - HYBRID PC & MOBILE AUTO HEAL)
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
        local UI_NAME = "DigimonEra5_MultiUI"

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

-- ANTI AFK
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- NOTIFICATION
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

local function updateButton(btn, enabled, label)
    btn.Text = label .. (enabled and ": ON" or ": OFF")
    btn.BackgroundColor3 = enabled and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
end

farmBtn.MouseButton1Click:Connect(function() AUTO_FARM = not AUTO_FARM updateButton(farmBtn, AUTO_FARM, "Auto Farm") end)
chestBtn.MouseButton1Click:Connect(function() AUTO_CHEST = not AUTO_CHEST updateButton(chestBtn, AUTO_CHEST, "Auto Chest") end)
dropBtn.MouseButton1Click:Connect(function() AUTO_DROPS = not AUTO_DROPS updateButton(dropBtn, AUTO_DROPS, "Auto Drops") end)
healBtn.MouseButton1Click:Connect(function() AUTO_HEAL = not AUTO_HEAL updateButton(healBtn, AUTO_HEAL, "Auto Heal") end)
feedBtn.MouseButton1Click:Connect(function() AUTO_FEED = not AUTO_FEED updateButton(feedBtn, AUTO_FEED, "Auto Feed") end)
exploreBtn.MouseButton1Click:Connect(function() AUTO_EXPLORE = not AUTO_EXPLORE updateButton(exploreBtn, AUTO_EXPLORE, "Auto Explore") end)

sendNotification("Digimon Era Control", "โหลด UI สำเร็จแล้ว!")

local function fireButton(btn)
    if not btn or not btn.Parent or not btn.Visible then return false end
    local fired = false
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.Activated)) do
                if conn.Enabled ~= false then pcall(function() conn:Fire() end) fired = true end
            end
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                if conn.Enabled ~= false then pcall(function() conn:Fire() end) fired = true end
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
-- AUTO HEAL (DUAL CONTROLLER HYBRID SYSTEM)
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

local function clickSlot4Potion()
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return false, "ไม่พบ PlayerGui" end

    local slot4Btn = nil
    local hud = pGui:FindFirstChild("HUD")

    -- 1. ตรวจสอบว่าเปิด UI แบบ PC_Controller หรือไม่
    local pcController = hud and hud:FindFirstChild("PC_Controller")
    if pcController and pcController.Visible then
        local moveFrame = pcController:FindFirstChild("MoveFrame")
        if moveFrame then
            local move4 = moveFrame:FindFirstChild("Move4")
            if move4 then
                slot4Btn = move4:FindFirstChild("QuickButton") or move4
            end
        end

        -- ส่งคำสั่งกดคีย์บอร์ดเลข 4 สำหรับ PC
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
        end)
    end

    -- 2. ตรวจสอบว่าเปิด UI แบบ Mobile_Controller หรือไม่
    local mobileController = hud and hud:FindFirstChild("Mobile_Controller")
    if not slot4Btn and mobileController and mobileController.Visible then
        local moveFrame = mobileController:FindFirstChild("MoveFrame")
        if moveFrame then
            for _, moveObj in ipairs(moveFrame:GetChildren()) do
                local qBtn = moveObj:FindFirstChild("QuickButton")
                if qBtn then
                    slot4Btn = qBtn:FindFirstChild("QuickButton") or qBtn
                end
            end
        end
    end

    -- 3. หากพบปุ่ม GUI สั่งยิงคลิกที่ตัวปุ่มโดยตรง
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

        return true, "กดใช้งานยาผ่าน Hotbar Slot 4 สำเร็จ"
    end

    -- 4. สำรอง: เรียกใช้ยา Potion จาก Backpack โดยตรงหากไม่พบปุ่ม
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if character and backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local itemName = item.Name:lower()
                if itemName:find("heal") or itemName:find("potion") or itemName:find("drug") or itemName:find("hp") then
                    pcall(function()
                        item.Parent = character
                        task.wait(0.05)
                        item:Activate()
                        task.wait(0.05)
                        item.Parent = backpack
                    end)
                    return true, "ใช้อยาจาก Backpack สำเร็จ"
                end
            end
        end
    end

    return false, "ไม่พบสล็อตปุ่มยาหรือยาในกระเป๋า"
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

                local used, result = clickSlot4Potion()
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

-- ================================================
-- AUTO CHEST
-- ================================================

local chestRetryAt = {}
local CHEST_RETRY_COOLDOWN = 3
local CHEST_ENEMY_CHECK_DISTANCE = 60

local function findAndTeleportToChest(rootPart)
    if not AUTO_CHEST or not rootPart then return false end

    local closestChest, closestDist = nil, SEARCH_RADIUS
    local now = tick()

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
            and not openedChests[obj]
            and (not chestRetryAt[obj] or now >= chestRetryAt[obj]) then

            local name = obj.Name:lower()

            if name:find("chest") or name:find("rewardbox") or name:find("treasure") then
                local ok, pos = pcall(function() return obj:GetPivot().Position end)
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

    if not closestChest or not AUTO_CHEST then return false end

    local chest = closestChest
    local ok, chestPos = pcall(function() return chest:GetPivot().Position end)
    if not ok then
        chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
        return false
    end

    sendNotification("Auto Chest", "กำลังลองเปิดหีบ...")

    for i = 1, 12 do
        if not AUTO_CHEST or not chest.Parent then break end
        pcall(function()
            rootPart.CFrame = CFrame.new(chest:GetPivot().Position + Vector3.new(0, 0.5, 0))
        end)

        for _, obj in ipairs(chest:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                pcall(function()
                    obj.RequiresLineOfSight = false
                    obj.MaxActivationDistance = 500
                    obj.HoldDuration = 0
                    if fireproximityprompt then fireproximityprompt(obj) end
                end)
            end
        end
        task.wait(0.1)
    end

    if not chest.Parent then
        openedChests[chest] = true
        chestRetryAt[chest] = nil
        sendNotification("Auto Chest", "หีบถูกเก็บแล้ว")
        return true
    end

    chestRetryAt[chest] = tick() + CHEST_RETRY_COOLDOWN
    return false
end

-- ================================================
-- MAIN LOOP (FARM, FEED, DROPS, EXPLORE)
-- ================================================

task.spawn(function()
    while screenGui.Parent do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if character and humanoid and rootPart and humanoid.Health > 0 then
            if AUTO_CHEST then
                findAndTeleportToChest(rootPart)
            end
        end
        task.wait(0.2)
    end
end)
