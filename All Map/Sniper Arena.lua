if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 9534705677 then
    game:GetService("Players").LocalPlayer:Kick("PatipanStudio: this script is for Sniper Arena only")
    return
end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local environment = getgenv and getgenv() or _G
if type(environment.SniperArenaUnload) == "function" then
    pcall(environment.SniperArenaUnload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local osClock = os.clock

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-10", "Auto Join Round: joins the next round from the lobby\nSkin pictures and rarity colors\nSmoother ESP, cleaner and faster menu\nAuto Sell never sells the guns you hold\nFixed Aimbot key and unloading" },
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nImproved Combat & Movement" },
    },
    SaveFolder = "Sniper Arena",
    LoadTimeout = 10,
    AlertTries = 20,
    AlertGap = 0.5,
    RequireTimeout = 5,
    RequireBudget = 15,
    MaxFails = 5,
    FailWindow = 10,
    FovColor = Color3.fromRGB(232, 160, 76),
    BannerCaps = { "HookFunction", "Namecall", "Gc", "Upvalues", "Drawing", "Connections", "FileSystem" },
    CombatToggles = { "Aimbot", "SilentAim", "Ragebot", "TriggerBot", "NoRecoil", "NoSpread", "InstantScope" },
    ModuleFeatures = {
        EntityService = { "Aimbot", "SilentAim", "Ragebot", "TriggerBot" },
        CombatService = { "SilentAim", "Ragebot", "TriggerBot", "NoRecoil", "NoSpread", "InstantScope", "SkinChanger" },
        CameraController = { "SilentAim", "Ragebot" },
        WeaponConfig = { "SkinChanger" },
        GachaService = { "AutoOpenCases" },
        WeaponService = { "AutoSell" },
        QuestService = { "AutoClaimQuest" },
        GameService = { "FastRespawn" },
    },
    SkinMainRows = 4,
    SkinGroupRows = 3,
    EconomyInterval = 1,
    JoinText = "Touch to Join",
    JoinRange = 400,
    JoinRetry = 3,
    StatusInterval = 1,
    OpenDelay = 0.6,
    ClaimDelay = 0.5,
    FireInterval = 0.12,
    LookSettle = 0.1,
    TriggerRange = 2000,
    EspInterval = 0.15,
    EspGrace = 1,
    ResultWait = 3,
    AimRenderPriority = Enum.RenderPriority.Camera.Value + 5,
}

PatipanStudio.State = {
    Alive = true,
    Connections = {},
    Halted = {},
    Notices = {},
    EspSnapshot = {},
}

PatipanStudio.Options = {
    AntiAfk = false,

    InfiniteDash = false,
    FastRespawn = false,
    AutoJoin = false,
    SkinChanger = false,
    SkinRarities = {},

    AutoOpenCases = false,
    OpenCount = 1,
    AutoSell = false,
    SellRarities = {},
    MaxSellPrice = 500,
    KeepPerRarity = 0,
    AutoClaimQuest = false,

    Aimbot = false,
    SilentAim = false,
    Ragebot = false,
    InstantScope = false,
    HitChance = 100,
    HeadChance = 100,
    TriggerBot = false,
    NoRecoil = false,
    NoSpread = false,
    AimTeamCheck = true,
    AimWallCheck = true,
    AimSmooth = 1,
    AimPrediction = 60,
    ShowFov = false,
    AimFov = 150,
    AimPriority = "Crosshair",
    AimMaxDistance = 1000,
    AimBone = "Head",
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
Util.GetHui = Resolve(gethui, get_hidden_gui)
Util.GetUpvalue = Resolve(getupvalue, debug.getupvalue)
Util.GetUpvalues = Resolve(getupvalues, debug.getupvalues)
Util.GetRawMetatable = Resolve(getrawmetatable)

PatipanStudio.Probes = {}

---@return boolean  getrawmetatable and getupvalues both answer for real
function PatipanStudio.Probes.LookSpoof()
    if not (Util.GetRawMetatable and Util.GetUpvalues) then return false end
    local marker, meta = {}, { __metatable = "locked" }
    local proxy = setmetatable({}, meta)
    local function Holder() return marker end

    local ok, found = pcall(function()
        if Util.GetRawMetatable(proxy) ~= meta then return false end
        for _, value in pairs(Util.GetUpvalues(Holder)) do
            if value == marker then return true end
        end
        return false
    end)
    return ok and found == true
end

PatipanStudio.Caps = setmetatable({}, {
    __index = function(caps, name)
        local probe = PatipanStudio.Probes[name]
        if probe then
            local has = probe()
            rawset(caps, name, has)
            return has
        end
        local lib = PatipanStudio.Library
        if not (lib and lib.Compat) then return false end
        return lib.Compat.Caps[name] == true
    end,
})

---@return string  response body, throws if every transport fails
function Util.HttpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then
        return body
    end
    if not Util.Request then
        error("HttpGet failed: " .. url)
    end

    local sent, response = pcall(Util.Request, { Url = url, Method = "GET" })
    if not sent then error(response) end
    local status = type(response) == "table" and tonumber(response.StatusCode) or nil
    if status == 200 and type(response.Body) == "string" then
        return response.Body
    end
    error("HttpGet " .. url .. ": status " .. tostring(status))
end

---@param detail any  goes to the console, the player only sees text
function Util.Alert(text, detail)
    warn("[SniperArena] menu: " .. tostring(detail or text))
    task.spawn(function()
        for _ = 1, PatipanStudio.Config.AlertTries do
            local shown = pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
                Title = "PatipanStudio",
                Text = text,
                Duration = 10,
            })
            if shown then return end
            task.wait(PatipanStudio.Config.AlertGap)
        end
    end)
end

---@return table?  UI library, nil after the player was told why
function Util.LoadLibrary(url)
    local fetched, source = pcall(Util.HttpGet, url)
    if not fetched or type(source) ~= "string" or not source:sub(-64):find("return Library%s*$") then
        Util.Alert("Could not download the menu. Check your connection and run it again.", fetched and "response is not the full menu" or source)
        return nil
    end

    local chunk, problem = loadstring(source)
    if type(chunk) ~= "function" then
        Util.Alert("The menu failed to load on this executor: " .. tostring(problem))
        return nil
    end
    local ran, lib = pcall(chunk)
    if not ran or type(lib) ~= "table" then
        Util.Alert("The menu failed to load on this executor: " .. tostring(lib))
        return nil
    end
    if type(lib.Compat) ~= "table" then
        Util.Alert("The menu is out of date. Run the script again in a few minutes.", "ui.lua has no Compat layer")
        return nil
    end
    return lib
end

---@return boolean  false after warning with context
function Util.Try(label, callback, ...)
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[SniperArena] " .. label .. ": " .. tostring(err))
    end
    return ok
end

function Util.Copy(text)
    if Util.SetClipboard then
        Util.SetClipboard(text)
        return true
    end
    return false
end

---@return ScreenGui  script-owned layer, hidden gui first, PlayerGui last
function Util.Overlay()
    local screen = PatipanStudio.State.Overlay
    if screen and screen.Parent then return screen end

    screen = Instance.new("ScreenGui")
    screen.Name = "PatipanStudioOverlay"
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 50
    local mounts = { function() return game:GetService("CoreGui") end }
    if Util.GetHui then table.insert(mounts, 1, Util.GetHui) end
    for _, mount in ipairs(mounts) do
        if pcall(function() screen.Parent = mount() end) and screen.Parent then break end
    end
    if not screen.Parent then
        screen.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", PatipanStudio.Config.LoadTimeout)
    end
    PatipanStudio.State.Overlay = screen
    return screen
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

PatipanStudio.GameLib = { Config = {}, Service = {}, Missing = {}, LoadEnds = nil }
local GameLib = PatipanStudio.GameLib

---@param asGame boolean     retry from an identity-2 thread, skipped when the executor can't switch
---@return boolean, boolean, any  finished before the deadline, require ok, module
function GameLib.RequireWithin(module, asGame)
    local done, ok, loaded = false, false, nil
    task.spawn(function()
        if asGame then
            pcall(setthreadidentity, 2)
            local read, identity = pcall(getthreadidentity)
            if not (read and identity == 2) then
                done = true
                return
            end
        end
        ok, loaded = pcall(require, module)
        done = true
    end)

    local deadline = osClock() + PatipanStudio.Config.RequireTimeout
    if GameLib.LoadEnds then deadline = math.min(deadline, GameLib.LoadEnds) end
    while not done and osClock() < deadline do
        task.wait()
    end
    return done, ok, loaded
end

---@return any  nil when this executor can't require it (never throws)
function GameLib.Require(module)
    if GameLib.LoadEnds and osClock() >= GameLib.LoadEnds then
        GameLib.Missing[module.Name] = true
        warn("[SniperArena] require " .. module.Name .. ": load budget spent")
        return nil
    end

    local finished, ok, loaded = GameLib.RequireWithin(module, false)
    if ok then return loaded end
    if finished then
        local _, again, retried = GameLib.RequireWithin(module, true)
        if again then return retried end
    end
    GameLib.Missing[module.Name] = true
    warn("[SniperArena] require " .. module.Name .. ": " .. (finished and tostring(loaded) or "timed out"))
    return nil
end

---@param parent Instance?  expected folder; a moved module is still found anywhere in ReplicatedStorage
local function RequireChild(parent, name)
    local child = parent and parent:FindFirstChild(name)
    if not (child and child:IsA("ModuleScript")) then
        child = ReplicatedStorage:FindFirstChild(name, true)
    end
    if not (child and child:IsA("ModuleScript")) then
        GameLib.Missing[name] = "Absent"
        warn("[SniperArena] module " .. name .. " not found, features that need it are blocked")
        return nil
    end
    return GameLib.Require(child)
end

do
    local configFolder = ReplicatedStorage:FindFirstChild("Config")
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remote")
    local constantFolder = ReplicatedStorage:FindFirstChild("Constant")
    GameLib.LoadEnds = osClock() + PatipanStudio.Config.RequireBudget

    for _, name in ipairs({ "WeaponConfig", "WrapConfig", "QuestConfig" }) do
        GameLib.Config[name] = RequireChild(configFolder, name)
    end
    GameLib.RarityColor = RequireChild(constantFolder, "RarityColor")

    local serviceNames = {
        "StatusService", "GachaService", "WeaponService", "QuestService", "EntityService",
        "CombatService", "GameService",
    }
    for _, name in ipairs(serviceNames) do
        GameLib.Service[name] = RequireChild(remoteFolder, name)
    end
    GameLib.CameraController = RequireChild(ReplicatedStorage:FindFirstChild("Client"), "CameraController")
    GameLib.WeaponController = RequireChild(ReplicatedStorage:FindFirstChild("Client"), "WeaponController")
    local gameService = remoteFolder and remoteFolder:FindFirstChild("GameService")
    GameLib.RoomManager = RequireChild(gameService, "RoomManager")
    GameLib.Status = RequireChild(constantFolder, "Status")
    GameLib.LoadEnds = nil
end

PatipanStudio.Player = { Client = LocalPlayer }

function PatipanStudio.Player:Bind(character)
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid", PatipanStudio.Config.LoadTimeout)
    self.Root = character:WaitForChild("HumanoidRootPart", PatipanStudio.Config.LoadTimeout)
end

function PatipanStudio.Player:IsAlive()
    return self.Humanoid ~= nil and self.Humanoid.Health > 0 and self.Root ~= nil and self.Root.Parent ~= nil
end

---@return number?  coin the server last replicated, nil when unreadable
function PatipanStudio.Player:Coin()
    local service = GameLib.Service.StatusService
    if not service then return nil end
    local key = GameLib.Status and GameLib.Status.Eco_Coin or "Eco_Coin"
    local ok, value = pcall(function() return service.GetStatus(key) end)
    return ok and tonumber(value) or nil
end

PatipanStudio.Entity = {}

function PatipanStudio.Entity.Service()
    return GameLib.Service.EntityService
end

---@return table  focused combatant entities (empty in lobby / combat paused)
function PatipanStudio.Entity.List()
    local service = PatipanStudio.Entity.Service()
    if not service then return {} end
    local ok, focused = pcall(function() return service.WorldManager:GetFocusedEntities() end)
    if not ok or type(focused) ~= "table" then return {} end
    return focused._items or focused.Items or focused
end

function PatipanStudio.Entity.Local()
    local service = PatipanStudio.Entity.Service()
    if not service then return nil end
    local ok, entity = pcall(function() return service.GetLocalEntity() end)
    if ok and entity then return entity end
    ok, entity = pcall(function() return service:GetLocalEntity() end)
    return ok and entity or nil
end

local function TryCall(object, method)
    if type(object) ~= "table" and typeof(object) ~= "Instance" then return nil, false end
    local call = object[method]
    if type(call) ~= "function" then return nil, false end
    local ok, value = pcall(call, object)
    if ok then return value, true end
    return nil, false
end

function PatipanStudio.Entity.IsLocal(entity)
    local value, called = TryCall(entity, "IsLocalEntity")
    if called then return value == true end
    return entity == PatipanStudio.Entity.Local()
end

