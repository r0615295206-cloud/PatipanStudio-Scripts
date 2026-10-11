if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 1202096104 then
    game:GetService("Players").LocalPlayer:Kick("PatipanStudio : this script is for Driving Empire only")
    return
end

local MarioBanner = {
    Print = print,
    Started = os.clock(),
    Last = os.clock(),
    Done = 0,
    Total = 4,
}

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

do
    local ok, renv = pcall(getrenv)
    if ok and type(renv) == "table" and type(renv.print) == "function" then
        MarioBanner.Print = renv.print
    end
end

pcall(MarioBanner.Show)
pcall(MarioBanner.Step, "Core")

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nFixed Noclip restore\nAuto-detect Jobs & Teleports" },
    },
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    SaveFolder = "Driving Empire",
    LoadTimeout = 10,
    AlertTries = 20,
    AlertRetry = 0.5,
    JobFailLimit = 5,
    JobFailWindow = 10,
    SpawnerCacheFile = "Driving Empire/atm_spawners.json",
    TickDelay = 0.5,
    BustWait = 2.6,
    DebounceTimeout = 6,
    StreamWait = 0.5,
    SweepStep = 800,
    SweepHeight = 400,
    SweepDelay = 0.35,
    SweepMin = Vector3.new(-3500, 0, -6500),
    SweepMax = Vector3.new(7500, 0, 5000),
    CashOutCrimes = 5,
    DropOffStage = 8,
    DropOffSettle = 2.5,
    DropOffPayWait = 4,
    DropOffTries = 2,
    WantedSafety = 25,
    CopAvoidRadius = 45,
    RewardInterval = 60,
    EspInterval = 1,
    HopDelay = 4,
    DriveSpeed = 200,
    DriveAlign = 2,
    DriveLift = 3,
    DriveEdge = 120,
    DriveRoadMin = 1200,
    DriveRoadWidth = 30,
    DriveRoadFlat = 0.05,
    DriveRoadSeed = Vector3.new(-822, 21, -487),
    SpawnWait = 10,
    SpawnTries = 2,
    DropOffSeeds = {
        Vector3.new(-2543.3, 11.9, 4030.3),
        Vector3.new(7322.1, 197.8, -2811.6),
    },
    PlaceSeeds = {
        ["Job: Criminal"] = Vector3.new(135.2, 21.5, -1852.0),
        ["Job: Security"] = Vector3.new(148.2, 21.5, -1991.5),
        ["Job: Delivery"] = Vector3.new(122.5, 21.8, -1922.7),
        ["Job: Security HQ"] = Vector3.new(-109.8, 25.1, -956.8),
        ["Spawn Dealership"] = Vector3.new(-482, 14, -1767),
    },
    Codes = {
        "RAMBO", "AIRDROP", "UWU", "RECORD", "USA250", "10KITS", "MARCH2026", "HAPPY2026", "CALL911", "GOBBLEGOBBLE",
        "SPOOKY", "VEGAS2025", "WHOOPS", "RDCNASCAR25", "2MLIKES", "NASCAR100M", "CUSTOMIZATION2025",
        "200KMEMBERS", "NEWYEAR2025", "ZOOM", "HAPPYXMAS",
        "1MILLIONLIKES", "1MILCASH",
    },
    CodeDelay = 1.5,
}

local Config = PatipanStudio.Config

PatipanStudio.State = {
    Alive = true,
    Messages = {},
    Halted = {},
    Busy = false,
    Stats = nil,
    Spawners = {},
    LastReward = 0,
    LastEsp = 0,
    AtmSession = { Busted = 0, Earned = 0, CashedOut = 0, StartCash = 0 },
    AtmWarn = nil,
    Banking = false,
    BankOnStop = false,
    DriveConn = nil,
    DriveRoad = nil,
    CollideBackup = setmetatable({}, { __mode = "k" }),
    Conns = {},
    EspObjects = {},
    LightingBackup = nil,
    Opt = {
        AtmFarm = false,
        HopWhenEmpty = false,
        AvoidCops = false,
        CashOutCrimes = 10,
        DriveFarm = false,
        DriveCar = nil,
        AutoPlaytime = false,
        AutoClaimMisc = false,
        Code = "",
        WalkSpeed = 16,
        JumpPower = 50,
        SpeedEnabled = false,
        Noclip = false,
        InfiniteJump = false,
        Fullbright = false,
        AntiAfk = false,
        AutoRejoin = false,
        EspAtm = false,
        EspCops = false,
        EspDropOff = false,
        CarSpeed = 0,
    },
}

local State = PatipanStudio.State

for _, name in ipairs({ "Util", "Player", "Vehicle", "Jobs", "Atm", "Drive", "Rewards", "Teleport", "Esp", "Movement", "Session", "Scheduler" }) do
    PatipanStudio[name] = {}
end

function PatipanStudio.Util.Try(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[Driving Empire]", err)
    end
    return ok, err
end

---@return string?  body, nil when every way to fetch failed
function PatipanStudio.Util.HttpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" then
        return body
    end
    local requestFn = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and syn.request)
    if type(requestFn) ~= "function" then
        return nil
    end
    local sent, response = pcall(requestFn, { Url = url, Method = "GET" })
    if not sent or type(response) ~= "table" or tonumber(response.StatusCode) ~= 200 or type(response.Body) ~= "string" then
        return nil
    end
    return response.Body
end

---@param text string  shown as a Roblox notification, works before the menu exists
function PatipanStudio.Util.Alert(text)
    warn("[Driving Empire] " .. text)
    task.spawn(function()
        local starterGui = game:GetService("StarterGui")
        for _ = 1, Config.AlertTries do
            if pcall(starterGui.SetCore, starterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 }) then
                return
            end
            task.wait(Config.AlertRetry)
        end
    end)
end

---@return table?  UI library, nil after telling the player why
function PatipanStudio.Util.LoadLibrary()
    local source = PatipanStudio.Util.HttpGet(Config.UiSource)
    if not source or not source:sub(-64):find("return Library%s*$") then
        PatipanStudio.Util.Alert("Could not download the menu. Check your connection and run it again.")
        return nil
    end
    local chunk, err = loadstring(source)
    if not chunk then
        PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(err))
        return nil
    end
    local ok, library = pcall(chunk)
    if not ok or type(library) ~= "table" then
        PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(library))
        return nil
    end
    return library
end

---@param instance Instance  parented to gethui, then CoreGui, then PlayerGui
function PatipanStudio.Util.Mount(instance)
    local ok, hui = pcall(gethui)
    if ok and typeof(hui) == "Instance" and pcall(function() instance.Parent = hui end) then
        return
    end
    if pcall(function() instance.Parent = game:GetService("CoreGui") end) then
        return
    end
    instance.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", Config.LoadTimeout)
end

function PatipanStudio.Util.Stats()
    if State.Stats and State.Stats.Parent then return State.Stats end
    local folder = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(LocalPlayer.Name .. "'s Stats")
    local data = PatipanStudio.GameLib.Data
    State.Stats = folder or (data and data.GetLoadedStatsFolder(LocalPlayer))
    return State.Stats
end

function PatipanStudio.Util.Cash()
    local stats = PatipanStudio.Util.Stats()
    local cash = stats and stats:FindFirstChild("Cash")
    return cash and cash.Value or 0
end

function PatipanStudio.Util.Commas(number)
    local text = tostring(math.floor(number))
    repeat
        local count
        text, count = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until count == 0
    return text
end

PatipanStudio.GameLib = {}
local GameLib = PatipanStudio.GameLib

---@return Instance?  child at the end of the path, nil when any step is missing
function GameLib.Find(root, ...)
    local node = root
    for _, name in ipairs({ ... }) do
        node = node and node:FindFirstChild(name)
    end
    return node
end

---@return Instance?  module at the path, else the first ModuleScript with that name anywhere under root
function GameLib.Locate(root, ...)
    local found = GameLib.Find(root, ...)
    if found or not root then return found end
    local name = select(select("#", ...), ...)
    for _, desc in ipairs(root:GetDescendants()) do
        if desc.Name == name and desc:IsA("ModuleScript") then return desc end
    end
    return nil
end

---@return RemoteEvent?  by name in the Remotes folder, else anywhere in ReplicatedStorage
function GameLib.Remote(name)
    local remote = GameLib.RemoteFolder and GameLib.RemoteFolder:FindFirstChild(name)
    remote = remote or ReplicatedStorage:FindFirstChild(name, true)
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

