if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 10418224975 then
    game:GetService("Players").LocalPlayer:Kick("PatipanStudio: this script is for TNT Mining only")
    return
end

local MarioBanner = {
    Print = print,
    Started = os.clock(),
    Last = os.clock(),
    Done = 0,
    Total = 4,
}

do
    local ok, renv = pcall(getrenv)
    if ok and type(renv) == "table" and type(renv.print) == "function" then
        MarioBanner.Print = renv.print
    end
end

function MarioBanner.Show()
    MarioBanner.Print("[PS] PatipanStudio | UI customized by PatipanStudio")
end

function MarioBanner.Step(label)
    local now = os.clock()
    MarioBanner.Done = math.min(MarioBanner.Done + 1, MarioBanner.Total)
    local filled = math.floor(MarioBanner.Done / MarioBanner.Total * 20 + 0.5)
    MarioBanner.Print(string.format("[PatipanStudio] [%s] %3d%%  %-24s +%dms",
        string.rep("#", filled) .. string.rep(".", 20 - filled),
        math.floor(MarioBanner.Done / MarioBanner.Total * 100), label, math.floor((now - MarioBanner.Last) * 1000)))
    MarioBanner.Last = now
end

function MarioBanner.Ready()
    local rule = string.rep("=", 54)
    MarioBanner.Print(table.concat({
        rule,
        string.format("   >> READY in %dms", math.floor((os.clock() - MarioBanner.Started) * 1000)),
        rule,
    }, "\n"))
end

pcall(MarioBanner.Show)
pcall(MarioBanner.Step, "Core")

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local vector3New, cframeNew = Vector3.new, CFrame.new
local mathMin, mathMax, mathCeil = math.min, math.max, math.ceil

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nBug fixes & better UI" },
    },
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    SaveFolder = "TNT Mining",
    LoadTimeout = 30,
    RequireTimeout = 3,
    GameCallTimeout = 8,
    MaxFailures = 5,
    FailWindow = 10,
    AlertTries = 20,
    AlertDelay = 0.5,
    TickDelay = 0.1,
    ClicksPerBatch = 25,
    ClickInterval = 1,
    ExplodeTimeout = 3,
    DropSettle = 0.35,
    IdConfirmTimeout = 3,
    SolverYieldEvery = 1500,
    HotbarSlots = 4,
    PurchaseInterval = 3,
    ClaimInterval = 60,
    HatchInterval = 1,
    MineStandOffset = 3,
    RejoinDelay = 5,
    RateWindow = 60,
    Needs = {
        AutoMine = { "Blocks", "Areas", "AreaRenderer", "Mine.Collectible", ":PlaceBomb", ":IgniteBomb", ":LeaveMine", ":CollectBlocks", ":GetBombExplosionRadius" },
        AutoSell = { ":SellBlocks" },
        AutoCollect = { "Mine.Collectible", ":CollectBlocks" },
        SecretAlert = { "Blocks" },
        AutoClick = { ":ApplyDataUpdate" },
        AutoRebirth = { "Rebirth", ":PerformRebirth" },
        AutoBomb = { "Bombs", ":BuyBomb", ":EquipBomb", ":OwnsBomb" },
        AutoUpgrade = { "Upgrades", ":BuyUpgrade" },
        AutoArea = { "Areas", ":PurchaseArea" },
        AutoLuck = { "Upgrades.MineLuck", ":BuyUpgrade" },
        AutoHatch = { "Areas", ":HatchPetEgg" },
        AutoEquipPets = { ":EquipBestPets" },
        AutoSellPets = { "Pets", ":SellPets", ":GetPetDamagePerClickMultiplier" },
        AutoClaim = { "Areas", ":IsAreaIndexComplete", ":ClaimIndexReward" },
    },
}

PatipanStudio.State = {
    Alive = true,
    Busy = false,
    NeedRefill = true,
    MineOrigin = nil,
    Connections = {},
    Requests = {},
    Messages = {},
    Failures = {},
    Halted = {},
    Status = "Idle",
    Summary = "Loading...",
    Bombs = 0,
    Earned = 0,
    LastPurchase = 0,
    LastClaim = 0,
    LastHatch = 0,
    EarnLog = {},
    SecretSeen = {},
    Opt = {
        AutoMine = false,
        MineArea = "Best",
        TargetShards = false,
        AutoSell = false,
        AutoCollect = false,
        AutoClick = false,
        AutoRebirth = false,
        AutoBomb = false,
        AutoUpgrade = false,
        Upgrades = {},
        AutoArea = false,
        AutoLuck = false,
        AutoHatch = false,
        AutoEquipPets = false,
        AutoSellPets = false,
        KeepPets = 10,
        KeepPetRarities = {},
        SecretAlert = false,
        AutoRejoin = false,
        LowGraphics = false,
        AutoClaim = false,
        SpeedOn = false,
        WalkSpeed = 60,
        InfJump = false,
    },
}

local Config, State = PatipanStudio.Config, PatipanStudio.State

PatipanStudio.GameLib = { Deferred = {} }

---Runs `fn` on a fresh thread switched to identity 2; game code that requires lazily fails from executor identities.
---@return boolean, any  pcall-style, false when the executor can't really switch or it timed out
function PatipanStudio.GameLib.RunAsGame(timeout, fn, ...)
    local args = table.pack(...)
    local box
    task.spawn(function()
        pcall(setthreadidentity, 2)
        local read, identity = pcall(getthreadidentity)
        if not (read and identity == 2) then
            box = { false, "identity switch unavailable", n = 2 }
            return
        end
        box = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
    end)

    local deadline = os.clock() + timeout
    while not box and os.clock() < deadline do
        task.wait()
    end
    if not box then return false, "game call timed out" end
    return table.unpack(box, 1, box.n)
end

---@param path string  dotted path from ReplicatedStorage
---@return table?      nil when it is missing or this executor can't require it
function PatipanStudio.GameLib.Require(path)
    local module = ReplicatedStorage
    for name in path:gmatch("[^.]+") do
        module = module and module:FindFirstChild(name)
    end
    if not module then
        local root = ReplicatedStorage:FindFirstChild(path:match("^[^.]+"))
        local found = root and root:FindFirstChild(path:match("[^.]+$"), true)
        module = found and found:IsA("ModuleScript") and found or nil
    end
    if not module then
        warn("[TNTMining] missing game module", path)
        return nil
    end

    local ok, loaded = pcall(require, module)
    if ok then return loaded end
    local okAgain, again = PatipanStudio.GameLib.RunAsGame(Config.RequireTimeout, require, module)
    if okAgain then return again end
    warn("[TNTMining] require", path, loaded)
    return nil