---@return string?  per-round team tag, unique per player in FFA/Duel
function PatipanStudio.Entity.Team(entity)
    local inst = entity and entity.Instance
    if typeof(inst) == "Instance" then
        local team = inst:GetAttribute("Team")
        if team ~= nil then return tostring(team) end
    end
    local char = PatipanStudio.Entity.Character(entity)
    local team = char and char:GetAttribute("Team")
    return team ~= nil and tostring(team) or nil
end

function PatipanStudio.Entity.Friendly(entity)
    local char = PatipanStudio.Entity.Character(entity)
    local marks = Workspace:FindFirstChild("Highlight")
    if char and marks then
        local friendly = marks:FindFirstChild("Friendly")
        if friendly and char:IsDescendantOf(friendly) then return true end
        if char:IsDescendantOf(marks) then return false end
    end

    if PatipanStudio.Match.ModeSet() ~= "TDM" then return false end
    local mine = PatipanStudio.Entity.Team(PatipanStudio.Entity.Local())
    local theirs = PatipanStudio.Entity.Team(entity)
    return mine ~= nil and mine == theirs
end

function PatipanStudio.Entity.Health(entity)
    if not entity then return 0, 0 end
    local health = entity.Health or select(1, TryCall(entity, "GetHealth")) or 0
    local maxHealth = entity.MaxHealth or select(1, TryCall(entity, "GetMaxHealth")) or 0
    return health, maxHealth
end

function PatipanStudio.Entity.Character(entity)
    local humanoid = entity and entity.Humanoid
    if humanoid and humanoid.Parent then return humanoid.Parent end
    return entity and entity.Character or nil
end

function PatipanStudio.Entity.Root(entity)
    local character = PatipanStudio.Entity.Character(entity)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart
end

PatipanStudio.Match = {}

---@return string?, string?  mode, map — nil outside a room
function PatipanStudio.Match.Info()
    local rooms = GameLib.RoomManager
    local ok, room = pcall(function() return rooms and rooms.GetFocusedRoom() end)
    if not ok or type(room) ~= "table" then return nil, nil end
    return room.Mode, room.Map
end

---@return string?  FFA / TDM / Duel / Boss
function PatipanStudio.Match.ModeSet()
    local rooms = GameLib.RoomManager
    local ok, room = pcall(function() return rooms and rooms.GetFocusedRoom() end)
    return ok and type(room) == "table" and room.ModeSet or nil
end

function PatipanStudio.Match.InRound()
    return LocalPlayer:GetAttribute("combatPaused") == false
end

PatipanStudio.Faults = { Streaks = {}, Said = {} }

---@param err any  the same error again stays quiet for FailWindow
function PatipanStudio.Faults.Say(name, err)
    local text, now = tostring(err), osClock()
    local last = PatipanStudio.Faults.Said[name]
    if last and last[1] == text and now - last[2] < PatipanStudio.Config.FailWindow then return end
    PatipanStudio.Faults.Said[name] = { text, now }
    warn("[SniperArena] " .. name .. ": " .. text)
end

function PatipanStudio.Faults.Clear(name)
    PatipanStudio.Faults.Streaks[name] = nil
end

function PatipanStudio.Faults.Wanted(toggles)
    for _, key in ipairs(toggles) do
        if PatipanStudio.Options[key] then return true end
    end
    return false
end

---@param restore function?  the feature's own off path
function PatipanStudio.Faults.Stop(name, err, toggles, restore)
    warn("[SniperArena] " .. name .. " stopped: " .. tostring(err))
    for _, key in ipairs(toggles) do
        PatipanStudio.Options[key] = false
    end
    if restore then Util.Try(name .. " restore", restore) end
    table.insert(PatipanStudio.State.Halted, { name, tostring(err):match("^[^\n]*"), toggles })
end

---@param toggles string[]   switched off when the feature keeps failing; empty = never stops, warns once per streak
---@param restore function?  run once when the feature is stopped
---@return boolean           true while the feature is stopped
function PatipanStudio.Faults.Report(name, err, toggles, restore)
    local now = osClock()
    local streak = PatipanStudio.Faults.Streaks[name]
    if not streak or (streak.Halted and PatipanStudio.Faults.Wanted(toggles)) then
        streak = { Count = 0, First = now, Warned = false, Halted = false }
        PatipanStudio.Faults.Streaks[name] = streak
    end
    streak.Count += 1
    if streak.Count == 1 then PatipanStudio.Faults.Say(name, err) end
    if streak.Warned then return streak.Halted end
    if streak.Count < PatipanStudio.Config.MaxFails or now - streak.First < PatipanStudio.Config.FailWindow then return false end

    streak.Warned = true
    if #toggles == 0 then
        warn("[SniperArena] " .. name .. " keeps failing: " .. tostring(err))
        return false
    end
    streak.Halted = true
    PatipanStudio.Faults.Stop(name, err, toggles, restore)
    return true
end

PatipanStudio.Scheduler = { Jobs = {}, Booted = false }

---@param toggles string[]?  options the job serves; turned off if it keeps failing
---@param restore function?  the job's off path, run once if it gets stopped
function PatipanStudio.Scheduler.Every(name, interval, work, toggles, restore)
    PatipanStudio.Scheduler.Jobs[name] = { Interval = interval, Fn = work, Last = 0, Running = false, Toggles = toggles or {}, Restore = restore }
end

---@return boolean  a stopped job comes back once one of its toggles is on again
function PatipanStudio.Scheduler.Revive(name, job)
    if not PatipanStudio.Faults.Wanted(job.Toggles) then return false end
    job.Halted = false
    PatipanStudio.Faults.Clear(name)
    return true
end

function PatipanStudio.Scheduler.Settle(name, job)
    local err = job.Error
    job.Error = nil
    if err then
        job.Halted = PatipanStudio.Faults.Report(name, err, job.Toggles, job.Restore)
    else
        PatipanStudio.Faults.Clear(name)
    end
end

function PatipanStudio.Scheduler.Step()
    if not PatipanStudio.State.Alive then return end
    local now = osClock()
    for name, job in pairs(PatipanStudio.Scheduler.Jobs) do
        if job.Running then continue end
        if job.Error ~= nil then PatipanStudio.Scheduler.Settle(name, job) end
        if job.Halted and not PatipanStudio.Scheduler.Revive(name, job) then continue end
        if now - job.Last < job.Interval then continue end

        job.Last = now
        job.Running = true
        task.spawn(function()
            local ok, err = pcall(job.Fn)
            job.Error = (not ok) and tostring(err) or false
            job.Running = false
        end)
    end
end

function PatipanStudio.Scheduler.Boot()
    if PatipanStudio.Scheduler.Booted then return end
    PatipanStudio.Scheduler.Booted = true
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Scheduler.Step)
end

PatipanStudio.Banner = {
    Print = print,
    Started = osClock(),
    Last = osClock(),
    Done = 0,
    Total = 5,
    Art = [[
                                                                     @%@
                                                                    @*-#@
                                          @@@@@@@@@@@@@          @@#+.:-*%@@      @@
                                   @@@@@%##***********##%@@@@@   @*--:-==+*@@@@#*+==+*%@@
                              @@@@#+=+==---==++++++++++++**+++#@@@@@%==+@@@@#:.......:::=%@@
                          @@%#+---::-=++++++++++************+***++#%@%+@@@#:..-+*****+-:::+%@
                      @@@#=-::.:-==++++++++++*************************#@@+::=*-:.:+-::-+:.:=#@
                    @@%-:...:-===+++++**#################****************%%*+::::+*++::-+..:=#@
                 @@%*-:...:--==++*########**+==--===+**#######************+#%+::-*==-:::=-::=+@@
               @@%+=-::---===+*###%#+-:...................:=+#####***********#@+++==----==:-+*@@
             @@%++=-======+*###%+:............................::+####**********#@*+=----=---**@@
            @%=++=++++++*####=:...................................:+###**********%@==--==--+**@@
          @@*+++++++++*###*:........................................:-*##**********%*==+--=**@@@
         @%+++++++++*##%+:............................................::*##*********%%+--=##%@+%@
       @@#+++++++++###*:.....-+==+*#-......................:**+**#+:....:=###********%%+*##%@*:+@@
      @@*++++++++*###:......-+:.:-=*#*-..................:+*--+**#%*:.....:+##********#@#%%+:.:--+#@
     @@+++++++++*##+:......-*::-=++++*##:...............=#=-++****#%*:.....:-##********#@@@%+=-++#@@
    @@+=-=+++++*##+.......:*-:==++++++*##+............-*+-=+*******#%+:.....:-##********#@  @#=#@@
    @*=:.=++++*##-.......:*=:=++++++++*+*##=........:**==+**********##=:.....::*#********%@  @#@
   @#+-.-++*+*##=........*+-++++++*********##-....:+*==+*************#%-:.....:-**********%@
  @@++-=++***##+........*+-++++++***********#%*::=#+-+****************#%-:.....:=**********@@
 @@*++=++***###........+*-+++++***************###+-=+*****************###-:.....:+*********%@
 @%++=+*****#%:.......=*-++++*******************==+********************#%*-:....:-#********#@@
@@**+++****##+.......=*=+++*********************************************#%+::....:+*********@@
@%**++*****##-......=#=++**********#%#********************%%*************#%+:....:-#********%@
@%**++*****#*:.....-*=++**********#%%%#*****************#%%%**************#%=:....-********##@@
@#**++*****#*:....:*++************%%%%%%#*************#%%%%%#**************##-:...-+*******#*@@
@#**+******#+:...:#++************#%%%@@%%##*********#%%%%%@%#**************#%#-:..:+*+*****#*@@
@#**+******#+:..:#+=************#%%%%%*%%%##*******%%%%%%#%%##**************#%#::.-+*+*****#*@@
@#*********#+:.:+*=*************%%%%%+==*%%###***#%%%%%#++*%##***************#%*::-+*+*****#*@@
@%*#*******#*:.+*=*************%%%%%*=----*%###%%%%%%#+====*###**************##%+--*++****###@@
@%*#********#-:####***********#%%%%#=-::.::=###%%%%#+==--:::####************#%%%#==*+*****###@@
@@##********#+:#%%%%#********#%%%%%=--:....::=%%%%+==--::..:-%###********#%%%%%%#=#++*****##%@
@@###********#-=#%%%%%%##****%%%%%*=-:.......::-==---::.....:+###*****##%%%%%%%#++#++****###@@
 @%###*******##::=+%%%%%%%##%%%%%#=-:...........:::::........:####*#%%%%%%%%%*+=+*+=*****##%@
 @@###********#+:.:-=*%%%%%%%%%%%+--:.........................=###%%%%%%%%*+====*=.=****###@@
  @@###********#+:..::-=*%%%%%%%*=-:..:::-------------::::...::*#%%%%%%*+==---=*+-=+***###%@
   @%###*******#%#*+-..::-=#%@@%#**++==----------------===+++**#%@@@#+===---+*#*++****####@@
    @%###**#%#=::-=+##*##+-:...:::-=+**---*###*=--++++=--=++++=--:::-=+#%**#-:..:=#%##%##@@
    @@%#%#+:...:-=++=:..::=*####+#=:..=@#%:....%@*....*%%#...:--=*##+------=+=:::::-=#%%@@
     @@%*=--::::-*::::::-%=...:%@#:...:@@#.....%@+....=@@=.........:*#=-----=+=:::-==++%@@
  @@%+--+==--:::-#=-::::-%+....+%%-....%@#....:@@+....+@@:...:%%....-@*---==+*+:::-=+++*=+#@@
 @%-:-==*+==-:::-+*--:::-*#:...........*@#....:@@+....+@%..........-%%+---==+*=::-=+++#*=-:-*@@
 @@#+===+*+==-::-=*=--::-=%-......:....+@%:....:-....:#@*....=+:...-%#=--==+**-:--=++#*+=-=*%@
   @@#*=++#+=-:::-+*------#+....+@%....-@@#:.......::*@@+....+#=.:::=%+-===+#+-:-=++***++*%@@
     @@#+++*==-::-=*=-----+%:...-@@-::-=@%%@#+=--==*%@%%=:::::::::::#%+===+**----=++#**#%@@
     @@*-=+*+=-::-=*+=----=%#+*#%@%@@@@@#+-=*%%@@@%#*==*@@%%%##*+*#@@*====+#+-:-=++***++%@
    @@*--=+++===++*#*=------#%%#+=-----===============----==+*#%%%#+=-===+*#*+++=++**+==*@@
    @%=:-==+***%%@@@#=-=====++*##%%%@@@@@@@@@@%%@@@@@@@@@%%%##**++=======+*@@@@%#*+#+=--=#@
    @*:---==+*###%@@@#*#%%@%%%%%%######*****++++++++***######%%%%%%%%%%#*#%@@@####**+=---+@@
   @@+--=**#%@@@@@  @@@%%%%%%%#*******************************####%%%%%%@@@  @@@@@%#**=--+%@
    @@%%@@@@@          @@@@%%%%%%###**********************####%%%%%%%@@@          @@@@@%%%@@
      @@                  @@@@@%%%%%%%%%###############%%%%%%%%%@@@@@                  @@@
                               @@@@@@%%%%%%%%%%%%%%%%%%%%%%@@@@@
                                    @@@@@@@@@@@@@@@@@@@@@@@
]],
    Title = [[
  __  __    _    ____  ___ ___    _   _ _   _ ____
 |  \/  |  / \  |  _ \|_ _/ _ \  | | | | | | | __ )
 | |\/| | / _ \ | |_) || | | | | | |_| | | | |  _ \
 | |  | |/ ___ \|  _ < | | |_| | |  _  | |_| | |_) |
 |_|  |_/_/   \_\_| \_\___\___/  |_| |_|\___/|____/
]],
}