---Plain require first; identity-3 executors get "Cannot require a non-RobloxScript module", so retry once from a fresh identity-2 thread.
---@return table?  module, nil when this executor cannot load it
function GameLib.Require(module)
    if not module or not module:IsA("ModuleScript") then return nil end
    local ok, loaded = pcall(require, module)
    if ok then return loaded end
    local setIdentity = setthreadidentity or setidentity
    local getIdentity = getthreadidentity or getidentity
    if type(setIdentity) ~= "function" or type(getIdentity) ~= "function" then return nil end
    local done, retried = false, nil
    task.spawn(function()
        pcall(setIdentity, 2)
        local switched = select(2, pcall(getIdentity)) == 2
        local again, value = false, nil
        if switched then again, value = pcall(require, module) end
        done, retried = true, again and value or nil
    end)
    local deadline = os.clock() + Config.LoadTimeout
    repeat
        if not done then task.wait() end
    until done or os.clock() > deadline
    return retried
end

do
    local modules = ReplicatedStorage:WaitForChild("Modules", Config.LoadTimeout)
    GameLib.RemoteFolder = ReplicatedStorage:WaitForChild("Remotes", Config.LoadTimeout)
    GameLib.Remotes = GameLib.Require(GameLib.Locate(modules, "Shared", "Remotes"))
    GameLib.Data = GameLib.Require(GameLib.Locate(modules, "Shared", "Data"))
    GameLib.JobsController = GameLib.Require(GameLib.Locate(modules, "Client", "Jobs", "JobsController"))
    GameLib.JobsConstants = GameLib.Require(GameLib.Locate(modules, "Shared", "Jobs", "JobsConstants"))
    GameLib.VehicleController = GameLib.Require(GameLib.Locate(modules, "Client", "Vehicles", "VehicleController"))
    GameLib.TeleportGuard = GameLib.Require(GameLib.Locate(modules, "Client", "Exploit", "VehicleTeleportDetectionController"))
    GameLib.PlayRewardUtil = GameLib.Require(GameLib.Locate(modules, "Shared", "PlayRewards", "PlayRewardUtil"))

    GameLib.VehicleEvent = GameLib.Remote("VehicleEvent")
    GameLib.CodeRemote = GameLib.Remote("Code")
    GameLib.AtmFolder = GameLib.Find(workspace, "Game", "Jobs", "CriminalATMSpawners") or workspace:FindFirstChild("CriminalATMSpawners", true)
end

GameLib.Needs = {
    AtmFarm = { "Remotes", "JobsController", "AtmFolder" },
    DriveFarm = { "VehicleController", "TeleportGuard", "JobsController", "VehicleEvent" },
    AutoPlaytime = { "Remotes", "PlayRewardUtil" },
    AutoClaimMisc = { "Remotes" },
    EspAtm = { "AtmFolder" },
}

GameLib.Parts = {
    VehicleEvent = "remote VehicleEvent",
    CodeRemote = "remote Code",
    AtmFolder = "folder CriminalATMSpawners",
}

---@return string?  first game module the feature needs that did not load
function GameLib.Missing(idx)
    for _, name in ipairs(GameLib.Needs[idx] or {}) do
        if not GameLib[name] then return name end
    end
    return nil
end

---@return Instance[]  ATM spawners, empty when the folder is gone
function GameLib.AtmSpawners()
    local folder = GameLib.AtmFolder
    if not folder or not folder.Parent then
        folder = GameLib.Find(workspace, "Game", "Jobs", "CriminalATMSpawners")
        GameLib.AtmFolder = folder
    end
    return folder and folder:GetChildren() or {}
end

function PatipanStudio.Player.Character()
    local character = LocalPlayer.Character
    if character and character.Parent and character:FindFirstChild("HumanoidRootPart") then
        return character
    end
    return nil
end

function PatipanStudio.Player.Humanoid()
    local character = PatipanStudio.Player.Character()
    return character and character:FindFirstChildOfClass("Humanoid")
end

function PatipanStudio.Player.Root()
    local character = PatipanStudio.Player.Character()
    return character and character.HumanoidRootPart
end

function PatipanStudio.Player.TeleportTo(cframe)
    local root = PatipanStudio.Player.Root()
    if not root then
        return false
    end
    if PatipanStudio.Vehicle.IsSeated() then
        PatipanStudio.Vehicle.Despawn()
        task.wait(1)
    end
    root.CFrame = cframe
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

function PatipanStudio.Vehicle.Current()
    if not GameLib.VehicleController then return nil end
    local vehicle = GameLib.VehicleController.getVehicle()
    return vehicle and vehicle.Object
end

function PatipanStudio.Vehicle.IsSeated()
    local humanoid = PatipanStudio.Player.Humanoid()
    return humanoid ~= nil and humanoid.SeatPart ~= nil
end

function PatipanStudio.Vehicle.Owned()
    local owned = {}
    local stats = PatipanStudio.Util.Stats()
    if not stats then
        return owned
    end
    local vehicles = stats:FindFirstChild("Vehicles")
    if not vehicles then return owned end
    for _, entry in ipairs(vehicles:GetChildren()) do
        if entry.Value == true then
            table.insert(owned, entry.Name)
        end
    end
    table.sort(owned)
    return owned
end

function PatipanStudio.Vehicle.Spawn(vehicleId)
    if not vehicleId or not GameLib.VehicleEvent then
        return nil
    end
    GameLib.VehicleEvent:FireServer("Spawn", vehicleId)
    local deadline = os.clock() + Config.SpawnWait
    repeat
        task.wait(0.25)
    until PatipanStudio.Vehicle.Current() or os.clock() > deadline
    return PatipanStudio.Vehicle.Current()
end

function PatipanStudio.Vehicle.Despawn()
    if not GameLib.VehicleEvent then return end
    GameLib.VehicleEvent:FireServer("Despawn")
end

---@return boolean  moved the car, or the character when on foot
function PatipanStudio.Vehicle.TeleportTo(cframe)
    local car = PatipanStudio.Vehicle.Current()
    if not car or not PatipanStudio.Vehicle.IsSeated() then
        local root = PatipanStudio.Player.Root()
        if root then
            root.CFrame = cframe
        end
        return root ~= nil
    end
    if not GameLib.TeleportGuard then
        return PatipanStudio.Player.TeleportTo(cframe)
    end
    GameLib.TeleportGuard.AuthorizeNextTeleport()
    car:PivotTo(cframe)
    if car.PrimaryPart then
        car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    end
    return true
end

function PatipanStudio.Vehicle.ApplySpeed()
    local car = PatipanStudio.Vehicle.Current()
    local boost = State.Opt.CarSpeed
    if not car or not car.PrimaryPart or boost <= 0 or not PatipanStudio.Vehicle.IsSeated() then
        return
    end
    if not UserInputService:IsKeyDown(Enum.KeyCode.W) then
        return
    end
    local root = car.PrimaryPart
    local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
    if flat.Magnitude < 0.1 then
        return
    end
    local velocity = root.AssemblyLinearVelocity
    local forward = velocity:Dot(flat.Unit)
    local target = math.max(forward, boost)
    root.AssemblyLinearVelocity = flat.Unit * target + Vector3.new(0, velocity.Y, 0)
end

function PatipanStudio.Jobs.Current()
    return LocalPlayer:GetAttribute("JobId")
end

---@return string[]  job ids the game defines plus any job pad on the map, sorted
function PatipanStudio.Jobs.List()
    local seen, list = {}, {}
    local function Add(jobId)
        if type(jobId) ~= "string" or seen[jobId] then return end
        seen[jobId] = true
        list[#list + 1] = jobId
    end
    local constants = GameLib.JobsConstants
    for _, jobId in pairs(constants and constants.JobIds or {}) do
        Add(jobId)
    end
    for _, pad in ipairs(CollectionService:GetTagged("JobPad")) do
        Add(pad:GetAttribute("JobId"))
    end
    table.sort(list)
    return list
end

function PatipanStudio.Jobs.Start(jobId)
    if PatipanStudio.Jobs.Current() == jobId then
        return true
    end
    if not GameLib.JobsController then
        return false
    end
    GameLib.JobsController.RequestStartJobSession(jobId, "jobPad")
    local deadline = os.clock() + 4
    repeat
        task.wait(0.2)
    until PatipanStudio.Jobs.Current() == jobId or os.clock() > deadline
    return PatipanStudio.Jobs.Current() == jobId
end

function PatipanStudio.Jobs.Leave()
    if PatipanStudio.Jobs.Current() and GameLib.JobsController then
        GameLib.JobsController.RequestEndJobSession("jobPad")
    end
end

function PatipanStudio.Atm.LoadCache()
    local read, text = pcall(function()
        return isfile(Config.SpawnerCacheFile) and readfile(Config.SpawnerCacheFile)
    end)
    if not read or type(text) ~= "string" then
        return
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, text)
    if not ok or type(decoded) ~= "table" then
        return
    end
    for id, coords in pairs(decoded) do
        State.Spawners[id] = Vector3.new(coords[1], coords[2], coords[3])
    end