end

---Calls a game function inline; one that hits "non-RobloxScript" moves to an identity-2 thread for good.
function PatipanStudio.GameLib.Call(fn, ...)
    local deferred = PatipanStudio.GameLib.Deferred
    if not deferred[fn] then
        local result = table.pack(pcall(fn, ...))
        if result[1] then return table.unpack(result, 2, result.n) end
        if not tostring(result[2]):find("non-RobloxScript", 1, true) then error(result[2], 0) end
        deferred[fn] = true
    end

    local result = table.pack(PatipanStudio.GameLib.RunAsGame(Config.GameCallTimeout, fn, ...))
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

do
    ReplicatedStorage:WaitForChild("Logic", Config.LoadTimeout)
    ReplicatedStorage:WaitForChild("ClientLogic", Config.LoadTimeout)

    local GameLib = PatipanStudio.GameLib
    GameLib.Session = GameLib.Require("Logic.Classes.PlayerSession")
    GameLib.Network = GameLib.Require("Logic.Network")
    GameLib.MineState = GameLib.Require("ClientLogic.Services.MineStateService")
    GameLib.AreaRenderer = GameLib.Require("Logic.Services.AreaRenderer")
    GameLib.Blocks = GameLib.Require("Logic.Configs.BlocksConfig")
    GameLib.Bombs = GameLib.Require("Logic.Configs.BombsConfig")
    GameLib.Areas = GameLib.Require("Logic.Configs.AreasConfig")
    GameLib.Upgrades = GameLib.Require("Logic.Configs.UpgradesConfig")
    GameLib.Mine = GameLib.Require("Logic.Configs.MineConfig")
    GameLib.Rebirth = GameLib.Require("Logic.Configs.RebirthConfig")
    GameLib.Pets = GameLib.Require("Logic.Configs.PetsConfig")
    GameLib.Ready = GameLib.Session ~= nil and GameLib.Network ~= nil and GameLib.MineState ~= nil
end

local GameLib = PatipanStudio.GameLib

---@param need string  GameLib field path, or ":Method" on the player session
---@return boolean     false only when it is known to be gone
function PatipanStudio.GameLib.Has(need, session)
    local method = need:match("^:(.+)")
    if method then return session == nil or type(session[method]) == "function" end
    local node = GameLib
    for part in need:gmatch("[^.]+") do
        node = type(node) == "table" and node[part] or nil
    end
    return node ~= nil
end

---@return table  option idx -> missing needs
function PatipanStudio.GameLib.Missing()
    local ok, session = pcall(function() return GameLib.Session.GetClient() end)
    if not ok then session = nil end
    local missing = {}
    for idx, needs in pairs(Config.Needs) do
        for _, need in ipairs(needs) do
            if not PatipanStudio.GameLib.Has(need, session) then
                missing[idx] = missing[idx] or {}
                table.insert(missing[idx], need)
            end
        end
    end
    return missing
end

PatipanStudio.AreaOrder = GameLib.Areas and GameLib.Areas.GetOrderedNames() or {}

PatipanStudio.BombOrder = {}
do
    for name, bomb in pairs(GameLib.Bombs or {}) do
        if type(bomb) == "table" and not bomb.IsPremium and bomb.Price then
            table.insert(PatipanStudio.BombOrder, name)
        end
    end
    table.sort(PatipanStudio.BombOrder, function(a, b) return GameLib.Bombs[a].Price < GameLib.Bombs[b].Price end)
end

PatipanStudio.UpgradeNames = {}
do
    for name, upgrade in pairs(GameLib.Upgrades or {}) do
        if type(upgrade) == "table" and not upgrade.AreaSpecific then
            table.insert(PatipanStudio.UpgradeNames, name)
        end
    end
    table.sort(PatipanStudio.UpgradeNames, function(a, b)
        return (GameLib.Upgrades[a].LayoutOrder or 0) < (GameLib.Upgrades[b].LayoutOrder or 0)
    end)
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function PatipanStudio:Session()
    return GameLib.Session.GetClient()
end

function PatipanStudio:Invoke(action, args)
    return GameLib.Network.ClientAction.Invoke({ action, args })
end

function PatipanStudio.Format(number)
    number = tonumber(number) or 0
    local tier = 1
    while number >= 1000 and tier < #SUFFIXES do
        number, tier = number / 1000, tier + 1
    end
    return tier == 1 and ("%d"):format(number) or ("%.2f%s"):format(number, SUFFIXES[tier])
end

function PatipanStudio:Notify(text)
    State.Messages[#State.Messages + 1] = text
end

function PatipanStudio:Connect(signal, handler)
    local conn = signal:Connect(handler)
    table.insert(State.Connections, conn)
    return conn
end

function PatipanStudio.Try(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[TNTMining]", err) end
    return ok, err
end

PatipanStudio.Util = {}

---@return string?, string?  body, or nil + why every transport failed
function PatipanStudio.Util.HttpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then return body end

    local send = request or http_request or (syn and syn.request) or (http and http.request)
    if not send then return nil, tostring(body) end
    local sent, response = pcall(send, { Url = url, Method = "GET" })
    if not sent then return nil, tostring(response) end
    if type(response) ~= "table" or response.StatusCode ~= 200 or type(response.Body) ~= "string" then
        return nil, "HTTP " .. tostring(type(response) == "table" and response.StatusCode)
    end
    return response.Body
end

---Shows a Roblox notification even when the menu never loaded; SetCore fails for a while after joining.
function PatipanStudio.Util.Alert(text, detail)
    warn("[TNTMining] menu:", text, detail or "")
    task.spawn(function()
        for _ = 1, Config.AlertTries do
            if pcall(StarterGui.SetCore, StarterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 }) then return end
            task.wait(Config.AlertDelay)
        end
    end)
end

---@return table?  the UI library, nil after telling the player why
function PatipanStudio.Util.LoadLibrary()
    local body, err = PatipanStudio.Util.HttpGet(Config.UiSource)
    if not body or not body:sub(-64):find("return Library%s*$") then
        PatipanStudio.Util.Alert("Could not download the menu. Check your connection and run it again.", err or "truncated body")
        return nil
    end

    local chunk, compileErr = loadstring(body)
    if not chunk then
        PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(compileErr))
        return nil
    end
    local ok, library = pcall(chunk)
    if ok and type(library) == "table" then return library end
    PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(library))
    return nil
end

function PatipanStudio:Root()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function PatipanStudio:Humanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function PatipanStudio:AreaModel(areaName)
    local map = Workspace:FindFirstChild("Map")
    local areas = map and map:FindFirstChild("Areas") or Workspace:FindFirstChild("Areas", true)
    if not areas then return nil end
    for _, area in ipairs(areas:GetChildren()) do
        if area:GetAttribute("AreaName") == areaName then return area end
    end
    return nil