pcall(function()
    local renv = getrenv()
    if type(renv.print) == "function" then PatipanStudio.Banner.Print = renv.print end
end)

function PatipanStudio.Banner.Show()
    local ok, executor = pcall(identifyexecutor)
    if not ok or type(executor) ~= "string" then executor = "Unknown" end
    local rule = string.rep("=", 54)
    PatipanStudio.Banner.Print(table.concat({
        "",
        PatipanStudio.Banner.Art,
        PatipanStudio.Banner.Title,
        rule,
        "   SNIPER ARENA  //  by PatipanStudio  //  discord.gg/FHVfmeSceA",
        "   executor: " .. tostring(executor) .. "   //   player: " .. LocalPlayer.Name,
        rule,
    }, "\n"))
end

---@param label string  what just finished loading
function PatipanStudio.Banner.Step(label)
    local banner = PatipanStudio.Banner
    local now = osClock()
    banner.Done = math.min(banner.Done + 1, banner.Total)
    local filled = math.floor(banner.Done / banner.Total * 20 + 0.5)
    local bar = string.rep("#", filled) .. string.rep(".", 20 - filled)
    PatipanStudio.Banner.Print(string.format("[PatipanStudio] [%s] %3d%%  %-24s +%dms",
        bar, math.floor(banner.Done / banner.Total * 100), label, math.floor((now - banner.Last) * 1000)))
    banner.Last = now
end