end

function PatipanStudio.Atm.SaveCache()
    local encoded = {}
    for id, position in pairs(State.Spawners) do
        encoded[id] = { position.X, position.Y, position.Z }
    end
    local saved, err = pcall(function()
        if not isfolder("Driving Empire") then
            makefolder("Driving Empire")
        end
        writefile(Config.SpawnerCacheFile, HttpService:JSONEncode(encoded))
    end)
    if not saved then
        warn("[Driving Empire] atm cache:", err)
    end
end

function PatipanStudio.Atm.SpawnerCount()
    local count = 0
    for _ in pairs(State.Spawners) do
        count += 1
    end
    return count
end

local function RecordStreamedSpawners()
    for _, spawner in ipairs(GameLib.AtmSpawners()) do
        local id = spawner:GetAttribute("ComponentServerId")
        if id then
            State.Spawners[id] = spawner.Position
        end
    end
end

function PatipanStudio.Atm.Sweep()
    local root = PatipanStudio.Player.Root()
    if not root then
        return 0
    end
    if PatipanStudio.Vehicle.IsSeated() then
        PatipanStudio.Vehicle.Despawn()
        task.wait(1)
    end
    for x = Config.SweepMin.X, Config.SweepMax.X, Config.SweepStep do
        for z = Config.SweepMin.Z, Config.SweepMax.Z, Config.SweepStep do
            if not State.Alive then
                return PatipanStudio.Atm.SpawnerCount()
            end
            root.CFrame = CFrame.new(x, Config.SweepHeight, z)
            root.AssemblyLinearVelocity = Vector3.zero
            task.wait(Config.SweepDelay)
            RecordStreamedSpawners()
        end
    end
    PatipanStudio.Atm.SaveCache()
    return PatipanStudio.Atm.SpawnerCount()
end

local function FindAtm(spawnerId)
    for _, spawner in ipairs(GameLib.AtmSpawners()) do
        if spawner:GetAttribute("ComponentServerId") == spawnerId then
            return spawner:FindFirstChild("CriminalATM")
        end
    end
    return nil
end

function PatipanStudio.Atm.IsAvailable(atm)
    if not atm or atm:GetAttribute("State") ~= "Normal" then
        return false
    end
    local engaging = atm:GetAttribute("EngagingPlayerId")
    return engaging == nil or engaging == LocalPlayer.UserId
end

function PatipanStudio.Atm.CopNearby(position)
    for _, other in ipairs(Players:GetPlayers()) do
        local character = other ~= LocalPlayer and other.Character
        if character and other:GetAttribute("JobId") == "Security" then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - position).Magnitude < Config.CopAvoidRadius then
                return true
            end
        end
    end
    return false
end

local function WaitForDebounce(character)
    local deadline = os.clock() + Config.DebounceTimeout
    while character:GetAttribute("ATMBustDebounce") and os.clock() < deadline do
        task.wait(0.1)
    end
end

---@return boolean, string?  robbed, else the server's reason
function PatipanStudio.Atm.Bust(atm)
    local character = PatipanStudio.Player.Character()
    if not GameLib.Remotes then
        return false, "Not available on this executor"
    end
    if not character or not PatipanStudio.Atm.IsAvailable(atm) then
        return false, "Unavailable"
    end
    local attachment = atm:FindFirstChild("PromptAttachment")
    local target = attachment and attachment.WorldPosition or atm:GetPivot().Position
    if State.Opt.AvoidCops and PatipanStudio.Atm.CopNearby(target) then
        return false, "CopNearby"
    end
    WaitForDebounce(character)
    character.HumanoidRootPart.CFrame = CFrame.lookAt(target + atm:GetPivot().LookVector * 3, target)
    task.wait(0.25)
    local started, reason = GameLib.Remotes.invokeServer("AttemptATMBustStart", atm)
    if not started then
        return false, reason
    end
    task.wait(Config.BustWait)
    local earnedBefore = character:GetAttribute("CurrencyEarned") or 0
    local done, failReason = GameLib.Remotes.invokeServer("AttemptATMBustComplete", atm)
    if not done then
        return false, failReason
    end
    State.AtmSession.Busted += 1
    task.defer(function()
        task.wait(0.5)
        State.AtmSession.Earned += math.max(0, (character:GetAttribute("CurrencyEarned") or 0) - earnedBefore)
    end)
    return true
end

function PatipanStudio.Atm.DropOffPositions()
    local positions = {}
    for _, point in ipairs(CollectionService:GetTagged("CriminalDropOffPoint")) do
        table.insert(positions, point:GetPivot().Position)
    end
    if #positions == 0 then
        return Config.DropOffSeeds
    end
    return positions
end

function PatipanStudio.Atm.NearestDropOff()
    local root = PatipanStudio.Player.Root()
    local best, bestDistance = nil, math.huge
    for _, position in ipairs(PatipanStudio.Atm.DropOffPositions()) do
        local distance = root and (position - root.Position).Magnitude or 0
        if distance < bestDistance then
            best, bestDistance = position, distance
        end
    end
    return best
end

function PatipanStudio.Atm.Crimes()
    local character = PatipanStudio.Player.Character()
    return character and character:GetAttribute("CrimesCommitted") or 0
end

---@return boolean        paid
---@return number|string  cash gained, or why it did not pay
function PatipanStudio.Atm.CashOut()
    if PatipanStudio.Atm.Crimes() < Config.CashOutCrimes then
        return false, "Need 5 stars first"
    end
    local seed = PatipanStudio.Atm.NearestDropOff()
    if not seed then return false, "No drop-off found" end

    local stage = Vector3.new(0, 3, Config.DropOffStage)
    local cashBefore = PatipanStudio.Util.Cash()
    State.Banking = true
    PatipanStudio.Player.TeleportTo(CFrame.new(seed + stage))
    task.wait(Config.StreamWait)
    local target = PatipanStudio.Atm.NearestDropOff() or seed

    for _ = 1, Config.DropOffTries do
        PatipanStudio.Player.TeleportTo(CFrame.new(target + stage))
        task.wait(Config.DropOffSettle)
        PatipanStudio.Player.TeleportTo(CFrame.new(target + Vector3.new(0, 3, 0)))
        local deadline = os.clock() + Config.DropOffPayWait
        repeat
            task.wait(0.25)
        until PatipanStudio.Util.Cash() > cashBefore or os.clock() > deadline
        if PatipanStudio.Util.Cash() > cashBefore or PatipanStudio.Atm.Crimes() < Config.CashOutCrimes then break end
    end
    State.Banking = false

    local gained = PatipanStudio.Util.Cash() - cashBefore
    if gained <= 0 then return false, "The drop-off did not pay" end
    State.AtmSession.CashedOut += gained
    return true, gained
end

function PatipanStudio.Atm.RunPass()
    if not PatipanStudio.Jobs.Start("Criminal") then
        State.AtmWarn = "Could not start the Criminal job"
        error(State.AtmWarn, 0)
    end
    State.AtmWarn = nil
    if PatipanStudio.Atm.SpawnerCount() == 0 then
        PatipanStudio.Atm.Sweep()
    end
    local busted = 0
    for id, position in pairs(State.Spawners) do
        if not State.Opt.AtmFarm or not State.Alive then
            break
        end
        PatipanStudio.Player.TeleportTo(CFrame.new(position + Vector3.new(0, 6, 0)))
        local atm
        local deadline = os.clock() + Config.StreamWait
        repeat
            task.wait(0.1)
            atm = FindAtm(id)
        until atm or os.clock() > deadline
        RecordStreamedSpawners()
        if PatipanStudio.Atm.IsAvailable(atm) and PatipanStudio.Atm.Bust(atm) then
            busted += 1
        end
        local crimes = PatipanStudio.Atm.Crimes()
        if crimes >= State.Opt.CashOutCrimes or (crimes >= Config.CashOutCrimes and PatipanStudio.Atm.WantedLeft() < Config.WantedSafety) then
            PatipanStudio.Atm.CashOut()
        end
    end
    return busted