end

PatipanStudio.Mine = {}

---@return string  best owned area for current damage
function PatipanStudio.Mine.PickArea(session)
    local picked = State.Opt.MineArea
    if picked ~= "Best" and session.OwnedAreas[picked] then return picked end

    local best = PatipanStudio.AreaOrder[1]
    for _, name in ipairs(PatipanStudio.AreaOrder) do
        if session.OwnedAreas[name] and session.Damage >= GameLib.Areas[name].ExplosionDamage.Start then
            best = name
        end
    end
    return best
end

---@return boolean  mine loaded
function PatipanStudio.Mine.Enter(areaName)
    local area = PatipanStudio:AreaModel(areaName)
    if not area then
        GameLib.AreaRenderer.RenderArea(areaName)
        area = PatipanStudio:AreaModel(areaName)
    end

    local mineArea = area and area:FindFirstChild("MineArea", true)
    local hrp = PatipanStudio:Root()
    if not (mineArea and hrp) then return false end

    if not State.MineOrigin and not PatipanStudio:Session():IsInMineArea() then State.MineOrigin = hrp.CFrame end
    hrp.CFrame = cframeNew(mineArea.Position + vector3New(0, mineArea.Size.Y / 2 + Config.MineStandOffset, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero

    local mineState = GameLib.MineState
    local giveUp = os.clock() + 8
    repeat
        if mineState.IsLoaded() and mineState.GetAreaName() == areaName then return true end
        task.wait(0.2)
    until os.clock() > giveUp
    return false
end

function PatipanStudio.Mine.BlockValue(block, shardValue)
    if block.BlockType == "EggShard" then return shardValue end
    local info = GameLib.Blocks[block.BlockType]
    return info and info.SellValue or 0
end

---@param count number  max spots
---@return Vector3[]    best first, no overlap
function PatipanStudio.Mine.FindBatch(session, count)
    local mineState = GameLib.MineState
    local damage = session.Damage
    local radius = session:GetBombExplosionRadius(session.EquippedBomb, session.EnchantedBombs > 0)
    local reach, radiusSq = mathCeil(radius), radius * radius

    local shardValue = 0
    if State.Opt.TargetShards then
        for _, info in pairs(GameLib.Blocks) do
            shardValue = mathMax(shardValue, info.SellValue or 0)
        end
    end

    local offsets = {}
    for dx = -reach, reach do
        for dy = -reach, reach do
            for dz = -reach, reach do
                if dx * dx + dy * dy + dz * dz <= radiusSq then
                    offsets[#offsets + 1] = { dx, dy, dz }
                end
            end
        end
    end

    local scores, seen = {}, 0
    for _, block in pairs(mineState.GetBlocks()) do
        if not block.Alive then continue end

        local worth = PatipanStudio.Mine.BlockValue(block, shardValue) * mathMin(1, damage / mathMax(block.Health, 1))
        if worth > 0 then
            local gx, gy, gz = block.GridX, block.GridY, block.GridZ
            for i = 1, #offsets do
                local o = offsets[i]
                local center = mineState.GetBlockAt(gx + o[1], gy + o[2], gz + o[3])
                if center then scores[center] = (scores[center] or 0) + worth end
            end
        end

        seen += 1
        if seen % Config.SolverYieldEvery == 0 then task.wait() end
    end

    local ranked = {}
    for block, score in pairs(scores) do
        ranked[#ranked + 1] = { block, score }
    end
    table.sort(ranked, function(a, b) return a[2] > b[2] end)

    local spots, spacingSq = {}, (2 * radius) ^ 2
    for _, entry in ipairs(ranked) do
        if #spots >= count then break end

        local block, tooClose = entry[1], false
        for _, other in ipairs(spots) do
            local dx, dy, dz = block.GridX - other.GridX, block.GridY - other.GridY, block.GridZ - other.GridZ
            if dx * dx + dy * dy + dz * dz < spacingSq then
                tooClose = true
                break
            end
        end
        if not tooClose then spots[#spots + 1] = block end
    end

    for i, block in ipairs(spots) do
        spots[i] = block.Position
    end
    return spots
end

---@return string?  nil if rejected
function PatipanStudio.Mine.WaitServerId(bomb)
    local giveUp = os.clock() + Config.IdConfirmTimeout
    while os.clock() < giveUp and not bomb.IsDestroyed do
        if not tostring(bomb.Id):match("^P") then return bomb.Id end
        task.wait()
    end
    return nil
end

---@return number  drops collected
function PatipanStudio.Mine.Collect(session)
    local folder = Workspace:FindFirstChild("ClientCollectibleBlocks")
    if not folder then return 0 end

    local ids = {}
    for _, drop in ipairs(folder:GetChildren()) do
        ids[#ids + 1] = drop.Name
    end

    local batchSize = GameLib.Mine.Collectible.PickupBatchSize or 20
    local got = 0
    for first = 1, #ids, batchSize do
        local reply = session:CollectBlocks(table.move(ids, first, mathMin(first + batchSize - 1, #ids), 1, {}), false, Config.HotbarSlots)
        got += reply and reply.Collected or 0
    end
    return got
end

function PatipanStudio.Mine.Sell(session)
    local before = session.Money
    session:SellBlocks(nil)

    local gained = mathMax(session.Money - before, 0)
    State.Earned += gained
    State.EarnLog[#State.EarnLog + 1] = { os.clock(), gained }
end

---@return number  money per minute
function PatipanStudio.Mine.EarnRate()
    local log, cutoff = State.EarnLog, os.clock() - Config.RateWindow
    while log[1] and log[1][1] < cutoff do
        table.remove(log, 1)
    end

    local total = 0
    for _, entry in ipairs(log) do total += entry[2] end
    return total * 60 / Config.RateWindow
end

function PatipanStudio.Mine.ScanSecrets()
    for _, block in pairs(GameLib.MineState.GetBlocks()) do
        local info = GameLib.Blocks[block.BlockType]
        local id = block.CollectibleId
        if block.Alive and info and info.Rarity == "Secret" and not State.SecretSeen[id] then
            State.SecretSeen[id] = true
            PatipanStudio:Notify(("Secret block spawned: %s (%s)"):format(block.BlockType, PatipanStudio.Format(info.SellValue)))
        end
    end
end

---Brings the character back to where Auto Mine entered the mine from; keeps the origin while the character is respawning.
function PatipanStudio.Mine.ReturnHome()
    local origin = State.MineOrigin
    if not origin then return end

    local hrp = PatipanStudio:Root()
    if not hrp then return end

    local session = PatipanStudio:Session()
    if session:IsInMineArea() then
        session:LeaveMine()
        hrp.CFrame = origin
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
    State.MineOrigin = nil
end

function PatipanStudio.Mine.Cycle()
    local session = PatipanStudio:Session()
    local areaName = PatipanStudio.Mine.PickArea(session)

    if session:GetMineAreaName() ~= areaName or GameLib.MineState.GetAreaName() ~= areaName then
        State.Status = "Entering " .. areaName
        if not PatipanStudio.Mine.Enter(areaName) then
            State.Status = "Could not enter " .. areaName
            return
        end
    end

    if State.NeedRefill or session.HeldBombs < session.MaxActiveBombs then
        State.NeedRefill = false
        PatipanStudio.Mine.Collect(session)
        session:LeaveMine()
    end

    for id, bomb in pairs(session.ActiveBombs) do
        if not bomb.IsFused and not tostring(id):match("^P") then session:IgniteBomb(id) end
    end

    State.Status = "Bombing " .. areaName
    local placed = PatipanStudio.Mine.PlaceBatch(session)
    if #placed == 0 then
        State.Status = "Resetting mine run"
        session:LeaveMine()
        task.wait(1)
        return
    end

    for _, bomb in ipairs(placed) do
        local serverId = PatipanStudio.Mine.WaitServerId(bomb)
        if serverId then
            session:IgniteBomb(serverId)
            State.Bombs += 1
        else
            State.NeedRefill = true
        end
    end

    PatipanStudio.Mine.WaitExploded(placed)
    PatipanStudio.Mine.Collect(session)
    if State.Opt.AutoSell then PatipanStudio.Mine.Sell(session) end
end

---@return table[]  placed bombs
function PatipanStudio.Mine.PlaceBatch(session)
    local placed = {}
    for _, pos in ipairs(PatipanStudio.Mine.FindBatch(session, mathMin(session.HeldBombs, session.MaxActiveBombs))) do
        local reply = session:PlaceBomb(cframeNew(pos))
        local bomb = reply and reply.Success and session.ActiveBombs[reply.Id]
        if not bomb then break end
        placed[#placed + 1] = bomb
    end
    return placed
end

function PatipanStudio.Mine.WaitExploded(bombs)
    local giveUp = os.clock() + Config.ExplodeTimeout
    local function anyLeft()
        for _, bomb in ipairs(bombs) do
            if not bomb.IsDestroyed then return true end
        end
        return false
    end

    while anyLeft() and os.clock() < giveUp do
        task.wait()
    end
    task.wait(Config.DropSettle)
end

PatipanStudio.Progress = {}

function PatipanStudio.Progress.Click()
    local reply = PatipanStudio:Invoke("ApplyClicks", { Config.ClicksPerBatch })
    if not (reply and reply.Success) then return end
    PatipanStudio:Session():ApplyDataUpdate({ Damage = reply.Damage, Level = reply.Level })
end

function PatipanStudio.Progress.StartClicking()
    task.spawn(function()
        while State.Alive and State.Opt.AutoClick do
            PatipanStudio.Scheduler.Run("AutoClick", PatipanStudio.Progress.Click)
            task.wait(Config.ClickInterval)
        end
    end)
end

---@return boolean  rebirth sent
function PatipanStudio.Progress.Rebirth()
    local session = PatipanStudio:Session()
    if session.Level < GameLib.Rebirth.GetRebirthLevelRequirement(session.Rebirths) then return false end
    session:PerformRebirth()
    return true
end

function PatipanStudio.Progress.BuyBestBomb()
    local session = PatipanStudio:Session()
    local target
    for _, name in ipairs(PatipanStudio.BombOrder) do
        if session:OwnsBomb(name) or session.Money >= GameLib.Bombs[name].Price then
            target = name
        end
    end
    if not target then return end

    if not session:OwnsBomb(target) then
        session:BuyBomb(target)
    elseif session.EquippedBomb ~= target and not session:IsPremiumBombEquipped() then
        session:EquipBomb(target)
    end
end

function PatipanStudio.Progress.BuyUpgrades()
    local session = PatipanStudio:Session()
    for _, name in ipairs(PatipanStudio.UpgradeNames) do
        if State.Opt.Upgrades[name] then session:BuyUpgrade(name) end
    end
end

function PatipanStudio.Progress.BuyLuck()
    local session = PatipanStudio:Session()
    session:BuyUpgrade("MineLuck", PatipanStudio.Mine.PickArea(session))
end

function PatipanStudio.Progress.BuyNextArea()
    local session = PatipanStudio:Session()
    for _, name in ipairs(PatipanStudio.AreaOrder) do
        if not session.OwnedAreas[name] then
            if session.Money >= GameLib.Areas[name].Price then session:PurchaseArea(name) end
            return
        end
    end
end

PatipanStudio.Pets = {}

function PatipanStudio.Pets.Hatch()
    local session = PatipanStudio:Session()
    local egg
    for _, name in ipairs(PatipanStudio.AreaOrder) do
        local price = GameLib.Areas[name].PetEggPrice
        if price and session.OwnedAreas[name] and session.EggShards >= price then egg = name end
    end
    if egg then session:HatchPetEgg(egg) end
end

function PatipanStudio.Pets.EquipBest()
    local session = PatipanStudio:Session()
    GameLib.Call(session.EquipBestPets, session)
end

---@return number  pets sold
function PatipanStudio.Pets.SellExtras()
    local session = PatipanStudio:Session()
    local keepRarity = State.Opt.KeepPetRarities

    local equipped = {}
    for _, id in ipairs(session.EquippedPets or {}) do equipped[id] = true end

    local pool = {}
    for id, petName in pairs(session.OwnedPets) do
        local info = GameLib.Pets[petName]
        if not equipped[id] and not (info and keepRarity[info.Rarity]) then
            pool[#pool + 1] = { id, session:GetPetDamagePerClickMultiplier(id) }
        end
    end
    table.sort(pool, function(a, b) return a[2] > b[2] end)

    local sell = {}
    for i = State.Opt.KeepPets + 1, #pool do
        sell[#sell + 1] = pool[i][1]
    end
    if #sell > 0 then session:SellPets(sell) end
    return #sell
end

PatipanStudio.Claim = {}

function PatipanStudio.Claim.All()
    local session = PatipanStudio:Session()
    pcall(session.ClaimDailyReward, session)
    pcall(session.ClaimGroupReward, session)

    for _, name in ipairs(PatipanStudio.AreaOrder) do
        if not session.ClaimedIndexRewards[name] and session:IsAreaIndexComplete(name) then
            session:ClaimIndexReward(name)
        end
    end
end

PatipanStudio.Client = {}

function PatipanStudio.Client.SetLowGraphics(enabled)
    RunService:Set3dRenderingEnabled(not enabled)
end

function PatipanStudio.Client.Bind()
    PatipanStudio:Connect(GuiService.ErrorMessageChanged, function(msg)
        if not State.Opt.AutoRejoin or msg == "" then return end
        task.delay(Config.RejoinDelay, TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
    end)
end

PatipanStudio.Movement = {}

function PatipanStudio.Movement.Apply()
    local hum = PatipanStudio:Humanoid()
    if not hum then return end
    hum.WalkSpeed = State.Opt.SpeedOn and State.Opt.WalkSpeed or PatipanStudio:Session():GetUpgradeValue("WalkSpeed")
end

function PatipanStudio.Movement.Bind()
    PatipanStudio:Connect(UserInputService.JumpRequest, function()
        local hum = PatipanStudio:Humanoid()
        if State.Opt.InfJump and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)

    PatipanStudio:Connect(LocalPlayer.CharacterAdded, function()
        task.wait(1)
        if State.Opt.SpeedOn then State.Requests.Speed = true end
    end)

    PatipanStudio:Connect(LocalPlayer.Idled, function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end

PatipanStudio.Scheduler = {}

PatipanStudio.Scheduler.RequestHandlers = {
    Speed = PatipanStudio.Movement.Apply,
    BombNow = PatipanStudio.Progress.BuyBestBomb,
    UpgradeNow = PatipanStudio.Progress.BuyUpgrades,
    AreaNow = PatipanStudio.Progress.BuyNextArea,
    LuckNow = PatipanStudio.Progress.BuyLuck,
    HatchNow = PatipanStudio.Pets.Hatch,
    ClaimNow = PatipanStudio.Claim.All,
    EquipPetsNow = PatipanStudio.Pets.EquipBest,

    SellNow = function()
        local session = PatipanStudio:Session()
        PatipanStudio.Mine.Collect(session)
        PatipanStudio.Mine.Sell(session)
        PatipanStudio:Notify("Sold all blocks")
    end,
    RebirthNow = function()
        PatipanStudio:Notify(PatipanStudio.Progress.Rebirth() and "Rebirthed" or "Level too low to rebirth")
    end,
    SellPetsNow = function()
        PatipanStudio:Notify(("Sold %d pets"):format(PatipanStudio.Pets.SellExtras()))
    end,
    CollectNow = function()
        PatipanStudio:Notify(("Collected %d drops"):format(PatipanStudio.Mine.Collect(PatipanStudio:Session())))
    end,
}

---Runs one round of a job; a toggle that keeps failing for Config.FailWindow seconds is switched off and queued for the UI to report.
---@param key string  State.Opt flag of the feature, or a plain label for jobs without one
function PatipanStudio.Scheduler.Run(key, fn)
    local ok, err = pcall(fn)
    local failures = State.Failures
    if ok then
        failures[key] = nil
        return
    end

    local streak = failures[key]
    if not streak then
        streak = { count = 0, since = os.clock() }
        failures[key] = streak
        warn("[TNTMining]", key, err)
    end
    streak.count += 1
    if streak.count < Config.MaxFailures or os.clock() - streak.since < Config.FailWindow then return end
    if State.Opt[key] ~= true then return end

    failures[key] = nil
    State.Opt[key] = false
    local reason = tostring(err):match("[^\n]*")
    warn("[TNTMining]", key, "stopped:", reason)
    table.insert(State.Halted, { key, reason })
end

---@param key string  State field holding last run time
---@return boolean    true once per interval
function PatipanStudio.Scheduler.Due(key, interval)
    local now = os.clock()
    if now - State[key] < interval then return false end
    State[key] = now
    return true
end

function PatipanStudio.Scheduler.Request(name, handler)
    local ok, err = pcall(handler)
    if ok then return end
    warn("[TNTMining]", name, err)
    PatipanStudio:Notify(("%s failed: %s"):format(name, tostring(err):match("[^\n]*")))
end

function PatipanStudio.Scheduler.Summarize()
    local session = PatipanStudio:Session()
    local fmt = PatipanStudio.Format
    State.Summary = ("Level %d · Rebirth %d · Damage %s\nMoney %s · Shards %d\nMoney/min %s"):format(
        session.Level, session.Rebirths, fmt(session.Damage),
        fmt(session.Money), session.EggShards,
        fmt(PatipanStudio.Mine.EarnRate()))
end

PatipanStudio.Scheduler.PurchaseJobs = {
    { "AutoBomb", PatipanStudio.Progress.BuyBestBomb },
    { "AutoUpgrade", PatipanStudio.Progress.BuyUpgrades },
    { "AutoArea", PatipanStudio.Progress.BuyNextArea },
    { "AutoLuck", PatipanStudio.Progress.BuyLuck },
    { "AutoEquipPets", PatipanStudio.Pets.EquipBest },
    { "AutoSellPets", PatipanStudio.Pets.SellExtras },
    { "SecretAlert", function()
        if GameLib.MineState.IsLoaded() then PatipanStudio.Mine.ScanSecrets() end
    end },
}

function PatipanStudio.Scheduler.Purchases()
    for _, job in ipairs(PatipanStudio.Scheduler.PurchaseJobs) do
        if State.Opt[job[1]] then PatipanStudio.Scheduler.Run(job[1], job[2]) end
    end
end

function PatipanStudio.Scheduler.CollectDrops()
    PatipanStudio.Mine.Collect(PatipanStudio:Session())
end

function PatipanStudio.Scheduler.Step()
    local opt = State.Opt
    PatipanStudio.Scheduler.Run("Summary", PatipanStudio.Scheduler.Summarize)

    for name, handler in pairs(PatipanStudio.Scheduler.RequestHandlers) do
        if State.Requests[name] then
            State.Requests[name] = nil
            PatipanStudio.Scheduler.Request(name, handler)
        end
    end

    if opt.AutoRebirth then PatipanStudio.Scheduler.Run("AutoRebirth", PatipanStudio.Progress.Rebirth) end
    if PatipanStudio.Scheduler.Due("LastPurchase", Config.PurchaseInterval) then PatipanStudio.Scheduler.Purchases() end
    if opt.AutoHatch and PatipanStudio.Scheduler.Due("LastHatch", Config.HatchInterval) then PatipanStudio.Scheduler.Run("AutoHatch", PatipanStudio.Pets.Hatch) end
    if opt.AutoClaim and PatipanStudio.Scheduler.Due("LastClaim", Config.ClaimInterval) then PatipanStudio.Scheduler.Run("AutoClaim", PatipanStudio.Claim.All) end

    if opt.AutoMine then
        PatipanStudio.Scheduler.Run("AutoMine", PatipanStudio.Mine.Cycle)
        return
    end

    if State.MineOrigin then PatipanStudio.Scheduler.Run("MineReturn", PatipanStudio.Mine.ReturnHome) end

    State.Status = "Idle"
    if opt.AutoCollect then PatipanStudio.Scheduler.Run("AutoCollect", PatipanStudio.Scheduler.CollectDrops) end
end

function PatipanStudio.Scheduler.Boot()
    PatipanStudio.Movement.Bind()
    PatipanStudio.Client.Bind()

    task.spawn(function()
        while State.Alive do
            if not State.Busy then
                State.Busy = true
                PatipanStudio.Scheduler.Step()
                State.Busy = false
            end
            task.wait(Config.TickDelay)
        end

        if State.MineOrigin then PatipanStudio.Scheduler.Run("MineReturn", PatipanStudio.Mine.ReturnHome) end
    end)
end

function PatipanStudio.Scheduler.Stop()
    State.Alive = false
    State.Opt.AutoClick = false

    for _, conn in ipairs(State.Connections) do conn:Disconnect() end
    table.clear(State.Connections)

    if State.Opt.LowGraphics then PatipanStudio.Client.SetLowGraphics(false) end

    local hum = PatipanStudio:Humanoid()
    if hum and State.Opt.SpeedOn and GameLib.Upgrades and GameLib.Upgrades.WalkSpeed then hum.WalkSpeed = GameLib.Upgrades.WalkSpeed.BaseValue end
end

local function BuildInterface()
    local Library = PatipanStudio.Util.LoadLibrary()
    if not Library then return end
    pcall(MarioBanner.Step, "UI library")
    local Options = Library.Options
    local T = function(en, th) return Library:T(en, th) end
    local opt = State.Opt

    local kaitunKeys = { "AutoMine", "AutoSell", "AutoClick", "AutoRebirth", "AutoBomb", "AutoUpgrade", "AutoArea", "AutoLuck", "AutoClaim", "AutoHatch", "AutoEquipPets", "AutoSellPets" }
    local featureNames = {}

    local function Notify(text, kind)
        Library:Notify("TNT Mining", text, 4, kind or "Info")
    end

    local function ReportHalts()
        for _, halt in ipairs(State.Halted) do
            local key, reason = halt[1], halt[2]
            local toggle = Options[key]
            if toggle and toggle.Value then toggle:SetValue(false) end

            local name = featureNames[key]
            Notify(("%s stopped: %s"):format(name and name.EN or key, reason), "Warning")
        end
        table.clear(State.Halted)
    end

    local function BlockWithoutGameData()
        if GameLib.Ready then return end
        local reason = T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
        for _, key in ipairs({ "Kaitun", "AutoCollect", "SecretAlert", table.unpack(kaitunKeys) }) do
            Library.Compat.Block(key, reason)
        end
        Library:Notify("TNT Mining", "This executor can't read the game's data, so farming is off. Movement still works.", 10, "Error")
    end

    local function BlockMissing()
        if not GameLib.Ready then return end
        for idx, needs in pairs(PatipanStudio.GameLib.Missing()) do
            warn("[TNTMining]", idx, "blocked, missing:", table.concat(needs, ", "))
            Library.Compat.Block(idx, T("Not available after a game update", "ใช้ไม่ได้หลังเกมอัปเดต"))
        end
    end

    local function Request(name)
        return function()
            State.Requests[name] = true
        end
    end

    local function Toggle(group, key, text, description, onChange)
        featureNames[key] = text
        return group:AddToggle(key, {
            Text = text,
            Description = description,
            Default = opt[key],
            Callback = function(value)
                opt[key] = value
                if onChange then onChange(value) end
            end,
        })
    end

    local function Feature(group, key, text, description, onChange)
        return Toggle(group, key, text, description, onChange):AddKeyPicker(key .. "Key", { Default = "None", Mode = "Toggle" })
    end

    local function BuildMain(window)
        window:AddTabSection(T("Farm", "ฟาร์ม"))
        local tab = window:AddTab(T("Main", "หลัก"), "house", T("Status and all-in-one mode", "สถานะและโหมดทำทุกอย่าง"))

        local statusBox = tab:AddLeftGroupbox(T("Status", "สถานะ"))
        local statusLabel = statusBox:AddLabel("Loading...")
        local runLabel = statusBox:AddLabel("-")

        local kaitunBox = tab:AddRightGroupbox("Kaitun")
        kaitunBox:AddToggle("Kaitun", {
            Text = T("Kaitun (All-in-one)", "ไก่ตัน (ทำทุกอย่าง)"),
            Description = T("Mines, sells, trains, buys bombs, upgrades and areas, and rebirths by itself", "ขุด ขาย ฝึก ซื้อระเบิด อัปเกรด พื้นที่ และรีเบิร์ธให้เองทั้งหมด"),
            NoSave = true,
            Callback = function(value)
                for _, key in ipairs(kaitunKeys) do
                    if Options[key] then Options[key]:SetValue(value) end
                end
            end,
        })

        local discordBox = tab:AddRightGroupbox("Discord", "link")
        discordBox:AddLabel(Config.Discord)
        discordBox:AddButton({ Text = T("Copy Discord Link", "คัดลอกลิงก์ Discord"), Style = "Primary", Func = function()
            local copy = setclipboard or toclipboard
            if copy then copy(Config.Discord) end
            Notify(copy and "Discord link copied" or Config.Discord)
        end })

        local logBox = tab:AddRightGroupbox(T("Update Log", "อัปเดตล่าสุด"), "bell")
        for i = 1, math.min(2, #Config.UpdateLog) do
            local entry = Config.UpdateLog[i]
            logBox:AddParagraph({ Title = entry[1], Content = entry[2] })
        end

        return { Summary = statusLabel, Run = runLabel }
    end

    local function BuildMining(window)
        local tab = window:AddTab(T("Mining", "ขุด"), "bomb", T("Auto mining and selling", "ขุดและขายอัตโนมัติ"))

        local mineBox = tab:AddLeftGroupbox(T("Auto Mine", "ขุดอัตโนมัติ"), "bomb")
        Feature(mineBox, "AutoMine", T("Auto Mine", "ขุดอัตโนมัติ"), T("Blasts the most valuable spots in the mine and picks up every drop", "ระเบิดจุดที่มีค่าที่สุดในเหมืองแล้วเก็บของดรอปทั้งหมด"))
        local areaChoices = { "Best" }
        for _, areaName in ipairs(PatipanStudio.AreaOrder) do table.insert(areaChoices, areaName) end
        mineBox:AddDropdown("MineArea", {
            Text = T("Mine Area", "พื้นที่ขุด"),
            Description = T("Best = strongest area your damage can handle", "Best = พื้นที่ดีสุดที่ดาเมจตอนนี้ขุดไหว"),
            Values = areaChoices,
            Default = 1,
            Searchable = true,
            Callback = function(value) opt.MineArea = value or "Best" end,
        })
        Toggle(mineBox, "SecretAlert", T("Secret Block Alert", "แจ้งเตือนบล็อก Secret"), T("Notifies you when a secret block spawns in your mine", "แจ้งเมื่อมีบล็อก Secret เกิดในเหมือง"))
        Toggle(mineBox, "TargetShards", T("Prioritize Egg Shards", "เน้นเศษไข่"), T("Goes for egg shards first", "ไล่เก็บเศษไข่ก่อน"))

        local sellBox = tab:AddRightGroupbox(T("Sell", "ขาย"), "coin")
        Feature(sellBox, "AutoSell", T("Auto Sell", "ขายอัตโนมัติ"), T("Sells blocks right after every blast, from anywhere. Favorited blocks are kept", "ขายบล็อกทันทีหลังระเบิดทุกครั้ง ขายได้จากทุกที่ บล็อกที่กดชอบจะเก็บไว้"))
        sellBox:AddButton({ Text = T("Sell All Now", "ขายทั้งหมดเดี๋ยวนี้"), Style = "Primary", Func = Request("SellNow") })

        local dropBox = tab:AddRightGroupbox(T("Drops", "ของดรอป"), "bomb")
        featureNames.AutoCollect = T("Auto Collect", "เก็บของอัตโนมัติ")
        dropBox:AddToggle("AutoCollect", {
            Text = featureNames.AutoCollect,
            Description = T("Instantly picks up every drop in the mine from anywhere, even when you bomb by hand", "เก็บของดรอปทั้งเหมืองทันทีจากทุกที่ แม้วางระเบิดเอง"),
            Risky = true,
            Default = false,
            Callback = function(value) opt.AutoCollect = value end,
        }):AddKeyPicker("AutoCollectKey", { Default = "None", Mode = "Toggle" })
        dropBox:AddButton({ Text = T("Collect Drops Now", "เก็บของดรอปเดี๋ยวนี้"), Func = Request("CollectNow") })
    end

    local function BuildUpgrades(window)
        window:AddTabSection(T("Progress", "ความคืบหน้า"))
        local tab = window:AddTab(T("Upgrades", "อัปเกรด"), "sliders-horizontal", T("Bombs, upgrades, areas and rebirth", "ระเบิด อัปเกรด พื้นที่ และรีเบิร์ธ"))

        local trainBox = tab:AddLeftGroupbox(T("Damage & Rebirth", "ดาเมจและรีเบิร์ธ"), "star")
        Feature(trainBox, "AutoClick", T("Auto Click", "คลิกอัตโนมัติ"), T("Trains damage at the fastest speed the game allows", "เพิ่มดาเมจเร็วสุดเท่าที่เกมยอม"), function(value)
            if value then PatipanStudio.Progress.StartClicking() end
        end)
        Feature(trainBox, "AutoRebirth", T("Auto Rebirth", "รีเบิร์ธอัตโนมัติ"), T("Rebirths as soon as your level is high enough", "รีเบิร์ธทันทีเมื่อเลเวลถึง"))
        trainBox:AddButton({ Text = T("Rebirth Now", "รีเบิร์ธเดี๋ยวนี้"), Func = Request("RebirthNow") })

        local shopBox = tab:AddRightGroupbox(T("Shop", "ร้านค้า"), "shop")
        Feature(shopBox, "AutoBomb", T("Auto Buy Best Bomb", "ซื้อระเบิดดีสุดอัตโนมัติ"), T("Buys and equips the strongest bomb you can afford", "ซื้อและใส่ระเบิดที่แรงที่สุดที่ซื้อไหว"))
        shopBox:AddButton({ Text = T("Buy Best Bomb Now", "ซื้อระเบิดดีสุดเดี๋ยวนี้"), Func = Request("BombNow") })
        Feature(shopBox, "AutoArea", T("Auto Buy Next Area", "ซื้อพื้นที่ถัดไปอัตโนมัติ"), T("Unlocks the next area when you have the money", "ปลดล็อกพื้นที่ถัดไปเมื่อเงินพอ"))
        shopBox:AddButton({ Text = T("Buy Next Area Now", "ซื้อพื้นที่ถัดไปเดี๋ยวนี้"), Func = Request("AreaNow") })
        Feature(shopBox, "AutoLuck", T("Auto Buy Mine Luck", "ซื้อโชคเหมืองอัตโนมัติ"), T("Upgrades luck for the area you mine", "อัปโชคของพื้นที่ที่กำลังขุด"))
        shopBox:AddButton({ Text = T("Buy Mine Luck Now", "ซื้อโชคเหมืองเดี๋ยวนี้"), Func = Request("LuckNow") })

        local upgradeBox = tab:AddLeftGroupbox(T("Upgrades", "อัปเกรด"), "gear")
        local upgradeDefault = {}
        opt.Upgrades = {}
        for _, name in ipairs({ "MaxHeldBombs", "MaxActiveBombs" }) do
            if GameLib.Upgrades and GameLib.Upgrades[name] then
                table.insert(upgradeDefault, name)
                opt.Upgrades[name] = true
            end
        end
        upgradeBox:AddDropdown("Upgrades", {
            Text = T("Upgrades To Buy", "อัปเกรดที่จะซื้อ"),
            Values = PatipanStudio.UpgradeNames,
            Multi = true,
            Default = upgradeDefault,
            Callback = function(selected) opt.Upgrades = selected end,
        })
        Feature(upgradeBox, "AutoUpgrade", T("Auto Buy Upgrades", "ซื้ออัปเกรดอัตโนมัติ"), T("Buys the selected upgrades whenever possible", "ซื้ออัปเกรดที่เลือกทุกครั้งที่ซื้อได้"))
        upgradeBox:AddButton({ Text = T("Buy Upgrades Now", "ซื้ออัปเกรดเดี๋ยวนี้"), Func = Request("UpgradeNow") })
    end

    local function BuildPets(window)
        local tab = window:AddTab(T("Pets & Rewards", "สัตว์เลี้ยงและรางวัล"), "star", T("Eggs, pets and free rewards", "ไข่ สัตว์เลี้ยง และรางวัลฟรี"))

        local hatchBox = tab:AddLeftGroupbox(T("Eggs", "ไข่"), "mushroom")
        Feature(hatchBox, "AutoHatch", T("Auto Hatch", "ฟักไข่อัตโนมัติ"), T("Hatches the best egg you can afford with egg shards", "ฟักไข่ที่ดีที่สุดที่เศษไข่พอ"))
        hatchBox:AddButton({ Text = T("Hatch Now", "ฟักเดี๋ยวนี้"), Func = Request("HatchNow") })

        local petBox = tab:AddLeftGroupbox(T("Pets", "สัตว์เลี้ยง"), "mushroom")
        Feature(petBox, "AutoEquipPets", T("Auto Equip Best Pets", "ใส่สัตว์เลี้ยงดีสุดอัตโนมัติ"), T("Always uses your strongest pets", "ใช้สัตว์เลี้ยงที่แรงที่สุดเสมอ"))
        petBox:AddButton({ Text = T("Equip Best Pets Now", "ใส่สัตว์เลี้ยงดีสุดเดี๋ยวนี้"), Func = Request("EquipPetsNow") })

        local petSellBox = tab:AddRightGroupbox(T("Sell Pets", "ขายสัตว์เลี้ยง"), "coin")
        Feature(petSellBox, "AutoSellPets", T("Auto Sell Pets", "ขายสัตว์เลี้ยงอัตโนมัติ"), T("Keeps your strongest pets and sells the rest so hatching never stops", "เก็บตัวที่แรงที่สุดไว้ ขายที่เหลือ ฟักไข่ได้ไม่มีวันเต็ม"))
        petSellBox:AddSlider("KeepPets", {
            Text = T("Keep Best Pets", "จำนวนตัวดีสุดที่เก็บไว้"),
            Min = 0, Max = 50, Default = opt.KeepPets, Rounding = 0,
            Callback = function(value) opt.KeepPets = tonumber(value) or opt.KeepPets end,
        })

        local rarityTable = GameLib.Pets and GameLib.Pets.Rarities or {}
        local petRarities = {}
        for rarity in pairs(rarityTable) do table.insert(petRarities, rarity) end
        table.sort(petRarities, function(a, b) return rarityTable[a].Weight > rarityTable[b].Weight end)
        petSellBox:AddDropdown("KeepPetRarities", {
            Text = T("Never Sell Rarity", "rarity ที่ห้ามขาย"),
            Values = petRarities,
            Multi = true,
            Default = {},
            Callback = function(selected) opt.KeepPetRarities = selected end,
        })
        petSellBox:AddButton({ Text = T("Sell Extra Pets Now", "ขายสัตว์เลี้ยงส่วนเกินเดี๋ยวนี้"), Func = Request("SellPetsNow") })

        local rewardBox = tab:AddRightGroupbox(T("Rewards", "รางวัล"), "flag")
        Feature(rewardBox, "AutoClaim", T("Auto Claim", "รับรางวัลอัตโนมัติ"), T("Claims daily, group and index rewards", "รับรางวัลรายวัน กลุ่ม และสมุดสะสม"))
        rewardBox:AddButton({ Text = T("Claim Now", "รับเดี๋ยวนี้"), Func = Request("ClaimNow") })
    end

    local function BuildPlayer(window)
        window:AddTabSection(T("Other", "อื่นๆ"))
        local tab = window:AddTab(T("Player", "ผู้เล่น"), "user", T("Movement", "การเคลื่อนที่"))

        local moveBox = tab:AddLeftGroupbox(T("Movement", "การเคลื่อนที่"), "star")
        Feature(moveBox, "SpeedOn", T("Speed", "ความเร็ว"), nil, Request("Speed"))
        moveBox:AddSlider("WalkSpeed", {
            Text = T("Walk Speed", "ความเร็วเดิน"),
            Min = 16, Max = 200, Default = opt.WalkSpeed, Rounding = 0,
            Callback = function(value)
                opt.WalkSpeed = tonumber(value) or opt.WalkSpeed
                State.Requests.Speed = true
            end,
        })

        local jumpBox = tab:AddRightGroupbox(T("Jump", "กระโดด"), "star")
        Feature(jumpBox, "InfJump", T("Infinite Jump", "กระโดดไม่จำกัด"))
    end

    local function BuildSettings(window)
        local tab = window:AddSettingsTab()
        local sessionBox = tab:AddRightGroupbox(T("Session", "เซสชัน"), "gear")
        Toggle(sessionBox, "AutoRejoin", T("Auto Rejoin", "เข้าเกมใหม่อัตโนมัติ"), T("Rejoins by itself after a disconnect", "หลุดแล้วเข้าเกมใหม่เอง"))
        Toggle(sessionBox, "LowGraphics", T("FPS Boost", "เพิ่ม FPS"), T("Turns off 3D rendering to save CPU and GPU", "ปิดการแสดงผล 3D ประหยัด CPU/GPU"), PatipanStudio.Client.SetLowGraphics)
    end

    local function BuildTabs()
        local window = Library.Window
        local _, labels = PatipanStudio.Try(BuildMain, window)
        for _, build in ipairs({ BuildMining, BuildUpgrades, BuildPets, BuildPlayer, BuildSettings }) do
            PatipanStudio.Try(build, window)
        end
        PatipanStudio.Try(BlockWithoutGameData)
        PatipanStudio.Try(BlockMissing)

        Library:Every(1, function()
            ReportHalts()
            while #State.Messages > 0 do
                Notify(table.remove(State.Messages, 1))
            end
            if type(labels) ~= "table" then return end
            labels.Summary:SetText(State.Summary)
            labels.Run:SetText(("%s\nBombs %d · Earned %s"):format(State.Status, State.Bombs, PatipanStudio.Format(State.Earned)))
        end)
    end

    Library:OnUnload(PatipanStudio.Scheduler.Stop)
    local function UnloadHub()
        Library:Unload()
    end
    getgenv().TNTMiningUnload = UnloadHub
    Library:OnUnload(function()
        if getgenv().TNTMiningUnload == UnloadHub then getgenv().TNTMiningUnload = nil end
    end)

    Library:CreateWindow({
        Title = "PatipanStudio",
        SubTitle = "TNT Mining by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        OnUnlocked = function()
            BuildTabs()
            PatipanStudio.Try(PatipanStudio.Scheduler.Boot)
            Notify("Loaded", "Success")
            PatipanStudio.Try(Library.LoadAutoloadConfig, Library)
        end,
    })
end

if getgenv().TNTMiningUnload then
    pcall(getgenv().TNTMiningUnload)
end

pcall(MarioBanner.Step, "Systems")
BuildInterface()
pcall(MarioBanner.Step, "Interface")
pcall(MarioBanner.Ready)