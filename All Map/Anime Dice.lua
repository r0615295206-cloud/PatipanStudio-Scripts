if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local environment = getgenv and getgenv() or _G
if type(environment.AnimeDiceUnload) == "function" then
    pcall(environment.AnimeDiceUnload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local osClock = os.clock

if game.GameId ~= 10708913337 then
    LocalPlayer:Kick("PatipanStudio: this script is for Anime Dice only")
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
    if ok and type(renv) == "table" and type(renv.print) == "function" then MarioBanner.Print = renv.print end
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

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-05", "Added Rebirth Stats: auto spend points on the stat you pick\nAdded Reset Stats with Reset Token\nAdded auto use of gamepass items" },
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nAuto Roll stops at full storage\nFixed Group Reward\nImproved Fast Roll" },
    },
    ReloadSource = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/loader.lua"))()',
    RejoinDelay = 5,
    RejoinRetry = 30,
    WebhookColor = 0xE8A04C,
    GroupId = 33017480,
    SaveFolder = "Anime Dice",
    LoadTimeout = 10,
    AlertTries = 20,
    AlertGap = 0.5,
    JobFailLimit = 5,
    JobFailWindow = 10,
    StatusInterval = 1,
    RollLead = 0.1,
    GradeDelay = 0.3,
    TraitDelay = 0.3,
    FuseDelay = 0.55,
    BuyDelay = 0.3,
    LevelDelay = 0.2,
    RedeemDelay = 0.6,
    ClaimDelay = 0.25,
    TowerTick = 0.25,
    TowerRetry = 0.5,
    TowerStartCooldown = 3.2,
    ItemDelay = 0.6,
    StatDelay = 0.12,
    RewardsInterval = 5,
    SnapshotTtl = 0.4,
    StorageHeadroom = 6,
    StorageRefill = 0.7,
    TowerDemoteFloor = 5,
    RollStats = { Luck = true, ["Roll Duration"] = true, Rolls = true },
    UtilitySeconds = { Default = 120, Walkspeed = 10, ["Sell Multiplier"] = 60, ["Unit Storage"] = 180, Luck = 600, ["Roll Duration"] = 600 },
    UtilityFallbackShare = 0.05,
    SwapMargin = 1.15,
    FuseGain = 1.25,
    FuseMoneyShare = 0.05,
    SwapsPerPass = 4,
    PlaceDelay = 0.55,
    TowerActionTime = {
        floorStarted = 0.76,
        damageEnemy = 0.62,
        damagePlayer = 0.62,
        memberDefeated = 0.32,
        floorCompleted = 0.24,
    },
}

PatipanStudio.State = {
    Alive = true,
    Connections = {},
    Halted = {},
    Notices = {},
}

PatipanStudio.Options = {
    AntiAfk = false,
    DisableCutscene = false,

    WalkSpeed = false,
    WalkSpeedValue = 32,
    InfiniteJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 60,

    AutoRoll = false,
    RollInterval = 0.02,

    AutoCollect = false,
    CollectInterval = 1,
    EquipBestUnitsAuto = false,
    EquipInterval = 5,
    PlacementMode = "Potential",
    AutoLevelUp = false,
    LevelMinRarity = "Common",
    LevelTarget = 10,

    AutoBuyDice = false,
    AutoEquipBestDice = false,
    AutoBuyUpgrades = false,
    UpgradeFilter = {},

    AutoSell = false,
    SellRarities = {},
    SellKeepMutations = {},
    KeepPerRarity = 0,
    SellInterval = 2,
    AutoClearStorage = false,
    ClearKeepRarity = "Mythical",
    LevelPayback = 180,
    UpgradePayback = 1800,

    AutoRebirth = false,
    AutoRebirthStats = false,
    RebirthStat = "Money",

    AutoGrade = false,
    GradeTarget = "S",
    GradeOverwrite = false,
    AutoTrait = false,
    TraitTarget = "Samurai",
    TraitOverwrite = false,
    AutoFuse = false,
    FuseRarities = {},

    AutoTower = false,
    TowerName = "Dragon Tower",
    TowerStopFloor = 100,
    TowerReequip = false,
    TowerSmart = false,

    AutoGear = false,
    AutoPotion = false,
    PotionFilter = {},
    AutoSpin = false,
    AutoGamepass = false,
    AutoTicketShop = false,
    TicketShopItems = {},

    AutoDaily = false,
    AutoGroup = false,
    AutoOffline = false,
    AutoQuest = false,

    RareNotify = false,
    NotifyRarities = {},
    NotifyMutations = {},
    WebhookUrl = "",
    AutoLock = false,
    LockRarity = "Secret I",
    LockMutations = {},
    AutoRejoin = false,

    Kaitun = false,
}

PatipanStudio.Util = {}
local Util = PatipanStudio.Util

---@return function?  first argument that is callable
local function Resolve(...)
    for index = 1, select("#", ...) do
        local candidate = select(index, ...)
        if type(candidate) == "function" then
            return candidate
        end
    end
    return nil
end

Util.Request = Resolve(request, http_request, syn and syn.request, http and http.request)
Util.SetClipboard = Resolve(setclipboard, toclipboard)
Util.QueueTeleport = Resolve(queue_on_teleport, queueonteleport, syn and syn.queue_on_teleport)

---@return string?, string?  body, or nil and why every transport failed
function Util.HttpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then
        return body
    end
    if not Util.Request then return nil, "no http function" end

    local sent, response = pcall(Util.Request, { Url = url, Method = "GET" })
    if not sent or type(response) ~= "table" then return nil, tostring(response) end
    if response.StatusCode ~= 200 or type(response.Body) ~= "string" then
        return nil, "HTTP " .. tostring(response.StatusCode)
    end
    return response.Body
end

---@param detail any?  extra context for the console only
function Util.Alert(text, detail)
    warn("[AnimeDice] " .. text, detail or "")
    task.spawn(function()
        local starterGui = game:GetService("StarterGui")
        for _ = 1, PatipanStudio.Config.AlertTries do
            if pcall(starterGui.SetCore, starterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 }) then return end
            task.wait(PatipanStudio.Config.AlertGap)
        end
    end)
end

function Util.Copy(text)
    if not Util.SetClipboard then return false end
    return (pcall(Util.SetClipboard, text))
end

---@return boolean  fn finished without error
function Util.Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[AnimeDice] " .. label .. ":", err) end
    return ok
end

---@return table?, string?  UI library, or nil and a message for the player
function Util.LoadLibrary(url)
    local source, why = Util.HttpGet(url)
    if not source or not source:sub(-64):find("return%s+Library%s*$") then
        warn("[AnimeDice] ui download:", why or "truncated or not the library")
        return nil, "Could not download the menu. Check your connection and run it again."
    end
    local chunk, compileErr = loadstring(source)
    if not chunk then
        return nil, "The menu failed to load on this executor: " .. tostring(compileErr)
    end
    local ok, lib = pcall(chunk)
    if not ok or type(lib) ~= "table" then
        return nil, "The menu failed to load on this executor: " .. tostring(lib)
    end
    return lib
end