end

function PatipanStudio.Atm.WantedLeft()
    local character = PatipanStudio.Player.Character()
    local expire = character and character:GetAttribute("CriminalExpireEpoch")
    return expire and expire - workspace:GetServerTimeNow() or math.huge
end

function PatipanStudio.Atm.FarmStep()
    local busted = PatipanStudio.Atm.RunPass()
    if not State.Opt.AtmFarm then
        return
    end
    if PatipanStudio.Atm.Crimes() >= State.Opt.CashOutCrimes then
        PatipanStudio.Atm.CashOut()
    end
    if busted == 0 and State.Opt.HopWhenEmpty and PatipanStudio.Atm.Crimes() == 0 then
        PatipanStudio.Session.Hop()
    end
end

function PatipanStudio.Atm.NearestAvailable()
    local root = PatipanStudio.Player.Root()
    if not root then return nil end
    local best, bestDistance
    for _, spawner in ipairs(GameLib.AtmSpawners()) do
        local atm = spawner:FindFirstChild("CriminalATM")
        if PatipanStudio.Atm.IsAvailable(atm) then
            local distance = (spawner.Position - root.Position).Magnitude
            if not bestDistance or distance < bestDistance then
                best, bestDistance = atm, distance
            end
        end
    end
    return best
end

---@return boolean, string?  robbed, else why not
function PatipanStudio.Atm.RobNearest()
    if not PatipanStudio.Jobs.Start("Criminal") then
        return false, "Could not start the Criminal job"
    end
    local atm = PatipanStudio.Atm.NearestAvailable()
    if not atm then
        return false, "No ATM nearby"
    end
    return PatipanStudio.Atm.Bust(atm)
end

---@return table?  Center, Axis, Half, Top of the longest flat asphalt road; nil if none is loaded
function PatipanStudio.Drive.FindRoad()
    local road = State.DriveRoad
    if road and road.Part.Parent then return road end
    local best, bestLength = nil, Config.DriveRoadMin
    for _, part in ipairs((workspace:FindFirstChild("Map") or workspace):GetDescendants()) do
        if not part:IsA("BasePart") or part.Material ~= Enum.Material.Asphalt or not part.CanCollide then continue end
        local size = part.Size
        local length, width = math.max(size.X, size.Z), math.min(size.X, size.Z)
        local axis = size.X >= size.Z and part.CFrame.RightVector or part.CFrame.LookVector
        if length > bestLength and width >= Config.DriveRoadWidth and math.abs(axis.Y) < Config.DriveRoadFlat then
            best, bestLength = { Part = part, Axis = (axis * Vector3.new(1, 0, 1)).Unit, Length = length }, length
        end
    end
    if not best then return nil end
    local part = best.Part
    State.DriveRoad = {
        Part = part,
        Center = part.Position,
        Axis = best.Axis,
        Half = best.Length / 2 - Config.DriveEdge,
        Top = part.Position.Y + part.Size.Y / 2 + Config.DriveLift,
    }
    return State.DriveRoad
end

---@return table?  road, streamed in when it is not loaded yet
function PatipanStudio.Drive.LoadRoad()
    local road = PatipanStudio.Drive.FindRoad()
    if road then return road end
    pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Config.DriveRoadSeed, Config.LoadTimeout)
    task.wait(Config.StreamWait)
    return PatipanStudio.Drive.FindRoad()
end

function PatipanStudio.Drive.Warp(road)
    local start = road.Center - road.Axis * road.Half
    local spot = Vector3.new(start.X, road.Top, start.Z)
    PatipanStudio.Vehicle.TeleportTo(CFrame.lookAt(spot, spot + road.Axis))
end

function PatipanStudio.Drive.Step(road)
    local car = PatipanStudio.Vehicle.Current()
    local root = car and car.PrimaryPart
    if not root or not PatipanStudio.Vehicle.IsSeated() then return end
    local offset = root.Position - road.Center
    local along = offset:Dot(road.Axis)
    if along > road.Half then
        PatipanStudio.Drive.Warp(road)
        return
    end
    local side = offset - road.Axis * along
    side = Vector3.new(side.X, 0, side.Z)
    local fall = math.min(root.AssemblyLinearVelocity.Y, 0)
    root.AssemblyLinearVelocity = road.Axis * Config.DriveSpeed - side * Config.DriveAlign + Vector3.new(0, fall, 0)
end

function PatipanStudio.Drive.Board()
    local carId = State.Opt.DriveCar or PatipanStudio.Vehicle.Owned()[1]
    for _ = 1, Config.SpawnTries do
        local car = PatipanStudio.Vehicle.Spawn(carId)
        if car then return car end
    end
    return nil
end

---@return boolean, string?  started, else why not
function PatipanStudio.Drive.Start()
    if State.DriveConn then return true end
    PatipanStudio.Jobs.Leave()
    local road = PatipanStudio.Drive.LoadRoad()
    if not road then return false, "No paved road found" end
    local car = PatipanStudio.Vehicle.Current()
    if not car or not PatipanStudio.Vehicle.IsSeated() then
        car = PatipanStudio.Drive.Board()
    end
    if not car then return false, "No car to drive" end
    task.wait(1)
    PatipanStudio.Drive.Warp(road)
    task.wait(1)
    if not State.Opt.DriveFarm or State.DriveConn then return true end
    State.DriveConn = RunService.Heartbeat:Connect(function()
        PatipanStudio.Drive.Step(road)
    end)
    return true
end

function PatipanStudio.Drive.Stop()
    if State.DriveConn then
        State.DriveConn:Disconnect()
        State.DriveConn = nil
    end
    local car = PatipanStudio.Vehicle.Current()
    if car and car.PrimaryPart then
        car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    end
end

function PatipanStudio.Rewards.ClaimPlaytime()
    local ok, unclaimed = pcall(function()
        local pending = GameLib.PlayRewardUtil.getUnclaimedRewards(LocalPlayer)
        if type(pending) == "table" and pending.expect then
            pending = pending:expect()
        end
        return pending
    end)
    if not ok or type(unclaimed) ~= "table" then
        return 0
    end
    local count = 0
    for index in pairs(unclaimed) do
        GameLib.Remotes.fireServer("PlayRewards", tonumber(index) or index, false)
        count += 1
        task.wait(0.5)
    end
    return count
end

function PatipanStudio.Rewards.ClaimMisc()
    if not GameLib.Remotes then return end
    GameLib.Remotes.fireServer("ClaimRewards")
    GameLib.Remotes.fireServer("RaceLeaderboardClaimRewards")
end

function PatipanStudio.Rewards.Redeemed()
    local stats = PatipanStudio.Util.Stats()
    local codes = stats and stats:FindFirstChild("Codes")
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, codes and codes.Value or "")
    return ok and type(decoded) == "table" and decoded or {}
end

---@return number, number  new codes redeemed, cash gained
function PatipanStudio.Rewards.RedeemCodes(codes)
    if not GameLib.CodeRemote then return 0, 0 end
    local redeemedBefore = PatipanStudio.Rewards.Redeemed()
    local cashBefore = PatipanStudio.Util.Cash()
    local success = 0
    for _, code in ipairs(codes) do
        if not redeemedBefore[code] then
            GameLib.CodeRemote:FireServer(code)
            task.wait(Config.CodeDelay)
            if PatipanStudio.Rewards.Redeemed()[code] then
                success += 1
            end
        end
    end
    return success, PatipanStudio.Util.Cash() - cashBefore
end

function PatipanStudio.Teleport.Destinations()
    local destinations = {}
    local names = {}
    local function Add(name, position)
        if position and not destinations[name] then
            destinations[name] = position
            table.insert(names, name)
        end
    end
    local padCount = {}
    for _, pad in ipairs(CollectionService:GetTagged("JobPad")) do
        local jobId = pad:GetAttribute("JobId")
        if jobId and pad:IsA("BasePart") then
            padCount[jobId] = (padCount[jobId] or 0) + 1
            Add(padCount[jobId] == 1 and "Job: " .. jobId or ("Job: %s %d"):format(jobId, padCount[jobId]), pad.Position)
        end
    end
    for name, position in pairs(Config.PlaceSeeds) do
        Add(name, position)
    end
    for index, position in ipairs(PatipanStudio.Atm.DropOffPositions()) do
        Add(("Criminal Drop-off %d"):format(index), position)
    end
    local heist = GameLib.Find(workspace, "Game", "Heists", "BankHeist")
    local heistStart = heist and heist:FindFirstChild("HeistStartTeleport", true)
    if heistStart then
        Add("Bank Heist", heistStart.Position)
    end
    local dealerships = workspace.Game:FindFirstChild("Dealerships")
    dealerships = dealerships and dealerships:FindFirstChild("Dealerships")
    if dealerships then
        for _, dealership in ipairs(dealerships:GetChildren()) do
            local part = dealership:FindFirstChildWhichIsA("BasePart", true)
            if part then
                Add("Dealership: " .. dealership.Name, part.Position)
            end
        end
    end
    table.sort(names)
    return names, destinations
