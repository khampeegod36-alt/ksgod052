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

    local