function Util.FormatNumber(value)
    value = tonumber(value) or 0
    if value >= 1e6 then
        local suffixes = { "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
        local tier = math.clamp(math.floor(math.log(value, 1000)) - 1, 1, #suffixes)
        return string.format("%.2f%s", value / (1000 ^ (tier + 1)), suffixes[tier])
    end
    local text = tostring(math.floor(value))
    local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (formatted:gsub("^,", ""))
end

---@return string[]  sorted keys, stable dropdown order
function Util.SortedKeys(map)
    local keys = {}
    for key in pairs(map or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

function Util.SetFromList(list)
    local set = {}
    for key, value in pairs(list or {}) do
        if type(key) == "number" then
            set[value] = true
        elseif value then
            set[key] = true
        end
    end
    return set
end

function PatipanStudio:Connect(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(self.State.Connections, connection)
    return connection
end

PatipanStudio.GameLib = {}
local GameLib = PatipanStudio.GameLib

---@return Instance?  descendant at a dotted path, nil when any part is missing
function GameLib.Find(root, path)
    local node = root
    for part in path:gmatch("[^.]+") do
        if not node then return nil end
        node = node:FindFirstChild(part)
    end
    return node
end

---@return boolean, any  ok and module, required from a fresh identity-2 thread
function GameLib.RequireAsGame(module)
    if GameLib.CanSwitch == false then return false, nil end

    local done, ok, loaded = false, false, nil
    task.spawn(function()
        local switched = pcall(setthreadidentity, 2)
        local read, identity = pcall(getthreadidentity)
        if switched and read and identity == 2 then
            ok, loaded = pcall(require, module)
        else
            GameLib.CanSwitch = false
        end
        done = true
    end)
    local deadline = osClock() + PatipanStudio.Config.LoadTimeout
    while not done and osClock() < deadline do task.wait() end
    return ok, loaded
end

---@return any?  module, nil when it is missing or no identity can require it
function GameLib.Require(module)
    if not (module and module:IsA("ModuleScript")) then return nil end
    local ok, loaded = pcall(require, module)
    if ok then return loaded end
    local retried, again = GameLib.RequireAsGame(module)
    if retried then return again end
    warn("[AnimeDice] require " .. module:GetFullName() .. ":", loaded)
    return nil
end

do
    local framework = ReplicatedStorage:WaitForChild("Framework", PatipanStudio.Config.LoadTimeout)
    local features = framework and framework:WaitForChild("Features", PatipanStudio.Config.LoadTimeout)
    local function Load(path) return GameLib.Require(GameLib.Find(features, path)) end

    GameLib.Dice = Load("Rolling.Dice")
    GameLib.Rebirths = Load("Rebirth.Rebirths")
    GameLib.Upgrades = Load("Upgrades.Upgrades")
    GameLib.Tree = Load("Upgrades.TreeStructure")
    GameLib.Grades = Load("Grades.Grades")
    GameLib.Traits = Load("Traits.Traits")
    GameLib.Towers = Load("Towers.Towers")
    GameLib.Rarities = GameLib.Require(GameLib.Find(framework, "Other.Rarities"))
    GameLib.Entry = Load("Inventory.EntryRegistry")
    GameLib.Mutations = Load("Inventory.Kinds.Unit.Mutations")
    GameLib.UnitUtil = Load("Inventory.Kinds.Unit.UnitUtil")
    GameLib.Codes = Load("Codes.CodesConfig")
    GameLib.Quests = Load("Quests.QuestConfig")
    GameLib.RollController = Load("Rolling.RollController")
    GameLib.Buffs = Load("Buffs.BuffController")
    GameLib.BuffsConfig = Load("Buffs.BuffsConfig")
    GameLib.FusingConfig = Load("Fusing.FusingConfig")
    GameLib.RebirthStats = Load("Rebirth.RebirthStatsConfig")

    local rewards = GameLib.Find(features, "Rewards")
    GameLib.Daily = GameLib.Require(rewards and rewards:FindFirstChild("DailyRewardConfig", true))
    GameLib.Group = GameLib.Require(rewards and rewards:FindFirstChild("GroupRewardConfig", true))
    GameLib.DataClient = GameLib.Require(GameLib.Find(ReplicatedStorage, "Packages.Data.Client"))
end

GameLib.EntryCache = {}

function GameLib.EntryOf(name)
    local registry = GameLib.Entry
    if not registry or not name then return nil end
    local cached = GameLib.EntryCache[name]
    if cached ~= nil then return cached or nil end
    local ok, config = pcall(registry.getEntryConfig, name)
    GameLib.EntryCache[name] = ok and config or false
    return ok and config or nil
end

function GameLib.GradeOrder(gradeName)
    local grade = gradeName and GameLib.Grades and GameLib.Grades[gradeName]
    return type(grade) == "table" and tonumber(grade.order) or 0
end

---@return number  strongest multiplier, order breaks ties
function GameLib.TraitPower(traitName)
    local trait = traitName and GameLib.Traits and GameLib.Traits[traitName]
    if type(trait) ~= "table" then return 0 end
    local best = math.max(tonumber(trait.incomeMultiplier) or 0, tonumber(trait.damageMultiplier) or 0,
        tonumber(trait.healthMultiplier) or 0)
    return best + (tonumber(trait.order) or 0) / 1000
end

function GameLib.RarityOrder(rarityName)
    local rarities = GameLib.Rarities
    if not rarities or not rarityName then return 0 end
    local ok, entry = pcall(rarities.Get, rarityName)
    return ok and type(entry) == "table" and tonumber(entry.sortOrder) or 0
end

---@return string[]  names of every entry of a kind, sorted
function GameLib.NamesOfKind(kind)
    local registry = GameLib.Entry
    local names = {}
    if not registry then return names end
    local ok, entries = pcall(registry.entriesOfKind, kind)
    if ok and type(entries) == "table" then
        for name in pairs(entries) do names[#names + 1] = tostring(name) end
    end
    table.sort(names)
    return names
end

function GameLib.RebirthStatNames()
    local names = {}
    local config = GameLib.RebirthStats
    if not (config and type(config.Stats) == "table") then return names end
    for _, stat in ipairs(config.Stats) do names[#names + 1] = tostring(stat.name) end
    return names
end

function GameLib.GradeNames()
    local names = Util.SortedKeys(GameLib.Grades or {})
    table.sort(names, function(a, b) return GameLib.GradeOrder(a) < GameLib.GradeOrder(b) end)
    return names
end

function GameLib.TraitNames()
    local names = {}
    for name, trait in pairs(GameLib.Traits or {}) do
        if type(trait) == "table" and GameLib.TraitPower(name) > 0 then names[#names + 1] = name end
    end
    table.sort(names, function(a, b) return GameLib.TraitPower(a) < GameLib.TraitPower(b) end)
    return names
end

function GameLib.MutationNames()
    local names = {}
    for name, mutation in pairs(GameLib.Mutations or {}) do
        if type(mutation) == "table" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        return (tonumber(GameLib.Mutations[a].chance) or 0) < (tonumber(GameLib.Mutations[b].chance) or 0)
    end)
    return names
end

---@return string[]  unit rarities present in the registry, worst first
function GameLib.UnitRarities()
    local seen = {}
    local registry = GameLib.Entry
    if registry then
        local ok, units = pcall(registry.entriesOfKind, "Unit")
        if ok and type(units) == "table" then
            for _, config in pairs(units) do
                if type(config) == "table" and config.rarity then seen[config.rarity] = true end
            end
        end
    end
    local list = {}
    for rarity in pairs(seen) do list[#list + 1] = rarity end
    table.sort(list, function(a, b) return GameLib.RarityOrder(a) < GameLib.RarityOrder(b) end)
    return list
end

function GameLib.ShopNames()
    local names = {}
    local shop = GameLib.Quests and GameLib.Quests.Shop
    for _, item in ipairs(type(shop) == "table" and shop or {}) do
        if type(item) == "table" and item.name and not item.gamepass then names[#names + 1] = item.name end
    end
    return names
end

PatipanStudio.Net = { Cache = {} }
local Network = ReplicatedStorage:WaitForChild("Network", PatipanStudio.Config.LoadTimeout)

---@return Instance?  remote whose name and parent match the path tail, anywhere under Network
function PatipanStudio.Net.Search(path)
    if not Network then return nil end
    local parts = string.split(path, ".")
    local name, parent = parts[#parts], parts[#parts - 1]
    for _, node in ipairs(Network:GetDescendants()) do
        if node.Name == name and (not parent or (node.Parent and node.Parent.Name == parent)) then return node end
    end
    return nil
end

---@return Instance?  remote at a dotted path under Network
function PatipanStudio.Net.Get(path)
    local cached = PatipanStudio.Net.Cache[path]
    if cached and cached.Parent then return cached end

    local remote = GameLib.Find(Network, path) or PatipanStudio.Net.Search(path)
    PatipanStudio.Net.Cache[path] = remote
    return remote
end

function PatipanStudio.Net.Fire(path, ...)
    local remote = PatipanStudio.Net.Get(path)
    if remote then remote:FireServer(...) end
end

---@return boolean, any  invoke success, server reply
function PatipanStudio.Net.Invoke(path, ...)
    local remote = PatipanStudio.Net.Get(path)
    if not remote then return false, "no remote" end
    return pcall(remote.InvokeServer, remote, ...)
end

PatipanStudio.Data = {}

---@return any  raw replicated value of a top-level profile field
function PatipanStudio.Data.Read(field)
    local client = GameLib.DataClient
    if not client then return nil end
    local ok, proxy = pcall(function() return client:get({ field }) end)
    if not ok then return nil end
    if type(proxy) == "table" then
        local okCall, value = pcall(proxy)
        if okCall then return value end
    end
    return proxy
end

function PatipanStudio.Data.Table(field)
    local value = PatipanStudio.Data.Read(field)
    return type(value) == "table" and value or {}
end

function PatipanStudio.Data.Money()
    return tonumber(PatipanStudio.Data.Read("Money")) or 0
end

function PatipanStudio.Data.Rebirth()
    return tonumber(PatipanStudio.Data.Read("Rebirth")) or 0
end

function PatipanStudio.Data.Rolls()
    return tonumber(PatipanStudio.Data.Read("Rolls")) or 0
end

function PatipanStudio.Data.Token(name)
    local total = 0
    for _, entry in pairs(PatipanStudio.Data.Table("Inventory")) do
        if type(entry) == "table" and entry.name == name then
            total += tonumber(entry.amount) or 0
        end
    end
    return total
end

---@return table<string, boolean>  unit keys placed on the plot or in the tower team
function PatipanStudio.Data.BusyKeys()
    local busy = {}
    for _, slot in pairs(PatipanStudio.Data.Table("Slots")) do
        if type(slot) == "table" and slot.unitId then busy[tostring(slot.unitId)] = true end
    end
    for _, key in pairs(PatipanStudio.Data.Table("TowerTeam")) do
        if type(key) == "string" then busy[key] = true end
    end
    return busy
end

---@return table[]  items of one kind {Key, Name, Amount}
function PatipanStudio.Data.ItemsOfKind(kind)
    local items = {}
    for key, entry in pairs(PatipanStudio.Data.Table("Inventory")) do
        if type(entry) == "table" and entry.name then
            local config = GameLib.EntryOf(entry.name)
            if config and config.kind == kind then
                items[#items + 1] = { Key = tostring(key), Name = entry.name, Amount = tonumber(entry.amount) or 1 }
            end
        end
    end
    return items
end

---@return number  unit entries the server counts against Unit Storage, trade reservations included
function PatipanStudio.Data.UnitCount()
    local count = 0
    for _, entry in pairs(PatipanStudio.Data.Table("Inventory")) do
        local config = type(entry) == "table" and entry.name and GameLib.EntryOf(entry.name)
        if config and config.kind == "Unit" then count += 1 end
    end
    local trade = PatipanStudio.Data.Read("PendingTrade")
    if type(trade) == "table" and not trade.applied then count += tonumber(trade.reservedUnits) or 0 end
    return count
end

PatipanStudio.Data.UnitCache = { At = -1, List = {} }

---@return table[]  owned units, plotted first then by income; shared snapshot
function PatipanStudio.Data.Units()
    local cache = PatipanStudio.Data.UnitCache
    local now = osClock()
    if now - cache.At < PatipanStudio.Config.SnapshotTtl then return cache.List end
    cache.List = PatipanStudio.Data.ScanUnits()
    cache.At = now
    return cache.List
end

function PatipanStudio.Data.Invalidate()
    PatipanStudio.Data.UnitCache.At = -1
end

function PatipanStudio.Data.IncomeAt(config, attrs, level)
    local probe = table.clone(attrs)
    probe.level = level
    local ok, value = pcall(config.income, probe)
    return ok and tonumber(value) or 0
end

function PatipanStudio.Data.LevelPrice(unit, level)
    local probe = table.clone(unit.Attr)
    probe.level = level
    local ok, price = pcall(GameLib.UnitUtil.GetLevelPrice, unit.Name, probe)
    return ok and tonumber(price) or math.huge
end

function PatipanStudio.Data.ScanUnits()
    local busy = PatipanStudio.Data.BusyKeys()
    local units = {}
    for key, entry in pairs(PatipanStudio.Data.Table("Inventory")) do
        if type(entry) == "table" and entry.name then
            local config = GameLib.EntryOf(entry.name)
            if config and config.kind == "Unit" then
                local attrs = type(entry.attributes) == "table" and entry.attributes or {}
                local rarity = config.rarity
                if type(config.getRarity) == "function" then
                    local ok, dynamic = pcall(config.getRarity, attrs)
                    if ok and dynamic then rarity = dynamic end
                end
                local income, potential = 0, 0
                if type(config.income) == "function" then
                    local ok, value = pcall(config.income, attrs)
                    if ok then income = tonumber(value) or 0 end
                    potential = PatipanStudio.Data.IncomeAt(config, attrs, 1)
                end
                local chance
                if type(config.chance) == "function" and not config.limited and (tonumber(entry.amount) or 1) == 1 then
                    local ok, value = pcall(config.chance, attrs)
                    chance = ok and tonumber(value) or nil
                end
                key = tostring(key)
                units[#units + 1] = {
                    Key = key,
                    Name = entry.name,
                    Attr = attrs,
                    Rarity = rarity,
                    Grade = attrs.grade,
                    Trait = attrs.trait,
                    Mutation = attrs.mutation,
                    Level = tonumber(attrs.level) or 1,
                    Locked = attrs.locked == true,
                    Busy = busy[key] == true,
                    Value = income,
                    Potential = potential,
                    Chance = chance,
                }
            end
        end
    end
    table.sort(units, function(a, b)
        if a.Busy ~= b.Busy then return a.Busy end
        return a.Value > b.Value
    end)
    return units
end

PatipanStudio.Player = { Client = LocalPlayer }

function PatipanStudio.Player:Bind(character)
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid", PatipanStudio.Config.LoadTimeout)
    self.Root = character:WaitForChild("HumanoidRootPart", PatipanStudio.Config.LoadTimeout)
end

PatipanStudio.Scheduler = { Jobs = {}, Booted = false }

---@param interval number|function  seconds, or a getter read every tick
---@param toggles string[]?          options switched off when the job keeps failing
function PatipanStudio.Scheduler.Every(name, interval, fn, toggles)
    PatipanStudio.Scheduler.Jobs[name] = { Interval = interval, Fn = fn, Last = 0, Running = false, Fails = 0, Toggles = toggles or {} }
end

---@return boolean  one of the job's toggles is on
function PatipanStudio.Scheduler.Wanted(job)
    for _, idx in ipairs(job.Toggles) do
        if PatipanStudio.Options[idx] == true then return true end
    end
    return false
end

function PatipanStudio.Scheduler.Run(name, job)
    local ok, err = pcall(job.Fn)
    job.Running = false
    if ok then
        job.Fails, job.FailSince = 0, nil
        return
    end

    job.Fails += 1
    job.FailSince = job.FailSince or osClock()
    if job.Fails == 1 then warn("[AnimeDice] job " .. name .. " failing:", err) end

    local config = PatipanStudio.Config
    if job.Fails < config.JobFailLimit or osClock() - job.FailSince < config.JobFailWindow then return end
    if not PatipanStudio.Scheduler.Wanted(job) then return end
    job.Halted = true
    table.insert(PatipanStudio.State.Halted, { name, job.Toggles, tostring(err):match("^[^\n]*") })
end

function PatipanStudio.Scheduler.Step()
    local now = osClock()
    for name, job in pairs(PatipanStudio.Scheduler.Jobs) do
        local interval = type(job.Interval) == "function" and job.Interval() or job.Interval
        if not job.Running and not job.Halted and now - job.Last >= interval then
            job.Last = now
            job.Running = true
            task.spawn(PatipanStudio.Scheduler.Run, name, job)
        end
    end
end

function PatipanStudio.Scheduler.Resume(idx)
    for _, job in pairs(PatipanStudio.Scheduler.Jobs) do
        if table.find(job.Toggles, idx) then
            job.Halted, job.Fails, job.FailSince = false, 0, nil
        end
    end
end

function PatipanStudio.Scheduler.Boot()
    if PatipanStudio.Scheduler.Booted then return end
    PatipanStudio.Scheduler.Booted = true
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Scheduler.Step)
end

PatipanStudio.AntiAfk = { Connection = nil }

function PatipanStudio.AntiAfk.OnIdled()
    if not PatipanStudio.Options.AntiAfk then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end

function PatipanStudio.AntiAfk.Start()
    PatipanStudio.Options.AntiAfk = true
    if not PatipanStudio.AntiAfk.Connection then
        PatipanStudio.AntiAfk.Connection = PatipanStudio:Connect(LocalPlayer.Idled, PatipanStudio.AntiAfk.OnIdled)
    end
end

function PatipanStudio.AntiAfk.Stop()
    PatipanStudio.Options.AntiAfk = false
end

PatipanStudio.Cutscene = { Saved = nil }

function PatipanStudio.Cutscene.Skip() end

function PatipanStudio.Cutscene.Apply()
    local controller = GameLib.RollController
    if type(controller) ~= "table" or table.isfrozen(controller) or PatipanStudio.Cutscene.Saved then return end
    local original = rawget(controller, "PlayCutscene")
    if type(original) ~= "function" then return end
    PatipanStudio.Cutscene.Saved = original
    rawset(controller, "PlayCutscene", PatipanStudio.Cutscene.Skip)
end

function PatipanStudio.Cutscene.Restore()
    local controller = GameLib.RollController
    local original = PatipanStudio.Cutscene.Saved
    if not original then return end
    if rawget(controller, "PlayCutscene") == PatipanStudio.Cutscene.Skip then rawset(controller, "PlayCutscene", original) end
    PatipanStudio.Cutscene.Saved = nil
end

function PatipanStudio.Cutscene.Step()
    if PatipanStudio.Options.DisableCutscene then PatipanStudio.Cutscene.Apply() else PatipanStudio.Cutscene.Restore() end
end

PatipanStudio.Move = { NoClipConnection = nil, FlyConnection = nil, FlyForce = nil, JumpConnection = nil }

function PatipanStudio.Move.ApplyWalkSpeed()
    local hum = PatipanStudio.Player.Humanoid
    if hum and PatipanStudio.Options.WalkSpeed then hum.WalkSpeed = PatipanStudio.Options.WalkSpeedValue end
end

function PatipanStudio.Move.SpeedStart()
    PatipanStudio.Options.WalkSpeed = true
    PatipanStudio.Move.ApplyWalkSpeed()
end

function PatipanStudio.Move.SpeedStop()
    PatipanStudio.Options.WalkSpeed = false
    local hum = PatipanStudio.Player.Humanoid
    if hum then hum.WalkSpeed = 16 end
end

function PatipanStudio.Move.JumpStart()
    PatipanStudio.Options.InfiniteJump = true
    if PatipanStudio.Move.JumpConnection then return end
    PatipanStudio.Move.JumpConnection = PatipanStudio:Connect(UserInputService.JumpRequest, function()
        local hum = PatipanStudio.Player.Humanoid
        if PatipanStudio.Options.InfiniteJump and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

function PatipanStudio.Move.JumpStop()
    PatipanStudio.Options.InfiniteJump = false
end

function PatipanStudio.Move.NoClipStart()
    PatipanStudio.Options.NoClip = true
    if PatipanStudio.Move.NoClipConnection then return end
    PatipanStudio.Move.NoClipConnection = PatipanStudio:Connect(RunService.Stepped, function()
        local char = PatipanStudio.Player.Character
        if not (PatipanStudio.Options.NoClip and char) then return end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
end

function PatipanStudio.Move.NoClipStop()
    PatipanStudio.Options.NoClip = false
    local char = PatipanStudio.Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CanCollide = true end
end

function PatipanStudio.Move.FlyStart()
    if PatipanStudio.Move.FlyForce then return end
    local hrp = PatipanStudio.Player.Root
    if not hrp then return end
    PatipanStudio.Options.Fly = true

    local force = Instance.new("BodyVelocity")
    force.MaxForce = Vector3.one * 9e9
    force.Velocity = Vector3.zero
    force.Parent = hrp
    PatipanStudio.Move.FlyForce = force

    if PatipanStudio.Move.FlyConnection then return end
    PatipanStudio.Move.FlyConnection = PatipanStudio:Connect(RunService.RenderStepped, function()
        local bv = PatipanStudio.Move.FlyForce
        if not (PatipanStudio.Options.Fly and bv) then return end
        local look = Workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= look.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += look.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * PatipanStudio.Options.FlySpeed or Vector3.zero
    end)
end

function PatipanStudio.Move.FlyStop()
    PatipanStudio.Options.Fly = false
    if PatipanStudio.Move.FlyForce then
        PatipanStudio.Move.FlyForce:Destroy()
        PatipanStudio.Move.FlyForce = nil
    end
end

function PatipanStudio.Move.Rebind()
    PatipanStudio.Move.ApplyWalkSpeed()
    if PatipanStudio.Options.Fly then
        PatipanStudio.Move.FlyForce = nil
        PatipanStudio.Move.FlyStart()
    end
end

PatipanStudio.Roll = { Status = "Off", Session = 0, LastRolls = nil, StorageFull = false, NextAt = 0 }

---@return number  seconds the server holds a roll back after an accepted one
function PatipanStudio.Roll.Duration()
    local buffs = GameLib.Buffs
    if not buffs then return 0 end
    local ok, duration = pcall(buffs.GetBuff, "Roll Duration")
    return ok and tonumber(duration) or 0
end

---@return boolean, number, number  room left for a roll, units held, units the server allows
function PatipanStudio.Roll.Room()
    local buffs = GameLib.Buffs
    if not buffs then return true, 0, 0 end
    local okStorage, storage = pcall(buffs.GetBuff, "Unit Storage")
    local okRolls, rolls = pcall(buffs.GetBuff, "Rolls")
    storage, rolls = tonumber(okStorage and storage), tonumber(okRolls and rolls)
    if not storage or not rolls then return true, 0, 0 end
    local limit = storage + rolls - 1
    local held = PatipanStudio.Data.UnitCount()
    return held < limit, held, limit
end

function PatipanStudio.Roll.SetStorageFull(full, held, limit)
    if full == PatipanStudio.Roll.StorageFull then return end
    PatipanStudio.Roll.StorageFull = full
    if not full then return end
    table.insert(PatipanStudio.State.Notices, {
        "Unit storage full",
        string.format("%d/%d units. Rolling paused until you sell or clear some.", held, limit),
    })
end

function PatipanStudio.Roll.Once()
    return PatipanStudio.Net.Invoke("RollService.RF.RollDice")
end

function PatipanStudio.Roll.ResetCounter()
    PatipanStudio.Roll.Session = 0
    PatipanStudio.Roll.LastRolls = PatipanStudio.Data.Rolls()
end

function PatipanStudio.Roll.Track()
    local rolls = PatipanStudio.Data.Rolls()
    if PatipanStudio.Roll.LastRolls and rolls > PatipanStudio.Roll.LastRolls then
        PatipanStudio.Roll.Session += rolls - PatipanStudio.Roll.LastRolls
    end
    PatipanStudio.Roll.LastRolls = rolls
end

function PatipanStudio.Roll.Step()
    PatipanStudio.Roll.Track()
    if not PatipanStudio.Options.AutoRoll then
        PatipanStudio.Roll.Status = "Off"
        PatipanStudio.Roll.StorageFull = false
        return
    end
    local hasRoom, held, limit = PatipanStudio.Roll.Room()
    PatipanStudio.Roll.SetStorageFull(not hasRoom, held, limit)
    if not hasRoom then
        PatipanStudio.Roll.Status = string.format("Storage full %d/%d, paused", held, limit)
        return
    end
    PatipanStudio.Roll.Status = "Rolling"
    if osClock() < PatipanStudio.Roll.NextAt then return end
    local ok, reply = PatipanStudio.Roll.Once()
    if ok and reply ~= nil then
        PatipanStudio.Roll.NextAt = osClock() + math.max(PatipanStudio.Roll.Duration() - PatipanStudio.Config.RollLead, 0)
    end
end

function PatipanStudio.Roll.GetStatus()
    return string.format("%s · session %s · total %s", PatipanStudio.Roll.Status,
        Util.FormatNumber(PatipanStudio.Roll.Session), Util.FormatNumber(PatipanStudio.Data.Rolls()))
end

PatipanStudio.Plot = { Status = "Off" }

function PatipanStudio.Plot.CollectNow()
    for index, slot in pairs(PatipanStudio.Data.Table("Slots")) do
        local balance = type(slot) == "table" and tonumber(slot.balance) or 0
        if balance > 0 then
            PatipanStudio.Net.Fire("PlotService.RE.CollectBalance", tonumber(index))
            PatipanStudio.Economy.Collected += balance
        end
    end
end

---@return number  highest level whose price still pays back within the payback limit
function PatipanStudio.Plot.WorthLevel(unit, mult)
    local config = GameLib.EntryOf(unit.Name)
    if not config then return unit.Level end
    local gain = (PatipanStudio.Data.IncomeAt(config, unit.Attr, 2) - unit.Potential) * mult
    if gain <= 0 then return unit.Level end
    local cap = math.min(PatipanStudio.Options.LevelTarget, 500)
    local level = 1
    while level < cap and PatipanStudio.Data.LevelPrice(unit, level) / gain <= PatipanStudio.Options.LevelPayback do
        level += 1
    end
    return level
end

---@return number  income this unit reaches on the plot once cheap levels are bought
function PatipanStudio.Plot.Score(unit, mult)
    local config = GameLib.EntryOf(unit.Name)
    if not config then return unit.Value end
    local level = math.max(unit.Level, PatipanStudio.Plot.WorthLevel(unit, mult))
    return level == unit.Level and unit.Value or PatipanStudio.Data.IncomeAt(config, unit.Attr, level)
end

---@return table[]  { slot, placeKey } swaps that raise plot income, weakest slot first
function PatipanStudio.Plot.PlanSwaps()
    local slots = PatipanStudio.Data.Table("Slots")
    local byKey = {}
    for _, unit in ipairs(PatipanStudio.Data.Units()) do byKey[unit.Key] = unit end

    local mult = PatipanStudio.Economy.Multiplier()
    local current, placed = {}, {}
    for index, slot in pairs(slots) do
        if type(slot) ~= "table" then continue end
        local unit = slot.unitId and byKey[tostring(slot.unitId)]
        current[#current + 1] = { tonumber(index), unit and PatipanStudio.Plot.Score(unit, mult) or 0 }
        if unit then placed[unit.Key] = true end
    end
    table.sort(current, function(a, b) return a[2] < b[2] end)

    local bench = {}
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if not placed[unit.Key] then bench[#bench + 1] = unit end
    end
    table.sort(bench, function(a, b) return a.Potential > b.Potential end)
    for index = #bench, #current * 2 + 1, -1 do bench[index] = nil end
    for _, unit in ipairs(bench) do unit.Score = PatipanStudio.Plot.Score(unit, mult) end
    table.sort(bench, function(a, b) return a.Score > b.Score end)

    local swaps = {}
    for index, slot in ipairs(current) do
        local candidate = bench[index]
        if not candidate or candidate.Score < slot[2] * PatipanStudio.Config.SwapMargin then break end
        swaps[#swaps + 1] = { slot[1], candidate.Key }
    end
    return swaps
end

---@return number  units moved onto the plot
function PatipanStudio.Plot.EquipBest()
    if PatipanStudio.Options.PlacementMode ~= "Potential" then
        PatipanStudio.Net.Fire("PlotService.RE.EquipBest")
        return 0
    end
    local moved = 0
    for _, swap in ipairs(PatipanStudio.Plot.PlanSwaps()) do
        if moved >= PatipanStudio.Config.SwapsPerPass then break end
        PatipanStudio.Net.Fire("PlotService.RE.CollectBalance", swap[1])
        local ok, held = PatipanStudio.Net.Invoke("UnitService.RF.Equip", swap[2])
        if not (ok and held) then break end
        task.wait(PatipanStudio.Config.PlaceDelay)
        PatipanStudio.Net.Fire("PlotService.RE.InteractSlot", swap[1])
        moved += 1
        task.wait(PatipanStudio.Config.PlaceDelay)
    end
    if moved > 0 then PatipanStudio.Data.Invalidate() end
    PatipanStudio.Plot.Status = moved > 0 and (moved .. " better units placed") or "Best units placed"
    return moved
end

function PatipanStudio.Plot.CollectStep()
    if PatipanStudio.Options.AutoCollect then PatipanStudio.Plot.CollectNow() end
end

function PatipanStudio.Plot.EquipStep()
    if PatipanStudio.Options.EquipBestUnitsAuto then PatipanStudio.Plot.EquipBest() end
end

---@return table[]  { slot, price, payback } for plotted units, fastest payback first
function PatipanStudio.Plot.LevelCandidates()
    local byKey = {}
    for _, unit in ipairs(PatipanStudio.Data.Units()) do byKey[unit.Key] = unit end
    local minRarity = GameLib.RarityOrder(PatipanStudio.Options.LevelMinRarity)
    local mult = PatipanStudio.Economy.Multiplier()
    local list = {}

    for index, slot in pairs(PatipanStudio.Data.Table("Slots")) do
        local unit = type(slot) == "table" and slot.unitId and byKey[tostring(slot.unitId)]
        if not unit or unit.Level >= PatipanStudio.Options.LevelTarget or GameLib.RarityOrder(unit.Rarity) < minRarity then continue end
        local config = GameLib.EntryOf(unit.Name)
        local okPrice, price = pcall(GameLib.UnitUtil.GetLevelPrice, unit.Name, unit.Attr)
        local nextAttrs = table.clone(unit.Attr)
        nextAttrs.level = unit.Level + 1
        local okGain, nextIncome = pcall(config.income, nextAttrs)
        local gain = okGain and ((tonumber(nextIncome) or 0) - unit.Value) * mult or 0
        if okPrice and tonumber(price) and gain > 0 then
            list[#list + 1] = { tonumber(index), price, price / gain }
        end
    end
    table.sort(list, function(a, b) return a[3] < b[3] end)
    return list
end

---@param ignoreGoal boolean?  manual pass: skip saving for dice/rebirth
---@return number  levels bought
function PatipanStudio.Plot.LevelPass(ignoreGoal)
    local money = PatipanStudio.Data.Money()
    local goal = not ignoreGoal and PatipanStudio.Economy.Goal()
    local levelled = 0

    for _, pick in ipairs(PatipanStudio.Plot.LevelCandidates()) do
        local slot, price, payback = pick[1], pick[2], pick[3]
        if payback > PatipanStudio.Options.LevelPayback then break end
        if price > money then continue end
        if goal and money - price < goal.Cost and payback >= PatipanStudio.Economy.Eta(goal.Cost, money - price) then continue end
        PatipanStudio.Net.Fire("PlotService.RE.LevelUpSlot", slot)
        money -= price
        levelled += 1
        task.wait(PatipanStudio.Config.LevelDelay)
    end
    PatipanStudio.Plot.Status = levelled > 0 and (levelled .. " levelled") or (goal and ("Saving for " .. goal.Name) or "No level worth it")
    return levelled
end

PatipanStudio.Economy = { Rate = 0, Collected = 0, LastTotal = nil, LastAt = 0, Earned = 0 }

function PatipanStudio.Economy.Sample()
    local total = 0
    for _, slot in pairs(PatipanStudio.Data.Table("Slots")) do
        if type(slot) == "table" then total += tonumber(slot.balance) or 0 end
    end
    local economy, now = PatipanStudio.Economy, osClock()
    if economy.LastTotal and now > economy.LastAt then
        local earned = total + economy.Collected - economy.LastTotal
        local sample = earned / (now - economy.LastAt)
        if sample >= 0 then
            economy.Rate = economy.Rate == 0 and sample or economy.Rate * 0.8 + sample * 0.2
            economy.Earned += earned
        end
    end
    economy.LastTotal, economy.LastAt, economy.Collected = total, now, 0
end

---@return number  real money per second divided by the plotted units' raw income
function PatipanStudio.Economy.Multiplier()
    local plotted = {}
    for _, slot in pairs(PatipanStudio.Data.Table("Slots")) do
        if type(slot) == "table" and slot.unitId then plotted[tostring(slot.unitId)] = true end
    end
    local raw = 0
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if plotted[unit.Key] then raw += unit.Value end
    end
    return (raw > 0 and PatipanStudio.Economy.Rate > 0) and PatipanStudio.Economy.Rate / raw or 1
end

---@return table?  cheapest enabled goal {Name, Cost} still out of reach
function PatipanStudio.Economy.Goal()
    local goals = {}
    if PatipanStudio.Options.AutoRebirth then
        local rebirth = PatipanStudio.Rebirth.Next()
        if rebirth then goals[#goals + 1] = { Name = "rebirth", Cost = tonumber(rebirth.cost) or math.huge } end
    end
    if PatipanStudio.Options.AutoBuyDice then
        local name, price = PatipanStudio.Dice.NextTarget()
        if name then goals[#goals + 1] = { Name = name .. " dice", Cost = price } end
    end
    table.sort(goals, function(a, b) return a.Cost < b.Cost end)
    return goals[1]
end

function PatipanStudio.Economy.Eta(cost, money)
    local rate = PatipanStudio.Economy.Rate
    if cost <= money then return 0 end
    return rate > 0 and (cost - money) / rate or math.huge
end

function PatipanStudio.Economy.Step()
    PatipanStudio.Economy.Sample()
    local options = PatipanStudio.Options
    if options.AutoBuyDice or options.AutoEquipBestDice then PatipanStudio.Dice.Step() end
    if options.AutoRebirth then PatipanStudio.Rebirth.RebirthNow() end
    if options.AutoRebirthStats then PatipanStudio.Rebirth.SpendPoints() end
    if options.AutoBuyUpgrades then PatipanStudio.Upgrade.BuyAll() end
    if options.AutoLevelUp then PatipanStudio.Plot.LevelPass() end
end

function PatipanStudio.Economy.GetStatus()
    local goal = PatipanStudio.Economy.Goal()
    local text = "Income " .. Util.FormatNumber(PatipanStudio.Economy.Rate) .. "/s"
    if not goal then return text end
    local eta = PatipanStudio.Economy.Eta(goal.Cost, PatipanStudio.Data.Money())
    local etaText = eta == math.huge and "?" or (eta < 60 and string.format("%ds", eta) or string.format("%dm", math.floor(eta / 60)))
    return string.format("%s · %s in %s", text, goal.Name, etaText)
end

PatipanStudio.Dice = { Status = "Off" }

---@return string, number  free starter dice (cheapest in the shop) and its luck
function PatipanStudio.Dice.Starter()
    local name, price, luck = "Basic", math.huge, 1
    for diceName, info in pairs(GameLib.Dice and GameLib.Dice.GetAll() or {}) do
        local cost = tonumber(info.price) or 0
        if cost < price then name, price, luck = diceName, cost, tonumber(info.luck) or 1 end
    end
    return name, luck
end

function PatipanStudio.Dice.OwnedSet()
    local owned = { [PatipanStudio.Dice.Starter()] = true }
    for key, value in pairs(PatipanStudio.Data.Table("OwnedDice")) do
        if type(key) == "number" then owned[value] = true elseif value then owned[key] = true end
    end
    return owned
end

---@return string, number  best owned dice and its luck
function PatipanStudio.Dice.BestOwned()
    local owned = PatipanStudio.Dice.OwnedSet()
    local bestName, bestLuck = PatipanStudio.Dice.Starter()
    for name, info in pairs(GameLib.Dice and GameLib.Dice.GetAll() or {}) do
        local luck = tonumber(info.luck) or 0
        if owned[name] and luck > bestLuck then bestName, bestLuck = name, luck end
    end
    return bestName, bestLuck
end

---@return string?  highest-luck dice affordable now that beats the best owned
function PatipanStudio.Dice.NextBuy()
    local owned = PatipanStudio.Dice.OwnedSet()
    local money = PatipanStudio.Data.Money()
    local _, pickLuck = PatipanStudio.Dice.BestOwned()
    local pick
    for name, info in pairs(GameLib.Dice and GameLib.Dice.GetAll() or {}) do
        local luck = tonumber(info.luck) or 0
        if not owned[name] and (tonumber(info.price) or math.huge) <= money and luck > pickLuck then
            pick, pickLuck = name, luck
        end
    end
    return pick
end

---@return string?, number  cheapest unowned dice luckier than the best owned
function PatipanStudio.Dice.NextTarget()
    local owned = PatipanStudio.Dice.OwnedSet()
    local _, bestLuck = PatipanStudio.Dice.BestOwned()
    local pick, pickPrice = nil, math.huge
    for name, info in pairs(GameLib.Dice and GameLib.Dice.GetAll() or {}) do
        local price = tonumber(info.price) or math.huge
        if not owned[name] and (tonumber(info.luck) or 0) > bestLuck and price < pickPrice then pick, pickPrice = name, price end
    end
    return pick, pickPrice
end

function PatipanStudio.Dice.EquipBest()
    local best = PatipanStudio.Dice.BestOwned()
    if best ~= PatipanStudio.Data.Read("Dice") then PatipanStudio.Net.Fire("DiceShopService.RE.EquipDice", best) end
end

function PatipanStudio.Dice.Step()
    if PatipanStudio.Options.AutoBuyDice then
        local buy = PatipanStudio.Dice.NextBuy()
        if buy then
            PatipanStudio.Net.Fire("DiceShopService.RE.BuyDice", buy)
            PatipanStudio.Dice.Status = "Bought " .. buy
            task.wait(PatipanStudio.Config.BuyDelay)
        end
    end
    if PatipanStudio.Options.AutoEquipBestDice or PatipanStudio.Options.AutoBuyDice then PatipanStudio.Dice.EquipBest() end
end

PatipanStudio.Upgrade = { Status = "Off" }

function PatipanStudio.Upgrade.Branch(name)
    return (name:gsub("%s+[IVXLC]+$", ""))
end

function PatipanStudio.Upgrade.Branches()
    local seen = {}
    for name in pairs(GameLib.Upgrades or {}) do
        if type(name) == "string" and name ~= "Start" then seen[PatipanStudio.Upgrade.Branch(name)] = true end
    end
    return Util.SortedKeys(seen)
end

---@return table  stat -> { base, percentage } summed over owned upgrades
function PatipanStudio.Upgrade.OwnedBuffs(owned)
    local sums = {}
    for name in pairs(owned) do
        local info = GameLib.Upgrades and GameLib.Upgrades[name]
        for stat, buff in pairs(type(info) == "table" and info.buffs or {}) do
            sums[stat] = sums[stat] or { base = 0, percentage = 0 }
            if sums[stat][buff.bucket] then sums[stat][buff.bucket] += tonumber(buff.amount) or 0 end
        end
    end
    return sums
end

---@return number  relative boost this buff adds to its stat (0.1 = +10%)
function PatipanStudio.Upgrade.Gain(stat, buff, sums)
    local amount = tonumber(buff.amount) or 0
    local sum = sums[stat] or { base = 0, percentage = 0 }
    if stat == "Roll Duration" then
        local ok, duration = pcall(GameLib.Buffs.GetBuff, stat)
        duration = ok and tonumber(duration) or 0
        return duration + amount > 0 and duration / (duration + amount) - 1 or 0
    end
    if buff.bucket == "percentage" then return amount / (1 + sum.percentage) end
    if buff.bucket == "multiplier" then return amount - 1 end
    local ok, config = pcall(GameLib.BuffsConfig.GetBuff, stat)
    local default = ok and type(config) == "table" and tonumber(config.default) or 1
    return amount / math.max(default + sum.base, 1e-3)
end

---@return number?  money spent per +1% luck on the next dice, nil when dice are maxed
function PatipanStudio.Upgrade.DiceDeal()
    local name, price = PatipanStudio.Dice.NextTarget()
    if not name then return nil end
    local _, bestLuck = PatipanStudio.Dice.BestOwned()
    local luck = tonumber(GameLib.Dice.GetAll()[name].luck) or bestLuck
    return price / math.max(luck / bestLuck - 1, 1e-3)
end

---@return boolean  price is a small slice of what the player earns
function PatipanStudio.Upgrade.Cheap(stat, price, money, rate)
    local seconds = PatipanStudio.Config.UtilitySeconds
    if rate > 0 then return price <= rate * (seconds[stat] or seconds.Default) end
    return price <= money * PatipanStudio.Config.UtilityFallbackShare
end

---@return table[]  { name, price, rank } upgrades worth buying now, best first
function PatipanStudio.Upgrade.Worth()
    local owned = PatipanStudio.Data.Table("Upgrades")
    local sums = PatipanStudio.Upgrade.OwnedBuffs(owned)
    local money, rate = PatipanStudio.Data.Money(), PatipanStudio.Economy.Rate
    local goal = PatipanStudio.Economy.Goal()
    local diceDeal = PatipanStudio.Upgrade.DiceDeal()
    local filter = Util.SetFromList(PatipanStudio.Options.UpgradeFilter)
    local anyBranch = next(filter) == nil
    local tree = GameLib.Tree
    local picks = {}

    for name, info in pairs(GameLib.Upgrades or {}) do
        if type(info) ~= "table" or name == "Start" or owned[name] then continue end
        local price = tonumber(info.price) or math.huge
        if price > money or not (anyBranch or filter[PatipanStudio.Upgrade.Branch(name)]) then continue end
        local parent = tree.GetParent(name)
        if parent and parent ~= "Start" and not owned[parent] then continue end

        local rank
        for stat, buff in pairs(info.buffs or {}) do
            local gain = PatipanStudio.Upgrade.Gain(stat, buff, sums)
            if gain <= 0 then continue end
            if stat == "Money Multiplier" and rate > 0 then
                local payback = price / (rate * gain)
                local etaAfter = goal and PatipanStudio.Economy.Eta(goal.Cost, money - price) or math.huge
                if payback <= PatipanStudio.Options.UpgradePayback or payback < etaAfter then rank = payback end
            elseif PatipanStudio.Config.RollStats[stat] and diceDeal then
                if price / (gain * 100) <= diceDeal / 100 then rank = 1e6 + price / money end
            elseif PatipanStudio.Upgrade.Cheap(stat, price, money, rate) then
                rank = 2e6 + price / money
            end
        end
        if rank then picks[#picks + 1] = { name, price, rank } end
    end
    table.sort(picks, function(a, b) return a[3] < b[3] end)
    return picks
end

---@return string  cheapest upgrade still locked behind money
function PatipanStudio.Upgrade.NextHint()
    local owned = PatipanStudio.Data.Table("Upgrades")
    local pick, price = nil, math.huge
    for name, info in pairs(GameLib.Upgrades or {}) do
        if type(info) ~= "table" or name == "Start" or owned[name] then continue end
        local parent = GameLib.Tree.GetParent(name)
        if parent and parent ~= "Start" and not owned[parent] then continue end
        if (tonumber(info.price) or math.huge) < price then pick, price = name, tonumber(info.price) end
    end
    return pick and string.format("Next: %s at %s", pick, Util.FormatNumber(price)) or "All upgrades owned"
end

---@return number  upgrades bought
function PatipanStudio.Upgrade.BuyAll()
    local bought, spent = 0, 0
    for _, pick in ipairs(PatipanStudio.Upgrade.Worth()) do
        if pick[2] + spent > PatipanStudio.Data.Money() then continue end
        PatipanStudio.Net.Fire("RE.BuyUpgrade", pick[1])
        spent += pick[2]
        bought += 1
        task.wait(PatipanStudio.Config.BuyDelay)
    end
    PatipanStudio.Upgrade.Status = bought > 0 and (bought .. " bought") or PatipanStudio.Upgrade.NextHint()
    return bought
end

PatipanStudio.Sell = { Status = "Off" }

---@return string[]  unit keys to sell under the current filters
function PatipanStudio.Sell.Pick()
    local wanted = Util.SetFromList(PatipanStudio.Options.SellRarities)
    if next(wanted) == nil then return {} end
    local keepMutation = Util.SetFromList(PatipanStudio.Options.SellKeepMutations)
    local keep = math.max(PatipanStudio.Options.KeepPerRarity, 0)

    local byRarity = {}
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if unit.Busy or unit.Locked or not wanted[unit.Rarity] then continue end
        if unit.Mutation and keepMutation[unit.Mutation] then continue end
        byRarity[unit.Rarity] = byRarity[unit.Rarity] or {}
        table.insert(byRarity[unit.Rarity], unit)
    end

    local keys = {}
    for _, list in pairs(byRarity) do
        for index = keep + 1, #list do keys[#keys + 1] = list[index].Key end
    end
    return keys
end

function PatipanStudio.Sell.SellNow()
    local keys = PatipanStudio.Sell.Pick()
    if #keys == 0 then PatipanStudio.Sell.Status = "Nothing to sell" return PatipanStudio.Sell.Status end
    local before = PatipanStudio.Data.Money()
    PatipanStudio.Net.Invoke("SellService.RF.SellInventory", keys)
    PatipanStudio.Data.Invalidate()
    PatipanStudio.Sell.Status = string.format("%d sold (+%s)", #keys, Util.FormatNumber(PatipanStudio.Data.Money() - before))
    return PatipanStudio.Sell.Status
end

function PatipanStudio.Sell.Step()
    if PatipanStudio.Options.AutoSell then PatipanStudio.Sell.SellNow() end
end

PatipanStudio.Storage = { Status = "-" }

function PatipanStudio.Storage.Cap()
    local buffs = GameLib.Buffs
    local ok, cap = pcall(function() return buffs.GetBuff("Unit Storage") end)
    return ok and tonumber(cap) or math.huge
end

---@return number  units sold to make room for rolling
function PatipanStudio.Storage.Clear()
    local units = PatipanStudio.Data.Units()
    local cap = PatipanStudio.Storage.Cap()
    PatipanStudio.Storage.Status = string.format("%d/%s", #units, cap == math.huge and "?" or tostring(cap))
    if #units < cap - PatipanStudio.Config.StorageHeadroom then return 0 end

    local keepRank = GameLib.RarityOrder(PatipanStudio.Options.ClearKeepRarity)
    local keepMutation = Util.SetFromList(PatipanStudio.Options.SellKeepMutations)
    local spare = {}
    for _, unit in ipairs(units) do
        if unit.Busy or unit.Locked or (unit.Mutation and keepMutation[unit.Mutation]) then continue end
        if keepRank > 0 and GameLib.RarityOrder(unit.Rarity) >= keepRank then continue end
        spare[#spare + 1] = unit
    end
    table.sort(spare, function(a, b) return a.Potential < b.Potential end)

    local excess = #units - math.floor(cap * PatipanStudio.Config.StorageRefill)
    local keys = {}
    for index = 1, math.min(excess, #spare) do keys[index] = spare[index].Key end
    if #keys == 0 then PatipanStudio.Storage.Status ..= " · full, nothing sellable" return 0 end

    PatipanStudio.Net.Invoke("SellService.RF.SellInventory", keys)
    PatipanStudio.Data.Invalidate()
    return #keys
end

function PatipanStudio.Storage.Step()
    if PatipanStudio.Options.AutoClearStorage then PatipanStudio.Storage.Clear() end
end

PatipanStudio.Rebirth = { Status = "Off" }

---@return table?  next tier {cost, moneyMultiplier}, nil at max
function PatipanStudio.Rebirth.Next()
    local rebirths = GameLib.Rebirths
    if not rebirths then return nil end
    local ok, info = pcall(rebirths.GetNext, PatipanStudio.Data.Rebirth())
    return ok and type(info) == "table" and info or nil
end

function PatipanStudio.Rebirth.RebirthNow()
    local info = PatipanStudio.Rebirth.Next()
    if not info then PatipanStudio.Rebirth.Status = "Max rebirth" return false end
    if PatipanStudio.Data.Money() < (tonumber(info.cost) or math.huge) then
        PatipanStudio.Rebirth.Status = "Need " .. Util.FormatNumber(info.cost)
        return false
    end
    PatipanStudio.Net.Fire("RebirthService.RE.Rebirth")
    PatipanStudio.Rebirth.Status = "Rebirthed"
    return true
end

function PatipanStudio.Rebirth.PointsLeft()
    local config = GameLib.RebirthStats
    if not config then return 0 end
    local ok, left = pcall(config.GetRemaining, PatipanStudio.Data.Rebirth(), PatipanStudio.Data.Table("RebirthStats"))
    return ok and tonumber(left) or 0
end

---@return number  points spent
function PatipanStudio.Rebirth.SpendPoints()
    local stat = PatipanStudio.Options.RebirthStat
    local spent = 0
    while PatipanStudio.Rebirth.PointsLeft() > 0 and spent < 200 do
        local before = PatipanStudio.Rebirth.PointsLeft()
        PatipanStudio.Net.Fire("RebirthService.RE.AddStat", stat)
        task.wait(PatipanStudio.Config.StatDelay)
        if PatipanStudio.Rebirth.PointsLeft() >= before then
            task.wait(PatipanStudio.Config.StatDelay * 3)
            if PatipanStudio.Rebirth.PointsLeft() >= before then break end
        end
        spent += 1
    end
    return spent
end

---@return boolean, string?  false and why when the reset can't run
function PatipanStudio.Rebirth.ResetStats()
    local config = GameLib.RebirthStats
    if not config then return false, "Stats not found" end
    if config.GetSpent(PatipanStudio.Data.Table("RebirthStats")) <= 0 then return false, "No points spent" end
    if PatipanStudio.Data.Token("Reset Token") < 1 then return false, "No Reset Token" end
    PatipanStudio.Net.Fire("RebirthService.RE.UseResetToken")
    return true
end

PatipanStudio.Grade = { Status = "Off" }

---@return table?  next unit that should be rerolled toward the target
function PatipanStudio.Grade.Pick()
    local target = GameLib.GradeOrder(PatipanStudio.Options.GradeTarget)
    local protected = PatipanStudio.Data.Table("ProtectedGrades")
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if not unit.Busy or unit.Locked or GameLib.GradeOrder(unit.Grade) >= target then continue end
        if unit.Grade and protected[unit.Grade] and not PatipanStudio.Options.GradeOverwrite then continue end
        return unit
    end
    return nil
end

function PatipanStudio.Grade.RollOne()
    if PatipanStudio.Data.Token("Gems") < 1 then PatipanStudio.Grade.Status = "No Gems" return false end
    local unit = PatipanStudio.Grade.Pick()
    if not unit then PatipanStudio.Grade.Status = "All at target" return false end
    PatipanStudio.Net.Fire("GradeService.RE.Roll", unit.Key)
    PatipanStudio.Grade.Status = string.format("%s [%s]", unit.Name, unit.Grade or "-")
    return true
end

function PatipanStudio.Grade.Step()
    if PatipanStudio.Options.AutoGrade then PatipanStudio.Grade.RollOne() end
end

PatipanStudio.Trait = { Status = "Off" }

function PatipanStudio.Trait.Pick()
    local target = GameLib.TraitPower(PatipanStudio.Options.TraitTarget)
    local protected = PatipanStudio.Data.Table("ProtectedTraits")
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if not unit.Busy or unit.Locked or GameLib.TraitPower(unit.Trait) >= target then continue end
        if unit.Trait and protected[unit.Trait] and not PatipanStudio.Options.TraitOverwrite then continue end
        return unit
    end
    return nil
end

function PatipanStudio.Trait.RollOne()
    if PatipanStudio.Data.Token("Trait Reroll") < 1 then PatipanStudio.Trait.Status = "No Trait Reroll" return false end
    local unit = PatipanStudio.Trait.Pick()
    if not unit then PatipanStudio.Trait.Status = "All at target" return false end
    PatipanStudio.Net.Fire("TraitService.RE.Roll", unit.Key)
    PatipanStudio.Trait.Status = string.format("%s [%s]", unit.Name, unit.Trait or "-")
    return true
end

function PatipanStudio.Trait.Step()
    if PatipanStudio.Options.AutoTrait then PatipanStudio.Trait.RollOne() end
end

PatipanStudio.Fuse = { Status = "Off" }

---@return table[]  spare units the game allows to fuse, rarest first
function PatipanStudio.Fuse.Pool()
    local wanted = Util.SetFromList(PatipanStudio.Options.FuseRarities)
    local anyRarity = next(wanted) == nil
    local keepRank = GameLib.RarityOrder(PatipanStudio.Options.ClearKeepRarity)
    local keepMutation = Util.SetFromList(PatipanStudio.Options.SellKeepMutations)
    local pool = {}
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if unit.Busy or unit.Locked or not unit.Chance then continue end
        if unit.Mutation and keepMutation[unit.Mutation] then continue end
        if anyRarity and keepRank > 0 and GameLib.RarityOrder(unit.Rarity) >= keepRank then continue end
        if anyRarity or wanted[unit.Rarity] then pool[#pool + 1] = unit end
    end
    table.sort(pool, function(a, b) return a.Chance > b.Chance end)
    return pool
end

---@return table?  three keys whose expected result is clearly rarer than the best input and cheap to fuse
function PatipanStudio.Fuse.PickTrio()
    local pool = PatipanStudio.Fuse.Pool()
    local config = GameLib.FusingConfig
    local average = tonumber(config.AverageMultiplier) or 0.667
    local budget = PatipanStudio.Data.Money() * PatipanStudio.Config.FuseMoneyShare
    for index = 1, #pool - 2 do
        local a, b, c = pool[index], pool[index + 1], pool[index + 2]
        local sum = a.Chance + b.Chance + c.Chance
        local ok, cost = pcall(config.GetCost, sum)
        if sum * average >= a.Chance * PatipanStudio.Config.FuseGain and ok and cost <= budget then
            return { a.Key, b.Key, c.Key, a.Name }
        end
    end
    return nil
end

function PatipanStudio.Fuse.FuseNow()
    local trio = PatipanStudio.Fuse.PickTrio()
    if not trio then PatipanStudio.Fuse.Status = "No worthwhile trio" return false end
    PatipanStudio.Net.Fire("FusingService.RE.Fuse", trio[1], trio[2], trio[3])
    PatipanStudio.Data.Invalidate()
    PatipanStudio.Fuse.Status = "Fused " .. trio[4] .. " +2"
    return true
end

function PatipanStudio.Fuse.Step()
    if PatipanStudio.Options.AutoFuse then PatipanStudio.Fuse.FuseNow() end
end

PatipanStudio.Tower = { Status = "Off", State = "Idle", NextAt = 0, Floor = 0, Best = 0, Runs = 0, Misses = 0, Ending = false }

---@return string[]  "Tower (Difficulty)" labels, easiest first
function PatipanStudio.Tower.Labels()
    local towers = GameLib.Towers and GameLib.Towers.GetAll() or {}
    local names = {}
    for name in pairs(towers) do names[#names + 1] = name end
    table.sort(names, function(a, b) return (tonumber(towers[a].order) or 0) < (tonumber(towers[b].order) or 0) end)
    local labels = {}
    for _, name in ipairs(names) do
        local difficulty = type(towers[name].difficulty) == "table" and towers[name].difficulty.name or "?"
        labels[#labels + 1] = string.format("%s (%s)", name, difficulty)
    end
    return labels
end

function PatipanStudio.Tower.NameFromLabel(label)
    return (tostring(label):gsub("%s*%b()$", ""))
end

function PatipanStudio.Tower.EquipTeam()
    PatipanStudio.Net.Fire("Towers.RE.EquipBestTowerTeam")
end

---@return number  seconds the server needs to play the returned actions
function PatipanStudio.Tower.Duration(actions)
    local total = 0
    for _, action in ipairs(actions) do
        total += PatipanStudio.Config.TowerActionTime[action.action] or 0.3
    end
    return total
end

---@return string[]  tower names, easiest first
function PatipanStudio.Tower.Order()
    local towers = GameLib.Towers and GameLib.Towers.GetAll() or {}
    local names = {}
    for name in pairs(towers) do names[#names + 1] = name end
    table.sort(names, function(a, b) return (tonumber(towers[a].order) or 0) < (tonumber(towers[b].order) or 0) end)
    return names
end

---@param floor number?  floor the last run reached, nil when the tower could not be entered
function PatipanStudio.Tower.Adapt(floor)
    if not PatipanStudio.Options.TowerSmart then return end
    local order = PatipanStudio.Tower.Order()
    local index = table.find(order, PatipanStudio.Options.TowerName) or 1
    local info = GameLib.Towers.Get(PatipanStudio.Options.TowerName)
    local top = math.min(tonumber(info and info.maxFloors) or math.huge, PatipanStudio.Options.TowerStopFloor)
    if floor and floor >= top and order[index + 1] then
        index += 1
    elseif (not floor or floor < PatipanStudio.Config.TowerDemoteFloor) and index > 1 then
        index -= 1
    end
    PatipanStudio.Options.TowerName = order[index]
end

function PatipanStudio.Tower.Leave()
    if PatipanStudio.Tower.Ending then return end
    PatipanStudio.Tower.Ending = true
    PatipanStudio.Net.Invoke("Towers.RF.CancelTower")
end

function PatipanStudio.Tower.Start()
    local now = osClock()
    if PatipanStudio.Options.TowerReequip or PatipanStudio.Tower.Runs == 0 then
        PatipanStudio.Tower.EquipTeam()
        task.wait(0.4)
    end
    local _, started = PatipanStudio.Net.Invoke("Towers.RF.PlayTower", PatipanStudio.Options.TowerName)
    PatipanStudio.Tower.State = "Climbing"
    PatipanStudio.Tower.Floor = 0
    PatipanStudio.Tower.Ending = not started
    PatipanStudio.Tower.NextAt = now
    PatipanStudio.Tower.Status = started and ("Entered " .. PatipanStudio.Options.TowerName) or "Finishing previous run"
end

function PatipanStudio.Tower.Climb()
    local ok, actions = PatipanStudio.Net.Invoke("Towers.RF.CompleteTowerFloor")
    local now = osClock()
    if not ok or type(actions) ~= "table" or #actions == 0 then
        PatipanStudio.Tower.Misses += 1
        PatipanStudio.Tower.NextAt = now + PatipanStudio.Config.TowerRetry
        if PatipanStudio.Tower.Misses >= 20 then
            PatipanStudio.Tower.Misses = 0
            PatipanStudio.Tower.Adapt(nil)
            PatipanStudio.Tower.State = "Idle"
            PatipanStudio.Tower.NextAt = now + PatipanStudio.Config.TowerStartCooldown
        end
        return
    end
    PatipanStudio.Tower.Misses = 0

    for _, action in ipairs(actions) do
        if tonumber(action.floor) then PatipanStudio.Tower.Floor = math.max(PatipanStudio.Tower.Floor, action.floor) end
    end
    PatipanStudio.Tower.Best = math.max(PatipanStudio.Tower.Best, PatipanStudio.Tower.Floor)
    PatipanStudio.Tower.NextAt = now + PatipanStudio.Tower.Duration(actions)

    if actions[#actions].action == "ended" then
        PatipanStudio.Tower.Runs += 1
        PatipanStudio.Tower.State = "Idle"
        PatipanStudio.Tower.Ending = false
        PatipanStudio.Tower.NextAt += PatipanStudio.Config.TowerStartCooldown
        PatipanStudio.Tower.Status = string.format("Run %d ended at floor %d", PatipanStudio.Tower.Runs, PatipanStudio.Tower.Floor)
        PatipanStudio.Tower.Adapt(PatipanStudio.Tower.Floor)
        return
    end
    if PatipanStudio.Tower.Floor >= PatipanStudio.Options.TowerStopFloor then PatipanStudio.Tower.Leave() end
    PatipanStudio.Tower.Status = string.format("%s · floor %d", PatipanStudio.Options.TowerName, PatipanStudio.Tower.Floor)
end

function PatipanStudio.Tower.Step()
    local tower = PatipanStudio.Tower
    if osClock() < tower.NextAt then return end
    if not PatipanStudio.Options.AutoTower then
        if tower.State == "Idle" then tower.Status = "Off" return end
        tower.Leave()
        tower.Climb()
        return
    end
    if tower.State == "Idle" then tower.Start() else tower.Climb() end
end

function PatipanStudio.Tower.GetStatus()
    if not PatipanStudio.Options.AutoTower then return "Off" end
    return string.format("%s · best %d · runs %d", PatipanStudio.Tower.Status, PatipanStudio.Tower.Best, PatipanStudio.Tower.Runs)
end

PatipanStudio.Gear = { Status = "Off" }

---@return number  slots changed
function PatipanStudio.Gear.EquipBest()
    local best = {}
    for _, item in ipairs(PatipanStudio.Data.ItemsOfKind("Gear")) do
        local config = GameLib.EntryOf(item.Name)
        local slot = config and config.slot
        if not slot then continue end
        local rank = GameLib.RarityOrder(config.rarity)
        if not best[slot] or rank > best[slot][2] then best[slot] = { item.Name, rank } end
    end

    local equipped = PatipanStudio.Data.Table("EquippedGear")
    local changed = 0
    for slot, pick in pairs(best) do
        if equipped[slot] ~= pick[1] then
            PatipanStudio.Net.Fire("GearService.RE.Equip", slot, pick[1])
            changed += 1
            task.wait(PatipanStudio.Config.GradeDelay)
        end
    end
    PatipanStudio.Gear.Status = changed > 0 and (changed .. " slots upgraded") or "Best gear on"
    return changed
end

function PatipanStudio.Gear.Step()
    if PatipanStudio.Options.AutoGear then PatipanStudio.Gear.EquipBest() end
end

PatipanStudio.Items = { Status = "Off" }

---@return boolean  true while the potion's effect is actually being used
function PatipanStudio.Items.PotionUseful(name)
    local towerWord = name:match("^(%a+)%s+%a+%s+[IVX]+$")
    if towerWord then
        return PatipanStudio.Options.AutoTower and PatipanStudio.Tower.State == "Climbing" and PatipanStudio.Options.TowerName:find(towerWord) ~= nil
    end
    if name:find("Luck") then return PatipanStudio.Options.AutoRoll end
    if name:find("Damage") then return PatipanStudio.Options.AutoTower end
    if name:find("Income") then return PatipanStudio.Economy.Rate > 0 end
    return true
end

---@param force boolean?  manual use: ignore timing
function PatipanStudio.Items.UsePotions(force)
    local filter = Util.SetFromList(PatipanStudio.Options.PotionFilter)
    local anyPotion = next(filter) == nil
    local active = PatipanStudio.Data.Table("ActiveEntries")
    local used = 0
    for _, item in ipairs(PatipanStudio.Data.ItemsOfKind("Boost")) do
        if not (force or PatipanStudio.Items.PotionUseful(item.Name)) then continue end
        if (anyPotion or filter[item.Name]) and not active[item.Name] then
            PatipanStudio.Net.Fire("BoostService.RE.Use", item.Key)
            used += 1
            task.wait(PatipanStudio.Config.ItemDelay)
        end
    end
    return used
end

function PatipanStudio.Items.UseSpins()
    local used = 0
    for _, item in ipairs(PatipanStudio.Data.ItemsOfKind("Spin")) do
        for _ = 1, math.min(item.Amount, 10) do
            PatipanStudio.Net.Fire("SpinService.RE.Use", item.Key)
            used += 1
            task.wait(PatipanStudio.Config.ItemDelay)
        end
    end
    return used
end

---@return number  gamepass items redeemed
function PatipanStudio.Items.UseGamepasses()
    local owned = PatipanStudio.Data.Table("OwnedGamepasses")
    local used = 0
    for _, item in ipairs(PatipanStudio.Data.ItemsOfKind("Gamepass")) do
        local config = GameLib.EntryOf(item.Name)
        if config and config.gamepass and owned[config.gamepass] then continue end
        PatipanStudio.Net.Fire("GamepassService.RE.Use", item.Key)
        used += 1
        task.wait(PatipanStudio.Config.ItemDelay)
    end
    return used
end

---@return number  ticket shop purchases made
function PatipanStudio.Items.BuyTicketShop()
    local wanted = Util.SetFromList(PatipanStudio.Options.TicketShopItems)
    if next(wanted) == nil then return 0 end
    local shop = GameLib.Quests and GameLib.Quests.Shop or {}
    local bought = 0
    for _, item in ipairs(shop) do
        if type(item) ~= "table" or not wanted[item.name] then continue end
        local cost = tonumber(item.tickets) or math.huge
        while PatipanStudio.Data.Token("Tickets") >= cost and bought < 50 do
            local before = PatipanStudio.Data.Token("Tickets")
            PatipanStudio.Net.Fire("QuestService.RE.Buy", item.name)
            bought += 1
            task.wait(PatipanStudio.Config.ItemDelay)
            if PatipanStudio.Data.Token("Tickets") >= before then break end
        end
    end
    return bought
end

function PatipanStudio.Items.Step()
    if PatipanStudio.Options.AutoPotion then PatipanStudio.Items.UsePotions() end
    if PatipanStudio.Options.AutoSpin then PatipanStudio.Items.UseSpins() end
    if PatipanStudio.Options.AutoGamepass then PatipanStudio.Items.UseGamepasses() end
    if PatipanStudio.Options.AutoTicketShop then PatipanStudio.Items.BuyTicketShop() end
end

PatipanStudio.Watch = { Seen = nil, Best = nil, Pulls = 0, StartAt = osClock(), StartGems = nil }

function PatipanStudio.Watch.Describe(unit)
    return string.format("%s [%s]%s", unit.Name, unit.Rarity or "?", unit.Mutation and (" · " .. unit.Mutation) or "")
end

function PatipanStudio.Watch.Alert(unit)
    local text = PatipanStudio.Watch.Describe(unit)
    pcall(function() PatipanStudio.Library:Notify("Rare pull", text, 8, "Success") end)
    local url = PatipanStudio.Options.WebhookUrl
    if type(url) ~= "string" or not url:find("^https://") or not Util.Request then return end
    local body = HttpService:JSONEncode({
        username = "PatipanStudio",
        embeds = { { title = "Anime Dice · rare pull", description = text, color = PatipanStudio.Config.WebhookColor } },
    })
    local ok, err = pcall(Util.Request, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
    if not ok then warn("[AnimeDice] webhook:", err) end
end

function PatipanStudio.Watch.OnNew(unit)
    local watch = PatipanStudio.Watch
    watch.Pulls += 1
    if not watch.Best or unit.Potential > watch.Best.Potential then watch.Best = unit end
    if not PatipanStudio.Options.RareNotify then return end
    local rarities = Util.SetFromList(PatipanStudio.Options.NotifyRarities)
    local mutations = Util.SetFromList(PatipanStudio.Options.NotifyMutations)
    if rarities[unit.Rarity] or (unit.Mutation and mutations[unit.Mutation]) then watch.Alert(unit) end
end

function PatipanStudio.Watch.Step()
    local watch = PatipanStudio.Watch
    local units = PatipanStudio.Data.Units()
    if not watch.Seen then
        watch.Seen, watch.StartGems = {}, PatipanStudio.Data.Token("Gems")
        for _, unit in ipairs(units) do watch.Seen[unit.Key] = true end
        return
    end
    for _, unit in ipairs(units) do
        if not watch.Seen[unit.Key] then
            watch.Seen[unit.Key] = true
            watch.OnNew(unit)
        end
    end
end

---@return string[]  lines for the stats panel
function PatipanStudio.Watch.Stats()
    local watch = PatipanStudio.Watch
    local hours = math.max(osClock() - watch.StartAt, 1) / 3600
    return {
        string.format("Money %s/h · Rolls %s/h", Util.FormatNumber(PatipanStudio.Economy.Earned / hours), Util.FormatNumber(PatipanStudio.Roll.Session / hours)),
        string.format("Pulls %d · Gems %+d · Tower runs %d", watch.Pulls, PatipanStudio.Data.Token("Gems") - (watch.StartGems or 0), PatipanStudio.Tower.Runs),
        "Best pull: " .. (watch.Best and PatipanStudio.Watch.Describe(watch.Best) or "-"),
    }
end

PatipanStudio.Lock = { Status = "Off" }

---@return number  units locked this pass
function PatipanStudio.Lock.Step()
    if not PatipanStudio.Options.AutoLock then return 0 end
    local rank = GameLib.RarityOrder(PatipanStudio.Options.LockRarity)
    local mutations = Util.SetFromList(PatipanStudio.Options.LockMutations)
    local keys, count = {}, 0
    for _, unit in ipairs(PatipanStudio.Data.Units()) do
        if unit.Locked then continue end
        if (rank > 0 and GameLib.RarityOrder(unit.Rarity) >= rank) or (unit.Mutation and mutations[unit.Mutation]) then
            keys[unit.Key] = true
            count += 1
        end
    end
    if count > 0 then
        PatipanStudio.Net.Fire("UnitService.RE.SetLocked", keys)
        PatipanStudio.Data.Invalidate()
    end
    PatipanStudio.Lock.Status = count > 0 and (count .. " locked") or "Nothing new to lock"
    return count
end

PatipanStudio.Rejoin = { Hooked = false, Busy = false }

function PatipanStudio.Rejoin.Now()
    if PatipanStudio.Rejoin.Busy then return end
    PatipanStudio.Rejoin.Busy = true
    if Util.QueueTeleport then
        local resume = PatipanStudio.Options.Kaitun and "getgenv().AnimeDiceResume = true " or ""
        pcall(Util.QueueTeleport, resume .. PatipanStudio.Config.ReloadSource)
    end
    local ok, err = pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
    if not ok then warn("[AnimeDice] rejoin:", err) end
    task.delay(PatipanStudio.Config.RejoinRetry, function() PatipanStudio.Rejoin.Busy = false end)
end

function PatipanStudio.Rejoin.Start()
    PatipanStudio.Options.AutoRejoin = true
    if PatipanStudio.Rejoin.Hooked then return end
    PatipanStudio.Rejoin.Hooked = true
    PatipanStudio:Connect(GuiService.ErrorMessageChanged, function(message)
        if PatipanStudio.Options.AutoRejoin and message ~= "" then task.delay(PatipanStudio.Config.RejoinDelay, PatipanStudio.Rejoin.Now) end
    end)
end

function PatipanStudio.Rejoin.Stop()
    PatipanStudio.Options.AutoRejoin = false
end

PatipanStudio.Rewards = { Status = "Off", DailyRetryAt = 0, Member = nil }

function PatipanStudio.Rewards.RedeemAll()
    local redeemed = PatipanStudio.Data.Table("RedeemedCodes")
    local sent = 0
    for code in pairs(GameLib.Codes or {}) do
        if type(code) == "string" and not redeemed[code] then
            PatipanStudio.Net.Fire("CodesService.RE.RedeemCode", code)
            sent += 1
            task.wait(PatipanStudio.Config.RedeemDelay)
        end
    end
    return sent > 0 and (sent .. " codes redeemed") or "All codes already redeemed"
end

---@return number  quests claimed
function PatipanStudio.Rewards.ClaimQuests()
    local periods = GameLib.Quests and GameLib.Quests.Periods
    local records = PatipanStudio.Data.Table("Quests")
    if type(periods) ~= "table" then return 0 end
    local claimedCount = 0
    for period, def in pairs(periods) do
        local record = records[period]
        if type(record) ~= "table" or type(def) ~= "table" then continue end
        local progress = type(record.progress) == "table" and record.progress or {}
        local claimed = type(record.claimed) == "table" and record.claimed or {}
        for _, quest in ipairs(def.quests or {}) do
            if not claimed[quest.id] and (tonumber(progress[quest.id]) or 0) >= (tonumber(quest.target) or math.huge) then
                PatipanStudio.Net.Fire("QuestService.RE.Claim", period, quest.id, record.expiresAt)
                claimedCount += 1
                task.wait(PatipanStudio.Config.ClaimDelay)
            end
        end
    end
    return claimedCount
end

function PatipanStudio.Rewards.ClaimOffline()
    if (tonumber(PatipanStudio.Data.Read("PendingOfflineEarnings")) or 0) > 0 then
        PatipanStudio.Net.Fire("OfflineEarningsService.RE.Claim")
    end
end

function PatipanStudio.Rewards.DailyReady()
    local cooldown = GameLib.Daily and tonumber(GameLib.Daily.Cooldown) or 82800
    local last = tonumber(PatipanStudio.Data.Read("LastDailyRewardClaim")) or 0
    return os.time() - last >= cooldown and osClock() >= PatipanStudio.Rewards.DailyRetryAt
end

function PatipanStudio.Rewards.InGroup()
    if PatipanStudio.Rewards.Member == nil then
        local groupId = GameLib.Group and tonumber(GameLib.Group.GroupId) or PatipanStudio.Config.GroupId
        local ok, member = pcall(LocalPlayer.IsInGroup, LocalPlayer, groupId)
        PatipanStudio.Rewards.Member = ok and member == true
    end
    return PatipanStudio.Rewards.Member
end

function PatipanStudio.Rewards.Step()
    if PatipanStudio.Options.AutoDaily and PatipanStudio.Rewards.DailyReady() then
        PatipanStudio.Rewards.DailyRetryAt = osClock() + 60
        PatipanStudio.Net.Fire("DailyRewardService.RE.Claim")
    end
    if PatipanStudio.Options.AutoGroup and not PatipanStudio.Data.Read("ClaimedGroupReward") and PatipanStudio.Rewards.InGroup() then
        PatipanStudio.Net.Fire("GroupRewardService.RE.Claim")
    end
    if PatipanStudio.Options.AutoOffline then PatipanStudio.Rewards.ClaimOffline() end
    if PatipanStudio.Options.AutoQuest then PatipanStudio.Rewards.ClaimQuests() end
end

PatipanStudio.Kaitun = { Status = "Off", Members = {
    "AntiAfk", "AutoRejoin", "RareNotify", "AutoLock", "TowerSmart", "AutoFuse", "DisableCutscene", "AutoRoll", "AutoCollect", "EquipBestUnitsAuto", "AutoLevelUp",
    "AutoBuyDice", "AutoEquipBestDice", "AutoBuyUpgrades", "AutoSell", "AutoRebirth", "AutoRebirthStats", "AutoGrade",
    "AutoTrait", "AutoTower", "AutoPotion", "AutoSpin", "AutoGamepass", "AutoTicketShop", "AutoDaily", "AutoGroup",
    "AutoOffline", "AutoQuest", "AutoGear", "AutoClearStorage",
} }

---@param fromTop boolean  take the rarest end instead of the commonest
---@return string[]        up to count names from a list sorted commonest first
function PatipanStudio.Kaitun.Slice(list, count, fromTop)
    local picked = {}
    local first = fromTop and math.max(#list - count + 1, 1) or 1
    for index = first, math.min(first + count - 1, #list) do
        table.insert(picked, list[index])
    end
    return picked
end

function PatipanStudio.Kaitun.SetMembers(on)
    local toggles = PatipanStudio.Library and PatipanStudio.Library.Toggles or {}
    for _, idx in ipairs(PatipanStudio.Kaitun.Members) do
        if toggles[idx] then toggles[idx]:SetValue(on) else PatipanStudio.Options[idx] = on end
    end
end

function PatipanStudio.Kaitun.Start()
    PatipanStudio.Options.Kaitun = true
    local options = PatipanStudio.Library and PatipanStudio.Library.Options or {}
    local function Default(idx, value)
        if next(Util.SetFromList(PatipanStudio.Options[idx])) ~= nil then return end
        if options[idx] then options[idx]:SetValue(Util.SetFromList(value)) end
        PatipanStudio.Options[idx] = value
    end
    local slice = PatipanStudio.Kaitun.Slice
    local lists = PatipanStudio.UI.Lists
    local rarities, mutations = lists.Rarities, lists.Mutations
    if table.find(GameLib.ShopNames(), "Gems") then Default("TicketShopItems", { "Gems" }) end
    Default("SellRarities", slice(rarities, 2))
    Default("LockMutations", slice(mutations, 3, true))
    Default("NotifyRarities", slice(rarities, 4, true))
    Default("NotifyMutations", slice(mutations, 2, true))
    if options.LevelTarget then options.LevelTarget:SetValue(200) end
    PatipanStudio.Options.LevelTarget = 200
    PatipanStudio.Kaitun.SetMembers(true)
    task.defer(function() PatipanStudio.Rewards.RedeemAll() end)
end

function PatipanStudio.Kaitun.Stop()
    PatipanStudio.Options.Kaitun = false
    PatipanStudio.Kaitun.SetMembers(false)
end

function PatipanStudio.Kaitun.GetStatus()
    return string.format("R%d · %s", PatipanStudio.Data.Rebirth(), PatipanStudio.Economy.GetStatus())
end

PatipanStudio.UI = { Labels = {}, Lists = { Rarities = {}, Mutations = {} } }
local Library, T

function PatipanStudio.UI.Detach(fn)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(fn, table.unpack(packed, 1, packed.n))
            if not ok then warn("[AnimeDice] ui: " .. tostring(err)) end
        end)
    end
end

---@param module table  feature with Start/Stop
function PatipanStudio.UI.StartStop(module)
    return PatipanStudio.UI.Detach(function(on)
        if on then module.Start() else module.Stop() end
    end)
end

function PatipanStudio.UI.Notify(title, text, kind)
    Library:Notify(title, tostring(text), 4, kind or "Info")
end

---@return table  list from a game-data source, empty when it errors
function PatipanStudio.UI.Values(source, ...)
    local ok, list = pcall(source, ...)
    return ok and type(list) == "table" and list or {}
end

---@param fallback number  index used when the game renamed or removed the preferred value
function PatipanStudio.UI.Prefer(values, preferred, fallback)
    if table.find(values, preferred) then return preferred end
    return values[math.clamp(fallback, 1, math.max(#values, 1))]
end

function PatipanStudio.UI.MultiDropdown(group, idx, text, desc, values)
    return group:AddDropdown(idx, {
        Text = text,
        Description = desc,
        Values = values,
        Multi = true,
        Default = {},
        AllowNull = true,
        Searchable = true,
    })
end

PatipanStudio.UI.Needs = {
    Kaitun = { "DataClient", "Entry" },
    AutoCollect = { "DataClient" },
    EquipBestUnitsAuto = { "DataClient", "Entry" },
    AutoLevelUp = { "DataClient", "Entry", "UnitUtil" },
    AutoTower = { "Towers" },
    AutoSell = { "DataClient", "Entry" },
    AutoClearStorage = { "DataClient", "Entry", "Buffs" },
    AutoBuyDice = { "DataClient", "Dice" },
    AutoEquipBestDice = { "DataClient", "Dice" },
    AutoBuyUpgrades = { "DataClient", "Upgrades", "Tree", "Buffs", "BuffsConfig" },
    AutoRebirth = { "DataClient", "Rebirths" },
    AutoRebirthStats = { "DataClient", "RebirthStats" },
    AutoGamepass = { "DataClient", "Entry" },
    AutoGrade = { "DataClient", "Entry", "Grades" },
    AutoTrait = { "DataClient", "Entry", "Traits" },
    AutoFuse = { "DataClient", "Entry", "FusingConfig" },
    AutoGear = { "DataClient", "Entry" },
    AutoLock = { "DataClient", "Entry" },
    AutoPotion = { "DataClient", "Entry" },
    AutoSpin = { "DataClient", "Entry" },
    AutoTicketShop = { "DataClient", "Quests" },
    AutoQuest = { "DataClient", "Quests" },
    AutoDaily = { "DataClient" },
    AutoGroup = { "DataClient" },
    AutoOffline = { "DataClient" },
    RareNotify = { "DataClient", "Entry" },
}

PatipanStudio.UI.Remotes = {
    AutoRoll = { "RollService.RF.RollDice" },
    AutoCollect = { "PlotService.RE.CollectBalance" },
    EquipBestUnitsAuto = { "PlotService.RE.EquipBest", "PlotService.RE.InteractSlot", "UnitService.RF.Equip" },
    AutoLevelUp = { "PlotService.RE.LevelUpSlot" },
    AutoTower = { "Towers.RF.PlayTower", "Towers.RF.CompleteTowerFloor", "Towers.RF.CancelTower" },
    AutoSell = { "SellService.RF.SellInventory" },
    AutoClearStorage = { "SellService.RF.SellInventory" },
    AutoBuyDice = { "DiceShopService.RE.BuyDice" },
    AutoEquipBestDice = { "DiceShopService.RE.EquipDice" },
    AutoBuyUpgrades = { "RE.BuyUpgrade" },
    AutoRebirth = { "RebirthService.RE.Rebirth" },
    AutoRebirthStats = { "RebirthService.RE.AddStat" },
    AutoGamepass = { "GamepassService.RE.Use" },
    AutoGrade = { "GradeService.RE.Roll" },
    AutoTrait = { "TraitService.RE.Roll" },
    AutoFuse = { "FusingService.RE.Fuse" },
    AutoGear = { "GearService.RE.Equip" },
    AutoLock = { "UnitService.RE.SetLocked" },
    AutoPotion = { "BoostService.RE.Use" },
    AutoSpin = { "SpinService.RE.Use" },
    AutoTicketShop = { "QuestService.RE.Buy" },
    AutoQuest = { "QuestService.RE.Claim" },
    AutoDaily = { "DailyRewardService.RE.Claim" },
    AutoGroup = { "GroupRewardService.RE.Claim" },
    AutoOffline = { "OfflineEarningsService.RE.Claim" },
}

---@return string?, boolean  first missing module or remote, true when it is a remote
function PatipanStudio.UI.MissingFor(idx)
    for _, key in ipairs(PatipanStudio.UI.Needs[idx] or {}) do
        if GameLib[key] == nil then return key, false end
    end
    for _, path in ipairs(PatipanStudio.UI.Remotes[idx] or {}) do
        if not PatipanStudio.Net.Get(path) then return path, true end
    end
    return nil, false
end

function PatipanStudio.UI.Gate()
    local blocked = 0
    local seen = {}
    for idx in pairs(PatipanStudio.UI.Needs) do seen[idx] = true end
    for idx in pairs(PatipanStudio.UI.Remotes) do seen[idx] = true end

    for idx in pairs(seen) do
        local missing, isRemote = PatipanStudio.UI.MissingFor(idx)
        if not Library.Options[idx] or not missing then continue end
        blocked += 1
        warn("[AnimeDice] " .. idx .. " blocked, missing " .. (isRemote and "remote " or "module ") .. missing)
        local reason = isRemote and T("The game changed, waiting for a script update", "เกมอัปเดต รอสคริปต์อัปเดต")
            or T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
        Library.Compat.Block(idx, reason)
    end
    if blocked == 0 then return end
    Library:Notify("PatipanStudio", T(blocked .. " features are turned off for now", "ปิดไว้ก่อน " .. blocked .. " ฟีเจอร์"), 8, "Warning")
end

function PatipanStudio.UI.DrainHalted()
    local halted = PatipanStudio.State.Halted
    while #halted > 0 do
        local entry = table.remove(halted, 1)
        local stopKaitun = false
        for _, idx in ipairs(entry[2]) do
            local toggle = Library.Toggles[idx]
            if toggle and toggle.Value == true then toggle:SetValue(false) end
            stopKaitun = stopKaitun or table.find(PatipanStudio.Kaitun.Members, idx) ~= nil
        end

        local kaitun = Library.Toggles.Kaitun
        if stopKaitun and kaitun and kaitun.Value == true then kaitun:SetValue(false) end
        Library:Notify("PatipanStudio", entry[1] .. " stopped: " .. tostring(entry[3]), 8, "Error")
    end
end

function PatipanStudio.UI.DrainNotices()
    local notices = PatipanStudio.State.Notices
    while #notices > 0 do
        local notice = table.remove(notices, 1)
        Library:Notify(notice[1], notice[2], 8, "Warning")
    end
end

function PatipanStudio.UI.BuildMain(window)
    local tab = window:AddTab(T("Home", "หน้าแรก"), "mushroom", T("Status and full auto", "สถานะและโหมดอัตโนมัติ"))

    local status = tab:AddLeftGroupbox(T("Status", "สถานะ"), "star")
    PatipanStudio.UI.Labels.Economy = status:AddParagraph({ Title = T("Economy", "เศรษฐกิจ"), Content = "-" })
    PatipanStudio.UI.Labels.Roll = status:AddParagraph({ Title = T("Rolling", "การทอย"), Content = "-" })
    PatipanStudio.UI.Labels.Units = status:AddParagraph({ Title = T("Units", "ตัวละคร"), Content = "-" })
    PatipanStudio.UI.Labels.Tower = status:AddParagraph({ Title = T("Tower", "หอคอย"), Content = "-" })

    local stats = tab:AddLeftGroupbox(T("Session Stats", "สถิติรอบนี้"), "flag")
    PatipanStudio.UI.Labels.Stats = stats:AddParagraph({ Title = T("This session", "รอบนี้"), Content = "-" })

    local discord = tab:AddRightGroupbox(T("Discord", "ดิสคอร์ด"), "link")
    discord:AddLabel(PatipanStudio.Config.Discord)
    discord:AddButton({ Text = T("Copy Discord Link", "คัดลอกลิงก์ดิสคอร์ด"), Func = PatipanStudio.UI.Detach(function()
        if Util.Copy(PatipanStudio.Config.Discord) then
            Library:Notify(T("Discord", "ดิสคอร์ด"), T("Link copied", "คัดลอกลิงก์แล้ว"), 3, "Success")
        else
            Library:Notify(T("Discord", "ดิสคอร์ด"), PatipanStudio.Config.Discord, 6, "Info")
        end
    end) })

    local logBox = tab:AddRightGroupbox(T("Update Log", "อัปเดตล่าสุด"), "bell")
    for i = 1, math.min(2, #PatipanStudio.Config.UpdateLog) do
        local entry = PatipanStudio.Config.UpdateLog[i]
        logBox:AddParagraph({ Title = entry[1], Content = entry[2] })
    end

    local master = tab:AddRightGroupbox(T("Kaitun", "ไคตุน"), "qblock")
    master:AddToggle("Kaitun", {
        Text = T("Kaitun (full auto)", "ไคตุน (อัตโนมัติทั้งหมด)"),
        Description = T("Rolls, levels, upgrades, grades, climbs towers and rebirths on its own", "ทอย อัปเลเวล อัปเกรด รีเกรด ไต่หอคอย และรีเบิร์ธเองทั้งหมด"),
        Callback = PatipanStudio.UI.StartStop(PatipanStudio.Kaitun),
    })
    PatipanStudio.UI.Labels.Kaitun = master:AddParagraph({ Title = T("Progress", "ความคืบหน้า"), Content = "-" })
end

function PatipanStudio.UI.BuildFarm(window)
    local tab = window:AddTab(T("Auto Farm", "ฟาร์มอัตโนมัติ"), "coin", T("Rolling, plot and levels", "ทอย ฐาน และเลเวล"))
    local rarities = PatipanStudio.UI.Values(GameLib.UnitRarities)

    local roll = tab:AddLeftGroupbox(T("Rolling", "การทอย"), "star")
    roll:AddToggle("AutoRoll", { Text = T("Fast roll", "ทอยเร็ว"), Description = T("Rolls non-stop with no roll animation", "ทอยต่อเนื่องไม่มีแอนิเมชัน") })
    roll:AddSlider("RollInterval", { Text = T("Roll interval", "ความถี่ทอย"), Min = 0.02, Max = 0.5, Default = 0.02, Rounding = 2, Suffix = "s" })
    roll:AddButton({ Text = T("Roll Once", "ทอย 1 ครั้ง"), Func = PatipanStudio.UI.Detach(function() PatipanStudio.Roll.Once() end) })
    roll:AddButton({ Text = T("Reset roll counter", "รีเซ็ตตัวนับการทอย"), Func = PatipanStudio.UI.Detach(PatipanStudio.Roll.ResetCounter) })

    local plot = tab:AddLeftGroupbox(T("Placement", "วางตัว"), "castle")
    plot:AddToggle("EquipBestUnitsAuto", { Text = T("Auto equip best", "วางตัวดีสุดอัตโนมัติ") })
    plot:AddDropdown("PlacementMode", {
        Text = T("Pick units by", "เลือกตัวตาม"),
        Description = T("Potential places your strongest units even at level 1", "ศักยภาพ = วางตัวที่เก่งจริงแม้ยังเลเวล 1"),
        Values = { "Potential", "Current income" },
        Default = "Potential",
    })
    plot:AddSlider("EquipInterval", { Text = T("Equip interval", "ความถี่วางตัว"), Min = 1, Max = 120, Default = 5, Rounding = 0, Suffix = "s" })
    plot:AddButton({ Text = T("Equip Best Now", "วางตัวดีสุดตอนนี้"), Func = PatipanStudio.UI.Detach(PatipanStudio.Plot.EquipBest) })

    local collect = tab:AddRightGroupbox(T("Collect", "เก็บเงิน"), "coin")
    collect:AddToggle("AutoCollect", { Text = T("Auto collect", "เก็บเงินอัตโนมัติ") })
    collect:AddSlider("CollectInterval", { Text = T("Collect interval", "ความถี่เก็บเงิน"), Min = 0.5, Max = 60, Default = 1, Rounding = 1, Suffix = "s" })
    collect:AddButton({ Text = T("Collect Now", "เก็บเงินตอนนี้"), Func = PatipanStudio.UI.Detach(PatipanStudio.Plot.CollectNow) })

    local level = tab:AddRightGroupbox(T("Level Up", "อัปเลเวล"), "oneup")
    level:AddToggle("AutoLevelUp", { Text = T("Auto level up", "อัปเลเวลอัตโนมัติ"), Description = T("Levels plotted units when you can afford it", "อัปเลเวลตัวบนฐานเมื่อเงินพอ") })
    level:AddDropdown("LevelMinRarity", { Text = T("Minimum rarity (plotted units)", "rarity ขั้นต่ำ (ตัวบนฐาน)"), Values = rarities, Default = PatipanStudio.UI.Prefer(rarities, "Common", 1), Searchable = true })
    level:AddSlider("LevelTarget", { Text = T("Target level", "เลเวลเป้าหมาย"), Min = 2, Max = 200, Default = 10, Rounding = 0 })
    level:AddSlider("LevelPayback", { Text = T("Max payback time", "คืนทุนไม่เกิน"), Description = T("Buys levels that pay back fast without delaying dice or rebirth", "อัปเฉพาะเลเวลที่คืนทุนเร็ว ไม่ทำให้เต๋า/รีเบิร์ธช้าลง"), Min = 10, Max = 3600, Default = 180, Rounding = 0, Suffix = "s" })
    level:AddButton({ Text = T("Run a pass", "อัปเลเวล 1 รอบ"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Level Up", "อัปเลเวล"), PatipanStudio.Plot.LevelPass(true) .. " levelled", "Success")
    end) })
end

function PatipanStudio.UI.BuildEconomy(window)
    local tab = window:AddTab(T("Economy", "เศรษฐกิจ"), "shop", T("Dice, upgrades, selling, rebirth", "เต๋า อัปเกรด ขาย รีเบิร์ธ"))
    local rarities = PatipanStudio.UI.Values(GameLib.UnitRarities)

    local dice = tab:AddLeftGroupbox(T("Dice", "เต๋า"), "qblock")
    dice:AddToggle("AutoBuyDice", { Text = T("Auto buy dice", "ซื้อเต๋าอัตโนมัติ"), Description = T("Buys the luckiest dice you can afford", "ซื้อเต๋าที่ดวงดีสุดเท่าที่เงินถึง") })
    dice:AddToggle("AutoEquipBestDice", { Text = T("Equip best owned dice", "ใส่เต๋าดีสุดที่มี") })
    dice:AddButton({ Text = T("Equip Best Now", "ใส่เต๋าดีสุดตอนนี้"), Func = PatipanStudio.UI.Detach(PatipanStudio.Dice.EquipBest) })

    local upgrade = tab:AddRightGroupbox(T("Upgrades", "อัปเกรด"), "star")
    upgrade:AddToggle("AutoBuyUpgrades", { Text = T("Auto upgrades", "อัปเกรดอัตโนมัติ") })
    PatipanStudio.UI.MultiDropdown(upgrade, "UpgradeFilter", T("Branches to upgrade", "สายที่จะอัปเกรด"),
        T("Empty buys every branch", "ไม่เลือก = ซื้อทุกสาย"), PatipanStudio.UI.Values(PatipanStudio.Upgrade.Branches))
    upgrade:AddSlider("UpgradePayback", { Text = T("Max income payback", "คืนทุนรายได้ไม่เกิน"), Description = T("Buys money and luck upgrades only when they are worth it", "ซื้ออัปเกรดเงินและดวงเฉพาะตอนคุ้ม"), Min = 30, Max = 7200, Default = 1800, Rounding = 0, Suffix = "s" })
    upgrade:AddButton({ Text = T("Buy available upgrades", "ซื้ออัปเกรดที่ซื้อได้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Upgrades", "อัปเกรด"), PatipanStudio.Upgrade.BuyAll() .. " bought", "Success")
    end) })

    local sell = tab:AddLeftGroupbox(T("Sell", "ขาย"), "coin")
    sell:AddToggle("AutoSell", { Text = T("Auto sell", "ขายอัตโนมัติ"), Description = T("Never sells units on your plot or tower team", "ไม่ขายตัวที่อยู่บนฐานหรือในทีมหอคอย") })
    PatipanStudio.UI.MultiDropdown(sell, "SellRarities", T("Rarities to sell", "rarity ที่จะขาย"), nil, rarities)
    PatipanStudio.UI.MultiDropdown(sell, "SellKeepMutations", T("Mutations to keep", "mutation ที่เก็บไว้"), nil, PatipanStudio.UI.Values(GameLib.MutationNames))
    sell:AddSlider("KeepPerRarity", { Text = T("Keep best per rarity", "เก็บตัวดีสุดต่อ rarity"), Min = 0, Max = 20, Default = 0, Rounding = 0 })
    sell:AddSlider("SellInterval", { Text = T("Interval", "ความถี่"), Min = 0.5, Max = 60, Default = 2, Rounding = 1, Suffix = "s" })
    sell:AddButton({ Text = T("Sell Now", "ขายตอนนี้"), Style = "Warning", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Sell", "ขาย"), PatipanStudio.Sell.SellNow(), "Coin")
    end) })

    local storage = tab:AddRightGroupbox(T("Full Storage", "กระเป๋าเต็ม"), "bomb")
    storage:AddToggle("AutoClearStorage", { Text = T("Auto clear full storage", "เคลียร์กระเป๋าเมื่อเต็ม"), Description = T("Sells your weakest spare units so rolling never stops", "ขายตัวสำรองที่อ่อนสุดเพื่อให้ทอยได้ไม่หยุด") })
    storage:AddDropdown("ClearKeepRarity", { Text = T("Never clear rarity and above", "ไม่เคลียร์ rarity นี้ขึ้นไป"), Values = rarities, Default = PatipanStudio.UI.Prefer(rarities, "Mythical", math.ceil(#rarities / 2)), Searchable = true })

    local rebirth = tab:AddRightGroupbox(T("Rebirth", "รีเบิร์ธ"), "flag")
    rebirth:AddToggle("AutoRebirth", { Text = T("Auto rebirth", "รีเบิร์ธอัตโนมัติ"), Description = T("Rebirths the moment you can afford it", "รีเบิร์ธทันทีที่เงินถึง") })
    rebirth:AddButton({ Text = T("Rebirth Now", "รีเบิร์ธตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.Rebirth.RebirthNow()
        PatipanStudio.UI.Notify(T("Rebirth", "รีเบิร์ธ"), PatipanStudio.Rebirth.Status)
    end) })

    local statNames = PatipanStudio.UI.Values(GameLib.RebirthStatNames)
    local stats = tab:AddLeftGroupbox(T("Rebirth Stats", "สเตตัสรีเบิร์ธ"), "oneup")
    stats:AddToggle("AutoRebirthStats", { Text = T("Auto spend points", "ลงแต้มอัตโนมัติ"), Description = T("Puts every new rebirth point into the stat below", "ลงแต้มรีเบิร์ธใหม่ทุกแต้มที่สเตตัสด้านล่าง") })
    stats:AddDropdown("RebirthStat", { Text = T("Stat", "สเตตัส"), Values = statNames, Default = PatipanStudio.UI.Prefer(statNames, "Money", 1) })
    stats:AddButton({ Text = T("Spend Points Now", "ลงแต้มตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Rebirth Stats", "สเตตัสรีเบิร์ธ"), PatipanStudio.Rebirth.SpendPoints() .. " points spent")
    end) }):AddButton({ Text = T("Reset Stats", "รีเซ็ตสเตตัส"), Func = PatipanStudio.UI.Detach(function()
        local ok, why = PatipanStudio.Rebirth.ResetStats()
        PatipanStudio.UI.Notify(T("Rebirth Stats", "สเตตัสรีเบิร์ธ"), ok and "Reset Token used" or why)
    end) })
end

function PatipanStudio.UI.BuildUnits(window)
    local tab = window:AddTab(T("Units", "ตัวละคร"), "heart", T("Grades, traits, fusing", "เกรด trait หลอมรวม"))
    local rarities = PatipanStudio.UI.Values(GameLib.UnitRarities)
    local mutations = PatipanStudio.UI.Values(GameLib.MutationNames)
    local grades, traits = PatipanStudio.UI.Values(GameLib.GradeNames), PatipanStudio.UI.Values(GameLib.TraitNames)

    local grade = tab:AddLeftGroupbox(T("Grades", "เกรด"), "star")
    grade:AddToggle("AutoGrade", { Text = T("Auto grade", "รีเกรดอัตโนมัติ"), Description = T("Rerolls units on your plot and tower team up to the minimum", "รีเกรดตัวบนฐานและในทีมหอคอยจนถึงขั้นต่ำ") })
    grade:AddDropdown("GradeTarget", { Text = T("Minimum grade", "เกรดขั้นต่ำ"), Values = grades, Default = PatipanStudio.UI.Prefer(grades, "S", math.ceil(#grades / 2)) })
    grade:AddToggle("GradeOverwrite", { Text = T("Overwrite protected tiers (S+)", "ยอมทับเกรดที่ป้องกันไว้ (S+)"), Risky = true })
    grade:AddButton({ Text = T("Grade Once", "รีเกรด 1 ครั้ง"), Func = PatipanStudio.UI.Detach(PatipanStudio.Grade.RollOne) })

    local trait = tab:AddLeftGroupbox(T("Traits", "trait"), "shell")
    trait:AddToggle("AutoTrait", { Text = T("Auto trait", "รี trait อัตโนมัติ"), Description = T("Rerolls units on your plot and tower team up to the minimum", "รี trait ตัวบนฐานและในทีมหอคอยจนถึงขั้นต่ำ") })
    trait:AddDropdown("TraitTarget", { Text = T("Minimum trait", "trait ขั้นต่ำ"), Values = traits, Default = PatipanStudio.UI.Prefer(traits, "Samurai", math.ceil(#traits / 2)), Searchable = true })
    trait:AddToggle("TraitOverwrite", { Text = T("Overwrite protected tiers (Samurai/Shogun)", "ยอมทับ trait ที่ป้องกันไว้ (Samurai/Shogun)"), Risky = true })
    trait:AddButton({ Text = T("Trait Once", "รี trait 1 ครั้ง"), Func = PatipanStudio.UI.Detach(PatipanStudio.Trait.RollOne) })

    local lock = tab:AddRightGroupbox(T("Auto Lock", "ล็อกอัตโนมัติ"), "key")
    lock:AddToggle("AutoLock", { Text = T("Auto lock rare units", "ล็อกตัวหายากอัตโนมัติ"), Description = T("Locked units are never sold or fused", "ตัวที่ล็อกจะไม่ถูกขายหรือหลอม") })
    lock:AddDropdown("LockRarity", { Text = T("Lock rarity and above", "ล็อก rarity นี้ขึ้นไป"), Values = rarities, Default = PatipanStudio.UI.Prefer(rarities, "Secret I", #rarities - 3), Searchable = true })
    PatipanStudio.UI.MultiDropdown(lock, "LockMutations", T("Lock mutations", "ล็อก mutation"), nil, mutations)

    local gear = tab:AddRightGroupbox(T("Gear", "อุปกรณ์"), "shield")
    gear:AddToggle("AutoGear", { Text = T("Auto equip best gear", "ใส่อุปกรณ์ดีสุดอัตโนมัติ"), Description = T("Wears your rarest gear in every slot", "ใส่ชิ้นที่หายากสุดทุกช่อง") })
    gear:AddButton({ Text = T("Equip Best Now", "ใส่ดีสุดตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Gear", "อุปกรณ์"), PatipanStudio.Gear.EquipBest() .. " slots upgraded", "Success")
    end) })

    local fuse = tab:AddRightGroupbox(T("Fusing", "หลอมรวม"), "bomb")
    fuse:AddToggle("AutoFuse", { Text = T("Auto Fuse", "หลอมอัตโนมัติ"), Description = T("Fuses spare trios only when the result is expected to be rarer and the cost is small", "หลอมตัวสำรองเฉพาะเมื่อผลที่คาดไว้หายากกว่าเดิมและค่าหลอมถูก"), Risky = true })
    PatipanStudio.UI.MultiDropdown(fuse, "FuseRarities", T("Rarities to fuse", "rarity ที่จะหลอม"), T("Empty uses any spare below the never-clear rarity", "ไม่เลือก = ใช้ตัวสำรองที่ต่ำกว่า rarity ที่ไม่เคลียร์"), rarities)
    fuse:AddButton({ Text = T("Fuse Now", "หลอมตอนนี้"), Func = PatipanStudio.UI.Detach(PatipanStudio.Fuse.FuseNow) })
end

function PatipanStudio.UI.BuildTower(window)
    local tab = window:AddTab(T("Tower", "หอคอย"), "castle", T("Tower climbing for Gems", "ไต่หอคอยเก็บ Gems"))

    local group = tab:AddLeftGroupbox(T("Auto Tower", "ไต่หอคอยอัตโนมัติ"), "castle")
    group:AddToggle("AutoTower", { Text = T("Auto tower", "ไต่หอคอยอัตโนมัติ"), Description = T("Climbs, restarts after each run and keeps going", "ไต่ จบรอบแล้วเริ่มใหม่ต่อเนื่อง") })
    local labels = PatipanStudio.UI.Values(PatipanStudio.Tower.Labels)
    group:AddDropdown("TowerDifficulty", {
        Text = T("Difficulty", "ความยาก"),
        Values = labels,
        Default = labels[1],
        Callback = function(label) PatipanStudio.Options.TowerName = PatipanStudio.Tower.NameFromLabel(label) end,
    })
    group:AddToggle("TowerSmart", { Text = T("Auto Difficulty", "ปรับความยากอัตโนมัติ"), Description = T("Moves up after a full clear and down when the team falls early", "ขึ้นหอยากขึ้นเมื่อผ่านหมด ลดลงเมื่อแพ้เร็ว") })
    if labels[1] then PatipanStudio.Options.TowerName = PatipanStudio.Tower.NameFromLabel(labels[1]) end

    local run = tab:AddRightGroupbox(T("Run Settings", "ตั้งค่ารอบ"), "flag")
    run:AddSlider("TowerStopFloor", { Text = T("Stop at floor", "หยุดที่ชั้น"), Min = 1, Max = 500, Default = 100, Rounding = 0 })
    run:AddToggle("TowerReequip", { Text = T("Re-equip before each run", "จัดทีมใหม่ก่อนทุกรอบ") })
    run:AddButton({ Text = T("Equip best team", "จัดทีมดีสุด"), Func = PatipanStudio.UI.Detach(PatipanStudio.Tower.EquipTeam) })
end

function PatipanStudio.UI.BuildItems(window)
    local tab = window:AddTab(T("Items", "ไอเทม"), "flower", T("Potions, spins, ticket shop", "ยา สปิน ร้านตั๋ว"))

    local potion = tab:AddLeftGroupbox(T("Potions", "ยาบัฟ"), "flower")
    potion:AddToggle("AutoPotion", { Text = T("Auto potion", "ใช้ยาอัตโนมัติ"), Description = T("Uses each boost only when it helps", "ใช้บัฟแต่ละตัวเฉพาะตอนมีประโยชน์") })
    PatipanStudio.UI.MultiDropdown(potion, "PotionFilter", T("Potions to use", "ยาที่จะใช้"), T("Empty uses every potion", "ไม่เลือก = ใช้ทุกชนิด"), PatipanStudio.UI.Values(GameLib.NamesOfKind, "Boost"))
    potion:AddButton({ Text = T("Use Now", "ใช้ตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Potions", "ยาบัฟ"), PatipanStudio.Items.UsePotions(true) .. " used", "Power")
    end) })

    local spin = tab:AddRightGroupbox(T("Spins", "สปิน"), "star")
    spin:AddToggle("AutoSpin", { Text = T("Auto use spins", "ใช้สปินอัตโนมัติ"), Description = T("Uses Lucky and Jackpot spins", "ใช้ Lucky และ Jackpot spin") })
    spin:AddButton({ Text = T("Use Spins Now", "ใช้สปินตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Spins", "สปิน"), PatipanStudio.Items.UseSpins() .. " used")
    end) })
    spin:AddToggle("AutoGamepass", { Text = T("Auto use gamepass items", "ใช้ไอเทมเกมพาสอัตโนมัติ"), Description = T("Unlocks gamepasses you got from codes and rewards", "ปลดล็อกเกมพาสที่ได้จากโค้ดและรางวัล") })

    local shop = tab:AddRightGroupbox(T("Ticket Shop", "ร้านตั๋ว"), "shop")
    shop:AddToggle("AutoTicketShop", { Text = T("Auto buy with tickets", "ซื้อด้วยตั๋วอัตโนมัติ"), Description = T("Spends quest tickets on what you pick", "ใช้ตั๋วเควสต์ซื้อของที่เลือก") })
    PatipanStudio.UI.MultiDropdown(shop, "TicketShopItems", T("Items to buy", "ของที่จะซื้อ"), nil, PatipanStudio.UI.Values(GameLib.ShopNames))
    shop:AddButton({ Text = T("Buy Now", "ซื้อตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Ticket Shop", "ร้านตั๋ว"), PatipanStudio.Items.BuyTicketShop() .. " bought", "Coin")
    end) })
end

function PatipanStudio.UI.BuildRewards(window)
    local tab = window:AddTab(T("Rewards", "รางวัล"), "key", T("Codes, daily, quests", "โค้ด รายวัน เควสต์"))

    local codes = tab:AddLeftGroupbox(T("Codes", "โค้ด"), "qblock")
    codes:AddButton({ Text = T("Redeem All Codes", "แลกโค้ดทั้งหมด"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Codes", "โค้ด"), PatipanStudio.Rewards.RedeemAll(), "Success")
    end) })

    local quest = tab:AddLeftGroupbox(T("Quests", "เควสต์"), "flag")
    quest:AddToggle("AutoQuest", { Text = T("Auto claim quests", "รับรางวัลเควสต์อัตโนมัติ") })
    quest:AddButton({ Text = T("Claim now", "รับตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notify(T("Quests", "เควสต์"), PatipanStudio.Rewards.ClaimQuests() .. " claimed", "Success")
    end) })

    local claims = tab:AddRightGroupbox(T("Claims", "รับรางวัล"), "coin")
    claims:AddToggle("AutoDaily", { Text = T("Auto daily reward", "รับรางวัลรายวันอัตโนมัติ") })
    claims:AddToggle("AutoGroup", { Text = T("Auto group reward", "รับรางวัลกลุ่มอัตโนมัติ") })
    claims:AddToggle("AutoOffline", { Text = T("Auto offline earnings", "รับรายได้ออฟไลน์อัตโนมัติ") })
end

function PatipanStudio.UI.BuildPlayer(window)
    local tab = window:AddTab(T("Player", "ผู้เล่น"), "oneup", T("Movement and utility", "การเคลื่อนที่และอรรถประโยชน์"))

    local move = tab:AddLeftGroupbox(T("Movement", "การเคลื่อนที่"), "gear")
    move:AddToggle("WalkSpeed", { Text = T("Walk speed", "ความเร็วเดิน"), Callback = PatipanStudio.UI.Detach(function(on)
        if on then PatipanStudio.Move.SpeedStart() else PatipanStudio.Move.SpeedStop() end
    end) })
    move:AddSlider("WalkSpeedValue", { Text = T("Speed", "ความเร็ว"), Min = 16, Max = 200, Default = 32, Rounding = 0 })
    move:AddToggle("InfiniteJump", { Text = T("Infinite jump", "กระโดดไม่จำกัด"), Callback = PatipanStudio.UI.Detach(function(on)
        if on then PatipanStudio.Move.JumpStart() else PatipanStudio.Move.JumpStop() end
    end) })

    local util = tab:AddLeftGroupbox(T("Utility", "อรรถประโยชน์"), "star")
    util:AddToggle("AntiAfk", { Text = T("Anti-AFK", "กันหลุด AFK"), Callback = PatipanStudio.UI.StartStop(PatipanStudio.AntiAfk) })
    util:AddToggle("AutoRejoin", { Text = T("Auto rejoin", "รีจอยน์อัตโนมัติ"), Description = T("Rejoins after a disconnect and resumes Kaitun", "เข้าเกมใหม่เมื่อหลุดและทำไคตุนต่อ"), Callback = PatipanStudio.UI.StartStop(PatipanStudio.Rejoin) })
    util:AddToggle("DisableCutscene", { Text = T("Disable cutscenes", "ปิดคัตซีน"), Description = T("Skips roll and fuse reveal cutscenes", "ข้ามคัตซีนตอนทอยและหลอม"), Callback = function(on)
        if not on then PatipanStudio.Cutscene.Restore() end
    end })

    local air = tab:AddRightGroupbox(T("Fly and No Clip", "บินและทะลุกำแพง"), "pipe")
    air:AddToggle("NoClip", { Text = T("No clip", "ทะลุกำแพง"), Callback = PatipanStudio.UI.Detach(function(on)
        if on then PatipanStudio.Move.NoClipStart() else PatipanStudio.Move.NoClipStop() end
    end) }):AddKeyPicker("NoClipKey", { Default = "None", Mode = "Toggle" })
    air:AddToggle("Fly", { Text = T("Fly", "บิน"), Callback = PatipanStudio.UI.Detach(function(on)
        if on then PatipanStudio.Move.FlyStart() else PatipanStudio.Move.FlyStop() end
    end) }):AddKeyPicker("FlyKey", { Default = "None", Mode = "Toggle" })
    air:AddSlider("FlySpeed", { Text = T("Fly speed", "ความเร็วบิน"), Min = 20, Max = 300, Default = 60, Rounding = 0 })

    local alerts = tab:AddRightGroupbox(T("Rare Alerts", "แจ้งเตือนของหายาก"), "bell")
    alerts:AddToggle("RareNotify", { Text = T("Alert on rare pulls", "แจ้งเตือนเมื่อได้ของหายาก") })
    PatipanStudio.UI.MultiDropdown(alerts, "NotifyRarities", T("Rarities", "rarity"), nil, PatipanStudio.UI.Values(GameLib.UnitRarities))
    PatipanStudio.UI.MultiDropdown(alerts, "NotifyMutations", T("Mutations", "mutation"), nil, PatipanStudio.UI.Values(GameLib.MutationNames))
    alerts:AddInput("WebhookUrl", { Text = T("Discord webhook", "Discord webhook"), Default = "", Placeholder = T("Optional webhook URL", "ลิงก์ webhook (ไม่ใส่ก็ได้)"), Finished = true })
    alerts:AddButton({ Text = T("Send test alert", "ทดสอบแจ้งเตือน"), Func = PatipanStudio.UI.Detach(function()
        local rarities, mutations = PatipanStudio.UI.Lists.Rarities, PatipanStudio.UI.Lists.Mutations
        PatipanStudio.Watch.Alert({ Name = "Test", Rarity = rarities[#rarities] or "?", Mutation = mutations[#mutations] })
    end) })
end

function PatipanStudio.UI.RefreshStatus()
    local labels = PatipanStudio.UI.Labels
    if not labels.Kaitun then return end

    labels.Economy:SetContent(string.format("$%s · R%d · Gems %s · Tickets %s",
        Util.FormatNumber(PatipanStudio.Data.Money()), PatipanStudio.Data.Rebirth(),
        Util.FormatNumber(PatipanStudio.Data.Token("Gems")), Util.FormatNumber(PatipanStudio.Data.Token("Tickets"))))
    labels.Roll:SetContent(PatipanStudio.Roll.GetStatus())
    labels.Units:SetContent(string.format("Storage %s · Grade: %s · Trait: %s", PatipanStudio.Storage.Status, PatipanStudio.Grade.Status, PatipanStudio.Trait.Status))
    labels.Tower:SetContent(PatipanStudio.Tower.GetStatus())
    labels.Kaitun:SetContent(PatipanStudio.Kaitun.GetStatus() .. "\nUpgrades: " .. PatipanStudio.Upgrade.Status .. "\nLevels: " .. PatipanStudio.Plot.Status)
    labels.Stats:SetContent(table.concat(PatipanStudio.Watch.Stats(), "\n"))
end

function PatipanStudio.UI.BindOptions()
    for key in pairs(PatipanStudio.Options) do
        local widget = Library.Options[key]
        if widget and widget.OnChanged then
            PatipanStudio.Options[key] = widget.Value
            widget:OnChanged(function(value)
                PatipanStudio.Options[key] = value
                if value == true then PatipanStudio.Scheduler.Resume(key) end
            end)
        end
    end
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    PatipanStudio.UI.Lists = { Rarities = PatipanStudio.UI.Values(GameLib.UnitRarities), Mutations = PatipanStudio.UI.Values(GameLib.MutationNames) }
    local layout = {
        { T("Main", "หลัก"), "Main", PatipanStudio.UI.BuildMain },
        { T("Farming", "ฟาร์ม"), "Farm", PatipanStudio.UI.BuildFarm },
        { nil, "Tower", PatipanStudio.UI.BuildTower },
        { T("Progression", "พัฒนา"), "Units", PatipanStudio.UI.BuildUnits },
        { nil, "Economy", PatipanStudio.UI.BuildEconomy },
        { nil, "Items", PatipanStudio.UI.BuildItems },
        { nil, "Rewards", PatipanStudio.UI.BuildRewards },
        { T("Misc", "อื่นๆ"), "Player", PatipanStudio.UI.BuildPlayer },
    }
    for _, section in ipairs(layout) do
        if section[1] then window:AddTabSection(section[1]) end
        Util.Try("ui " .. section[2], section[3], window)
    end
    Util.Try("ui settings", window.AddSettingsTab, window)

    Util.Try("ui bind", PatipanStudio.UI.BindOptions)
    Util.Try("ui gate", PatipanStudio.UI.Gate)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.RefreshStatus)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.DrainHalted)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.DrainNotices)
end

local function BuildInterface()
    local lib, problem = Util.LoadLibrary(PatipanStudio.Config.UiSource)
    if not lib then
        Util.Alert(problem)
        return
    end
    Library = lib
    pcall(MarioBanner.Step, "UI library")
    PatipanStudio.Library = Library
    T = function(en, th) return Library:T(en, th) end
    Library:CreateWindow({
        Title = "PatipanStudio",
        SubTitle = "Anime Dice by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = PatipanStudio.Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        Intro = true,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            task.defer(Util.Try, "boot", PatipanStudio.Boot)
            task.defer(function()
                Util.Try("autoload config", Library.LoadAutoloadConfig, Library)
                if environment.AnimeDiceResume then
                    environment.AnimeDiceResume = nil
                    if Library.Toggles.Kaitun then Library.Toggles.Kaitun:SetValue(true) end
                end
            end)
        end,
    })
    Library:OnUnload(function()
        PatipanStudio:Unload()
    end)
    return true
end

function PatipanStudio.Boot()
    PatipanStudio:Connect(LocalPlayer.CharacterAdded, function(character)
        PatipanStudio.Player:Bind(character)
        task.defer(PatipanStudio.Move.Rebind)
    end)
    PatipanStudio.Roll.ResetCounter()

    local options, config = PatipanStudio.Options, PatipanStudio.Config
    local every = PatipanStudio.Scheduler.Every
    every("Roll", function() return options.RollInterval end, PatipanStudio.Roll.Step, { "AutoRoll" })
    every("Collect", function() return options.CollectInterval end, PatipanStudio.Plot.CollectStep, { "AutoCollect" })
    every("Equip", function() return options.EquipInterval end, PatipanStudio.Plot.EquipStep, { "EquipBestUnitsAuto" })
    every("Economy", 1, PatipanStudio.Economy.Step, { "AutoBuyDice", "AutoEquipBestDice", "AutoRebirth", "AutoRebirthStats", "AutoBuyUpgrades", "AutoLevelUp" })
    every("Sell", function() return options.SellInterval end, PatipanStudio.Sell.Step, { "AutoSell" })
    every("Storage", 1, PatipanStudio.Storage.Step, { "AutoClearStorage" })
    every("Grade", config.GradeDelay, PatipanStudio.Grade.Step, { "AutoGrade" })
    every("Trait", config.TraitDelay, PatipanStudio.Trait.Step, { "AutoTrait" })
    every("Fuse", config.FuseDelay, PatipanStudio.Fuse.Step, { "AutoFuse" })
    every("Tower", config.TowerTick, PatipanStudio.Tower.Step, { "AutoTower" })
    every("Items", config.RewardsInterval, PatipanStudio.Items.Step, { "AutoPotion", "AutoSpin", "AutoGamepass", "AutoTicketShop" })
    every("Gear", config.RewardsInterval, PatipanStudio.Gear.Step, { "AutoGear" })
    every("Watch", 1, PatipanStudio.Watch.Step, { "RareNotify" })
    every("Lock", config.RewardsInterval, PatipanStudio.Lock.Step, { "AutoLock" })
    every("Rewards", config.RewardsInterval, PatipanStudio.Rewards.Step, { "AutoDaily", "AutoGroup", "AutoOffline", "AutoQuest" })
    every("Speed", 1, PatipanStudio.Move.ApplyWalkSpeed, { "WalkSpeed" })
    every("Cutscene", 1, PatipanStudio.Cutscene.Step, { "DisableCutscene" })
    PatipanStudio.Scheduler.Boot()
end

function PatipanStudio:Unload()
    self.State.Alive = false
    if environment.AnimeDiceUnload == self.State.UnloadEntry then environment.AnimeDiceUnload = nil end
    self.Options.AutoTower = false
    if PatipanStudio.Tower.State ~= "Idle" then PatipanStudio.Tower.Leave() end
    PatipanStudio.Move.SpeedStop()
    PatipanStudio.Move.NoClipStop()
    PatipanStudio.Move.FlyStop()
    PatipanStudio.Cutscene.Restore()
    for _, connection in ipairs(self.State.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.State.Connections)
end

PatipanStudio.State.UnloadEntry = function()
    if PatipanStudio.Library and not PatipanStudio.Library.Unloaded then
        PatipanStudio.Library:Unload()
    else
        PatipanStudio:Unload()
    end
end
environment.AnimeDiceUnload = PatipanStudio.State.UnloadEntry

if LocalPlayer.Character then
    PatipanStudio.Player:Bind(LocalPlayer.Character)
end

pcall(MarioBanner.Step, "Systems")
if BuildInterface() then
    pcall(MarioBanner.Step, "Interface")
    pcall(MarioBanner.Ready)
end