end

function PatipanStudio.Teleport.Go(position)
    if not position then
        return
    end
    LocalPlayer:RequestStreamAroundAsync(position, 5)
    PatipanStudio.Vehicle.TeleportTo(CFrame.new(position + Vector3.new(0, 5, 0)))
end

function PatipanStudio.Teleport.ToPlayer(name)
    local target = Players:FindFirstChild(name)
    local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if root then
        PatipanStudio.Teleport.Go(root.Position + Vector3.new(0, 0, 4))
    end
end

function PatipanStudio.Movement.Step()
    local opt = State.Opt
    local character = PatipanStudio.Player.Character()
    local humanoid = PatipanStudio.Player.Humanoid()
    if not character or not humanoid then
        return
    end
    if opt.SpeedEnabled and not PatipanStudio.Vehicle.IsSeated() then
        humanoid.WalkSpeed = opt.WalkSpeed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = opt.JumpPower
    end
    if opt.Noclip then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                State.CollideBackup[part] = true
                part.CanCollide = false
            end
        end
    end
    PatipanStudio.Vehicle.ApplySpeed()
end

function PatipanStudio.Movement.SetNoclip(enabled)
    if enabled then return end
    for part, original in pairs(State.CollideBackup) do
        if part.Parent then
            part.CanCollide = original
        end
    end
    table.clear(State.CollideBackup)
end

function PatipanStudio.Movement.ResetSpeed()
    local humanoid = PatipanStudio.Player.Humanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

function PatipanStudio.Movement.SetFullbright(enabled)
    if enabled then
        State.LightingBackup = State.LightingBackup or {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
        }
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        return
    end
    if State.LightingBackup then
        for property, value in pairs(State.LightingBackup) do
            Lighting[property] = value
        end
        State.LightingBackup = nil
    end
end