function PatipanStudio.Banner.Ready()
    local names = PatipanStudio.Config.BannerCaps
    local caps = 0
    for _, name in ipairs(names) do
        if PatipanStudio.Caps[name] then caps += 1 end
    end
    local rule = string.rep("=", 54)
    PatipanStudio.Banner.Print(table.concat({
        rule,
        string.format("   >> READY in %dms  //  caps %d/%d  //  LeftCtrl = menu",
            math.floor((osClock() - PatipanStudio.Banner.Started) * 1000), caps, #names),
        rule,
    }, "\n"))
end

pcall(PatipanStudio.Banner.Show)
pcall(PatipanStudio.Banner.Step, "Core")

PatipanStudio.Player.AntiAfk = { Connection = nil, Status = "Off" }

function PatipanStudio.Player.AntiAfk.OnIdled()
    if not PatipanStudio.Options.AntiAfk then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end

function PatipanStudio.Player.AntiAfk.Start()
    PatipanStudio.Options.AntiAfk = true
    if not PatipanStudio.Player.AntiAfk.Connection then
        PatipanStudio.Player.AntiAfk.Connection = PatipanStudio:Connect(LocalPlayer.Idled, PatipanStudio.Player.AntiAfk.OnIdled)
    end
    PatipanStudio.Player.AntiAfk.Status = "Armed"
end

function PatipanStudio.Player.AntiAfk.Stop()
    PatipanStudio.Options.AntiAfk = false
    local conn = PatipanStudio.Player.AntiAfk.Connection
    PatipanStudio.Player.AntiAfk.Connection = nil
    if conn then conn:Disconnect() end
    PatipanStudio.Player.AntiAfk.Status = "Off"
end

function PatipanStudio.Player.AntiAfk.GetStatus()
    return PatipanStudio.Player.AntiAfk.Status
end

PatipanStudio.Player.Respawn = { Status = "Off", Count = 0, Fired = false }

function PatipanStudio.Player.Respawn.IsDead()
    local state = LocalPlayer:GetAttribute("State")
    if state == "Dead" or state == "Died" then return true end
    local hum = PatipanStudio.Player.Humanoid
    return hum ~= nil and hum.Health <= 0
end

function PatipanStudio.Player.Respawn.Fire()
    local gameService = PatipanStudio.GameLib.Service.GameService
    if gameService and gameService.CanFastRespawn and gameService.CanFastRespawn() then
        gameService.FastRespawn()
        return
    end
    local folder = ReplicatedStorage:FindFirstChild("Remote")
    local service = folder and folder:FindFirstChild("GameService")
    local remote = service and service:FindFirstChild("Respawn")
    if remote then remote:FireServer() end
end

function PatipanStudio.Player.Respawn.Reset()
    PatipanStudio.Player.Respawn.Fired = false
end

function PatipanStudio.Player.Respawn.Step()
    local respawn = PatipanStudio.Player.Respawn
    if not PatipanStudio.Options.FastRespawn then
        respawn.Status = "Off"
        return
    end
    local gameService = PatipanStudio.GameLib.Service.GameService
    if not (gameService and gameService.IsJoined and gameService.IsJoined()) then
        respawn.Status = "Not in game"
        return
    end
    if not respawn.IsDead() then
        respawn.Fired = false
        respawn.Status = "Alive · respawns " .. respawn.Count
        return
    end

    respawn.Status = "Respawning"
    if respawn.Fired then return end
    respawn.Fired = true
    respawn.Count += 1
    respawn.Fire()
end

function PatipanStudio.Player.Respawn.GetStatus()
    return PatipanStudio.Player.Respawn.Status
end

PatipanStudio.Player.Join = { Status = "Off", LastTry = 0 }

---@return BasePart?  the lobby pad that puts you in a round, while it says the round can be joined
function PatipanStudio.Player.Join.Pad()
    local lobby = Workspace:FindFirstChild("Lobby")
    local start = lobby and lobby:FindFirstChild("Start")
    local pad = start and start:FindFirstChild("Touch", true)
    if not (pad and pad:IsA("BasePart")) then return nil end
    for _, label in ipairs(start:GetDescendants()) do
        if label:IsA("TextLabel") and label.Text:find(PatipanStudio.Config.JoinText, 1, true) then return pad end
    end
    return nil
end

---Touches the lobby pad from where you stand, so you drop into the next round without walking there.
function PatipanStudio.Player.Join.Step()
    local join = PatipanStudio.Player.Join
    local root = PatipanStudio.Player.Root
    local pad = join.Pad()
    if not (root and root.Parent and pad) then
        join.Status = pad and "Waiting for character" or "In a round"
        return
    end
    if (root.Position - pad.Position).Magnitude > PatipanStudio.Config.JoinRange then
        join.Status = "In a round"
        return
    end
    if osClock() - join.LastTry < PatipanStudio.Config.JoinRetry then return end
    join.LastTry = osClock()
    join.Status = "Joining"
    firetouchinterest(root, pad, 0)
    task.wait(0.1)
    firetouchinterest(root, pad, 1)
end

PatipanStudio.Movement = { Booted = false, Dash = nil, Resolving = false }

---@return ModuleScript?  dash helper, searched by name if CombatHelper moved
function PatipanStudio.Movement.FindDash()
    local client = ReplicatedStorage:FindFirstChild("Client")
    local helper = client and client:FindFirstChild("CombatHelper")
    local dash = helper and helper:FindFirstChild("Dash")
    if dash and dash:IsA("ModuleScript") then return dash end
    helper = ReplicatedStorage:FindFirstChild("CombatHelper", true)
    dash = helper and helper:FindFirstChild("Dash")
    return dash and dash:IsA("ModuleScript") and dash or nil
end

function PatipanStudio.Movement.ResolveDash()
    local found = PatipanStudio.Movement.FindDash()
    PatipanStudio.Movement.Dash = found and GameLib.Require(found) or false
    PatipanStudio.Movement.Resolving = false
end

---@return table?  dash module once resolved, nil while the single require is still running
function PatipanStudio.Movement.DashHelper()
    local dash = PatipanStudio.Movement.Dash
    if dash ~= nil then return dash or nil end
    if PatipanStudio.Movement.Resolving then return nil end
    PatipanStudio.Movement.Resolving = true
    task.spawn(PatipanStudio.Movement.ResolveDash)
    return nil
end

function PatipanStudio.Movement.OnStepped()
    if not PatipanStudio.Options.InfiniteDash then return end
    local dash = PatipanStudio.Movement.DashHelper()
    if dash and dash.RefreshNextDashTime then pcall(dash.RefreshNextDashTime) end
end

function PatipanStudio.Movement.Start()
    if PatipanStudio.Movement.Booted then return end
    PatipanStudio.Movement.Booted = true
    PatipanStudio:Connect(RunService.Stepped, PatipanStudio.Movement.OnStepped)
end

function PatipanStudio.Movement.GetStatus()
    return PatipanStudio.Options.InfiniteDash and "Infinite dash" or "Off"
end

PatipanStudio.Esp = { Count = 0, Rows = {} }

function PatipanStudio.Esp.Enabled()
    local visuals = PatipanStudio.Library and PatipanStudio.Library.Visuals
    return visuals ~= nil and visuals:Get("Enabled") == true
end

---@return any  stays the same while the entity lives, even when its model streams out
function PatipanStudio.Esp.KeyOf(entity, char)
    local inst = entity.Instance
    if typeof(inst) == "Instance" then return inst end
    return char or entity
end

---@return table?  row for Library.Visuals, nil for dead, local or missing entities
function PatipanStudio.Esp.Row(entity)
    if type(entity) ~= "table" or PatipanStudio.Entity.IsLocal(entity) then return nil end
    local char = PatipanStudio.Entity.Character(entity)
    local health, maxHealth = PatipanStudio.Entity.Health(entity)
    if not char or health <= 0 then return nil end

    local player = Players:GetPlayerFromCharacter(char)
    return {
        Model = char,
        Name = player and player.DisplayName or char.Name,
        Health = health,
        MaxHealth = maxHealth > 0 and maxHealth or 100,
        Friendly = PatipanStudio.Entity.Friendly(entity),
        Root = PatipanStudio.Entity.Root(entity),
    }
end

---@param now number  rows unseen for longer than EspGrace are dropped
function PatipanStudio.Esp.Expire(seen, now)
    local grace = PatipanStudio.Config.EspGrace
    for key, held in pairs(PatipanStudio.Esp.Rows) do
        if seen[key] then continue end
        local row = held.Row
        local alive = row.Model.Parent and row.Root and row.Root.Parent
        if now - held.Seen > grace or not alive then PatipanStudio.Esp.Rows[key] = nil end
    end
end

function PatipanStudio.Esp.Step()
    if not PatipanStudio.Esp.Enabled() then
        table.clear(PatipanStudio.Esp.Rows)
        PatipanStudio.State.EspSnapshot = {}
        PatipanStudio.Esp.Count = 0
        return
    end

    local now, seen = osClock(), {}
    for _, entity in pairs(PatipanStudio.Entity.List()) do
        local row = PatipanStudio.Esp.Row(entity)
        if not row then continue end
        local key = PatipanStudio.Esp.KeyOf(entity, row.Model)
        local held = PatipanStudio.Esp.Rows[key]
        if not row.Root and held then row.Root = held.Row.Root end
        seen[key] = true
        PatipanStudio.Esp.Rows[key] = { Row = row, Seen = now }
    end
    PatipanStudio.Esp.Expire(seen, now)

    local snapshot = {}
    for _, held in pairs(PatipanStudio.Esp.Rows) do
        table.insert(snapshot, held.Row)
    end
    PatipanStudio.State.EspSnapshot = snapshot
    PatipanStudio.Esp.Count = #snapshot
end

---@return table[]  last snapshot from the scheduler, never touches game modules
function PatipanStudio.Esp.Targets()
    return PatipanStudio.State.EspSnapshot
end

function PatipanStudio.Esp.GetStatus()
    if not PatipanStudio.Esp.Enabled() then return "Off" end
    return PatipanStudio.Esp.Count .. " targets"
end

---@param probe function  re-read until it differs from before or ResultWait runs out
---@return any             value after the wait
local function AwaitChange(before, probe)
    local deadline = osClock() + PatipanStudio.Config.ResultWait
    local now = probe()
    while now == before and osClock() < deadline do
        task.wait(0.2)
        now = probe()
    end
    return now
end

PatipanStudio.Shop = { Status = "Off", LastResult = "" }

---@return string[]  case keys the player actually owns (from the gacha store)
function PatipanStudio.Shop.Cases()
    local service = GameLib.Service.GachaService
    local store = service and service.LocalGachaStore
    local cases = store and store.Data
    if type(cases) ~= "table" then return {} end
    local keys = {}
    for key, entry in pairs(cases) do
        local owned = type(entry) == "table" and entry.Owned or entry
        if tonumber(owned) and owned > 0 then keys[#keys + 1] = tostring(key) end
    end
    table.sort(keys)
    return keys
end

function PatipanStudio.Shop.Owned(caseKey)
    local service = GameLib.Service.GachaService
    if not service then return 0 end
    local ok, owned = pcall(function() return service.GetGachaCount(caseKey) end)
    return ok and tonumber(owned) or 0
end

---@return number  cases the owned count really dropped by
function PatipanStudio.Shop.Open(caseKey, count)
    local service = GameLib.Service.GachaService
    if not service then return 0 end
    local before = PatipanStudio.Shop.Owned(caseKey)
    count = math.min(count, before)
    if count < 1 then return 0 end

    local ok, err = pcall(function() return service.Gacha(caseKey, count) end)
    if not ok then
        warn("[SniperArena] open " .. caseKey .. ": " .. tostring(err))
        return 0
    end
    local after = AwaitChange(before, function() return PatipanStudio.Shop.Owned(caseKey) end)
    return math.max(before - after, 0)
end

function PatipanStudio.Shop.OpenAllNow()
    local opened = 0
    for _, caseKey in ipairs(PatipanStudio.Shop.Cases()) do
        local owned = PatipanStudio.Shop.Owned(caseKey)
        if owned < 1 then continue end
        opened += PatipanStudio.Shop.Open(caseKey, math.min(owned, math.max(PatipanStudio.Options.OpenCount, 1)))
        task.wait(PatipanStudio.Config.OpenDelay)
    end
    PatipanStudio.Shop.LastResult = opened > 0 and (opened .. " cases opened") or "no case opened"
    return PatipanStudio.Shop.LastResult
end

function PatipanStudio.Shop.Step()
    if not PatipanStudio.Options.AutoOpenCases then PatipanStudio.Shop.Status = "Off" return end
    PatipanStudio.Shop.Status = "Opening owned cases"
    PatipanStudio.Shop.OpenAllNow()
end

function PatipanStudio.Shop.GetStatus()
    return PatipanStudio.Options.AutoOpenCases and PatipanStudio.Shop.Status or "Off"
end

PatipanStudio.Sell = { Status = "Off", LastResult = "" }

---@return string?  skin rarity from WrapConfig, nil for base/unknown skins
function PatipanStudio.Sell.RarityOf(weaponName)
    local skin = tostring(weaponName):match("%.(.+)$")
    local wraps = GameLib.Config.WrapConfig
    local entry = skin and type(wraps) == "table" and wraps[skin]
    return type(entry) == "table" and entry.Rarity or nil
end

---@return string[]  rarity names present in WrapConfig
function PatipanStudio.Sell.Rarities()
    local wraps = GameLib.Config.WrapConfig
    if type(wraps) ~= "table" then return {} end
    local seen = {}
    for _, entry in pairs(wraps) do
        if type(entry) == "table" and entry.Rarity then seen[tostring(entry.Rarity)] = true end
    end
    return Util.SortedKeys(seen)
end

---@return table[]  owned weapons with uid, rarity, price, wear
function PatipanStudio.Sell.Inventory()
    local service = GameLib.Service.WeaponService
    local ok, content = pcall(function() return service and service.GetContent() end)
    if not ok or type(content) ~= "table" then return {} end

    local list = {}
    for uid, weapon in pairs(content) do
        if type(weapon) == "table" then
            list[#list + 1] = {
                Uid = uid,
                Name = weapon.Name or tostring(uid),
                Rarity = PatipanStudio.Sell.RarityOf(weapon.Name),
                Price = tonumber(weapon.Price) or 0,
                Wear = tonumber(weapon.WearFactor) or 0,
            }
        end
    end
    return list
end

---@return table?  skin names of the weapons you hold (the loadout has no inventory id), nil when unknown
function PatipanStudio.Sell.Equipped()
    local combat = GameLib.Service.CombatService
    if not combat then return nil end
    local ok, weapons = pcall(function() return combat.GetWeapons() end)
    if not ok or type(weapons) ~= "table" then return nil end

    local set, count = {}, 0
    for _, weapon in pairs(weapons) do
        if type(weapon) == "table" and type(weapon.Name) == "string" then
            set[weapon.Name] = true
            count += 1
        end
    end
    return count > 0 and set or nil
end

---@return string[]?  uids to sell, the priciest KeepPerRarity of each rarity stay; nil when equipped is unknown
function PatipanStudio.Sell.Pick()
    local equipped = PatipanStudio.Sell.Equipped()
    if not equipped then return nil end
    local wanted = Util.SetFromList(PatipanStudio.Options.SellRarities)
    local ceiling = PatipanStudio.Options.MaxSellPrice

    local owned = PatipanStudio.Sell.Inventory()
    table.sort(owned, function(left, right) return left.Price > right.Price end)

    local kept, uids = {}, {}
    for _, weapon in ipairs(owned) do
        if not (weapon.Rarity and wanted[weapon.Rarity]) or equipped[weapon.Name] then continue end
        kept[weapon.Rarity] = (kept[weapon.Rarity] or 0) + 1
        if kept[weapon.Rarity] <= PatipanStudio.Options.KeepPerRarity then continue end
        if ceiling <= 0 or weapon.Price <= ceiling then table.insert(uids, weapon.Uid) end
    end
    return uids
end

function PatipanStudio.Sell.SellNow()
    local service = GameLib.Service.WeaponService
    if not service then PatipanStudio.Sell.LastResult = "no service" return PatipanStudio.Sell.LastResult end

    local uids = PatipanStudio.Sell.Pick()
    if not uids then
        PatipanStudio.Sell.LastResult = "equipped weapons unknown, nothing sold"
        return PatipanStudio.Sell.LastResult
    end
    if #uids == 0 then
        PatipanStudio.Sell.LastResult = "nothing to sell"
        return PatipanStudio.Sell.LastResult
    end

    local countBefore, coinBefore = #PatipanStudio.Sell.Inventory(), PatipanStudio.Player:Coin()
    local ok, err = pcall(function() return service.Sell(uids) end)
    if not ok then
        PatipanStudio.Sell.LastResult = "sell failed: " .. tostring(err)
        return PatipanStudio.Sell.LastResult
    end

    local countAfter = AwaitChange(countBefore, function() return #PatipanStudio.Sell.Inventory() end)
    local coinAfter = PatipanStudio.Player:Coin()
    local gained = (coinBefore and coinAfter) and (" · +" .. (coinAfter - coinBefore) .. " coin") or ""
    PatipanStudio.Sell.LastResult = math.max(countBefore - countAfter, 0) .. " sold" .. gained
    return PatipanStudio.Sell.LastResult
end

function PatipanStudio.Sell.Step()
    if not PatipanStudio.Options.AutoSell then PatipanStudio.Sell.Status = "Off" return end
    PatipanStudio.Sell.Status = PatipanStudio.Sell.SellNow()
end

function PatipanStudio.Sell.GetStatus()
    return PatipanStudio.Options.AutoSell and PatipanStudio.Sell.Status or "Off"
end

PatipanStudio.Collect = { Status = "Off", LastResult = "" }

---@return boolean  false when the game can't answer
function PatipanStudio.Collect.IsClaimed(questId)
    local service = GameLib.Service.QuestService
    local ok, claimed = pcall(function() return service.IsClaimed(questId) end)
    return ok and claimed == true
end

---@return any[]  quest ids the game marks finished and not yet claimed
function PatipanStudio.Collect.Claimable()
    local service = GameLib.Service.QuestService
    local quests = GameLib.Config.QuestConfig
    if not (service and type(quests) == "table") then return {} end

    local list = {}
    for questId in pairs(quests) do
        local asked, finished = pcall(function() return service.IsFinished(questId) end)
        if asked and finished and not PatipanStudio.Collect.IsClaimed(questId) then
            list[#list + 1] = questId
        end
    end
    return list
end

function PatipanStudio.Collect.ClaimNow()
    local service = GameLib.Service.QuestService
    if not service then PatipanStudio.Collect.LastResult = "no service" return PatipanStudio.Collect.LastResult end

    local ids = PatipanStudio.Collect.Claimable()
    if #ids == 0 then
        PatipanStudio.Collect.LastResult = "nothing to claim"
        return PatipanStudio.Collect.LastResult
    end

    local claimed = 0
    for _, questId in ipairs(ids) do
        local ok, err = pcall(function() return service.ClaimReward(questId) end)
        if not ok then
            warn("[SniperArena] claim " .. tostring(questId) .. ": " .. tostring(err))
        elseif AwaitChange(false, function() return PatipanStudio.Collect.IsClaimed(questId) end) then
            claimed += 1
        end
        task.wait(PatipanStudio.Config.ClaimDelay)
    end
    PatipanStudio.Collect.LastResult = claimed .. "/" .. #ids .. " quests claimed"
    return PatipanStudio.Collect.LastResult
end

function PatipanStudio.Collect.Step()
    if not PatipanStudio.Options.AutoClaimQuest then PatipanStudio.Collect.Status = "Off" return end
    PatipanStudio.Collect.Status = PatipanStudio.Collect.ClaimNow()
end

function PatipanStudio.Collect.GetStatus()
    return PatipanStudio.Options.AutoClaimQuest and PatipanStudio.Collect.Status or "Off"
end

PatipanStudio.Combat = { State = "Idle", Status = "Off", Target = nil, Part = nil, Look = nil, Bound = false, LastShot = 0, Circle = nil, OriginFn = nil, OriginParams = nil, LookSource = nil, LookHolders = nil, LockedSince = 0 }

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude

function PatipanStudio.Combat.AimActive()
    return PatipanStudio.Options.Aimbot == true
end

function PatipanStudio.Combat.SilentActive()
    return PatipanStudio.Options.SilentAim == true or PatipanStudio.Options.Ragebot == true
end

function PatipanStudio.Combat.Active()
    local opts = PatipanStudio.Options
    return opts.Aimbot or opts.SilentAim or opts.Ragebot or opts.TriggerBot or opts.ShowFov
end

---@return BasePart?  server hitbox for the chosen bone
function PatipanStudio.Combat.BonePart(entity, bone)
    local char = PatipanStudio.Entity.Character(entity)
    if not char then return nil end
    local collider = char:FindFirstChild("Collider")
    bone = bone or PatipanStudio.Options.AimBone or "Head"
    return collider and (collider:FindFirstChild(bone) or collider:FindFirstChild("Head"))
        or char:FindFirstChild("Head")
        or PatipanStudio.Entity.Root(entity)
end

function PatipanStudio.Combat.Filter()
    local cam = Workspace.CurrentCamera
    aimParams.FilterDescendantsInstances = { cam, PatipanStudio.Entity.Character(PatipanStudio.Entity.Local()) }
    return cam
end

---@return CFrame, any  where the game fires bullets from, detect tag
function PatipanStudio.Combat.Origin()
    local originFn = PatipanStudio.Combat.OriginFn
    if not originFn then
        local camCtrl = PatipanStudio.GameLib.CameraController
        originFn = camCtrl and camCtrl.GetCombatOriginFn and camCtrl.GetCombatOriginFn()
        PatipanStudio.Combat.OriginFn = originFn
    end
    if originFn then
        local ok, origin, detect = pcall(originFn)
        if ok and typeof(origin) == "CFrame" then return origin, detect end
    end
    return Workspace.CurrentCamera.CFrame, nil
end

function PatipanStudio.Combat.Visible(part, char)
    PatipanStudio.Combat.Filter()
    local origin = PatipanStudio.Combat.Origin().Position
    local hit = Workspace:Raycast(origin, part.Position - origin, aimParams)
    return hit ~= nil and hit.Instance:IsDescendantOf(char)
end

function PatipanStudio.Combat.IsEnemy(entity)
    if type(entity) ~= "table" or PatipanStudio.Entity.IsLocal(entity) then return false end
    if PatipanStudio.Options.AimTeamCheck and PatipanStudio.Entity.Friendly(entity) then return false end
    local inst = entity.Instance
    if typeof(inst) == "Instance" and inst:GetAttribute("State") == "Dead" then return false end
    return PatipanStudio.Entity.Health(entity) > 0
end

---@return Vector3  part position led by its velocity
function PatipanStudio.Combat.Predict(part)
    local lead = (PatipanStudio.Options.AimPrediction or 0) / 1000
    if lead <= 0 then return part.Position end
    return part.Position + part.AssemblyLinearVelocity * lead
end

---@return Vector2  screen point the FOV circle is centred on
function PatipanStudio.Combat.AimCenter(cam)
    if PatipanStudio.Options.AimPriority == "Mouse" then return UserInputService:GetMouseLocation() end
    return cam.ViewportSize / 2
end

function PatipanStudio.Combat.UsesFov()
    if PatipanStudio.Options.Ragebot then return false end
    local mode = PatipanStudio.Options.AimPriority
    return mode == "Crosshair" or mode == "Mouse"
end

---@return number?  lower is better, nil when the target is filtered out
function PatipanStudio.Combat.Score(entity, part, cam, center, origin)
    local dist = (part.Position - origin).Magnitude
    if dist > PatipanStudio.Options.AimMaxDistance then return nil end

    if PatipanStudio.Combat.UsesFov() then
        local screen, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then return nil end
        local gap = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if gap > PatipanStudio.Options.AimFov then return nil end
        return gap
    end
    if PatipanStudio.Options.AimPriority == "Health" then
        return PatipanStudio.Entity.Health(entity) * 10000 + dist
    end
    return dist
end

---@return table?, BasePart?  best target for the chosen priority mode
function PatipanStudio.Combat.SelectTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = PatipanStudio.Combat.AimCenter(cam)
    local origin = cam.CFrame.Position
    local best, bestPart, bestScore

    for _, entity in pairs(PatipanStudio.Entity.List()) do
        if not PatipanStudio.Combat.IsEnemy(entity) then continue end
        local part = PatipanStudio.Combat.BonePart(entity)
        if not part then continue end
        local score = PatipanStudio.Combat.Score(entity, part, cam, center, origin)
        if not score or (bestScore and score >= bestScore) then continue end
        if (PatipanStudio.Options.AimWallCheck or PatipanStudio.Options.Ragebot) and not PatipanStudio.Combat.Visible(part, PatipanStudio.Entity.Character(entity)) then continue end
        best, bestPart, bestScore = entity, part, score
    end
    return best, bestPart
end

function PatipanStudio.Combat.BindCamera()
    if PatipanStudio.Combat.Bound then return end
    PatipanStudio.Combat.Bound = true
    RunService:BindToRenderStep("PatipanStudioAim", PatipanStudio.Config.AimRenderPriority, function()
        local cam = Workspace.CurrentCamera
        local part = PatipanStudio.Combat.Part
        if not (PatipanStudio.Combat.AimActive() and part and part.Parent) then
            PatipanStudio.Combat.Look = nil
            return
        end
        local origin = cam.CFrame.Position
        local want = (PatipanStudio.Combat.Predict(part) - origin).Unit
        local smooth = math.max(PatipanStudio.Options.AimSmooth or 1, 1)
        local look = PatipanStudio.Combat.Look or cam.CFrame.LookVector
        look = smooth <= 1 and want or look:Lerp(want, 1 / smooth).Unit
        PatipanStudio.Combat.Look = look
        cam.CFrame = CFrame.lookAt(origin, origin + look)
    end)
end

function PatipanStudio.Combat.UnbindCamera()
    if not PatipanStudio.Combat.Bound then return end
    PatipanStudio.Combat.Bound = false
    RunService:UnbindFromRenderStep("PatipanStudioAim")
end

---@return boolean  crosshair currently on an enemy hitbox
function PatipanStudio.Combat.CrosshairOnEnemy()
    PatipanStudio.Combat.Filter()
    local origin = PatipanStudio.Combat.Origin()
    local hit = Workspace:Raycast(origin.Position, origin.LookVector * PatipanStudio.Config.TriggerRange, aimParams)
    if not hit then return false end
    for _, entity in pairs(PatipanStudio.Entity.List()) do
        local char = PatipanStudio.Entity.Character(entity)
        if char and hit.Instance:IsDescendantOf(char) then return PatipanStudio.Combat.IsEnemy(entity) end
    end
    return false
end

---@return boolean  true when the weapon accepted the shot
function PatipanStudio.Combat.Fire()
    local now = os.clock()
    if now - PatipanStudio.Combat.LastShot < PatipanStudio.Config.FireInterval then return false end
    PatipanStudio.Combat.LastShot = now

    local _, shooter = PatipanStudio.Combat.Shooter()
    if not shooter then return false end

    local ok, fired = pcall(shooter.LocalShoot, shooter)
    if not ok then warn("[SniperArena] shoot:", fired) end
    return ok and fired ~= nil
end

function PatipanStudio.Combat.Shooter()
    local combat = PatipanStudio.GameLib.Service.CombatService
    local weapon = combat and combat.GetCurrentWeapon()
    return weapon, weapon and weapon._Shootable
end

PatipanStudio.Combat.SilentSaved = setmetatable({}, { __mode = "k" })

---@return table?  the game's combat-origin override table
function PatipanStudio.Combat.OriginOverride()
    if PatipanStudio.Combat.OriginParams ~= nil then return PatipanStudio.Combat.OriginParams or nil end
    if not PatipanStudio.Caps.Upvalues then return nil end
    local camCtrl = PatipanStudio.GameLib.CameraController
    local ok, holder = pcall(function() return Util.GetUpvalue(camCtrl.GetCombatOriginFn(), 1) end)
    local params = ok and type(holder) == "table" and type(holder.TempParams) == "table" and holder.TempParams
    PatipanStudio.Combat.OriginParams = params or false
    return params or nil
end

---@return any  what the game's Shoot returns
function PatipanStudio.Combat.ShootAt(shooter, entity, part, opts)
    local params = PatipanStudio.Combat.OriginOverride()
    local start = PatipanStudio.Combat.Origin().Position
    local aim = PatipanStudio.Combat.Predict(part)
    opts = type(opts) == "table" and opts or {}
    opts.Target = entity.Instance
    opts.TargetHeadshot = part.Name == "Head" or nil
    local ok, localPos = pcall(function() return entity:GetPivot(true):PointToObjectSpace(aim) end)
    if ok then opts.TargetPos = localPos end

    local saved = { params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset }
    params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset = CFrame.lookAt(start, aim), 0, Vector3.zero
    local fired, shot = pcall(shooter.Shoot, shooter, start, (aim - start).Unit, opts)
    params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset = saved[1], saved[2], saved[3]
    if not fired then warn("[SniperArena] silent:", shot) end
    return fired and shot or nil
end

---@return any  same as the game's LocalShoot, bullet sent at the locked target
function PatipanStudio.Combat.SilentShoot(shooter, opts)
    local saved = PatipanStudio.Combat.SilentSaved[shooter]
    local entity = PatipanStudio.Combat.Target
    if not (PatipanStudio.Combat.SilentActive() and entity and PatipanStudio.Combat.OriginOverride()) then return saved.Fn(shooter, opts) end
    if math.random(100) > PatipanStudio.Options.HitChance then return saved.Fn(shooter, opts) end

    local bone = math.random(100) <= PatipanStudio.Options.HeadChance and "Head" or "Body"
    local part = PatipanStudio.Combat.BonePart(entity, bone)
    if not (part and part.Parent) then return saved.Fn(shooter, opts) end
    return PatipanStudio.Combat.ShootAt(shooter, entity, part, opts)
end

---@return CFrame  camera the server is told we look through
function PatipanStudio.Combat.ReportedLook(...)
    local look = PatipanStudio.Combat.LookSource(...)
    local part = PatipanStudio.Combat.Part
    if typeof(look) ~= "CFrame" or not (PatipanStudio.Combat.SilentActive() and PatipanStudio.Combat.Target and part and part.Parent) then return look end
    return CFrame.lookAt(look.Position, PatipanStudio.Combat.Predict(part))
end

---@return table[]  tables that really hold CameraController's functions
function PatipanStudio.Combat.LookTables()
    local camCtrl = PatipanStudio.GameLib.CameraController
    local tables = {}
    if type(camCtrl) ~= "table" then return tables end
    if rawget(camCtrl, "GetCFrame") and not table.isfrozen(camCtrl) then tables[1] = camCtrl end
    local meta = Util.GetRawMetatable and Util.GetRawMetatable(camCtrl)
    local index = type(meta) == "table" and rawget(meta, "__index")
    if type(index) == "table" then index = { index } elseif type(index) == "function" and Util.GetUpvalues then index = Util.GetUpvalues(index) else index = {} end
    for _, holder in pairs(index) do
        if type(holder) == "table" and type(rawget(holder, "GetCFrame")) == "function" and not table.isfrozen(holder) then
            tables[#tables + 1] = holder
        end
    end
    return tables
end

function PatipanStudio.Combat.ApplyLook()
    if PatipanStudio.Combat.LookSource ~= nil then return end
    local tables = PatipanStudio.Combat.LookTables()
    if #tables == 0 then
        PatipanStudio.Combat.LookSource = false
        return
    end
    PatipanStudio.Combat.LookSource = rawget(tables[1], "GetCFrame")
    PatipanStudio.Combat.LookHolders = tables
    for _, holder in ipairs(tables) do rawset(holder, "GetCFrame", PatipanStudio.Combat.ReportedLook) end
end

function PatipanStudio.Combat.RestoreLook()
    local source = PatipanStudio.Combat.LookSource
    if not source then
        PatipanStudio.Combat.LookSource = nil
        return
    end
    for _, holder in ipairs(PatipanStudio.Combat.LookHolders or {}) do
        if rawget(holder, "GetCFrame") == PatipanStudio.Combat.ReportedLook then rawset(holder, "GetCFrame", source) end
    end
    PatipanStudio.Combat.LookSource, PatipanStudio.Combat.LookHolders = nil, nil
end

function PatipanStudio.Combat.ApplySilent()
    local _, shooter = PatipanStudio.Combat.Shooter()
    if type(shooter) ~= "table" or rawget(shooter, "LocalShoot") == PatipanStudio.Combat.SilentShoot then return end
    if type(shooter.Shoot) ~= "function" then return end
    PatipanStudio.Combat.SilentSaved[shooter] = { Raw = rawget(shooter, "LocalShoot"), Fn = shooter.LocalShoot }
    rawset(shooter, "LocalShoot", PatipanStudio.Combat.SilentShoot)
end

function PatipanStudio.Combat.RestoreSilent()
    for shooter, saved in pairs(PatipanStudio.Combat.SilentSaved) do
        rawset(shooter, "LocalShoot", saved.Raw)
    end
    table.clear(PatipanStudio.Combat.SilentSaved)
end

PatipanStudio.Combat.ScopeSaved = setmetatable({}, { __mode = "k" })

function PatipanStudio.Combat.ApplyInstantScope()
    local weapon = PatipanStudio.Combat.Shooter()
    local cfg = weapon and weapon.Config
    if type(cfg) ~= "table" or rawget(cfg, "AimTime") == 0 then return end
    if not PatipanStudio.Combat.ScopeSaved[cfg] then
        PatipanStudio.Combat.ScopeSaved[cfg] = { rawget(cfg, "AimTime"), rawget(cfg, "DelayTime") }
    end
    rawset(cfg, "AimTime", 0)
    rawset(cfg, "DelayTime", 0)
end

function PatipanStudio.Combat.RestoreScope()
    for cfg, saved in pairs(PatipanStudio.Combat.ScopeSaved) do
        rawset(cfg, "AimTime", saved[1])
        rawset(cfg, "DelayTime", saved[2])
    end
    table.clear(PatipanStudio.Combat.ScopeSaved)
end

---@return table  { Drawing = circle }, or { Frame = ring } as a Gui circle when Drawing is missing
function PatipanStudio.Combat.MakeCircle()
    local color = PatipanStudio.Config.FovColor
    if PatipanStudio.Caps.Drawing then
        local circle = Drawing.new("Circle")
        circle.Thickness, circle.NumSides, circle.Filled = 1.5, 64, false
        circle.Color = color
        return { Drawing = circle }
    end

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.BackgroundTransparency = 1
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Parent = ring
    ring.Parent = Util.Overlay()
    return { Frame = ring }
end

function PatipanStudio.Combat.SetCircleVisible(visible)
    local circle = PatipanStudio.Combat.Circle
    if not circle then return end
    if circle.Drawing then circle.Drawing.Visible = visible else circle.Frame.Visible = visible end
end

function PatipanStudio.Combat.UpdateCircle()
    if not PatipanStudio.Options.ShowFov then
        PatipanStudio.Combat.SetCircleVisible(false)
        return
    end
    local circle = PatipanStudio.Combat.Circle
    if not circle then
        circle = PatipanStudio.Combat.MakeCircle()
        PatipanStudio.Combat.Circle = circle
    end

    local center = PatipanStudio.Combat.AimCenter(Workspace.CurrentCamera)
    local radius = PatipanStudio.Options.AimFov
    if circle.Drawing then
        circle.Drawing.Position, circle.Drawing.Radius, circle.Drawing.Visible = center, radius, true
        return
    end
    circle.Frame.Position = UDim2.fromOffset(center.X, center.Y)
    circle.Frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
    circle.Frame.Visible = true
end

function PatipanStudio.Combat.DrawCircle()
    local ok, err = pcall(PatipanStudio.Combat.UpdateCircle)
    if ok then
        PatipanStudio.Faults.Clear("FOV circle")
    else
        PatipanStudio.Faults.Report("FOV circle", err, { "ShowFov" })
    end
end

PatipanStudio.Combat.RecoilSaved = setmetatable({}, { __mode = "k" })
PatipanStudio.Combat.ZoomSaved = setmetatable({}, { __mode = "k" })

function PatipanStudio.Combat.ApplyNoRecoil()
    local weapon = PatipanStudio.Combat.Shooter()
    local cfg = weapon and weapon.Config
    if type(cfg) ~= "table" then return end
    if type(cfg.RecoilZoom) == "number" and cfg.RecoilZoom ~= 0 then
        PatipanStudio.Combat.ZoomSaved[cfg] = PatipanStudio.Combat.ZoomSaved[cfg] or cfg.RecoilZoom
        cfg.RecoilZoom = 0
    end
    for _, key in ipairs({ "Recoil", "RecoilAiming" }) do
        local recoil = cfg[key]
        if type(recoil) == "table" and recoil.Degree ~= 0 then
            if PatipanStudio.Combat.RecoilSaved[recoil] == nil then PatipanStudio.Combat.RecoilSaved[recoil] = recoil.Degree end
            recoil.Degree = 0
        end
    end
end

PatipanStudio.Combat.SpreadSaved = setmetatable({}, { __mode = "k" })

function PatipanStudio.Combat.ZeroSpread()
    return 0
end

function PatipanStudio.Combat.ApplyNoSpread()
    local _, shooter = PatipanStudio.Combat.Shooter()
    if type(shooter) ~= "table" or rawget(shooter, "GetCurrentSpread") == PatipanStudio.Combat.ZeroSpread then return end
    PatipanStudio.Combat.SpreadSaved[shooter] = { rawget(shooter, "GetCurrentSpread") }
    rawset(shooter, "GetCurrentSpread", PatipanStudio.Combat.ZeroSpread)
end

function PatipanStudio.Combat.RestoreSpread()
    for shooter, original in pairs(PatipanStudio.Combat.SpreadSaved) do
        rawset(shooter, "GetCurrentSpread", original[1])
    end
    table.clear(PatipanStudio.Combat.SpreadSaved)
end

function PatipanStudio.Combat.RestoreRecoil()
    for recoil, degree in pairs(PatipanStudio.Combat.RecoilSaved) do recoil.Degree = degree end
    for cfg, zoom in pairs(PatipanStudio.Combat.ZoomSaved) do cfg.RecoilZoom = zoom end
    table.clear(PatipanStudio.Combat.RecoilSaved)
    table.clear(PatipanStudio.Combat.ZoomSaved)
end

function PatipanStudio.Combat.Patches()
    if not PatipanStudio.State.Alive then return end
    local opts = PatipanStudio.Options

    if opts.NoRecoil then
        PatipanStudio.Combat.ApplyNoRecoil()
    elseif next(PatipanStudio.Combat.RecoilSaved) or next(PatipanStudio.Combat.ZoomSaved) then
        PatipanStudio.Combat.RestoreRecoil()
    end
    if opts.NoSpread then
        PatipanStudio.Combat.ApplyNoSpread()
    elseif next(PatipanStudio.Combat.SpreadSaved) then
        PatipanStudio.Combat.RestoreSpread()
    end
    if opts.InstantScope or opts.Ragebot or opts.SilentAim then
        PatipanStudio.Combat.ApplyInstantScope()
    elseif next(PatipanStudio.Combat.ScopeSaved) then
        PatipanStudio.Combat.RestoreScope()
    end

    if PatipanStudio.Combat.SilentActive() then
        PatipanStudio.Combat.ApplySilent()
        PatipanStudio.Combat.ApplyLook()
        return
    end
    if next(PatipanStudio.Combat.SilentSaved) then PatipanStudio.Combat.RestoreSilent() end
    PatipanStudio.Combat.RestoreLook()
end

function PatipanStudio.Combat.Aim(mode)
    local target, part = PatipanStudio.Combat.SelectTarget()
    if target ~= PatipanStudio.Combat.Target then PatipanStudio.Combat.LockedSince = os.clock() end
    PatipanStudio.Combat.Target, PatipanStudio.Combat.Part = target, part
    PatipanStudio.Combat.State = target and "Locked" or "Acquire"
    local char = target and PatipanStudio.Entity.Character(target)
    PatipanStudio.Combat.Status = mode .. " · " .. (char and char.Name or "no target")
end

function PatipanStudio.Combat.Step()
    PatipanStudio.Combat.Patches()
    if not PatipanStudio.Combat.Active() then
        if PatipanStudio.Combat.State ~= "Idle" then PatipanStudio.Combat.Stop() end
        return
    end
    if not PatipanStudio.Match.InRound() then
        PatipanStudio.Combat.Target, PatipanStudio.Combat.Part = nil, nil
        PatipanStudio.Combat.State, PatipanStudio.Combat.Status = "Wait", "Waiting for round"
        return
    end

    local mode = PatipanStudio.Match.Info() or "?"
    if PatipanStudio.Combat.AimActive() then PatipanStudio.Combat.BindCamera() else PatipanStudio.Combat.UnbindCamera() end
    if PatipanStudio.Combat.AimActive() or PatipanStudio.Combat.SilentActive() then
        PatipanStudio.Combat.Aim(mode)
    else
        PatipanStudio.Combat.Target, PatipanStudio.Combat.Part = nil, nil
        PatipanStudio.Combat.State, PatipanStudio.Combat.Status = "Ready", mode .. " · aim idle"
    end

    local settled = PatipanStudio.Combat.Target ~= nil and os.clock() - PatipanStudio.Combat.LockedSince >= PatipanStudio.Config.LookSettle
    local shoot = (PatipanStudio.Options.Ragebot and settled) or (PatipanStudio.Options.TriggerBot and PatipanStudio.Combat.CrosshairOnEnemy())
    if shoot and PatipanStudio.Combat.Fire() then PatipanStudio.Combat.State = "Fired" end
end

function PatipanStudio.Combat.Stop()
    PatipanStudio.Combat.UnbindCamera()
    PatipanStudio.Combat.Target, PatipanStudio.Combat.Part = nil, nil
    PatipanStudio.Combat.State, PatipanStudio.Combat.Status = "Idle", "Off"
end

function PatipanStudio.Combat.Rest()
    local undo = {
        PatipanStudio.Combat.Stop, PatipanStudio.Combat.RestoreRecoil, PatipanStudio.Combat.RestoreSpread,
        PatipanStudio.Combat.RestoreScope, PatipanStudio.Combat.RestoreSilent, PatipanStudio.Combat.RestoreLook,
    }
    for _, restore in ipairs(undo) do
        Util.Try("combat restore", restore)
    end
end

function PatipanStudio.Combat.Unload()
    PatipanStudio.Combat.Rest()
    local circle = PatipanStudio.Combat.Circle
    PatipanStudio.Combat.Circle = nil
    if not circle then return end
    if circle.Frame then
        circle.Frame:Destroy()
    else
        pcall(function() circle.Drawing:Remove() end)
    end
end

function PatipanStudio.Combat.GetStatus()
    return PatipanStudio.Combat.Status
end

PatipanStudio.Skin = {
    Catalog = {},
    Types = {},
    Rarities = {},
    Labels = {},
    Images = {},
    Colors = {},
    Chosen = {},
    Saved = setmetatable({}, { __mode = "k" }),
    Status = "Off",
    RarityRank = { Common = 1, UnCommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mystic = 6 },
    Hidden = { Charm = true },
}

---@return string?, string?  weapon type and family, nil for non-weapons
function PatipanStudio.Skin.Classify(cfg)
    if type(cfg) ~= "table" then return nil end
    local ok, kind, family = pcall(function() return cfg.WeaponType, cfg.Family end)
    if not ok or type(kind) ~= "string" or type(family) ~= "string" then return nil end
    if PatipanStudio.Skin.Hidden[kind] or family:find("^Base") then return nil end
    return kind, family
end

do
    local configs = PatipanStudio.GameLib.Config.WeaponConfig or {}
    for key, cfg in pairs(configs) do
        if type(key) ~= "string" then continue end
        local kind, family = PatipanStudio.Skin.Classify(cfg)
        if not kind then continue end
        local byFamily = PatipanStudio.Skin.Catalog[kind]
        if not byFamily then
            byFamily = {}
            PatipanStudio.Skin.Catalog[kind] = byFamily
            table.insert(PatipanStudio.Skin.Types, kind)
        end
        byFamily[family] = byFamily[family] or {}
        local rarity = tostring(cfg.Rarity or "Common")
        table.insert(byFamily[family], { key, rarity, type(cfg.Display) == "string" and cfg.Display or key, type(cfg.Image) == "string" and cfg.Image or nil })
        if not table.find(PatipanStudio.Skin.Rarities, rarity) then table.insert(PatipanStudio.Skin.Rarities, rarity) end
    end
    table.sort(PatipanStudio.Skin.Types)
    table.sort(PatipanStudio.Skin.Rarities, function(left, right)
        local rankLeft, rankRight = PatipanStudio.Skin.RarityRank[left] or 0, PatipanStudio.Skin.RarityRank[right] or 0
        if rankLeft ~= rankRight then return rankLeft > rankRight end
        return left < right
    end)
    for _, byFamily in pairs(PatipanStudio.Skin.Catalog) do
        for _, list in pairs(byFamily) do
            table.sort(list, function(left, right)
                local rankLeft, rankRight = PatipanStudio.Skin.RarityRank[left[2]] or 0, PatipanStudio.Skin.RarityRank[right[2]] or 0
                if rankLeft ~= rankRight then return rankLeft > rankRight end
                return left[3] < right[3]
            end)
        end
    end
end

function PatipanStudio.Skin.Families(kind)
    return Util.SortedKeys(PatipanStudio.Skin.Catalog[kind])
end

---@param rarities table?  set of rarities to show, empty = all
---@return string[]  labels for the dropdown, best rarity first
function PatipanStudio.Skin.List(kind, family, rarities)
    local list = PatipanStudio.Skin.Catalog[kind] and PatipanStudio.Skin.Catalog[kind][family]
    local names = {}
    if not list then return names end
    local filter = rarities and next(rarities) ~= nil and rarities or nil
    for _, skin in ipairs(list) do
        if filter and not filter[skin[2]] then continue end
        local label = string.format("[%s] %s", skin[2], skin[3])
        if PatipanStudio.Skin.Labels[label] and PatipanStudio.Skin.Labels[label] ~= skin[1] then label = label .. " · " .. skin[1] end
        PatipanStudio.Skin.Labels[label] = skin[1]
        PatipanStudio.Skin.Images[label] = skin[4]
        local colors = PatipanStudio.GameLib.RarityColor
        PatipanStudio.Skin.Colors[label] = type(colors) == "table" and typeof(colors[skin[2]]) == "Color3" and colors[skin[2]] or nil
        names[#names + 1] = label
    end
    return names
end

function PatipanStudio.Skin.Choose(family, label)
    PatipanStudio.Skin.Chosen[family] = label and PatipanStudio.Skin.Labels[label] or nil
end

function PatipanStudio.Skin.ClearAll()
    table.clear(PatipanStudio.Skin.Chosen)
end

---@return table[]  every weapon the local player carries
function PatipanStudio.Skin.Carried()
    local combat = PatipanStudio.GameLib.Service.CombatService
    local ok, weapons = pcall(function() return combat.GetWeapons() end)
    local list = {}
    if ok and type(weapons) == "table" then
        for _, weapon in pairs(weapons) do
            if type(weapon) == "table" and weapon.Name then list[#list + 1] = weapon end
        end
    end
    local held = combat and combat.GetCurrentWeapon()
    if held and not table.find(list, held) then list[#list + 1] = held end
    return list
end

function PatipanStudio.Skin.Rebuild(weapon)
    local controllers = PatipanStudio.GameLib.WeaponController
    local entity = PatipanStudio.GameLib.Service.EntityService.LocalEntity
    if not (controllers and entity and weapon.Controller) then return end
    weapon.Controller:Destroy()
    controllers.Create(entity, weapon)
end

function PatipanStudio.Skin.Apply(weapon, key)
    local cfg = PatipanStudio.GameLib.Config.WeaponConfig[key]
    if not cfg then return end
    if not PatipanStudio.Skin.Saved[weapon] then PatipanStudio.Skin.Saved[weapon] = { weapon.Name, weapon.Config } end
    weapon.Name, weapon.Config = key, cfg
    PatipanStudio.Skin.Rebuild(weapon)
end

function PatipanStudio.Skin.Revert(weapon)
    local saved = PatipanStudio.Skin.Saved[weapon]
    if not saved then return end
    weapon.Name, weapon.Config = saved[1], saved[2]
    PatipanStudio.Skin.Saved[weapon] = nil
    PatipanStudio.Skin.Rebuild(weapon)
end

function PatipanStudio.Skin.Restore()
    for weapon in pairs(PatipanStudio.Skin.Saved) do PatipanStudio.Skin.Revert(weapon) end
end

function PatipanStudio.Skin.Step()
    if not PatipanStudio.Options.SkinChanger then
        if next(PatipanStudio.Skin.Saved) then PatipanStudio.Skin.Restore() end
        PatipanStudio.Skin.Status = "Off"
        return
    end

    local applied = 0
    for _, weapon in ipairs(PatipanStudio.Skin.Carried()) do
        local saved = PatipanStudio.Skin.Saved[weapon]
        local originalCfg = saved and saved[2] or weapon.Config
        local _, family = PatipanStudio.Skin.Classify(originalCfg)
        local key = family and PatipanStudio.Skin.Chosen[family]
        if key then
            if weapon.Name ~= key then PatipanStudio.Skin.Apply(weapon, key) end
            applied += 1
        elseif saved then
            PatipanStudio.Skin.Revert(weapon)
        end
    end
    PatipanStudio.Skin.Status = applied > 0 and (applied .. " weapon(s) skinned") or "Pick a skin"
end

function PatipanStudio.Skin.GetStatus()
    return PatipanStudio.Skin.Status
end

PatipanStudio.UI = { Labels = {}, Shown = {}, Stats = { Cases = 0, Quests = 0 } }
local Library, T

function PatipanStudio.UI.Detach(handler)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(handler, table.unpack(packed, 1, packed.n))
            if not ok then warn("[SniperArena] ui: " .. tostring(err)) end
        end)
    end
end

---@param module table  feature with Start/Stop
function PatipanStudio.UI.StartStop(module)
    return PatipanStudio.UI.Detach(function(on)
        if on then module.Start() else module.Stop() end
    end)
end

---@param widget table  option whose value mirrors an Options key
function PatipanStudio.UI.Bind(widget, key, transform)
    local function Apply(value)
        if transform then value = transform(value) end
        PatipanStudio.Options[key] = value
    end
    Apply(widget.Value)
    widget:OnChanged(Apply)
    return widget
end

function PatipanStudio.UI.SampleStats()
    local cases = 0
    for _, caseKey in ipairs(PatipanStudio.Shop.Cases()) do
        cases += PatipanStudio.Shop.Owned(caseKey)
    end
    PatipanStudio.UI.Stats.Cases = cases
    PatipanStudio.UI.Stats.Quests = #PatipanStudio.Collect.Claimable()
end

---@param title table  T() pair; the UI pump shows it, game-module threads can't
function PatipanStudio.UI.Notice(title, text, kind)
    table.insert(PatipanStudio.State.Notices, { title, tostring(text), kind })
end

function PatipanStudio.UI.BuildMain(window)
    window:AddTabSection(T("Main", "หลัก"))
    local tab = window:AddTab(T("Main", "หลัก"), "mushroom", T("Status and links", "สถานะและลิงก์"))

    local status = tab:AddLeftGroupbox(T("Status", "สถานะ"), "star")
    PatipanStudio.UI.Labels.Esp = status:AddParagraph({ Title = T("ESP", "ESP"), Content = "-" })
    PatipanStudio.UI.Labels.Combat = status:AddParagraph({ Title = T("Combat", "การต่อสู้"), Content = "-" })
    PatipanStudio.UI.Labels.Skin = status:AddParagraph({ Title = T("Skin", "สกิน"), Content = "-" })
    PatipanStudio.UI.Labels.Economy = status:AddParagraph({ Title = T("Economy", "เศรษฐกิจ"), Content = "-" })

    local live = tab:AddRightGroupbox(T("Live", "ตัวเลขสด"), "coin")
    PatipanStudio.UI.Labels.Targets = live:AddParagraph({ Title = T("Enemies seen", "ศัตรูที่เห็น"), Content = "0" })
    PatipanStudio.UI.Labels.Cases = live:AddParagraph({ Title = T("Cases owned", "กล่องที่มี"), Content = "0" })
    PatipanStudio.UI.Labels.Quests = live:AddParagraph({ Title = T("Quests ready", "เควสต์รอรับ"), Content = "0" })

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
end

function PatipanStudio.UI.GuardSilent()
    local reason = T("Not supported on this executor", "ใช้กับ executor นี้ไม่ได้")
    for _, idx in ipairs({ "SilentAim", "Ragebot" }) do
        Library.Compat.NeedCap(idx, "Upvalues")
        if not PatipanStudio.Caps.LookSpoof then Library.Compat.Block(idx, reason) end
    end
end

function PatipanStudio.UI.BuildCombat(window)
    window:AddTabSection(T("Combat", "การต่อสู้"))
    local tab = window:AddTab(T("Combat", "การต่อสู้"), "target", T("Aimbot and firing", "เล็งอัตโนมัติและยิง"))

    local aim = tab:AddLeftGroupbox(T("Aimbot", "เล็งอัตโนมัติ"), "crosshair")
    aim:AddToggle("Aimbot", {
        Text = T("Aimbot", "เล็งอัตโนมัติ"),
        Description = T("Locks onto the enemy nearest your crosshair", "ล็อคศัตรูที่ใกล้เป้าเล็งที่สุด"),
    }):AddKeyPicker("AimbotKey", { Default = "MB2", Mode = "Hold" })
    aim:AddDropdown("AimPriority", { Text = T("Target priority", "เลือกเป้าตาม"), Values = { "Crosshair", "Mouse", "Distance", "Health" }, Default = "Crosshair" })
    aim:AddSlider("AimMaxDistance", { Text = T("Max aim distance", "ระยะเล็งสูงสุด"), Min = 50, Max = 2000, Default = 1000, Suffix = "m" })
    aim:AddDropdown("AimBone", { Text = T("Aim part", "จุดเล็ง"), Values = { "Head", "Body", "Arm", "Leg" }, Default = "Head" })
    aim:AddSlider("AimSmooth", { Text = T("Smoothness", "ความนุ่ม"), Min = 1, Max = 20, Default = 1, Rounding = 0 })
    aim:AddSlider("AimPrediction", { Text = T("Prediction", "เล็งดักหน้า"), Min = 0, Max = 200, Default = 60, Suffix = "ms", Rounding = 0 })
    aim:AddSlider("AimFov", { Text = T("FOV", "ระยะมอง"), Min = 20, Max = 600, Default = 150, Suffix = "px" })
    aim:AddToggle("ShowFov", { Text = T("Show FOV circle", "แสดงวงระยะมอง") })
    aim:AddCheckbox("AimWallCheck", { Text = T("Visible only", "เฉพาะที่มองเห็น"), Default = true })
    aim:AddCheckbox("AimTeamCheck", { Text = T("Team check", "เช็คทีม"), Default = true })

    local rage = tab:AddRightGroupbox(T("Rage", "เรจ"), "bomb")
    rage:AddToggle("Ragebot", { Text = T("Ragebot", "เรจบอท"), Description = T("Shoots every visible enemy on its own, view stays still", "ยิงศัตรูทุกตัวที่มองเห็นเอง กล้องไม่ขยับ") })
        :AddKeyPicker("RagebotKey", { Default = "None", Mode = "Toggle" })
    rage:AddToggle("SilentAim", { Text = T("Silent aim", "ไซเลนต์เอม"), Description = T("Shots land on the target inside the FOV, your view never moves", "กระสุนเข้าเป้าในวง FOV กล้องไม่ขยับเลย") })
        :AddKeyPicker("SilentAimKey", { Default = "None", Mode = "Toggle" })
    rage:AddSlider("HitChance", { Text = T("Hit chance", "โอกาสยิงโดน"), Min = 0, Max = 100, Default = 100, Suffix = "%", Rounding = 0 })
    rage:AddSlider("HeadChance", { Text = T("Headshot chance", "โอกาสเข้าหัว"), Min = 0, Max = 100, Default = 100, Suffix = "%", Rounding = 0 })
    rage:AddToggle("InstantScope", { Text = T("Fast scope", "เปิดสโคปเร็ว"), Description = T("Cuts the wait before the scope is ready", "ลดเวลารอก่อนสโคปพร้อมยิง") })

    local fire = tab:AddRightGroupbox(T("Firing", "การยิง"), "swords")
    fire:AddToggle("TriggerBot", { Text = T("Trigger bot", "ยิงอัตโนมัติ"), Description = T("Fires the moment your crosshair is on an enemy", "ยิงทันทีเมื่อเป้าเล็งทับศัตรู") })
        :AddKeyPicker("TriggerBotKey", { Default = "None", Mode = "Toggle" })
    fire:AddToggle("NoSpread", { Text = T("No spread", "ยิงไม่กระจาย"), Description = T("Shots stay accurate while moving or jumping", "ยิงแม่นแม้ตอนเดินหรือกระโดด") })
    fire:AddToggle("NoRecoil", { Text = T("No recoil", "ไม่มีแรงถีบ"), Description = T("Camera no longer kicks when firing", "กล้องไม่เด้งตอนยิง") })

    PatipanStudio.UI.GuardSilent()
end

function PatipanStudio.UI.BuildPlayer(window)
    window:AddTabSection(T("Player", "ผู้เล่น"))
    local tab = window:AddTab(T("Player", "ผู้เล่น"), "oneup", T("Respawn and utility", "เกิดใหม่และอรรถประโยชน์"))

    local util = tab:AddLeftGroupbox(T("Utility", "อรรถประโยชน์"), "gear")
    util:AddToggle("FastRespawn", { Text = T("Fast respawn", "เกิดใหม่เร็ว"), Description = T("Back in the fight the moment you die", "กลับเข้าสนามทันทีที่ตาย") })
    util:AddToggle("AutoJoin", { Text = T("Auto join round", "เข้ารอบอัตโนมัติ"), Description = T("Joins the next round from the lobby by itself", "เข้ารอบถัดไปจากล็อบบี้เอง") })
    Library.Compat.NeedCap("AutoJoin", "Touch")
    util:AddToggle("AntiAfk", { Text = T("Anti AFK", "กันหลุด AFK"), Callback = PatipanStudio.UI.StartStop(PatipanStudio.Player.AntiAfk) })

    local move = tab:AddRightGroupbox(T("Movement", "การเคลื่อนที่"), "zap")
    move:AddToggle("InfiniteDash", { Text = T("Infinite dash", "พุ่งไม่จำกัด"), Description = T("Dash again without waiting (FFA/TDM)", "พุ่งซ้ำได้ไม่ต้องรอ (FFA/TDM)") })
end

PatipanStudio.UI.SkinKinds = {
    Sniper = { "Snipers", "สไนเปอร์", "crosshair" },
    Rifle = { "Rifles", "ไรเฟิล", "target" },
    Melee = { "Knives", "มีด", "swords" },
    Glove = { "Gloves", "ถุงมือ", "shield" },
}

---@param kind string  WeaponType from the game config
function PatipanStudio.UI.BuildSkinGroup(tab, kind, left)
    local meta = PatipanStudio.UI.SkinKinds[kind] or { kind, kind, "star" }
    local group = left and tab:AddLeftGroupbox(T(meta[1], meta[2]), meta[3]) or tab:AddRightGroupbox(T(meta[1], meta[2]), meta[3])
    local families = PatipanStudio.Skin.Families(kind)
    local weaponIdx, skinIdx = "Skin" .. kind .. "Weapon", "Skin" .. kind .. "Pick"

    local function Family()
        local picker = Library.Options[weaponIdx]
        return picker and picker.Value
    end

    local function Refill()
        local picker = Library.Options[skinIdx]
        if picker then picker:SetValues(PatipanStudio.Skin.List(kind, Family(), Util.SetFromList(PatipanStudio.Options.SkinRarities))) end
    end
    table.insert(PatipanStudio.UI.SkinRefill, Refill)

    group:AddDropdown(weaponIdx, { Text = T("Weapon", "อาวุธ"), Values = families, Default = families[1], Searchable = true, Callback = function() Refill() end })
    group:AddDropdown(skinIdx, {
        Text = T("Skin", "สกิน"),
        Values = PatipanStudio.Skin.List(kind, families[1], {}),
        Images = PatipanStudio.Skin.Images,
        Colors = PatipanStudio.Skin.Colors,
        Searchable = true,
        AllowNull = true,
        Callback = function(label)
            if Family() then PatipanStudio.Skin.Choose(Family(), label) end
        end,
    })
    group:AddButton({ Text = T("Use default skin", "ใช้สกินเดิม"), Func = function()
        if Family() then PatipanStudio.Skin.Choose(Family(), nil) end
        Library.Options[skinIdx]:SetValue(nil)
    end })
end

function PatipanStudio.UI.BuildSkins(window)
    PatipanStudio.UI.SkinRefill = {}
    local tab = window:AddTab(T("Skins", "สกิน"), "star", T("Every weapon, knife and glove skin", "สกินปืน มีด และถุงมือทุกแบบ"))

    local main = tab:AddLeftGroupbox(T("Skin Changer", "เปลี่ยนสกิน"), "star")
    main:AddToggle("SkinChanger", { Text = T("Skin changer", "เปลี่ยนสกิน"), Description = T("Pick any skin per weapon, only you see it", "เลือกสกินรายอาวุธได้ทุกแบบ เห็นแค่ตัวเอง") })
    local filter = main:AddDropdown("SkinRarities", {
        Text = T("Show rarities", "แสดงเฉพาะ rarity"),
        Description = T("Empty shows everything", "ไม่เลือก = แสดงทั้งหมด"),
        Values = PatipanStudio.Skin.Rarities,
        Multi = true,
        Default = {},
        AllowNull = true,
    })
    PatipanStudio.UI.Bind(filter, "SkinRarities")
    filter:OnChanged(function()
        for _, refill in ipairs(PatipanStudio.UI.SkinRefill) do refill() end
    end)
    main:AddButton({ Text = T("Reset all skins", "คืนสกินเดิมทั้งหมด"), Style = "Warning", Func = function()
        PatipanStudio.Skin.ClearAll()
        for _, kind in ipairs(PatipanStudio.Skin.Types) do
            local picker = Library.Options["Skin" .. kind .. "Pick"]
            if picker then picker:SetValue(nil) end
        end
    end })

    local leftRows, rightRows = PatipanStudio.Config.SkinMainRows, 0
    for _, kind in ipairs(PatipanStudio.Skin.Types) do
        local left = leftRows < rightRows
        Util.Try("skins " .. kind, PatipanStudio.UI.BuildSkinGroup, tab, kind, left)
        if left then
            leftRows += PatipanStudio.Config.SkinGroupRows
        else
            rightRows += PatipanStudio.Config.SkinGroupRows
        end
    end
end

function PatipanStudio.UI.BuildVisuals(window)
    window:AddTabSection(T("Visuals", "การมองเห็น"))
    Util.Try("visuals tab", function()
        window:AddVisualsTab({ Provider = PatipanStudio.Esp.Targets, Preview = true })
    end)
    Util.Try("skins tab", PatipanStudio.UI.BuildSkins, window)
end

---@return table  rarities to sell: every known rarity not kept
function PatipanStudio.UI.SellSet(keep)
    local kept, sell = Util.SetFromList(keep), {}
    for _, rarity in ipairs(PatipanStudio.Sell.Rarities()) do
        if not kept[rarity] then sell[rarity] = true end
    end
    return sell
end

---@param sold table  rarity list an older save picked to sell
---@return string[]   the same choice as rarities to keep
function PatipanStudio.UI.KeepFromSold(sold)
    local selling, keep = Util.SetFromList(sold), {}
    for _, rarity in ipairs(PatipanStudio.Sell.Rarities()) do
        if not selling[rarity] then table.insert(keep, rarity) end
    end
    return keep
end

---@param keep table  KeepRarities dropdown; old saves that only have SellRarities load into it
function PatipanStudio.UI.AdoptOldSellSave(group, keep)
    local old = group:AddDropdown("SellRarities", {
        Text = T("Sell rarities", "rarity ที่จะขาย"),
        Values = PatipanStudio.Sell.Rarities(),
        Multi = true,
        Default = {},
        AllowNull = true,
    })
    old:SetVisible(false)
    old.Serialize = false
    old.Deserialize = function(_, saved)
        keep:SetValue(PatipanStudio.UI.KeepFromSold(saved))
    end
end

function PatipanStudio.UI.BuildEconomy(window)
    window:AddTabSection(T("Economy", "เศรษฐกิจ"))
    local tab = window:AddTab(T("Economy", "เศรษฐกิจ"), "coin", T("Cases, selling, quests", "เปิดกล่อง ขาย เควสต์"))

    local cases = tab:AddLeftGroupbox(T("Cases", "กล่องสุ่ม"), "qblock")
    cases:AddToggle("AutoOpenCases", { Text = T("Auto open owned cases", "เปิดกล่องที่มีอัตโนมัติ") })
    cases:AddSlider("OpenCount", { Text = T("Open per case", "เปิดต่อกล่อง"), Min = 1, Max = 10, Default = 1 })
    cases:AddButton({ Text = T("Open All Now", "เปิดทั้งหมดตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notice(T("Cases", "กล่องสุ่ม"), PatipanStudio.Shop.OpenAllNow(), "Coin")
    end) })

    local sell = tab:AddRightGroupbox(T("Sell", "ขาย"), "shop")
    local keep = sell:AddDropdown("KeepRarities", {
        Text = T("Never sell", "ไม่ขาย"),
        Description = T("Selected rarities are always kept", "rarity ที่เลือกจะเก็บไว้เสมอ"),
        Values = PatipanStudio.Sell.Rarities(),
        Multi = true,
        Default = {},
        AllowNull = true,
    })
    PatipanStudio.UI.Bind(keep, "SellRarities", PatipanStudio.UI.SellSet)
    PatipanStudio.UI.AdoptOldSellSave(sell, keep)
    sell:AddToggle("AutoSell", { Text = T("Auto sell", "ขายอัตโนมัติ") })
    sell:AddSlider("MaxSellPrice", { Text = T("Max price to sell", "ราคาสูงสุดที่ขาย"), Description = T("Keeps anything worth more (0 = no limit)", "ของแพงกว่านี้จะเก็บไว้ (0 = ไม่จำกัด)"), Min = 0, Max = 100000, Default = 500 })
    sell:AddSlider("KeepPerRarity", { Text = T("Keep per rarity", "เก็บต่อ rarity"), Min = 0, Max = 20, Default = 0 })
    sell:AddButton({ Text = T("Sell Now", "ขายตอนนี้"), Style = "Warning", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notice(T("Sell", "ขาย"), PatipanStudio.Sell.SellNow(), "Coin")
    end) })
    sell:AddButton({ Text = T("Refresh rarities", "รีเฟรช rarity"), Func = PatipanStudio.UI.Detach(function()
        keep:SetValues(PatipanStudio.Sell.Rarities())
        PatipanStudio.Options.SellRarities = PatipanStudio.UI.SellSet(keep.Value)
    end) })

    local quest = tab:AddLeftGroupbox(T("Quests", "เควสต์"), "key")
    quest:AddToggle("AutoClaimQuest", { Text = T("Auto claim quests", "รับรางวัลเควสต์อัตโนมัติ") })
    quest:AddButton({ Text = T("Claim Now", "รับตอนนี้"), Style = "Success", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Notice(T("Quests", "เควสต์"), PatipanStudio.Collect.ClaimNow(), "Success")
    end) })
end

---@param key string  entry in UI.Labels, only redrawn when the text changes
function PatipanStudio.UI.Show(key, text)
    local label = PatipanStudio.UI.Labels[key]
    text = tostring(text)
    if not label or PatipanStudio.UI.Shown[key] == text then return end
    PatipanStudio.UI.Shown[key] = text
    label:SetContent(text)
end

function PatipanStudio.UI.RefreshStatus()
    PatipanStudio.UI.Show("Skin", PatipanStudio.Skin.GetStatus())
    PatipanStudio.UI.Show("Esp", PatipanStudio.Esp.GetStatus())
    PatipanStudio.UI.Show("Combat", PatipanStudio.Combat.GetStatus())
    PatipanStudio.UI.Show("Economy", string.format("%s | %s | %s", PatipanStudio.Shop.GetStatus(), PatipanStudio.Sell.GetStatus(), PatipanStudio.Collect.GetStatus()))

    PatipanStudio.UI.Show("Targets", PatipanStudio.Esp.Count)
    PatipanStudio.UI.Show("Cases", PatipanStudio.UI.Stats.Cases)
    PatipanStudio.UI.Show("Quests", PatipanStudio.UI.Stats.Quests)
end

function PatipanStudio.UI.ShowHalted()
    local queue = PatipanStudio.State.Halted
    if #queue == 0 then return end
    local stopped = table.clone(queue)
    table.clear(queue)

    for _, halt in ipairs(stopped) do
        local name, reason, toggles = halt[1], halt[2], halt[3]
        for _, key in ipairs(toggles) do
            local toggle = Library.Options[key]
            if toggle and toggle.Value == true then
                Util.Try("halt " .. key, toggle.SetValue, toggle, false)
            end
        end
        Library:Notify("PatipanStudio", name .. " stopped: " .. reason, 6, "Error")
    end
end

function PatipanStudio.UI.ShowNotices()
    local queue = PatipanStudio.State.Notices
    if #queue == 0 then return end
    local pending = table.clone(queue)
    table.clear(queue)
    for _, notice in ipairs(pending) do
        Library:Notify(notice[1], notice[2], 4, notice[3])
    end
end

function PatipanStudio.UI.Pump()
    Util.Try("status", PatipanStudio.UI.RefreshStatus)
    Util.Try("halts", PatipanStudio.UI.ShowHalted)
    Util.Try("notices", PatipanStudio.UI.ShowNotices)
end

function PatipanStudio.UI.BlockMissing()
    local unsupported = T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
    local outdated = T("Changed by a game update, wait for a script update", "เกมอัปเดตแล้ว รอสคริปต์อัปเดต")
    for module, features in pairs(PatipanStudio.Config.ModuleFeatures) do
        local missing = GameLib.Missing[module]
        if not missing then continue end
        for _, idx in ipairs(features) do
            Library.Compat.Block(idx, missing == "Absent" and outdated or unsupported)
        end
    end

    if not PatipanStudio.Movement.FindDash() then
        warn("[SniperArena] module CombatHelper.Dash not found, Infinite dash is blocked")
        Library.Compat.Block("InfiniteDash", outdated)
    end
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    Util.Try("main tab", PatipanStudio.UI.BuildMain, window)
    Util.Try("combat tab", PatipanStudio.UI.BuildCombat, window)
    Util.Try("player tab", PatipanStudio.UI.BuildPlayer, window)
    Util.Try("visuals tabs", PatipanStudio.UI.BuildVisuals, window)
    Util.Try("economy tab", PatipanStudio.UI.BuildEconomy, window)
    Util.Try("settings tab", function()
        window:AddTabSection(T("Other", "อื่นๆ"))
        window:AddSettingsTab()
    end)

    for _, key in ipairs({ "AimFov", "AimBone", "AimPriority", "AimMaxDistance",
        "Aimbot", "AimSmooth", "AimPrediction", "ShowFov", "AimWallCheck", "AimTeamCheck",
        "SilentAim", "Ragebot", "InstantScope", "HitChance", "HeadChance", "TriggerBot", "NoRecoil", "NoSpread",
        "FastRespawn", "InfiniteDash", "SkinChanger", "OpenCount", "MaxSellPrice", "KeepPerRarity",
        "AutoOpenCases", "AutoSell", "AutoClaimQuest" }) do
        local widget = Library.Options[key]
        if widget then Util.Try("bind " .. key, PatipanStudio.UI.Bind, widget, key) end
    end
    Util.Try("missing modules", PatipanStudio.UI.BlockMissing)
    PatipanStudio:Connect(RunService.RenderStepped, PatipanStudio.Combat.DrawCircle)

    PatipanStudio.Scheduler.Every("Live stats", PatipanStudio.Config.EconomyInterval, PatipanStudio.UI.SampleStats)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.Pump)
end

---@return boolean  false when the menu could not be opened
local function BuildInterface()
    Library = Util.LoadLibrary(PatipanStudio.Config.UiSource)
    if not Library then return false end
    PatipanStudio.Library = Library
    pcall(PatipanStudio.Banner.Step, "UI library")
    T = function(en, th) return Library:T(en, th) end
    local opened, err = pcall(Library.CreateWindow, Library, {
        Title = "PatipanStudio",
        SubTitle = "Sniper Arena by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = PatipanStudio.Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        Intro = true,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            pcall(PatipanStudio.Banner.Step, "Interface")
            task.defer(Util.Try, "boot", PatipanStudio.Boot)
            task.defer(Util.Try, "autoload config", function() Library:LoadAutoloadConfig() end)
        end,
    })
    if not opened then
        Util.Alert("The menu failed to load on this executor: " .. tostring(err):match("^[^\n]*"), err)
        return false
    end
    Library:OnUnload(function()
        PatipanStudio:Unload()
    end)
    return true
end

function PatipanStudio.Boot()
    PatipanStudio:Connect(LocalPlayer.CharacterAdded, function(character)
        PatipanStudio.Player.Respawn.Reset()
        PatipanStudio.Player:Bind(character)
    end)

    Util.Try("movement", PatipanStudio.Movement.Start)

    PatipanStudio.Scheduler.Every("Combat", 0.03, PatipanStudio.Combat.Step, PatipanStudio.Config.CombatToggles, PatipanStudio.Combat.Rest)
    PatipanStudio.Scheduler.Every("ESP", PatipanStudio.Config.EspInterval, PatipanStudio.Esp.Step)
    PatipanStudio.Scheduler.Every("Fast Respawn", 0.1, PatipanStudio.Player.Respawn.Step, { "FastRespawn" })
    PatipanStudio.Scheduler.Every("Auto Join", 1, PatipanStudio.Player.Join.Step, { "AutoJoin" })
    PatipanStudio.Scheduler.Every("Skin Changer", 0.5, PatipanStudio.Skin.Step, { "SkinChanger" }, PatipanStudio.Skin.Restore)
    PatipanStudio.Scheduler.Every("Auto Open Cases", PatipanStudio.Config.EconomyInterval, PatipanStudio.Shop.Step, { "AutoOpenCases" })
    PatipanStudio.Scheduler.Every("Auto Sell", PatipanStudio.Config.EconomyInterval, PatipanStudio.Sell.Step, { "AutoSell" })
    PatipanStudio.Scheduler.Every("Auto Claim Quests", PatipanStudio.Config.EconomyInterval, PatipanStudio.Collect.Step, { "AutoClaimQuest" })
    Util.Try("scheduler", PatipanStudio.Scheduler.Boot)
    pcall(PatipanStudio.Banner.Step, "Combat + economy online")
    pcall(PatipanStudio.Banner.Ready)
end

function PatipanStudio:Unload()
    self.State.Alive = false
    for key, value in pairs(self.Options) do
        if value == true then self.Options[key] = false end
    end
    PatipanStudio.Combat.Unload()
    PatipanStudio.Skin.Restore()
    for _, connection in ipairs(self.State.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.State.Connections)

    local overlay = self.State.Overlay
    self.State.Overlay = nil
    if overlay then overlay:Destroy() end
    if environment.SniperArenaUnload == PatipanStudio.UnloadHook then environment.SniperArenaUnload = nil end
end

function PatipanStudio.UnloadHook()
    if PatipanStudio.Library and not PatipanStudio.Library.Unloaded then
        PatipanStudio.Library:Unload()
    else
        PatipanStudio:Unload()
    end
end

environment.SniperArenaUnload = PatipanStudio.UnloadHook

if LocalPlayer.Character then
    PatipanStudio.Player:Bind(LocalPlayer.Character)
end

pcall(PatipanStudio.Banner.Step, "Character bound")
BuildInterface()