function PatipanStudio.Movement.Bind()
    table.insert(State.Conns, RunService.Stepped:Connect(function()
        PatipanStudio.Scheduler.Run(PatipanStudio.Scheduler.MovementJob)
    end))
    table.insert(State.Conns, UserInputService.JumpRequest:Connect(function()
        local humanoid = PatipanStudio.Player.Humanoid()
        if State.Opt.InfiniteJump and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
end

local function EspMark(key, adornee, text, color)
    local entry = State.EspObjects[key]
    if entry and entry.Highlight.Parent and entry.Highlight.Adornee == adornee then
        entry.Label.Text = text
        return
    end
    if entry then
        entry.Highlight:Destroy()
        entry.Billboard:Destroy()
    end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = color
    highlight.Adornee = adornee
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    PatipanStudio.Util.Mount(highlight)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(160, 28)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    PatipanStudio.Util.Mount(billboard)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = text
    label.Parent = billboard
    State.EspObjects[key] = { Highlight = highlight, Billboard = billboard, Label = label }
end

function PatipanStudio.Esp.Refresh()
    local opt = State.Opt
    local root = PatipanStudio.Player.Root()
    local alive = {}
    local function Distance(position)
        return root and math.floor((position - root.Position).Magnitude) or 0
    end
    if opt.EspAtm then
        for _, spawner in ipairs(GameLib.AtmSpawners()) do
            local atm = spawner:FindFirstChild("CriminalATM")
            if PatipanStudio.Atm.IsAvailable(atm) then
                local key = "atm" .. tostring(spawner:GetAttribute("ComponentServerId"))
                alive[key] = true
                EspMark(key, atm, ("ATM %s · %dm"):format(tostring(atm:GetAttribute("Rarity")), Distance(spawner.Position)), Color3.fromRGB(90, 220, 120))
            end
        end
    end
    if opt.EspCops then
        for _, other in ipairs(Players:GetPlayers()) do
            local character = other.Character
            local job = other:GetAttribute("JobId")
            if other ~= LocalPlayer and character and character:FindFirstChild("HumanoidRootPart") and job then
                local key = "plr" .. other.UserId
                alive[key] = true
                local color = job == "Security" and Color3.fromRGB(80, 140, 255) or job == "Criminal" and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(232, 160, 76)
                EspMark(key, character, ("%s [%s] · %dm"):format(other.DisplayName, job, Distance(character.HumanoidRootPart.Position)), color)
            end
        end
    end
    if opt.EspDropOff then
        for index, point in ipairs(CollectionService:GetTagged("CriminalDropOffPoint")) do
            local key = "drop" .. index
            alive[key] = true
            EspMark(key, point, ("Drop-off · %dm"):format(Distance(point:GetPivot().Position)), Color3.fromRGB(255, 210, 80))
        end
    end
    for key, entry in pairs(State.EspObjects) do
        if not alive[key] then
            entry.Highlight:Destroy()
            entry.Billboard:Destroy()
            State.EspObjects[key] = nil
        end
    end
end

function PatipanStudio.Session.Bind()
    table.insert(State.Conns, LocalPlayer.Idled:Connect(function()
        if State.Opt.AntiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end
    end))
    table.insert(State.Conns, GuiService.ErrorMessageChanged:Connect(function()
        if not State.Opt.AutoRejoin then
            return
        end
        task.wait(Config.HopDelay)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end))
end

function PatipanStudio.Session.Hop()
    local body = PatipanStudio.Util.HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId))
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body or "")
    if not ok or type(decoded) ~= "table" then
        return false
    end
    local candidates = {}
    for _, server in ipairs(decoded.data or {}) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 then
            table.insert(candidates, server.id)
        end
    end
    if #candidates == 0 then
        return false
    end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(#candidates)], LocalPlayer)
    return true
end

function PatipanStudio.Scheduler.AtmStep()
    if State.Opt.AtmFarm then
        PatipanStudio.Atm.FarmStep()
        return
    end
    if not State.BankOnStop then return end
    State.BankOnStop = false
    if PatipanStudio.Atm.Crimes() < Config.CashOutCrimes then return end

    local ok, got = PatipanStudio.Atm.CashOut()
    if ok then
        PatipanStudio.UI.Notify("Banked $" .. PatipanStudio.Util.Commas(got) .. " before stopping", "Success")
    else
        PatipanStudio.UI.Notify("Wanted cash not banked: " .. got, "Warning")
    end
end

function PatipanStudio.Scheduler.RewardStep()
    local opt = State.Opt
    local now = os.clock()
    if not (opt.AutoPlaytime or opt.AutoClaimMisc) or now - State.LastReward <= Config.RewardInterval then
        return
    end
    State.LastReward = now
    if opt.AutoPlaytime then
        PatipanStudio.Rewards.ClaimPlaytime()
    end
    if opt.AutoClaimMisc then
        PatipanStudio.Rewards.ClaimMisc()
    end
end

function PatipanStudio.Scheduler.EspStep()
    local now = os.clock()
    if now - State.LastEsp > Config.EspInterval then
        State.LastEsp = now
        PatipanStudio.Esp.Refresh()
    end
end

PatipanStudio.Scheduler.Jobs = {
    { "ATM Farm", PatipanStudio.Scheduler.AtmStep, { "AtmFarm" } },
    { "Rewards", PatipanStudio.Scheduler.RewardStep, { "AutoPlaytime", "AutoClaimMisc" } },
    { "ESP", PatipanStudio.Scheduler.EspStep, { "EspAtm", "EspCops", "EspDropOff" }, Core = true },
}

PatipanStudio.Scheduler.MovementJob = { "Movement", PatipanStudio.Movement.Step, { "SpeedEnabled", "Noclip" } }

---@param job table  { label, step, toggle idxs }
---@return boolean   any of the job's features is on
function PatipanStudio.Scheduler.Wanted(job)
    for _, idx in ipairs(job[3]) do
        if State.Opt[idx] then return true end
    end
    return false
end

---Turns the job's features off after Config.JobFailLimit errors spanning Config.JobFailWindow seconds; the UI pump flips the toggles (this thread has touched game modules) and their callbacks restore.
---@param job table  { label, step, toggle idxs, Core = never rests }
function PatipanStudio.Scheduler.Run(job)
    if job.Stopped then
        if not PatipanStudio.Scheduler.Wanted(job) then return end
        job.Stopped = nil
    end
    local ok, err = pcall(job[2])
    if ok then
        job.Streak = nil
        return
    end

    local streak = job.Streak
    if not streak then
        streak = { count = 0, since = os.clock() }
        job.Streak = streak
        warn("[Driving Empire] " .. job[1] .. ":", err)
    end
    streak.count += 1
    if streak.count < Config.JobFailLimit or os.clock() - streak.since < Config.JobFailWindow then return end

    local switched = PatipanStudio.Scheduler.Wanted(job)
    if job.Core and not switched then return end
    job.Streak = nil
    job.Stopped = not job.Core and not switched
    for _, idx in ipairs(job[3]) do
        if State.Opt[idx] then
            State.Opt[idx] = false
            table.insert(State.Halted, idx)
        end
    end

    local reason = tostring(err):match("^[^\n]*")
    warn("[Driving Empire] " .. job[1] .. " stopped:", reason)
    if switched then PatipanStudio.UI.Notify(job[1] .. " stopped: " .. reason, "Warning") end
end

function PatipanStudio.Scheduler.Boot()
    PatipanStudio.Atm.LoadCache()
    PatipanStudio.Movement.Bind()
    PatipanStudio.Session.Bind()
    task.spawn(function()
        while State.Alive do
            if not State.Busy then
                State.Busy = true
                for _, job in ipairs(PatipanStudio.Scheduler.Jobs) do
                    PatipanStudio.Scheduler.Run(job)
                end
                State.Busy = false
            end
            task.wait(Config.TickDelay)
        end
    end)
end

function PatipanStudio.Scheduler.Stop()
    State.Alive = false
    for key in pairs(State.Opt) do
        if type(State.Opt[key]) == "boolean" and key ~= "AntiAfk" then
            State.Opt[key] = false
        end
    end
    PatipanStudio.Drive.Stop()
    PatipanStudio.Movement.SetNoclip(false)
    PatipanStudio.Movement.ResetSpeed()
    PatipanStudio.Movement.SetFullbright(false)
    for _, conn in ipairs(State.Conns) do
        conn:Disconnect()
    end
    table.clear(State.Conns)
    PatipanStudio.Esp.Refresh()
end

PatipanStudio.UI = {}
local Library, T

---@param kind string?  Info, Success, Warning or Error
function PatipanStudio.UI.Notify(text, kind)
    State.Messages[#State.Messages + 1] = { text, kind }
end

function PatipanStudio.UI.Spawn(action)
    return function()
        task.spawn(PatipanStudio.Util.Try, action)
    end
end

function PatipanStudio.UI.StartDrive()
    local started, reason = PatipanStudio.Drive.Start()
    if started then return end
    State.Opt.DriveFarm = false
    table.insert(State.Halted, "DriveFarm")
    PatipanStudio.UI.Notify(reason or "Could not start driving", "Warning")
end

---@param onChange function?  runs after State.Opt is updated
function PatipanStudio.UI.Toggle(group, key, text, description, onChange, risky)
    return group:AddToggle(key, {
        Text = text,
        Description = description,
        Default = State.Opt[key],
        Risky = risky,
        Callback = function(value)
            State.Opt[key] = value
            if onChange then
                PatipanStudio.Util.Try(onChange, value)
            end
        end,
    })
end

function PatipanStudio.UI.Slider(group, key, text, description, min, max)
    local opt = State.Opt
    return group:AddSlider(key, {
        Text = text,
        Description = description,
        Min = min, Max = max, Default = opt[key], Rounding = 0,
        Callback = function(value)
            opt[key] = tonumber(value) or opt[key]
        end,
    })
end

function PatipanStudio.UI.Panic()
    for idx, toggle in pairs(Library.Toggles) do
        if type(State.Opt[idx]) == "boolean" and toggle.Value == true then
            toggle:SetValue(false)
        end
    end
end

---@return string  one line for the status label
function PatipanStudio.UI.AtmStatus()
    if State.Banking then return "Cashing out" end
    if State.AtmWarn then return "Warn: " .. State.AtmWarn end
    if not State.Opt.AtmFarm then return "Off" end
    return ("Robbing · %d stars"):format(PatipanStudio.Atm.Crimes())
end

function PatipanStudio.UI.StatusText()
    local session = State.AtmSession
    local char = PatipanStudio.Player.Character()
    local carried = char and char:GetAttribute("CurrencyEarned") or 0
    return ("ATM Farm: %s · Drive: %s\nCash $%s · Job %s · Stars %d\nATMs robbed %d · Wanted cash $%s · Cashed out $%s\nATM spots known %d"):format(
        PatipanStudio.UI.AtmStatus(), State.Opt.DriveFarm and "Driving" or "Off",
        PatipanStudio.Util.Commas(PatipanStudio.Util.Cash()), tostring(PatipanStudio.Jobs.Current() or "Citizen"), PatipanStudio.Atm.Crimes(),
        session.Busted, PatipanStudio.Util.Commas(carried), PatipanStudio.Util.Commas(session.CashedOut), PatipanStudio.Atm.SpawnerCount())
end

function PatipanStudio.UI.BuildAtm(farmTab)
    local atmBox = farmTab:AddLeftGroupbox(T("ATM Farm", "ฟาร์ม ATM"))
    local wasOn = false
    PatipanStudio.UI.Toggle(atmBox, "AtmFarm", T("Auto ATM Farm", "ฟาร์ม ATM อัตโนมัติ"), T("Robs every ATM on the map with the full crime bonus, then cashes out", "ปล้น ATM ทุกตู้ในแมพพร้อมโบนัสอาชญากรรมเต็ม แล้วส่งเงิน"), function(on)
        if on then State.AtmWarn = nil end
        State.BankOnStop = wasOn and not on and PatipanStudio.Atm.Crimes() >= Config.CashOutCrimes
        wasOn = on
    end, true):AddKeyPicker("AtmFarmKey", { Default = "None", Mode = "Toggle" })
    PatipanStudio.UI.Slider(atmBox, "CashOutCrimes", T("Cash Out At Robberies", "ส่งเงินเมื่อปล้นครบ"), T("Banks the loot after this many robberies (higher = more risk)", "ส่งเงินหลังปล้นครบจำนวนนี้ (ยิ่งมากยิ่งเสี่ยง)"), 5, 30)

    atmBox:AddButton({ Text = T("Rob Nearest ATM", "ปล้น ATM ที่ใกล้ที่สุด"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        local ok, reason = PatipanStudio.Atm.RobNearest()
        PatipanStudio.UI.Notify(ok and "ATM robbed" or ("Failed: " .. tostring(reason)), ok and "Success" or "Warning")
    end) }):AddButton({ Text = T("Cash Out Now", "ส่งเงินเดี๋ยวนี้"), Func = PatipanStudio.UI.Spawn(function()
        local ok, got = PatipanStudio.Atm.CashOut()
        PatipanStudio.UI.Notify(ok and ("Cashed out $" .. PatipanStudio.Util.Commas(got)) or got, ok and "Success" or "Warning")
    end) })
    atmBox:AddButton({ Text = T("Scan Map For ATMs", "สแกนหา ATM ทั้งแมพ"), Func = PatipanStudio.UI.Spawn(function()
        PatipanStudio.UI.Notify(("Found %d ATM spots"):format(PatipanStudio.Atm.Sweep()))
    end) })
end

function PatipanStudio.UI.BuildAtmSafety(farmTab)
    local safetyBox = farmTab:AddRightGroupbox(T("ATM Safety", "ความปลอดภัย ATM"))
    PatipanStudio.UI.Toggle(safetyBox, "HopWhenEmpty", T("Server Hop When Empty", "ย้ายเซิร์ฟเมื่อ ATM หมด"), T("Moves to a new server once every ATM is taken", "ย้ายไปเซิร์ฟใหม่เมื่อ ATM ถูกปล้นหมดแล้ว"))
    PatipanStudio.UI.Toggle(safetyBox, "AvoidCops", T("Avoid Police", "หลบตำรวจ"), T("Skips ATMs with police standing close", "ข้าม ATM ที่มีตำรวจอยู่ใกล้"))
end

function PatipanStudio.UI.BuildFarm(window)
    local farmTab = window:AddTab(T("Farm", "ฟาร์ม"), "zap", T("Money farming", "ฟาร์มเงิน"))

    local statusBox = farmTab:AddLeftGroupbox(T("Status", "สถานะ"))
    PatipanStudio.UI.StatusLabel = statusBox:AddLabel("Loading...", true)
    statusBox:AddButton({ Text = T("Panic - All Off", "ฉุกเฉิน ปิดทั้งหมด"), Style = "Danger", Func = PatipanStudio.UI.Panic })

    PatipanStudio.UI.BuildAtm(farmTab)

    local discordBox = farmTab:AddRightGroupbox(T("Discord", "Discord"), "link")
    discordBox:AddLabel(Config.Discord)
    discordBox:AddButton({ Text = T("Copy Discord Link", "คัดลอกลิงก์ Discord"), Style = "Primary", Func = function()
        local copy = setclipboard or toclipboard
        local copied = type(copy) == "function" and pcall(copy, Config.Discord)
        PatipanStudio.UI.Notify(copied and "Discord link copied" or Config.Discord)
    end })

    local logBox = farmTab:AddRightGroupbox(T("Update Log", "อัปเดตล่าสุด"), "bell")
    for i = 1, math.min(2, #Config.UpdateLog) do
        local entry = Config.UpdateLog[i]
        logBox:AddParagraph({ Title = entry[1], Content = entry[2] })
    end

    PatipanStudio.UI.BuildAtmSafety(farmTab)

    local jobBox = farmTab:AddRightGroupbox(T("Jobs", "อาชีพ"))
    local jobDropdown = jobBox:AddDropdown("JobPick", {
        Text = T("Switch Job", "เปลี่ยนอาชีพ"),
        Values = PatipanStudio.Jobs.List(),
        Default = 1,
        Callback = function(value)
            State.Opt.JobPick = value
        end,
    })
    jobBox:AddButton({ Text = T("Start Job", "เริ่มงาน"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        PatipanStudio.UI.Notify(PatipanStudio.Jobs.Start(State.Opt.JobPick or "Criminal") and "Job started" or "Could not start job")
    end) }):AddButton({ Text = T("Quit Job", "ออกจากงาน"), Func = PatipanStudio.UI.Spawn(PatipanStudio.Jobs.Leave) })
        :AddButton({ Text = T("Refresh", "รีเฟรช"), Func = function()
            jobDropdown:SetValues(PatipanStudio.Jobs.List())
        end })

    local driveBox = farmTab:AddRightGroupbox(T("Drive Farm", "ฟาร์มขับรถ"))
    PatipanStudio.UI.Toggle(driveBox, "DriveFarm", T("Auto Drive", "ขับรถอัตโนมัติ"), T("Drives nonstop for passive cash", "ขับไม่หยุดเพื่อรับเงินจากการขับ"), function(on)
        if not on then
            PatipanStudio.Drive.Stop()
            return
        end
        task.spawn(PatipanStudio.Util.Try, PatipanStudio.UI.StartDrive)
    end):AddKeyPicker("DriveFarmKey", { Default = "None", Mode = "Toggle" })
end

function PatipanStudio.UI.BuildRewards(window)
    local rewardTab = window:AddTab(T("Rewards", "รางวัล"), "bell", T("Codes and claims", "โค้ดและรับรางวัล"))

    local codeBox = rewardTab:AddLeftGroupbox(T("Codes", "โค้ด"))
    codeBox:AddButton({ Text = T("Redeem All Codes", "ใช้โค้ดทั้งหมด"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        if not GameLib.CodeRemote then
            PatipanStudio.UI.Notify("The code box was not found in this game version", "Warning")
            return
        end
        local count, cash = PatipanStudio.Rewards.RedeemCodes(Config.Codes)
        PatipanStudio.UI.Notify(("Redeemed %d new codes (+$%s)"):format(count, PatipanStudio.Util.Commas(cash)))
    end) })
    codeBox:AddInput("Code", {
        Text = T("Custom Code", "ใส่โค้ดเอง"),
        Default = "",
        Finished = true,
        NoSave = true,
        Callback = function(value)
            State.Opt.Code = value
        end,
    })
    codeBox:AddButton({ Text = T("Redeem", "ใช้โค้ด"), Func = PatipanStudio.UI.Spawn(function()
        local count = PatipanStudio.Rewards.RedeemCodes({ State.Opt.Code })
        PatipanStudio.UI.Notify(count > 0 and "Code redeemed" or "Code invalid or already used")
    end) })

    local claimBox = rewardTab:AddRightGroupbox(T("Claims", "รับรางวัล"))
    PatipanStudio.UI.Toggle(claimBox, "AutoPlaytime", T("Auto Playtime Rewards", "รับรางวัลเวลาเล่นอัตโนมัติ"), T("Claims cash, cars and packs as soon as they unlock", "รับเงิน รถ และแพ็กทันทีที่ปลดล็อก"))
        :AddKeyPicker("AutoPlaytimeKey", { Default = "None", Mode = "Toggle" })
    PatipanStudio.UI.Toggle(claimBox, "AutoClaimMisc", T("Auto Claim Pending", "รับรางวัลค้างอัตโนมัติ"), T("Claims pending race and event rewards", "รับรางวัลแข่งและอีเวนต์ที่ค้างอยู่"))
    claimBox:AddButton({ Text = T("Claim All Now", "รับทั้งหมดเดี๋ยวนี้"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        local count = PatipanStudio.Rewards.ClaimPlaytime()
        PatipanStudio.Rewards.ClaimMisc()
        PatipanStudio.UI.Notify(("Claimed %d playtime rewards"):format(count))
    end) })
end

function PatipanStudio.UI.BuildVehicle(window)
    local carTab = window:AddTab(T("Vehicle", "รถ"), "play", T("Cars and driving", "รถและการขับ"))
    local read, owned = pcall(PatipanStudio.Vehicle.Owned)
    owned = read and owned or {}
    State.Opt.DriveCar = owned[1]

    local carBox = carTab:AddLeftGroupbox(T("Garage", "โรงรถ"))
    local carDropdown = carBox:AddDropdown("DriveCar", {
        Text = T("Car", "รถ"),
        Values = owned,
        Default = 1,
        Searchable = true,
        Callback = function(value)
            State.Opt.DriveCar = value
        end,
    })
    carBox:AddButton({ Text = T("Spawn Car", "เรียกรถ"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        PatipanStudio.UI.Notify(PatipanStudio.Vehicle.Spawn(State.Opt.DriveCar) and "Car spawned" or "Spawn failed")
    end) }):AddButton({ Text = T("Despawn", "เก็บรถ"), Func = PatipanStudio.UI.Spawn(PatipanStudio.Vehicle.Despawn) })
        :AddButton({ Text = T("Refresh", "รีเฟรช"), Func = function()
            carDropdown:SetValues(PatipanStudio.Vehicle.Owned())
        end })

    local tuneBox = carTab:AddRightGroupbox(T("Performance", "สมรรถนะ"))
    PatipanStudio.UI.Slider(tuneBox, "CarSpeed", T("Car Speed Boost", "เร่งความเร็วรถ"), T("Holds this speed while pressing W (0 = off)", "คงความเร็วนี้ขณะกด W (0 = ปิด)"), 0, 600)
end

local function PlayerNames()
    local names = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer then table.insert(names, other.Name) end
    end
    return names
end

function PatipanStudio.UI.BuildTeleport(window)
    local teleportTab = window:AddTab(T("Teleport", "วาร์ป"), "globe", T("Go anywhere", "ไปได้ทุกที่"))
    local read, destNames, destinations = pcall(PatipanStudio.Teleport.Destinations)
    if not read then destNames, destinations = {}, {} end

    local placeBox = teleportTab:AddLeftGroupbox(T("Places", "สถานที่"))
    local placeDropdown = placeBox:AddDropdown("Place", {
        Text = T("Destination", "จุดหมาย"),
        Values = destNames,
        Default = 1,
        Searchable = true,
        Callback = function(value)
            State.Opt.Place = value
        end,
    })
    placeBox:AddButton({ Text = T("Teleport", "วาร์ป"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        PatipanStudio.Teleport.Go(destinations[State.Opt.Place or destNames[1]])
    end) }):AddButton({ Text = T("Refresh", "รีเฟรช"), Func = function()
        destNames, destinations = PatipanStudio.Teleport.Destinations()
        placeDropdown:SetValues(destNames)
    end })

    local playerBox = teleportTab:AddRightGroupbox(T("Players", "ผู้เล่น"))
    local playerDropdown = playerBox:AddDropdown("TargetPlayer", {
        Text = T("Player", "ผู้เล่น"),
        Values = PlayerNames(),
        Searchable = true,
        AllowNull = true,
        NoSave = true,
        Callback = function(value)
            State.Opt.TargetPlayer = value
        end,
    })
    playerBox:AddButton({ Text = T("Teleport To Player", "วาร์ปไปหาผู้เล่น"), Style = "Primary", Func = PatipanStudio.UI.Spawn(function()
        PatipanStudio.Teleport.ToPlayer(State.Opt.TargetPlayer)
    end) }):AddButton({ Text = T("Refresh", "รีเฟรช"), Func = function()
        playerDropdown:SetValues(PlayerNames())
    end })
end

function PatipanStudio.UI.BuildPlayer(window)
    local playerTab = window:AddTab(T("Player", "ผู้เล่น"), "user", T("Movement", "การเคลื่อนที่"))

    local moveBox = playerTab:AddLeftGroupbox(T("Movement", "การเคลื่อนที่"))
    PatipanStudio.UI.Toggle(moveBox, "SpeedEnabled", T("Custom Speed", "ปรับความเร็วเอง"), T("Uses the speed and jump below while on foot", "ใช้ความเร็วและแรงกระโดดด้านล่างตอนเดิน"), function(on)
        if not on then PatipanStudio.Movement.ResetSpeed() end
    end):AddKeyPicker("SpeedEnabledKey", { Default = "None", Mode = "Toggle" })
    PatipanStudio.UI.Slider(moveBox, "WalkSpeed", T("Walk Speed", "ความเร็วเดิน"), nil, 16, 200)
    PatipanStudio.UI.Slider(moveBox, "JumpPower", T("Jump Power", "แรงกระโดด"), nil, 50, 300)

    local abilityBox = playerTab:AddRightGroupbox(T("Abilities", "ความสามารถ"))
    PatipanStudio.UI.Toggle(abilityBox, "Noclip", T("Noclip", "ทะลุวัตถุ"), T("Walk through walls", "เดินทะลุกำแพง"), PatipanStudio.Movement.SetNoclip)
    PatipanStudio.UI.Toggle(abilityBox, "InfiniteJump", T("Infinite Jump", "กระโดดไม่จำกัด"), T("Jump again in mid air", "กระโดดซ้ำกลางอากาศได้"))

    local worldBox = playerTab:AddRightGroupbox(T("World", "โลก"))
    PatipanStudio.UI.Toggle(worldBox, "Fullbright", T("Fullbright", "สว่างเต็มจอ"), T("Always daylight", "กลางวันตลอด"), PatipanStudio.Movement.SetFullbright)
end

function PatipanStudio.UI.BuildVisuals(window)
    local visualTab = window:AddTab(T("Visuals", "ภาพ"), "eye", T("ESP", "ESP"))
    local espBox = visualTab:AddLeftGroupbox(T("Robbery", "การปล้น"))
    PatipanStudio.UI.Toggle(espBox, "EspAtm", T("ATMs", "ATM"), T("Shows every ATM you can rob with its rarity", "โชว์ ATM ที่ปล้นได้ทุกตู้พร้อมระดับ"))
    PatipanStudio.UI.Toggle(espBox, "EspDropOff", T("Drop-off Points", "จุดส่งเงิน"), T("Where outlaws cash out", "จุดที่โจรไปส่งเงิน"))

    local peopleBox = visualTab:AddRightGroupbox(T("Players", "ผู้เล่น"))
    PatipanStudio.UI.Toggle(peopleBox, "EspCops", T("Players By Job", "ผู้เล่นตามอาชีพ"), T("Blue = police, red = outlaw, orange = delivery", "น้ำเงิน = ตำรวจ, แดง = โจร, ส้ม = ส่งของ"))
end

function PatipanStudio.UI.BuildSettings(window)
    local settingsTab = window:AddSettingsTab()
    local sessionBox = settingsTab:AddRightGroupbox(T("Session", "เซสชัน"))
    PatipanStudio.UI.Toggle(sessionBox, "AntiAfk", T("Anti AFK", "กันหลุด AFK"), T("Never get kicked for idling", "ไม่โดนเตะเพราะยืนนิ่ง"))
    PatipanStudio.UI.Toggle(sessionBox, "AutoRejoin", T("Auto Rejoin", "เข้าเกมใหม่อัตโนมัติ"), T("Rejoins after a disconnect", "หลุดแล้วเข้าเกมใหม่เอง"))
    sessionBox:AddButton({ Text = T("Server Hop", "ย้ายเซิร์ฟ"), Func = PatipanStudio.UI.Spawn(PatipanStudio.Session.Hop) })
end

---Features whose game module or remote is missing refuse to turn on and say why, instead of erroring every tick.
function PatipanStudio.UI.GateModules()
    local noExecutor = T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
    local changed = T("Not found after a game update", "หาไม่เจอหลังเกมอัปเดต")
    local en, th = {}, {}
    for idx in pairs(GameLib.Needs) do
        local option = Library.Options[idx]
        local missing = option and GameLib.Missing(idx)
        if missing then
            Library.Compat.Block(option, GameLib.Parts[missing] and changed or noExecutor)
            warn("[Driving Empire] " .. idx .. " off, missing " .. (GameLib.Parts[missing] or "module " .. missing))
            en[#en + 1] = option.Info.Text.EN
            table.insert(th, option.Info.Text.TH)
        end
    end
    if not GameLib.CodeRemote then warn("[Driving Empire] Redeem off, missing remote Code") end
    if #en == 0 then return end

    Library:Notify("Driving Empire", T("Not available on this executor: " .. table.concat(en, ", "), "ใช้กับ executor นี้ไม่ได้: " .. table.concat(th, ", ")), 8, "Warning")
end

---Runs on the UI's own thread: game-module threads cannot touch widgets, so halts and messages wait here.
function PatipanStudio.UI.Pump()
    while #State.Messages > 0 do
        local msg = table.remove(State.Messages, 1)
        Library:Notify("Driving Empire", msg[1], 5, msg[2])
    end
    while #State.Halted > 0 do
        local toggle = Library.Toggles[table.remove(State.Halted, 1)]
        if toggle and toggle.Value then toggle:SetValue(false) end
    end
    local label = PatipanStudio.UI.StatusLabel
    if label then label:SetText(PatipanStudio.UI.StatusText()) end
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    local try = PatipanStudio.Util.Try
    window:AddTabSection(T("Main", "หลัก"))
    for _, build in ipairs({ PatipanStudio.UI.BuildFarm, PatipanStudio.UI.BuildRewards, PatipanStudio.UI.BuildVehicle, PatipanStudio.UI.BuildTeleport, PatipanStudio.UI.BuildPlayer, PatipanStudio.UI.BuildVisuals, PatipanStudio.UI.BuildSettings }) do
        try(build, window)
    end
    try(PatipanStudio.UI.GateModules)
    Library:Every(1, PatipanStudio.UI.Pump)
end

---@return boolean  false when the menu could not load
local function BuildInterface()
    Library = PatipanStudio.Util.LoadLibrary()
    if not Library then return false end
    PatipanStudio.Library = Library
    pcall(MarioBanner.Step, "UI library")
    T = function(en, th) return Library:T(en, th) end

    Library:OnUnload(function()
        PatipanStudio.Scheduler.Stop()
        getgenv().DrivingEmpireUnload = nil
    end)
    getgenv().DrivingEmpireUnload = function()
        Library:Unload()
    end

    Library:CreateWindow({
        Title = "PatipanStudio",
        SubTitle = "Driving Empire by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        Intro = true,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            PatipanStudio.Util.Try(PatipanStudio.Scheduler.Boot)
            PatipanStudio.UI.Notify("Loaded", "Success")
            PatipanStudio.Util.Try(Library.LoadAutoloadConfig, Library)
        end,
    })
    return true
end

if getgenv().DrivingEmpireUnload then
    pcall(getgenv().DrivingEmpireUnload)
end

pcall(MarioBanner.Step, "Systems")
if BuildInterface() then
    pcall(MarioBanner.Step, "Interface")
    pcall(MarioBanner.Ready)
end