if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 6739698191 then
    game:GetService("Players").LocalPlayer:Kick("PatipanStudio: this script is for Violence District only")
    return
end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local environment = getgenv and getgenv() or _G
if type(environment.ViolenceDistrictUnload) == "function" then
    pcall(environment.ViolenceDistrictUnload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local vector3New, cframeNew, cframeLookAt = Vector3.new, CFrame.new, CFrame.lookAt
local vectorZero = Vector3.zero
local osClock, mathHuge = os.clock, math.huge

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

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nBug fixes & better UI" },
    },
    SaveFolder = "Violence District",
    Intro = true,
    LoadTimeout = 10,
    AlertTries = 20,
    AlertRetry = 0.5,
    JobFailLimit = 5,
    JobFailWindow = 10,
    StatusInterval = 1,
    RepairTick = 0.25,
    GenDone = 100,
    SpareGens = 1,
    AttackReach = 2,
    LungeDelay = 0.21,
    AuraCooldown = 1.1,
    CarryDelay = 0.8,
    Settle = 0.55,
    FinishFirst = 85,
    ArriveRadius = 4,
    DriftLimit = 12,
    DangerKeep = 2,
    DangerPick = 2.5,
    DistanceWeight = 0.05,
    HealMax = 15,
    HealMinUseful = 3,
    HelpBan = 8,
    UnhookReach = 10,
    GuardTick = 0.05,
    FarmDodge = 24,
    SwingTail = 0.4,
    LegitReach = 9,
    ServerReach = 4.2,
    ParryRange = 14,
    ParryPanic = 6,
    ParryClosing = 12,
    ParryRetry = 1,
    ParryFast = 0.25,
    ParryScan = 5,
    LegitAngle = 0.5,
    HookRest = 1,
    UnhookHold = 2.5,
    StallTime = 8,
    StallBan = 30,
    HookTween = 0.2,
    GenBreakTime = 2,
    KickRegress = 25,
    SelfUnhookRetry = 1,
    SelfUnhookMax = 12,
    DodgeCooldown = 1.5,
    RolePending = 8,
    JumpVelocity = 50,
    AlertRadius = 60,
    ShopDelay = 0.6,
    FirstLevelCost = 750,
    EscapeRetry = 6,
    ShopInterval = 10,
    SurvivorSpeed = 21,
    KillerSpeed = 18.7,
    ObjectEspRefresh = 1,
    ModelRescan = 10,
}

PatipanStudio.State = {
    Alive = true,
    Connections = {},
}

PatipanStudio.Options = {
    AntiAfk = false,
    RoleMode = "Any",
    Speed = false,
    SpeedValue = 24,
    Noclip = false,
    NoSlow = false,
    NoFall = false,
    FreeTurn = false,
    AntiShake = false,
    AntiBlind = false,
    SmartHitbox = false,
    SlashMode = "Rage",
    InfiniteJump = false,
    Fullbright = false,
    NoFog = false,

    AutoRepair = false,
    PerfectSkillCheck = false,
    InstantEscape = false,
    EscapeDelay = 0,
    AutoHeal = false,
    AutoUnhook = false,
    AutoDodge = false,
    DodgeRadius = 20,
    AutoSelfUnhook = false,
    AutoParry = false,
    NoParryCooldown = false,
    KillerAlert = false,

    AutoBuyPerks = false,
    AutoLevelPerks = false,
    KeepScrews = 0,

    KillAura = false,
    AuraRange = 500,
    AutoHook = false,
    AutoBreakGens = false,
    AntiStun = false,

    EspGenerators = false,
    EspHooks = false,
    EspGates = false,
    EspPallets = false,
    EspWindows = false,
}

PatipanStudio.Util = {}
local Util = PatipanStudio.Util

---@return function?  first argument that is callable
local function Resolve(...)
    for index = 1, select("#", ...) do
        local candidate = select(index, ...)
        if type(candidate) == "function" then return candidate end
    end
    return nil
end

Util.Request = Resolve(request, http_request, type(syn) == "table" and syn.request, type(http) == "table" and http.request)
Util.SetClipboard = Resolve(setclipboard, toclipboard)
Util.GetHui = Resolve(gethui, get_hidden_gui)
Util.GetConnections = Resolve(getconnections, get_signal_cons)
Util.FireSignal = Resolve(firesignal)
Util.FireTouch = Resolve(firetouchinterest)
Util.GetGc = Resolve(getgc, get_gc_objects)
Util.NameCallMethod = Resolve(getnamecallmethod)
Util.HookMetamethod = Resolve(hookmetamethod)
Util.Closure = Resolve(newcclosure) or function(fn) return fn end

Util.RawCaps = {
    Connections = function() return Util.GetConnections ~= nil end,
    Signals = function() return Util.FireSignal ~= nil end,
    Gc = function() return Util.GetGc ~= nil end,
    Namecall = function() return Util.HookMetamethod ~= nil and Util.NameCallMethod ~= nil end,
}

---@param cap string|string[]  Library.Compat cap name(s), false until the menu has loaded
function Util.Can(cap)
    local library = PatipanStudio.Library
    if library == nil then return false end
    if library.Compat then return (library.Compat.Has(cap)) end
    for _, name in ipairs(type(cap) == "table" and cap or { cap }) do
        local probe = Util.RawCaps[name]
        if not (probe and probe()) then return false end
    end
    return true
end

---@return function?  original, nil when the executor refused the hook
---@return function?  restore
function Util.HookMeta(object, method, handler)
    local compat = PatipanStudio.Library and PatipanStudio.Library.Compat
    if compat then return compat.HookMeta(object, method, handler) end
    if not Util.HookMetamethod then return nil end

    local ok, original = pcall(Util.HookMetamethod, object, method, Util.Closure(handler))
    if not ok or type(original) ~= "function" then return nil end
    return original, function()
        Util.HookMetamethod(object, method, original)
    end
end

---@return string?  response body, nil when every transport failed
function Util.HttpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then return body end
    if not Util.Request then return nil end
    local sent, response = pcall(Util.Request, { Url = url, Method = "GET" })
    if sent and type(response) == "table" and tonumber(response.StatusCode) == 200 and type(response.Body) == "string" then
        return response.Body
    end
    return nil
end

---@param text string  shown as a Roblox notification, works before the menu exists
function Util.Alert(text)
    warn("[ViolenceDistrict] " .. text)
    task.spawn(function()
        local starterGui = game:GetService("StarterGui")
        for _ = 1, PatipanStudio.Config.AlertTries do
            if pcall(starterGui.SetCore, starterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 }) then return end
            task.wait(PatipanStudio.Config.AlertRetry)
        end
    end)
end

---@return table?  UI library, nil after telling the player why
function Util.LoadLibrary()
    local source = Util.HttpGet(PatipanStudio.Config.UiSource)
    if not source or not source:sub(-64):find("return Library%s*$") then
        Util.Alert("Could not download the menu. Check your connection and run it again.")
        return nil
    end
    local chunk, err = loadstring(source)
    if not chunk then
        Util.Alert("The menu failed to load on this executor: " .. tostring(err))
        return nil
    end
    local ok, library = pcall(chunk)
    if not ok or type(library) ~= "table" then
        Util.Alert("The menu failed to load on this executor: " .. tostring(library))
        return nil
    end
    return library
end

function Util.Copy(text)
    if not Util.SetClipboard then return false end
    Util.SetClipboard(text)
    return true
end

---@return boolean, any  pcall result, warns with the label when it fails
function Util.Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[ViolenceDistrict] " .. label .. ": " .. tostring(err)) end
    return ok, err
end

---@param instance Instance  parented to gethui, then CoreGui, then PlayerGui
function Util.Mount(instance)
    local ok, hui = pcall(Util.GetHui or error)
    if ok and typeof(hui) == "Instance" and pcall(function() instance.Parent = hui end) then return end
    if pcall(function() instance.Parent = game:GetService("CoreGui") end) then return end
    instance.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", PatipanStudio.Config.LoadTimeout)
end

function PatipanStudio:Connect(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(self.State.Connections, connection)
    return connection
end

PatipanStudio.GameLib = {}
local GameLib = PatipanStudio.GameLib

GameLib.Folder = ReplicatedStorage:WaitForChild("Remotes", PatipanStudio.Config.LoadTimeout)

---@return Instance?  remote at the path under Remotes, else the only remote with that name anywhere under it
function GameLib.FindRemote(...)
    local root = GameLib.Folder
    if not root then return nil end
    local node = root
    for _, step in ipairs({ ... }) do
        node = node and node:FindFirstChild(step)
    end
    if node then return node end

    local name, found = select(select("#", ...), ...), nil
    for _, desc in ipairs(root:GetDescendants()) do
        if desc.Name ~= name or not (desc:IsA("BaseRemoteEvent") or desc:IsA("RemoteFunction")) then continue end
        if found then return nil end
        found = desc
    end
    return found
end

GameLib.RemotePaths = {
    Repair = { "Generator", "RepairEvent" },
    GenCheck = { "Generator", "SkillCheckEvent" },
    GenResult = { "Generator", "SkillCheckResultEvent" },
    Heal = { "Healing", "HealEvent" },
    HealCheck = { "Healing", "SkillCheckEvent" },
    HealResult = { "Healing", "SkillCheckResultEvent" },
    Unhook = { "Carry", "UnHookEvent" },
    SelfUnhook = { "Carry", "SelfUnHookEvent" },
    Fall = { "Mechanics", "Fall" },
    Carry = { "Carry", "CarrySurvivorEvent" },
    Hook = { "Carry", "HookEvent" },
    HookCommit = { "Carry", "HookCommit" },
    BreakGen = { "Generator", "BreakGenEvent" },
    BreakGenCommit = { "Generator", "BreakGenCommit" },
    Lunge = { "Attacks", "Lunge" },
    Stun = { "Pallet", "Jason", "Stun" },
    StunOver = { "Pallet", "Jason", "Stunover" },
    Attack = { "Attacks", "BasicAttack" },
    BuyPerk = { "Shop", "PurchasePerk" },
    LevelPerk = { "Shop", "LevelUpPerk" },
    PerkInfo = { "Shop", "GetPerkInfo" },
}

GameLib.Remote = {}
for key, path in pairs(GameLib.RemotePaths) do
    GameLib.Remote[key] = GameLib.FindRemote(table.unpack(path))
end

GameLib.Needs = {
    AutoRepair = { "Repair" },
    PerfectSkillCheck = { "GenCheck", "HealCheck", "GenResult", "HealResult" },
    AutoHeal = { "Heal" },
    AutoUnhook = { "Unhook" },
    AutoSelfUnhook = { "SelfUnhook" },
    NoFall = { "Fall" },
    KillAura = { "Lunge", "Attack" },
    AutoHook = { "Carry", "Hook", "HookCommit" },
    AutoBreakGens = { "BreakGen", "BreakGenCommit" },
    AntiStun = { "Stun", "StunOver" },
    AutoBuyPerks = { "BuyPerk", "PerkInfo" },
    AutoLevelPerks = { "LevelPerk", "PerkInfo" },
}

---@return string?  "Folder/Name" of the first remote the toggle needs that is gone
function GameLib.Missing(idx)
    for _, key in ipairs(GameLib.Needs[idx] or {}) do
        if not GameLib.Remote[key] then return table.concat(GameLib.RemotePaths[key], "/") end
    end
    return nil
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

---@return string?  "Survivors" / "Killer" / "Spectator"
function PatipanStudio.Player.Role(player)
    local team = (player or LocalPlayer).Team
    return team and team.Name or nil
end

---@return boolean  downed, hooked or carried
function PatipanStudio.Player.Disabled(character)
    if not character then return true end
    return character:GetAttribute("Knocked") == true
        or character:GetAttribute("IsHooked") == true
        or character:GetAttribute("IsCarried") == true
end

function PatipanStudio.Player.Killer()
    local team = Teams:FindFirstChild("Killer")
    local killer = team and team:GetPlayers()[1]
    return killer and killer.Character
end

function PatipanStudio.Player.Survivors()
    local team = Teams:FindFirstChild("Survivors")
    local list = {}
    if not team then return list end
    for _, player in ipairs(team:GetPlayers()) do
        local char = player.Character
        if player ~= LocalPlayer and char and char:FindFirstChild("HumanoidRootPart") then
            list[#list + 1] = char
        end
    end
    return list
end

function PatipanStudio.Player.Teleport(cframe)
    local hrp = PatipanStudio.Player.Root
    if not hrp then return end
    hrp.CFrame = cframe
    hrp.AssemblyLinearVelocity = vectorZero
end

PatipanStudio.Map = {}

function PatipanStudio.Map.Root()
    return Workspace:FindFirstChild("Map")
end

function PatipanStudio.Map.Tagged(tag)
    local map = PatipanStudio.Map.Root()
    local list = {}
    if not map then return list end
    for _, part in ipairs(CollectionService:GetTagged(tag)) do
        if part:IsA("BasePart") and part:IsDescendantOf(map) then
            list[#list + 1] = part
        end
    end
    return list
end

PatipanStudio.Map.Cache = { Map = nil, Models = {}, Scanned = {}, Total = 0 }

---@return Model[]  every model with this name in the current map, cached per round
function PatipanStudio.Map.Models(name)
    local map = PatipanStudio.Map.Root()
    local cache = PatipanStudio.Map.Cache
    if not map then return {} end
    if cache.Map ~= map then
        cache.Map, cache.Models, cache.Scanned = map, {}, {}
    end
    local list = cache.Models[name]
    local fresh = osClock() - (cache.Scanned[name] or 0) < PatipanStudio.Config.ModelRescan
    if list and fresh and (not list[1] or list[1]:IsDescendantOf(map)) then return list end
    cache.Scanned[name] = osClock()
    list = {}
    for _, inst in ipairs(map:GetDescendants()) do
        if inst.Name == name and inst:IsA("Model") then list[#list + 1] = inst end
    end
    cache.Models[name] = list
    return list
end

---@return Model[]  every generator on the map, finished ones included
function PatipanStudio.Map.Generators()
    return PatipanStudio.Map.Models("Generator")
end

---@return BasePart[]  GeneratorPoint parts of one generator, cached per round
function PatipanStudio.Map.PointsOf(gen)
    local cache = PatipanStudio.Map.Cache
    cache.Points = cache.Points or setmetatable({}, { __mode = "k" })
    local list = cache.Points[gen]
    if list and list[1] and list[1].Parent then return list end
    list = {}
    for _, point in ipairs(PatipanStudio.Map.Tagged("GeneratorPoint")) do
        if point:IsDescendantOf(gen) then list[#list + 1] = point end
    end
    cache.Points[gen] = list
    return list
end

function PatipanStudio.Map.GenProgress(model)
    return tonumber(model:GetAttribute("RepairProgress")) or 0
end

---@return number  gens still needed before the exits power (one gen is spare)
function PatipanStudio.Map.GensLeft()
    local gens = PatipanStudio.Map.Generators()
    local cache = PatipanStudio.Map.Cache
    local map = PatipanStudio.Map.Root()
    if cache.TotalMap ~= map then cache.TotalMap, cache.Total = map, 0 end
    cache.Total = math.max(cache.Total, #gens)
    local done = 0
    for _, gen in ipairs(gens) do
        if PatipanStudio.Map.GenProgress(gen) >= PatipanStudio.Config.GenDone then done += 1 end
    end
    return math.max(cache.Total - PatipanStudio.Config.SpareGens - done, 0)
end

---@return BasePart?, number  closest part to pos
function PatipanStudio.Map.Nearest(parts, pos, filter)
    local best, bestDist = nil, mathHuge
    for _, part in ipairs(parts) do
        if filter and not filter(part) then continue end
        local dist = (part.Position - pos).Magnitude
        if dist < bestDist then best, bestDist = part, dist end
    end
    return best, bestDist
end

PatipanStudio.Scheduler = { Jobs = {}, Halts = {}, Booted = false }

---@param toggles string[]?  switched off when the job keeps failing
---@param extra table?       { Core = keeps running whatever fails, Restore = run once when it halts }
function PatipanStudio.Scheduler.Every(name, interval, fn, toggles, extra)
    extra = extra or {}
    PatipanStudio.Scheduler.Jobs[name] = {
        Interval = interval, Fn = fn, Last = 0, Running = false, Toggles = toggles or {},
        Core = extra.Core or toggles == nil, Restore = extra.Restore,
    }
end

---Turns the job's options off for the logic right away; the menu toggles follow on the next UI pump.
---@return string[]  idx of every toggle that was on
function PatipanStudio.Scheduler.SwitchOff(job)
    local switched = {}
    for _, idx in ipairs(job.Toggles) do
        if PatipanStudio.Options[idx] then
            PatipanStudio.Options[idx] = false
            switched[#switched + 1] = idx
        end
    end
    return switched
end

---Warns once per failure streak. Config.JobFailLimit errors spanning Config.JobFailWindow seconds switch the job's toggles off and run its restore; a non-core job with nothing to switch off rests until one turns back on.
function PatipanStudio.Scheduler.Fail(name, job, err)
    local streak = job.Streak
    if not streak then
        streak = { count = 0, since = osClock() }
        job.Streak = streak
        warn("[ViolenceDistrict] job " .. name .. ":", err)
    end
    streak.count += 1
    if streak.count < PatipanStudio.Config.JobFailLimit or osClock() - streak.since < PatipanStudio.Config.JobFailWindow then return end

    local switched = PatipanStudio.Scheduler.SwitchOff(job)
    if job.Core and #switched == 0 then return end
    job.Streak = nil
    job.Stopped = not job.Core and #switched == 0
    if job.Restore then Util.Try("restore " .. name, job.Restore) end

    local reason = tostring(err):match("^[^\n]*")
    warn("[ViolenceDistrict] job " .. name .. " stopped: " .. reason)
    if #switched > 0 then
        table.insert(PatipanStudio.Scheduler.Halts, { Toggles = switched, Message = name .. " stopped: " .. reason })
    end
end

---@return boolean  a resting job may run again
function PatipanStudio.Scheduler.Wakes(job)
    for _, idx in ipairs(job.Toggles) do
        if PatipanStudio.Options[idx] then
            job.Stopped = nil
            return true
        end
    end
    return false
end

function PatipanStudio.Scheduler.Step()
    local now = osClock()
    for name, job in pairs(PatipanStudio.Scheduler.Jobs) do
        if job.Running or now - job.Last < job.Interval then continue end
        if job.Stopped and not PatipanStudio.Scheduler.Wakes(job) then continue end
        job.Last = now
        job.Running = true
        task.spawn(function()
            local ok, err = pcall(job.Fn)
            job.Running = false
            if ok then
                job.Streak = nil
            else
                PatipanStudio.Scheduler.Fail(name, job, err)
            end
        end)
    end
end

function PatipanStudio.Scheduler.Boot()
    if PatipanStudio.Scheduler.Booted then return end
    PatipanStudio.Scheduler.Booted = true
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Scheduler.Step)
end

PatipanStudio.Player.AntiAfk = { Connection = nil }

function PatipanStudio.Player.AntiAfk.OnIdled()
    if not PatipanStudio.Options.AntiAfk then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end

function PatipanStudio.Player.AntiAfk.Arm()
    if PatipanStudio.Player.AntiAfk.Connection then return end
    PatipanStudio.Player.AntiAfk.Connection = PatipanStudio:Connect(LocalPlayer.Idled, PatipanStudio.Player.AntiAfk.OnIdled)
end

PatipanStudio.Role = { Pending = 0 }

function PatipanStudio.Role.Step()
    local mode = PatipanStudio.Options.RoleMode
    if mode ~= "Survivor only" and mode ~= "Prefer killer" then return end
    if LocalPlayer:GetAttribute("AllowKiller") == (mode == "Prefer killer") or osClock() < PatipanStudio.Role.Pending then return end
    local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings", true)
    local button = settings and settings:FindFirstChild("chance", true)
    button = button and button:FindFirstChildWhichIsA("GuiButton")
    if not button or not PatipanStudio.Role.Supported() then return end
    PatipanStudio.Role.Pending = osClock() + PatipanStudio.Config.RolePending
    if not Util.Can("Connections") then
        Util.FireSignal(button.MouseButton1Click)
        return
    end
    for _, conn in ipairs(Util.GetConnections(button.MouseButton1Click)) do
        conn:Fire()
    end
end

---@return boolean  the executor can press the game's killer-chance button
function PatipanStudio.Role.Supported()
    return Util.Can("Connections") or Util.Can("Signals")
end

PatipanStudio.Movement = { Collide = {}, JumpConn = nil, Walk = nil, Lifted = nil, LiftedTo = nil }

function PatipanStudio.Movement.Frame()
    local hum, char = PatipanStudio.Player.Humanoid, PatipanStudio.Player.Character
    if not hum or not char then return end

    if PatipanStudio.Options.Speed then
        if not PatipanStudio.Movement.Walk then
            PatipanStudio.Movement.Walk = PatipanStudio.Movement.Lifted or hum.WalkSpeed
            PatipanStudio.Movement.Lifted, PatipanStudio.Movement.LiftedTo = nil, nil
        end
        hum.WalkSpeed = PatipanStudio.Options.SpeedValue
    elseif PatipanStudio.Movement.Walk then
        hum.WalkSpeed = PatipanStudio.Movement.Walk
        PatipanStudio.Movement.Walk = nil
    end
    if PatipanStudio.Options.NoSlow and not PatipanStudio.Options.Speed and hum.WalkSpeed > 0 then
        local base = PatipanStudio.Movement.BaseSpeed(char)
        if hum.WalkSpeed < base then
            PatipanStudio.Movement.Lifted = hum.WalkSpeed
            PatipanStudio.Movement.LiftedTo = base
            hum.WalkSpeed = base
        end
    elseif PatipanStudio.Movement.Lifted then
        PatipanStudio.Movement.DropLift(hum, char)
    end

    if PatipanStudio.Options.FreeTurn and not hum.AutoRotate and not char:GetAttribute("overridelookscript") and not char:GetAttribute("Immobile") then
        local root = PatipanStudio.Player.Root
        local look = Workspace.CurrentCamera.CFrame.LookVector
        local flat = vector3New(look.X, 0, look.Z)
        if root and flat.Magnitude > 0 then root.CFrame = cframeLookAt(root.Position, root.Position + flat) end
    end

    if PatipanStudio.Options.Noclip then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                PatipanStudio.Movement.Collide[part] = true
                part.CanCollide = false
            end
        end
    elseif next(PatipanStudio.Movement.Collide) then
        PatipanStudio.Movement.RestoreCollide()
    end
end

---@return number  normal run speed for the current role
function PatipanStudio.Movement.BaseSpeed(char)
    if PatipanStudio.Player.Role() == "Killer" then
        return tonumber(char:GetAttribute("Speed")) or PatipanStudio.Config.KillerSpeed
    end
    return PatipanStudio.Config.SurvivorSpeed
end

---skipped when the game has since changed the speed itself
---@param hum  Humanoid
---@param char Model
function PatipanStudio.Movement.DropLift(hum, char)
    local before, wrote = PatipanStudio.Movement.Lifted, PatipanStudio.Movement.LiftedTo
    PatipanStudio.Movement.Lifted, PatipanStudio.Movement.LiftedTo = nil, nil
    if char:GetAttribute("Sprinting") or hum.WalkSpeed ~= wrote then return end
    hum.WalkSpeed = before
end

function PatipanStudio.Movement.RestoreCollide()
    for part in pairs(PatipanStudio.Movement.Collide) do
        if part.Parent then part.CanCollide = true end
    end
    table.clear(PatipanStudio.Movement.Collide)
end

function PatipanStudio.Movement.OnJump()
    if not PatipanStudio.Options.InfiniteJump then return end
    local hrp = PatipanStudio.Player.Root
    if not hrp then return end
    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = vector3New(vel.X, PatipanStudio.Config.JumpVelocity, vel.Z)
end

function PatipanStudio.Movement.Start()
    PatipanStudio:Connect(RunService.Stepped, PatipanStudio.Movement.Frame)
    PatipanStudio:Connect(UserInputService.JumpRequest, PatipanStudio.Movement.OnJump)
end

function PatipanStudio.Movement.Release()
    PatipanStudio.Movement.RestoreCollide()
    local hum = PatipanStudio.Player.Humanoid
    local char = PatipanStudio.Player.Character
    if hum and hum.Parent and char and PatipanStudio.Movement.Lifted then PatipanStudio.Movement.DropLift(hum, char) end
    if hum and hum.Parent and PatipanStudio.Movement.Walk then hum.WalkSpeed = PatipanStudio.Movement.Walk end
    PatipanStudio.Movement.Walk = nil
    PatipanStudio.Movement.Lifted, PatipanStudio.Movement.LiftedTo = nil, nil
end

PatipanStudio.World = { Saved = nil }

function PatipanStudio.World.Save()
    if PatipanStudio.World.Saved then return end
    PatipanStudio.World.Saved = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Atmosphere = {},
    }
    for _, atmo in ipairs(Lighting:GetChildren()) do
        if atmo:IsA("Atmosphere") then PatipanStudio.World.Saved.Atmosphere[atmo] = atmo.Density end
    end
end

function PatipanStudio.World.Step()
    local bright, fog = PatipanStudio.Options.Fullbright, PatipanStudio.Options.NoFog
    if not bright and not fog then
        PatipanStudio.World.Restore()
        return
    end
    PatipanStudio.World.Save()
    local saved = PatipanStudio.World.Saved

    if bright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness, Lighting.ClockTime = saved.Brightness, saved.ClockTime
        Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient = saved.GlobalShadows, saved.Ambient, saved.OutdoorAmbient
    end

    Lighting.FogEnd = fog and 1e6 or saved.FogEnd
    Lighting.FogStart = fog and 1e6 or saved.FogStart
    for atmo, density in pairs(saved.Atmosphere) do
        if atmo.Parent then atmo.Density = fog and 0 or density end
    end
end

function PatipanStudio.World.Restore()
    local saved = PatipanStudio.World.Saved
    if not saved then return end
    PatipanStudio.World.Saved = nil
    Lighting.Brightness, Lighting.ClockTime = saved.Brightness, saved.ClockTime
    Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient = saved.GlobalShadows, saved.Ambient, saved.OutdoorAmbient
    Lighting.FogEnd, Lighting.FogStart = saved.FogEnd, saved.FogStart
    for atmo, density in pairs(saved.Atmosphere) do
        if atmo.Parent then atmo.Density = density end
    end
end

PatipanStudio.Block = { Muted = {}, Own = {}, Restore = nil }

---@return RBXScriptSignal?  game signal a rule silences
local function RemoteSignal(folder, ...)
    local node = ReplicatedStorage:FindFirstChild("Remotes")
    for _, name in ipairs({ folder, ... }) do
        node = node and node:FindFirstChild(name)
    end
    if not node then return nil end
    return node:IsA("BindableEvent") and node.Event or node.OnClientEvent
end

PatipanStudio.Block.Rules = {
    { Option = "PerfectSkillCheck", Signals = { RemoteSignal("Generator", "SkillCheckEvent"), RemoteSignal("Healing", "SkillCheckEvent") } },
    { Option = "AntiStun", Signals = { RemoteSignal("Pallet", "Jason", "Stun") } },
    { Option = "AntiBlind", Signals = { RemoteSignal("Items", "Flashlight", "GotBlinded") } },
    { Option = "AntiShake", Signals = { RemoteSignal("Game", "shake") } },
}

function PatipanStudio.Block.Keep(fn)
    PatipanStudio.Block.Own[fn] = true
end

function PatipanStudio.Block.Mute(rule)
    local muted = PatipanStudio.Block.Muted[rule] or {}
    PatipanStudio.Block.Muted[rule] = muted
    for _, signal in ipairs(rule.Signals) do
        for _, conn in ipairs(Util.GetConnections(signal)) do
            if conn.Enabled and not PatipanStudio.Block.Own[conn.Function] then
                pcall(function() conn:Disable() end)
                muted[#muted + 1] = conn
            end
        end
    end
end

function PatipanStudio.Block.Unmute(rule)
    local muted = PatipanStudio.Block.Muted[rule]
    if not muted then return end
    for _, conn in ipairs(muted) do pcall(function() conn:Enable() end) end
    PatipanStudio.Block.Muted[rule] = nil
end

function PatipanStudio.Block.Step()
    PatipanStudio.Block.SyncFall()
    if not Util.Can("Connections") then return end
    for _, rule in ipairs(PatipanStudio.Block.Rules) do
        if PatipanStudio.Options[rule.Option] then PatipanStudio.Block.Mute(rule) else PatipanStudio.Block.Unmute(rule) end
    end
end

function PatipanStudio.Block.Release()
    PatipanStudio.Block.SyncFall()
    for _, rule in ipairs(PatipanStudio.Block.Rules) do PatipanStudio.Block.Unmute(rule) end
end

---Fall hook lives only while No Fall is on; the original namecall goes back when it turns off or on unload.
function PatipanStudio.Block.SyncFall()
    local wanted = PatipanStudio.Options.NoFall and PatipanStudio.State.Alive
    if wanted and not PatipanStudio.Block.Restore then
        PatipanStudio.Block.HookFall()
    elseif not wanted and PatipanStudio.Block.Restore then
        local restore = PatipanStudio.Block.Restore
        PatipanStudio.Block.Restore = nil
        pcall(restore)
    end
end

function PatipanStudio.Block.HookFall()
    local fall = GameLib.Remote.Fall
    if not (fall and Util.Can("Namecall")) then return end
    local original, restore
    original, restore = Util.HookMeta(game, "__namecall", function(self, ...)
        if self == fall and PatipanStudio.Options.NoFall and PatipanStudio.State.Alive and Util.NameCallMethod() == "FireServer" then return nil end
        return original(self, ...)
    end)
    PatipanStudio.Block.Restore = restore
end

PatipanStudio.Survivor = {
    Job = nil,
    Gen = nil,
    Banned = {},
    Map = nil,
    Status = "Off",
    RoundStart = 0,
    Escapes = 0,
    LastEscape = 0,
}

PatipanStudio.Survivor.Rank = { Unhook = 3, Heal = 2, Repair = 1 }

---@param kind string    Repair / Heal / Unhook
---@param target Instance  point or teammate root the remote takes
function PatipanStudio.Survivor.NewJob(kind, target, remote)
    return { Kind = kind, Target = target, Remote = remote, Since = osClock(), Fired = false, Progress = 0, Checked = osClock() }
end

function PatipanStudio.Survivor.Finish()
    local job = PatipanStudio.Survivor.Job
    PatipanStudio.Survivor.Job = nil
    if not (job and job.Fired) or job.Kind == "Unhook" or not job.Target.Parent then return end
    pcall(function() job.Remote:FireServer(job.Target, false) end)
end

---@param locked boolean  action already started, only re-warp if we drifted far
function PatipanStudio.Survivor.Hold(target, locked)
    local hrp = PatipanStudio.Player.Root
    if not hrp then return end
    local teammate = target.Name == "HumanoidRootPart"
    local spot = teammate and (target.CFrame * cframeNew(0, 0, 2.5)).Position or target.Position
    local flat = vector3New(hrp.Position.X - spot.X, 0, hrp.Position.Z - spot.Z).Magnitude
    if flat <= (locked and PatipanStudio.Config.DriftLimit or PatipanStudio.Config.ArriveRadius) then return end
    local look = teammate and target.Position or spot + target.CFrame.LookVector
    PatipanStudio.Player.Teleport(cframeLookAt(spot, look))
end

---@param scale number?  radius multiplier, larger when picking new work
---@return boolean        too close to the killer while Auto Dodge is on
function PatipanStudio.Survivor.Danger(pos, scale)
    local opts = PatipanStudio.Options
    if not opts.AutoDodge then return false end
    local killer = PatipanStudio.Player.Killer()
    local root = killer and killer:FindFirstChild("HumanoidRootPart")
    return root ~= nil and (root.Position - pos).Magnitude <= opts.DodgeRadius * (scale or PatipanStudio.Config.DangerKeep)
end

function PatipanStudio.Survivor.GenUsable(gen)
    if not gen or not gen.Parent then return false end
    if PatipanStudio.Map.GenProgress(gen) >= PatipanStudio.Config.GenDone then return false end
    return osClock() >= (PatipanStudio.Survivor.Banned[gen] or 0)
end

---@return BasePart?  a free, safe point on this generator
function PatipanStudio.Survivor.PointOn(gen)
    local job = PatipanStudio.Survivor.Job
    for _, point in ipairs(PatipanStudio.Map.PointsOf(gen)) do
        local mine = job and job.Target == point
        if not mine and CollectionService:HasTag(point, "doing action") then continue end
        if PatipanStudio.Survivor.Danger(point.Position, PatipanStudio.Config.DangerPick) then continue end
        return point
    end
    return nil
end

---@param peek boolean?  don't change the committed generator
---@return BasePart?      keeps the committed generator until it is done or unsafe
function PatipanStudio.Survivor.PickGenPoint(pos, peek)
    local gen = PatipanStudio.Survivor.Gen
    local point = PatipanStudio.Survivor.GenUsable(gen) and PatipanStudio.Survivor.PointOn(gen)
    if point then return point end

    local best, bestScore = nil, mathHuge
    for _, candidate in ipairs(PatipanStudio.Map.Generators()) do
        if not PatipanStudio.Survivor.GenUsable(candidate) then continue end
        local spot = PatipanStudio.Survivor.PointOn(candidate)
        if not spot then continue end
        local score = (PatipanStudio.Config.GenDone - PatipanStudio.Map.GenProgress(candidate)) + (spot.Position - pos).Magnitude * PatipanStudio.Config.DistanceWeight
        if score < bestScore then best, bestScore = spot, score end
    end
    if not peek then PatipanStudio.Survivor.Gen = best and best:FindFirstAncestor("Generator") end
    return best
end

---@param downedOnly boolean  only teammates who are on the floor
---@return BasePart?            closest teammate worth healing, downed first
function PatipanStudio.Survivor.HealTarget(downedOnly)
    local me = PatipanStudio.Player.Root
    local best, bestScore = nil, mathHuge
    for _, char in ipairs(PatipanStudio.Player.Survivors()) do
        local hrp = char.HumanoidRootPart
        if hrp:GetAttribute("CanGetHealed") ~= true or char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then continue end
        if char:GetAttribute("IsBeingHealed") or osClock() < (PatipanStudio.Survivor.Banned[char] or 0) then continue end
        local downed = char:GetAttribute("Knocked") == true
        if downedOnly and not downed then continue end
        if PatipanStudio.Survivor.Danger(hrp.Position, PatipanStudio.Config.DangerPick) then continue end
        local score = (downed and 0 or 1000) + (me and (hrp.Position - me.Position).Magnitude or 0)
        if score < bestScore then best, bestScore = hrp, score end
    end
    return best
end

function PatipanStudio.Survivor.UnhookTarget()
    local points = PatipanStudio.Map.Tagged("UnhookPoint")
    for _, char in ipairs(PatipanStudio.Player.Survivors()) do
        if char:GetAttribute("IsHooked") ~= true or osClock() < (PatipanStudio.Survivor.Banned[char] or 0) then continue end
        local point, dist = PatipanStudio.Map.Nearest(points, char.HumanoidRootPart.Position)
        if point and dist < PatipanStudio.Config.UnhookReach and not PatipanStudio.Survivor.Danger(point.Position, PatipanStudio.Config.DangerPick) then
            return point, char
        end
    end
    return nil
end

---@return boolean  current job still has something to do
function PatipanStudio.Survivor.JobAlive(job)
    local target = job.Target
    if not target.Parent or PatipanStudio.Survivor.Danger(target.Position) then return false end
    local age = osClock() - job.Since
    if job.Kind == "Heal" then
        local ok = age <= PatipanStudio.Config.HealMax and target:GetAttribute("CanGetHealed") == true
        if not ok and age < PatipanStudio.Config.HealMinUseful then
            PatipanStudio.Survivor.Banned[target.Parent] = osClock() + PatipanStudio.Config.HelpBan
        end
        return ok
    end
    if job.Kind == "Unhook" then
        if age < PatipanStudio.Config.UnhookHold then return true end
        if job.Char then PatipanStudio.Survivor.Banned[job.Char] = osClock() + PatipanStudio.Config.HelpBan end
        return false
    end
    return PatipanStudio.Survivor.GenUsable(target:FindFirstAncestor("Generator")) and PatipanStudio.Map.GensLeft() > 0
end

---@return table?  best new job, only if it should replace the current one
function PatipanStudio.Survivor.Candidate(pos)
    local opts, remote = PatipanStudio.Options, GameLib.Remote
    local job = PatipanStudio.Survivor.Job
    local rank = job and PatipanStudio.Survivor.Rank[job.Kind] or 0
    local finishing = job and job.Kind == "Repair"
        and PatipanStudio.Map.GenProgress(job.Target:FindFirstAncestor("Generator")) >= PatipanStudio.Config.FinishFirst

    if opts.AutoUnhook and rank < 3 and not finishing then
        local point, char = PatipanStudio.Survivor.UnhookTarget()
        if point then
            local unhook = PatipanStudio.Survivor.NewJob("Unhook", point, remote.Unhook)
            unhook.Char = char
            return unhook
        end
    end
    if opts.AutoHeal and rank < 2 and not finishing then
        local hrp = PatipanStudio.Survivor.HealTarget(true)
        if hrp then return PatipanStudio.Survivor.NewJob("Heal", hrp, remote.Heal) end
    end
    if job then return nil end
    if opts.AutoRepair and PatipanStudio.Map.GensLeft() > 0 then
        local point = PatipanStudio.Survivor.PickGenPoint(pos)
        if point then return PatipanStudio.Survivor.NewJob("Repair", point, remote.Repair) end
    end
    if opts.AutoHeal then
        local hrp = PatipanStudio.Survivor.HealTarget(false)
        if hrp then return PatipanStudio.Survivor.NewJob("Heal", hrp, remote.Heal) end
    end
    return nil
end

function PatipanStudio.Survivor.Watchdog(job)
    if job.Kind ~= "Repair" or osClock() - job.Checked < PatipanStudio.Config.StallTime then return end
    local gen = job.Target:FindFirstAncestor("Generator")
    local progress = PatipanStudio.Map.GenProgress(gen)
    job.Checked = osClock()
    if progress > job.Progress then
        job.Progress = progress
        return
    end
    PatipanStudio.Survivor.Banned[gen] = osClock() + PatipanStudio.Config.StallBan
    PatipanStudio.Survivor.Gen = nil
    PatipanStudio.Survivor.Finish()
end

function PatipanStudio.Survivor.Run(job)
    PatipanStudio.Survivor.Hold(job.Target, job.Fired and job.Kind ~= "Heal")
    if not job.Fired and osClock() - job.Since >= PatipanStudio.Config.Settle then
        job.Fired = true
        job.Progress = job.Kind == "Repair" and PatipanStudio.Map.GenProgress(job.Target:FindFirstAncestor("Generator")) or 0
        job.Checked = osClock()
        if job.Kind == "Unhook" then job.Remote:FireServer(job.Target) else job.Remote:FireServer(job.Target, true) end
    end
    if job.Fired then PatipanStudio.Survivor.Watchdog(job) end
    PatipanStudio.Survivor.Status = (job.Fired and job.Kind or "Moving to " .. job.Kind) .. " · gens left " .. PatipanStudio.Map.GensLeft()
end

---@return BasePart?  walk-through floor of the finish line
function PatipanStudio.Survivor.FinishLine()
    local hrp = PatipanStudio.Player.Root
    if not hrp then return nil end
    return PatipanStudio.Map.Nearest(PatipanStudio.Map.Tagged("EscapePart"), hrp.Position, function(part)
        return not part.CanCollide
    end)
end

function PatipanStudio.Survivor.EscapeNow()
    local line = PatipanStudio.Survivor.FinishLine()
    if not line then return false end
    PatipanStudio.Survivor.Finish()
    PatipanStudio.Player.Teleport(line.CFrame + vector3New(0, 3, 0))
    local hrp = PatipanStudio.Player.Root
    if Util.FireTouch and hrp then
        Util.FireTouch(hrp, line, 0)
        Util.FireTouch(hrp, line, 1)
    end
    return true
end

function PatipanStudio.Survivor.Enabled()
    local opts = PatipanStudio.Options
    return opts.AutoRepair or opts.AutoHeal or opts.AutoUnhook or opts.InstantEscape
end

---@return boolean  escaped this tick
function PatipanStudio.Survivor.TryEscape()
    local opts = PatipanStudio.Options
    local ready = opts.InstantEscape and (osClock() - PatipanStudio.Survivor.RoundStart >= opts.EscapeDelay or PatipanStudio.Map.GensLeft() == 0)
    if not ready then return false end
    if osClock() - PatipanStudio.Survivor.LastEscape < PatipanStudio.Config.EscapeRetry then return true end
    if not PatipanStudio.Survivor.EscapeNow() then return false end
    PatipanStudio.Survivor.LastEscape = osClock()
    PatipanStudio.Survivor.Escapes += 1
    PatipanStudio.Survivor.Status = "Escaped"
    return true
end

function PatipanStudio.Survivor.Step()
    if not PatipanStudio.Survivor.Enabled() then
        PatipanStudio.Survivor.Finish()
        PatipanStudio.Survivor.Status = "Off"
        return
    end
    local map = PatipanStudio.Map.Root()
    if map ~= PatipanStudio.Survivor.Map then
        PatipanStudio.Survivor.Map = map
        PatipanStudio.Survivor.RoundStart = osClock()
    end
    if not PatipanStudio.State.Alive or PatipanStudio.Player.Role() ~= "Survivors" or not PatipanStudio.Player:IsAlive() then
        PatipanStudio.Survivor.Gen = nil
        table.clear(PatipanStudio.Survivor.Banned)
        PatipanStudio.Survivor.Finish()
        PatipanStudio.Survivor.Status = "Not a survivor"
        return
    end
    if PatipanStudio.Player.Disabled(PatipanStudio.Player.Character) then
        PatipanStudio.Survivor.Finish()
        PatipanStudio.Survivor.Status = "Downed / hooked"
        return
    end
    if PatipanStudio.Survivor.TryEscape() then return end

    local job = PatipanStudio.Survivor.Job
    if job and not PatipanStudio.Survivor.JobAlive(job) then
        PatipanStudio.Survivor.Finish()
        job = nil
    end
    local better = PatipanStudio.Survivor.Candidate(PatipanStudio.Player.Root.Position)
    if better then
        PatipanStudio.Survivor.Finish()
        PatipanStudio.Survivor.Job = better
        job = better
    end
    if not job then
        PatipanStudio.Survivor.Status = "Waiting · gens left " .. PatipanStudio.Map.GensLeft()
        return
    end
    PatipanStudio.Survivor.Run(job)
end

PatipanStudio.Guard = { Dodges = 0, LastUnhook = 0, UnhookTries = 0, LastDodge = 0 }

---@return BasePart?  free point on the unfinished generator farthest from the killer
function PatipanStudio.Guard.SafeSpot(killerPos)
    local best, bestDist = nil, 0
    for _, gen in ipairs(PatipanStudio.Map.Generators()) do
        if not PatipanStudio.Survivor.GenUsable(gen) then continue end
        local point = PatipanStudio.Survivor.PointOn(gen)
        local dist = point and (point.Position - killerPos).Magnitude or 0
        if dist > bestDist then best, bestDist = point, dist end
    end
    return best
end

function PatipanStudio.Guard.Step()
    local opts = PatipanStudio.Options
    if not (opts.AutoDodge or opts.AutoSelfUnhook) or not PatipanStudio.State.Alive then return end
    if PatipanStudio.Player.Role() ~= "Survivors" or not PatipanStudio.Player:IsAlive() then return end
    local char, hrp = PatipanStudio.Player.Character, PatipanStudio.Player.Root

    if not char:GetAttribute("IsHooked") then PatipanStudio.Guard.UnhookTries = 0 end
    if opts.AutoSelfUnhook and char:GetAttribute("IsHooked") and PatipanStudio.Guard.UnhookTries < PatipanStudio.Config.SelfUnhookMax
        and osClock() - PatipanStudio.Guard.LastUnhook >= PatipanStudio.Config.SelfUnhookRetry then
        PatipanStudio.Guard.LastUnhook = osClock()
        PatipanStudio.Guard.UnhookTries += 1
        GameLib.Remote.SelfUnhook:FireServer()
        return
    end
    if not opts.AutoDodge or PatipanStudio.Player.Disabled(char) or osClock() - PatipanStudio.Guard.LastDodge < PatipanStudio.Config.DodgeCooldown then return end

    local killer = PatipanStudio.Player.Killer()
    local root = killer and killer:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - hrp.Position).Magnitude > opts.DodgeRadius then return end
    local spot = PatipanStudio.Guard.SafeSpot(root.Position)
    if not spot or (spot.Position - root.Position).Magnitude <= opts.DodgeRadius then return end
    PatipanStudio.Guard.LastDodge = osClock()
    PatipanStudio.Survivor.Finish()
    PatipanStudio.Survivor.Gen = spot:FindFirstAncestor("Generator")
    PatipanStudio.Player.Teleport(spot.CFrame + vector3New(0, 3, 0))
    PatipanStudio.Guard.Dodges += 1
end

PatipanStudio.Alert = { Near = false, Distance = nil }

function PatipanStudio.Alert.Step()
    local hrp = PatipanStudio.Player.Root
    local killer = PatipanStudio.Player.Killer()
    local root = killer and killer:FindFirstChild("HumanoidRootPart")
    if not (hrp and root) or PatipanStudio.Player.Role() ~= "Survivors" then
        PatipanStudio.Alert.Near, PatipanStudio.Alert.Distance = false, nil
        return
    end
    local dist = (root.Position - hrp.Position).Magnitude
    PatipanStudio.Alert.Distance = dist
    local near = dist <= PatipanStudio.Config.AlertRadius
    if near and not PatipanStudio.Alert.Near and PatipanStudio.Options.KillerAlert and PatipanStudio.Library then
        PatipanStudio.Library:Notify("Killer nearby", ("%d m away"):format(dist), 3, "Warning")
    end
    PatipanStudio.Alert.Near = near
end

PatipanStudio.SkillCheck = { Started = false, Checks = 0 }

function PatipanStudio.SkillCheck.OnGen(point, checkId)
    if not PatipanStudio.Options.PerfectSkillCheck then return end
    PatipanStudio.SkillCheck.Checks += 1
    GameLib.Remote.GenResult:FireServer("success", 1, point, checkId)
end

function PatipanStudio.SkillCheck.OnHeal(point)
    if not PatipanStudio.Options.PerfectSkillCheck then return end
    PatipanStudio.SkillCheck.Checks += 1
    GameLib.Remote.HealResult:FireServer("success", 1, point)
end

function PatipanStudio.SkillCheck.Start()
    local remote = GameLib.Remote
    if PatipanStudio.SkillCheck.Started or not (remote.GenCheck and remote.HealCheck and remote.GenResult and remote.HealResult) then return end
    PatipanStudio.SkillCheck.Started = true
    PatipanStudio.Block.Keep(PatipanStudio.SkillCheck.OnGen)
    PatipanStudio.Block.Keep(PatipanStudio.SkillCheck.OnHeal)
    PatipanStudio:Connect(remote.GenCheck.OnClientEvent, PatipanStudio.SkillCheck.OnGen)
    PatipanStudio:Connect(remote.HealCheck.OnClientEvent, PatipanStudio.SkillCheck.OnHeal)
end

function PatipanStudio.Survivor.Sacrifice()
    local hum = PatipanStudio.Player.Humanoid
    if not hum or PatipanStudio.Player.Role() ~= "Survivors" then return false end
    PatipanStudio.Survivor.Finish()
    hum.Health = 0
    return true
end

PatipanStudio.Parry = { Last = 0, Count = 0, Clients = setmetatable({}, { __mode = "k" }), Scanned = 0 }

function PatipanStudio.Parry.Remote()
    return GameLib.FindRemote("Items", "Parrying Dagger", "parry")
end

function PatipanStudio.Parry.Holding()
    return LocalPlayer:GetAttribute("EquippedItem") == "Parrying Dagger"
end

---@return boolean  killer is close and closing in fast
function PatipanStudio.Parry.Threat()
    local hrp = PatipanStudio.Player.Root
    local killer = PatipanStudio.Player.Killer()
    local root = killer and killer:FindFirstChild("HumanoidRootPart")
    if not (hrp and root) then return false end
    local offset = hrp.Position - root.Position
    if offset.Magnitude > PatipanStudio.Config.ParryRange then return false end
    local closing = root.AssemblyLinearVelocity:Dot(offset.Unit)
    return closing >= PatipanStudio.Config.ParryClosing or offset.Magnitude <= PatipanStudio.Config.ParryPanic
end

function PatipanStudio.Parry.FindClients()
    if not Util.Can("Gc") or osClock() - PatipanStudio.Parry.Scanned < PatipanStudio.Config.ParryScan then return end
    PatipanStudio.Parry.Scanned = osClock()
    for _, obj in ipairs(Util.GetGc(true)) do
        if type(obj) == "table" and rawget(obj, "isParryOnCooldown") ~= nil and rawget(obj, "parryEvent") then
            PatipanStudio.Parry.Clients[obj] = true
        end
    end
end

function PatipanStudio.Parry.ClearCooldowns()
    PatipanStudio.Parry.FindClients()
    for client in pairs(PatipanStudio.Parry.Clients) do
        client.isParryOnCooldown = false
        client.isParryResolving = false
        client.cooldownToken = (client.cooldownToken or 0) + 1
    end
end

function PatipanStudio.Parry.Step()
    local opts = PatipanStudio.Options
    if not (opts.AutoParry or opts.NoParryCooldown) or not PatipanStudio.State.Alive then return end
    if PatipanStudio.Player.Role() ~= "Survivors" or not PatipanStudio.Parry.Holding() then return end
    if opts.NoParryCooldown then PatipanStudio.Parry.ClearCooldowns() end
    if not opts.AutoParry or PatipanStudio.Player.Disabled(PatipanStudio.Player.Character) then return end

    local retry = opts.NoParryCooldown and PatipanStudio.Config.ParryFast or PatipanStudio.Config.ParryRetry
    if osClock() - PatipanStudio.Parry.Last < retry or not PatipanStudio.Parry.Threat() then return end
    local remote = PatipanStudio.Parry.Remote()
    if not remote then return end
    PatipanStudio.Parry.Last = osClock()
    PatipanStudio.Parry.Count += 1
    remote:FireServer()
end

PatipanStudio.Killer = { Status = "Off", LastSwing = 0, Hits = 0, Breaks = 0, Kicked = {} }

function PatipanStudio.Killer.Behind(targetRoot)
    local pos = targetRoot.Position - targetRoot.CFrame.LookVector * PatipanStudio.Config.AttackReach
    return cframeLookAt(pos, targetRoot.Position)
end

---@return Model?  nearest survivor matching state, inside range
function PatipanStudio.Killer.Pick(knocked, range)
    local hrp = PatipanStudio.Player.Root
    local best, bestDist = nil, range
    for _, char in ipairs(PatipanStudio.Player.Survivors()) do
        if (char:GetAttribute("Knocked") == true) ~= knocked then continue end
        if char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
        if dist < bestDist then best, bestDist = char, dist end
    end
    return best
end

function PatipanStudio.Killer.Swing(target)
    local root = target.HumanoidRootPart
    local remote = GameLib.Remote
    local stop = osClock() + PatipanStudio.Config.LungeDelay + PatipanStudio.Config.SwingTail
    local fired = false
    remote.Lunge:FireServer()
    local start = osClock()
    while osClock() < stop and root.Parent and PatipanStudio.State.Alive and PatipanStudio.Options.KillAura do
        PatipanStudio.Player.Teleport(PatipanStudio.Killer.Behind(root))
        if not fired and osClock() - start >= PatipanStudio.Config.LungeDelay then
            fired = true
            remote.Attack:FireServer()
        end
        RunService.Heartbeat:Wait()
    end
    if target:GetAttribute("Knocked") then PatipanStudio.Killer.Hits += 1 end
end

---@return boolean  still allowed to act after a yield
function PatipanStudio.Killer.Live(option, hrp)
    return PatipanStudio.State.Alive and PatipanStudio.Options[option] and PatipanStudio.Player:IsAlive() and PatipanStudio.Player.Root == hrp
end

function PatipanStudio.Killer.Carry(target)
    local hrp = PatipanStudio.Player.Root
    PatipanStudio.Player.Teleport(PatipanStudio.Killer.Behind(target.HumanoidRootPart))
    task.wait(PatipanStudio.Config.Settle)
    if not PatipanStudio.Killer.Live("AutoHook", hrp) or not target:GetAttribute("Knocked") then return end
    GameLib.Remote.Carry:FireServer(target)
    task.wait(PatipanStudio.Config.CarryDelay)
end

---@param offset Vector3  where the game stands you relative to the point
---@return boolean  false if the action was abandoned
function PatipanStudio.Killer.Commit(option, point, offset, remote, commit)
    local hrp = PatipanStudio.Player.Root
    if not hrp then return false end
    local seat = point.CFrame * cframeNew(offset)
    PatipanStudio.Player.Teleport(seat * cframeNew(0, 0, 3))
    task.wait(PatipanStudio.Config.Settle)
    if not PatipanStudio.Killer.Live(option, hrp) then return false end
    remote:FireServer(point)
    local tween = TweenService:Create(hrp, TweenInfo.new(PatipanStudio.Config.HookTween), { CFrame = seat })
    tween:Play()
    tween.Completed:Wait()
    if not PatipanStudio.Killer.Live(option, hrp) then return false end
    commit:FireServer(point)
    return true
end

function PatipanStudio.Killer.Hook()
    local hrp = PatipanStudio.Player.Root
    local point = hrp and PatipanStudio.Map.Nearest(PatipanStudio.Map.Tagged("HookPoint"), hrp.Position)
    if not point then return end
    if PatipanStudio.Killer.Commit("AutoHook", point, vector3New(0, 0.6, 0), GameLib.Remote.Hook, GameLib.Remote.HookCommit) then
        task.wait(PatipanStudio.Config.HookRest)
    end
end

---@return BasePart?  point on the most-repaired unfinished generator
function PatipanStudio.Killer.GenToBreak()
    local best, bestProgress = nil, 0
    for _, point in ipairs(PatipanStudio.Map.Tagged("GeneratorPoint")) do
        local gen = point:FindFirstAncestor("Generator")
        local progress = gen and PatipanStudio.Map.GenProgress(gen) or 0
        local fresh = gen and osClock() - (PatipanStudio.Killer.Kicked[gen] or 0) > PatipanStudio.Config.KickRegress
        if fresh and progress > bestProgress and progress < PatipanStudio.Config.GenDone then
            best, bestProgress = point, progress
        end
    end
    return best
end

function PatipanStudio.Killer.BreakGen(point)
    if not PatipanStudio.Killer.Commit("AutoBreakGens", point, vector3New(0, 0, 1), GameLib.Remote.BreakGen, GameLib.Remote.BreakGenCommit) then return end
    task.wait(PatipanStudio.Config.GenBreakTime)
    PatipanStudio.Killer.Kicked[point:FindFirstAncestor("Generator")] = osClock()
    PatipanStudio.Killer.Breaks += 1
end

PatipanStudio.AntiStun = { Count = 0 }

function PatipanStudio.AntiStun.OnStun()
    if not PatipanStudio.Options.AntiStun or PatipanStudio.Player.Role() ~= "Killer" then return end
    PatipanStudio.AntiStun.Count += 1
    GameLib.Remote.StunOver:FireServer()
end

function PatipanStudio.AntiStun.Start()
    if not (GameLib.Remote.Stun and GameLib.Remote.StunOver) then return end
    PatipanStudio.Block.Keep(PatipanStudio.AntiStun.OnStun)
    PatipanStudio:Connect(GameLib.Remote.Stun.OnClientEvent, PatipanStudio.AntiStun.OnStun)
end

---@return Model?  survivor right in front of us inside lunge reach
function PatipanStudio.Killer.InFront()
    local hrp = PatipanStudio.Player.Root
    local look = hrp.CFrame.LookVector
    for _, char in ipairs(PatipanStudio.Player.Survivors()) do
        if char:GetAttribute("Knocked") or char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then continue end
        local offset = char.HumanoidRootPart.Position - hrp.Position
        if offset.Magnitude <= PatipanStudio.Config.LegitReach and look:Dot(offset.Unit) >= PatipanStudio.Config.LegitAngle then return char end
    end
    return nil
end

---@param target Model  survivor in front; closed in on when Smart Hitbox is on
function PatipanStudio.Killer.LegitSwing(target)
    local remote = GameLib.Remote
    local root = target.HumanoidRootPart
    local function Close()
        local hrp = PatipanStudio.Player.Root
        if not (PatipanStudio.Options.SmartHitbox and hrp and root.Parent) then return end
        local offset = root.Position - hrp.Position
        if offset.Magnitude <= PatipanStudio.Config.ServerReach then return end
        local spot = root.Position - offset.Unit * PatipanStudio.Config.AttackReach
        PatipanStudio.Player.Teleport(cframeLookAt(vector3New(spot.X, hrp.Position.Y, spot.Z), vector3New(root.Position.X, hrp.Position.Y, root.Position.Z)))
    end
    Close()
    remote.Lunge:FireServer()
    task.wait(PatipanStudio.Config.LungeDelay)
    Close()
    remote.Attack:FireServer()
end

function PatipanStudio.Killer.Enabled()
    local opts = PatipanStudio.Options
    return opts.KillAura or opts.AutoHook or opts.AutoBreakGens
end

function PatipanStudio.Killer.Step()
    if not PatipanStudio.Killer.Enabled() then
        PatipanStudio.Killer.Status = "Off"
        return
    end
    if not PatipanStudio.State.Alive or PatipanStudio.Player.Role() ~= "Killer" or not PatipanStudio.Player:IsAlive() then
        PatipanStudio.Killer.Status = "Not the killer"
        return
    end
    local char, opts = PatipanStudio.Player.Character, PatipanStudio.Options

    if char:GetAttribute("CarriedSurvivorId") then
        if opts.AutoHook then PatipanStudio.Killer.Hook() end
        PatipanStudio.Killer.Status = "Carrying"
        return
    end

    if opts.AutoHook then
        local downed = PatipanStudio.Killer.Pick(true, opts.AuraRange)
        if downed then
            PatipanStudio.Killer.Status = "Picking up " .. downed.Name
            PatipanStudio.Killer.Carry(downed)
            return
        end
    end

    if opts.KillAura and GameLib.Remote.Lunge and GameLib.Remote.Attack and osClock() - PatipanStudio.Killer.LastSwing >= PatipanStudio.Config.AuraCooldown then
        local legit = opts.SlashMode == "Legit"
        local target = legit and PatipanStudio.Killer.InFront() or not legit and PatipanStudio.Killer.Pick(false, opts.AuraRange)
        if target then
            PatipanStudio.Killer.LastSwing = osClock()
            PatipanStudio.Killer.Status = "Hitting " .. target.Name
            if legit then PatipanStudio.Killer.LegitSwing(target) else PatipanStudio.Killer.Swing(target) end
            return
        end
    end
    if opts.AutoBreakGens then
        local point = PatipanStudio.Killer.GenToBreak()
        if point then
            PatipanStudio.Killer.Status = "Breaking generator"
            PatipanStudio.Killer.BreakGen(point)
            return
        end
    end
    PatipanStudio.Killer.Status = ("Hunting · downs %d · gens kicked %d"):format(PatipanStudio.Killer.Hits, PatipanStudio.Killer.Breaks)
end

PatipanStudio.Teleport = {}

function PatipanStudio.Teleport.Places()
    local names = { "Nearest Generator", "Best Generator", "Exit Gate", "Nearest Hook", "Killer", "Farthest From Killer" }
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then names[#names + 1] = player.Name end
    end
    return names
end

---@return CFrame?  stand spot for a teleport choice
function PatipanStudio.Teleport.Resolve(choice)
    local hrp = PatipanStudio.Player.Root
    if not hrp then return nil end
    local pos = hrp.Position
    local function At(part) return part and part.CFrame + vector3New(0, 3, 0) end

    if choice == "Nearest Generator" then
        return At(PatipanStudio.Map.Nearest(PatipanStudio.Map.Tagged("GeneratorPoint"), pos, function(point)
            local gen = point:FindFirstAncestor("Generator")
            return gen and PatipanStudio.Map.GenProgress(gen) < PatipanStudio.Config.GenDone
        end))
    elseif choice == "Best Generator" then
        return At(PatipanStudio.Survivor.PickGenPoint(pos, true))
    elseif choice == "Exit Gate" then
        local gate = PatipanStudio.Map.Models("Gate")[1]
        local part = gate and (gate:FindFirstChild("ExitLever", true) or gate:FindFirstChildWhichIsA("BasePart", true))
        return part and (part:IsA("Model") and part:GetPivot() or part.CFrame) + vector3New(0, 3, 0)
    elseif choice == "Nearest Hook" then
        return At(PatipanStudio.Map.Nearest(PatipanStudio.Map.Tagged("HookPoint"), pos))
    elseif choice == "Killer" then
        local killer = PatipanStudio.Player.Killer()
        return killer and At(killer:FindFirstChild("HumanoidRootPart"))
    elseif choice == "Farthest From Killer" then
        local killer = PatipanStudio.Player.Killer()
        local root = killer and killer:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, bestDist = nil, 0
        for _, point in ipairs(PatipanStudio.Map.Tagged("GeneratorPoint")) do
            local dist = (point.Position - root.Position).Magnitude
            if dist > bestDist then best, bestDist = point, dist end
        end
        return At(best)
    end
    local player = Players:FindFirstChild(choice)
    return player and player.Character and At(player.Character:FindFirstChild("HumanoidRootPart"))
end

function PatipanStudio.Teleport.Go(choice)
    local cframe = PatipanStudio.Teleport.Resolve(choice)
    if not cframe then return false end
    PatipanStudio.Player.Teleport(cframe)
    return true
end

PatipanStudio.Esp = { Count = 0, Marks = {}, Folder = nil }

---@return table[]  players in the shape Library.Visuals expects
function PatipanStudio.Esp.Targets()
    local list = {}
    local mine = PatipanStudio.Player.Role()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local role = PatipanStudio.Player.Role(player)
        if player == LocalPlayer or not char or (role ~= "Survivors" and role ~= "Killer") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local tag = role == "Killer" and "KILLER" or char:GetAttribute("IsHooked") and "Hooked"
            or char:GetAttribute("Knocked") and "Downed" or nil
        list[#list + 1] = {
            Model = char,
            Name = tag and (player.DisplayName .. " [" .. tag .. "]") or player.DisplayName,
            Health = hum.Health,
            MaxHealth = hum.MaxHealth > 0 and hum.MaxHealth or 100,
            Friendly = mine == role,
            Root = char:FindFirstChild("HumanoidRootPart"),
        }
    end
    PatipanStudio.Esp.Count = #list
    return list
end

PatipanStudio.Esp.Kinds = {
    { Option = "EspGenerators", Glow = true, Color = Color3.fromRGB(255, 196, 64), Find = PatipanStudio.Map.Generators, Label = function(model)
        local progress = PatipanStudio.Map.GenProgress(model)
        if progress >= PatipanStudio.Config.GenDone then return "Gen DONE" end
        return ("Gen %d%%"):format(progress)
    end },
    { Option = "EspHooks", Glow = true, Color = Color3.fromRGB(235, 70, 70), Find = function()
        local list = {}
        for _, point in ipairs(PatipanStudio.Map.Tagged("HookPoint")) do list[#list + 1] = point.Parent end
        return list
    end, Label = function() return "Hook" end },
    { Option = "EspGates", Glow = true, Color = Color3.fromRGB(90, 220, 120), Find = function() return PatipanStudio.Map.Models("Gate") end, Label = function() return "Exit Gate" end },
    { Option = "EspPallets", Color = Color3.fromRGB(200, 150, 90), Find = function()
        local list = {}
        for _, point in ipairs(PatipanStudio.Map.Tagged("PalletPoint")) do list[#list + 1] = point.Parent end
        return list
    end, Label = function() return "Pallet" end },
    { Option = "EspWindows", Color = Color3.fromRGB(110, 170, 255), Find = function()
        local list = {}
        for _, point in ipairs(PatipanStudio.Map.Tagged("VaultPoint")) do
            local model = point.Parent
            if model and model.Name == "Window" and not table.find(list, model) then list[#list + 1] = model end
        end
        return list
    end, Label = function() return "Window" end },
}

function PatipanStudio.Esp.Holder()
    local folder = PatipanStudio.Esp.Folder
    if folder and folder.Parent then return folder end
    folder = Instance.new("Folder")
    folder.Name = "MarioObjectEsp"
    Util.Mount(folder)
    PatipanStudio.Esp.Folder = folder
    return folder
end

function PatipanStudio.Esp.Make(model, kind)
    local holder = PatipanStudio.Esp.Holder()
    local light
    if kind.Glow then
        light = Instance.new("Highlight")
        light.Adornee = model
        light.FillColor = kind.Color
        light.FillTransparency = 0.75
        light.OutlineColor = kind.Color
        light.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        light.Parent = holder
    end

    local board = Instance.new("BillboardGui")
    board.Adornee = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)) or model
    board.Size = UDim2.fromOffset(120, 22)
    board.StudsOffset = vector3New(0, 3, 0)
    board.AlwaysOnTop = true
    board.Parent = holder

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.TextColor3 = kind.Color
    text.TextStrokeTransparency = 0.3
    text.Parent = board
    return { Light = light, Board = board, Text = text }
end

function PatipanStudio.Esp.Drop(model)
    local mark = PatipanStudio.Esp.Marks[model]
    if not mark then return end
    if mark.Light then mark.Light:Destroy() end
    mark.Board:Destroy()
    PatipanStudio.Esp.Marks[model] = nil
end

function PatipanStudio.Esp.Step()
    local map = PatipanStudio.Map.Root()
    local seen = {}
    local hrp = PatipanStudio.Player.Root
    if map then
        for _, kind in ipairs(PatipanStudio.Esp.Kinds) do
            if not PatipanStudio.Options[kind.Option] then continue end
            for _, model in ipairs(kind.Find()) do
                seen[model] = true
                local mark = PatipanStudio.Esp.Marks[model] or PatipanStudio.Esp.Make(model, kind)
                PatipanStudio.Esp.Marks[model] = mark
                local label = kind.Label(model)
                local part = mark.Board.Adornee
                if hrp and part then label ..= (" · %dm"):format((part.Position - hrp.Position).Magnitude) end
                mark.Text.Text = label
            end
        end
    end
    for model in pairs(PatipanStudio.Esp.Marks) do
        if not seen[model] or not model.Parent then PatipanStudio.Esp.Drop(model) end
    end
end

function PatipanStudio.Esp.Clear()
    for model in pairs(PatipanStudio.Esp.Marks) do PatipanStudio.Esp.Drop(model) end
    if PatipanStudio.Esp.Folder then PatipanStudio.Esp.Folder:Destroy() end
    PatipanStudio.Esp.Folder = nil
end

function PatipanStudio.Esp.GetStatus()
    local visuals = PatipanStudio.Library and PatipanStudio.Library.Visuals
    local players = visuals and visuals:Get("Enabled") and (PatipanStudio.Esp.Count .. " players") or "players off"
    local objects = 0
    for _ in pairs(PatipanStudio.Esp.Marks) do objects += 1 end
    return players .. " · " .. objects .. " objects"
end

PatipanStudio.Shop = { Status = "Off", Maxed = {}, Owned = {}, LevelCost = {}, Bought = 0, Leveled = 0, Busy = false, LastWallet = nil }

function PatipanStudio.Shop.Remote(name)
    return GameLib.FindRemote("Shop", name)
end

---@return string[]  folder names under ReplicatedStorage.<folder>, dev entries skipped
function PatipanStudio.Shop.Names(folder)
    local list = {}
    local root = ReplicatedStorage:FindFirstChild(folder)
    for _, child in ipairs(root and root:GetChildren() or {}) do
        if not child.Name:find("^!") then list[#list + 1] = child.Name end
    end
    table.sort(list)
    return list
end

function PatipanStudio.Shop.Wallet()
    return tonumber(LocalPlayer:GetAttribute("Screws")) or 0, tonumber(LocalPlayer:GetAttribute("Gears")) or 0
end

---@return table?  { owned, level, price } from the server
function PatipanStudio.Shop.Info(getter, name)
    local remote = PatipanStudio.Shop.Remote(getter)
    if not remote then return nil end
    local ok, info = pcall(remote.InvokeServer, remote, name)
    return ok and type(info) == "table" and info or nil
end

---@return any  whatever fn returns, nil while another shop run is active
function PatipanStudio.Shop.Locked(fn, ...)
    if PatipanStudio.Shop.Busy then return 0 end
    PatipanStudio.Shop.Busy = true
    local ok, got = pcall(fn, ...)
    PatipanStudio.Shop.Busy = false
    if not ok then
        warn("[ViolenceDistrict] shop: " .. tostring(got))
        return 0
    end
    return got
end

function PatipanStudio.Shop.BuyPerks()
    local buy = PatipanStudio.Shop.Remote("PurchasePerk")
    if not buy then return 0 end
    local count = 0
    local _, gears = PatipanStudio.Shop.Wallet()
    for _, name in ipairs(PatipanStudio.Shop.Names("Perks")) do
        if not PatipanStudio.State.Alive then break end
        if PatipanStudio.Shop.Owned[name] then continue end
        local info = PatipanStudio.Shop.Info("GetPerkInfo", name)
        if info and info.owned then PatipanStudio.Shop.Owned[name] = true end
        if not info or info.owned or gears < (info.price or mathHuge) then continue end
        buy:FireServer(name)
        gears -= info.price
        count += 1
        task.wait(PatipanStudio.Config.ShopDelay)
    end
    PatipanStudio.Shop.Bought += count
    return count
end

function PatipanStudio.Shop.LevelPerks()
    local level = PatipanStudio.Shop.Remote("LevelUpPerk")
    if not level then return 0 end
    local count = 0
    for _, name in ipairs(PatipanStudio.Shop.Names("Perks")) do
        if PatipanStudio.Shop.Maxed[name] then continue end
        local screws = PatipanStudio.Shop.Wallet()
        local before = PatipanStudio.Shop.Info("GetPerkInfo", name)
        if not before or not before.owned then continue end
        if not PatipanStudio.State.Alive then break end
        local cost = PatipanStudio.Shop.LevelCost[name] or PatipanStudio.Shop.MaxCost()
        if screws - cost < PatipanStudio.Options.KeepScrews then continue end
        level:FireServer(name)
        task.wait(PatipanStudio.Config.ShopDelay)
        local after = PatipanStudio.Shop.Info("GetPerkInfo", name)
        local spent = screws - PatipanStudio.Shop.Wallet()
        if after and after.level ~= before.level then
            PatipanStudio.Shop.LevelCost[name] = math.max(spent, cost or 0)
            count += 1
        elseif spent == 0 and cost and screws > cost * 2 then
            PatipanStudio.Shop.Maxed[name] = true
        end
    end
    PatipanStudio.Shop.Leveled += count
    return count
end

---@param kind string  "Item" or "Killer"
function PatipanStudio.Shop.BuyList(kind, names)
    local buy = PatipanStudio.Shop.Remote("Purchase" .. kind)
    if not buy then return 0 end
    local count = 0
    for key, picked in pairs(names or {}) do
        local name = type(key) == "number" and picked or key
        if not picked or type(name) ~= "string" then continue end
        local owned
        if kind == "Killer" then
            local check = PatipanStudio.Shop.Remote("CheckKillerOwnership")
            local ok, got = pcall(function() return check and check:InvokeServer(name) end)
            owned = ok and got == true
        else
            local info = PatipanStudio.Shop.Info("GetItemInfo", name)
            owned = info and info.owned
        end
        local price = kind == "Killer" and PatipanStudio.Shop.KillerPrice(name) or (PatipanStudio.Shop.Info("GetItemInfo", name) or {}).price
        if owned or not price or PatipanStudio.Shop.Wallet() - price < PatipanStudio.Options.KeepScrews then continue end
        buy:FireServer(name)
        count += 1
        task.wait(PatipanStudio.Config.ShopDelay)
    end
    return count
end

---@return number  highest level-up cost seen so far, a safe guess for unknown perks
function PatipanStudio.Shop.MaxCost()
    local most = PatipanStudio.Config.FirstLevelCost
    for _, cost in pairs(PatipanStudio.Shop.LevelCost) do most = math.max(most, cost) end
    return most
end

function PatipanStudio.Shop.KillerPrice(name)
    local remote = PatipanStudio.Shop.Remote("GetKillerPrice")
    local ok, price = pcall(function() return remote and remote:InvokeServer(name) end)
    return ok and tonumber(price) or nil
end

function PatipanStudio.Shop.Step()
    local opts = PatipanStudio.Options
    if not (opts.AutoBuyPerks or opts.AutoLevelPerks) then
        PatipanStudio.Shop.Status = "Off"
        PatipanStudio.Shop.LastWallet = nil
        return
    end
    local wallet = table.concat({ PatipanStudio.Shop.Wallet() }, "/")
    if wallet == PatipanStudio.Shop.LastWallet then return end
    PatipanStudio.Shop.LastWallet = wallet
    if opts.AutoBuyPerks then PatipanStudio.Shop.Locked(PatipanStudio.Shop.BuyPerks) end
    if opts.AutoLevelPerks then PatipanStudio.Shop.Locked(PatipanStudio.Shop.LevelPerks) end
    local screws, gears = PatipanStudio.Shop.Wallet()
    PatipanStudio.Shop.Status = ("bought %d · leveled %d · %d screws · %d gears"):format(PatipanStudio.Shop.Bought, PatipanStudio.Shop.Leveled, screws, gears)
end

PatipanStudio.UI = { Labels = {}, FarmSaved = nil }
local Library, T

function PatipanStudio.UI.Detach(fn)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(fn, table.unpack(packed, 1, packed.n))
            if not ok then warn("[ViolenceDistrict] ui: " .. tostring(err)) end
        end)
    end
end

---@return table  list read from the game, empty when reading failed
function PatipanStudio.UI.List(read, ...)
    local ok, list = pcall(read, ...)
    return ok and type(list) == "table" and list or {}
end

---@param allow    fun(value: any): boolean
---@param refusal  table  { title, message, value the widget snaps back to }
function PatipanStudio.UI.Guard(widget, allow, refusal)
    local function Refuse()
        Library:Notify(refusal[1], refusal[2], 4, "Warning")
        task.defer(widget.SetValue, widget, refusal[3])
    end

    if type(widget.AddGuard) == "function" then
        widget:AddGuard(function(value)
            if allow(value) then return true end
            Refuse()
            return false
        end)
        return widget
    end

    widget:OnChanged(function(value)
        if not allow(value) then Refuse() end
    end)
    return widget
end

---@param cap string|string[]  needed before the toggle may turn on
function PatipanStudio.UI.NeedCap(idx, cap)
    if Library.Compat then
        Library.Compat.NeedCap(idx, cap)
        return
    end
    local toggle = Library.Toggles[idx]
    if not toggle then return end
    local title = toggle.Info and toggle.Info.Text or "PatipanStudio"
    PatipanStudio.UI.Guard(toggle, function(value)
        return value ~= true or Util.Can(cap)
    end, { title, T("Not supported on this executor", "ใช้กับ executor นี้ไม่ได้"), false })
end

---@param role table  RoleMode widget, kept on "Any" when the executor cannot press the game's button
function PatipanStudio.UI.GuardRole(role)
    return PatipanStudio.UI.Guard(role, function(value)
        return value == "Any" or PatipanStudio.Role.Supported()
    end, { "PatipanStudio", T("Role choice is not supported on this executor", "เลือกบทบาทใช้กับ executor นี้ไม่ได้"), "Any" })
end

---@param widget table  option whose value mirrors an Options key
function PatipanStudio.UI.Bind(widget, key)
    PatipanStudio.Options[key] = widget.Value
    widget:OnChanged(function(value) PatipanStudio.Options[key] = value end)
    return widget
end

function PatipanStudio.UI.BuildMain(window)
    window:AddTabSection(T("Main", "หลัก"))
    local tab = window:AddTab(T("Main", "หลัก"), "mushroom", T("Status and links", "สถานะและลิงก์"))

    local farm = tab:AddLeftGroupbox(T("Auto Farm", "ฟาร์มอัตโนมัติ"), "star")
    farm:AddToggle("AutoFarm", { Text = T("Auto Farm", "ฟาร์มอัตโนมัติ"), Description = T("Plays both roles for you: repairs, escapes, hunts and hooks", "เล่นให้ทั้งสองฝั่ง ซ่อม หนี ล่า แขวน"), Risky = true, Callback = PatipanStudio.UI.Detach(PatipanStudio.UI.SetFarm) }):AddKeyPicker("AutoFarmKey", { Default = "None", Mode = "Toggle" })
    PatipanStudio.UI.GuardRole(farm:AddDropdown("RoleMode", { Text = T("Role", "บทบาท"), Description = T("Survivor only never gets killer; Prefer killer keeps you in the killer pool", "Survivor only ไม่ถูกสุ่มเป็นฆาตกร / Prefer killer อยู่ในกลุ่มสุ่มฆาตกรเสมอ"), Values = { "Any", "Survivor only", "Prefer killer" }, Default = "Any" }))
    farm:AddSlider("FarmEscapeAfter", { Text = T("Survivor: escape after", "ผู้รอด: หนีหลัง"), Description = T("0 = never escape, stay and farm the whole round", "0 = ไม่หนี อยู่ฟาร์มจนจบรอบ"), Min = 0, Max = 900, Default = 0, Suffix = "s" })

    local status = tab:AddLeftGroupbox(T("Round", "รอบนี้"), "star")
    local labels = PatipanStudio.UI.Labels
    labels.Role = status:AddParagraph({ Title = T("Role", "บทบาท"), Content = "-" })
    labels.Survivor = status:AddParagraph({ Title = T("Survivor", "ผู้รอดชีวิต"), Content = "-" })
    labels.Killer = status:AddParagraph({ Title = T("Killer", "ฆาตกร"), Content = "-" })

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

    local panic = tab:AddRightGroupbox(T("Quick", "ด่วน"), "bomb")
    panic:AddButton({ Text = T("Panic — all off", "ฉุกเฉิน ปิดทั้งหมด"), Style = "Danger", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.FarmSaved = nil
        for _, toggle in pairs(Library.Toggles) do
            if toggle.Value == true then toggle:SetValue(false) end
        end
    end) })

    local activity = tab:AddRightGroupbox(T("Activity", "กิจกรรม"), "eye")
    labels.Esp = activity:AddParagraph({ Title = T("ESP", "ESP"), Content = "-" })
    labels.Shop = activity:AddParagraph({ Title = T("Shop", "ร้านค้า"), Content = "-" })
end

PatipanStudio.UI.FarmKeys = {
    "AutoRepair", "PerfectSkillCheck", "AutoHeal", "AutoUnhook", "AutoDodge", "AutoSelfUnhook", "InstantEscape", "NoSlow",
    "KillAura", "AutoHook", "AutoBreakGens", "AntiStun", "AntiAfk",
}

function PatipanStudio.UI.SetFarm(on)
    local options = Library.Options
    local tuned = { EscapeDelay = options.FarmEscapeAfter.Value, DodgeRadius = PatipanStudio.Config.FarmDodge }
    if on then
        if PatipanStudio.UI.FarmSaved then return end
        PatipanStudio.UI.FarmSaved = {}
        for key in pairs(tuned) do PatipanStudio.UI.FarmSaved[key] = options[key].Value end
        for _, key in ipairs(PatipanStudio.UI.FarmKeys) do PatipanStudio.UI.FarmSaved[key] = options[key].Value end
        for key, value in pairs(tuned) do options[key]:SetValue(value) end
        for _, key in ipairs(PatipanStudio.UI.FarmKeys) do options[key]:SetValue(true) end
        if options.FarmEscapeAfter.Value <= 0 then options.InstantEscape:SetValue(false) end
        return
    end
    local saved = PatipanStudio.UI.FarmSaved
    PatipanStudio.UI.FarmSaved = nil
    if not saved then return end
    for key, value in pairs(saved) do
        if options[key] then options[key]:SetValue(value) end
    end
end

function PatipanStudio.UI.BuildSurvivor(window)
    window:AddTabSection(T("Roles", "บทบาท"))
    local tab = window:AddTab(T("Survivor", "ผู้รอดชีวิต"), "heart", T("Generators, team and escape", "เครื่องปั่นไฟ ทีม และการหนี"))

    local work = tab:AddLeftGroupbox(T("Objectives", "ภารกิจ"), "gear")
    work:AddToggle("AutoRepair", { Text = T("Auto repair", "ซ่อมอัตโนมัติ"), Description = T("Repairs the best generator hands-free", "ซ่อมเครื่องที่ดีที่สุดให้เอง"), Risky = true })
    work:AddToggle("PerfectSkillCheck", { Text = T("Auto Skill Check", "สกิลเช็คอัตโนมัติ") })
    work:AddToggle("AutoHeal", { Text = T("Auto heal teammates", "รักษาเพื่อนอัตโนมัติ"), Risky = true })
    work:AddToggle("AutoUnhook", { Text = T("Auto unhook teammates", "ปลดเพื่อนจากตะขอ"), Risky = true })

    local escape = tab:AddLeftGroupbox(T("Escape", "หนี"), "flag")
    escape:AddToggle("InstantEscape", { Text = T("Instant escape", "หนีออกทันที"), Description = T("Leaves the round without repairing anything", "ออกจากรอบโดยไม่ต้องซ่อม"), Risky = true })
    escape:AddSlider("EscapeDelay", { Text = T("Escape after", "หนีหลังเริ่มรอบ"), Min = 0, Max = 900, Default = 0, Suffix = "s" })
    escape:AddButton({ Text = T("Escape Now", "หนีออกตอนนี้"), Style = "Warning", Func = PatipanStudio.UI.Detach(function()
        if not PatipanStudio.Survivor.EscapeNow() then
            Library:Notify(T("Escape", "หนี"), T("No exit found this round", "ไม่พบทางออกในรอบนี้"), 3, "Warning")
        end
    end) })

    local safety = tab:AddRightGroupbox(T("Safety", "ความปลอดภัย"), "boo")
    safety:AddToggle("AutoDodge", { Text = T("Auto dodge killer", "หลบฆาตกรอัตโนมัติ"), Description = T("Teleports away when the killer gets close and keeps other jobs away from him", "วาร์ปหนีเมื่อฆาตกรเข้าใกล้ และไม่ไปทำงานใกล้ฆาตกร"), Risky = true })
    safety:AddSlider("DodgeRadius", { Text = T("Dodge distance", "ระยะหลบ"), Min = 6, Max = 40, Default = 20, Suffix = "m" })
    safety:AddToggle("AutoSelfUnhook", { Text = T("Auto self-unhook", "ปลดตัวเองจากตะขอ"), Risky = true })
    safety:AddToggle("AutoParry", { Text = T("Auto parry (beta)", "ปัดป้องอัตโนมัติ (beta)"), Description = T("Needs the Parrying Dagger equipped", "ต้องใส่ Parrying Dagger") })
    safety:AddToggle("NoParryCooldown", { Text = T("No parry cooldown (beta)", "ปัดป้องไม่มีคูลดาวน์ (beta)") })
    PatipanStudio.UI.NeedCap("NoParryCooldown", "Gc")
    safety:AddToggle("KillerAlert", { Text = T("Killer alert", "เตือนฆาตกรเข้าใกล้") })
    safety:AddButton({ Text = T("Sacrifice Self", "สละชีพตัวเอง"), Style = "Danger", Func = PatipanStudio.UI.Detach(function()
        if not PatipanStudio.Survivor.Sacrifice() then
            Library:Notify(T("Sacrifice", "สละชีพ"), T("Only works as a survivor", "ใช้ได้ตอนเป็นผู้รอดเท่านั้น"), 3, "Warning")
        end
    end) })
end

function PatipanStudio.UI.BuildKiller(window)
    local tab = window:AddTab(T("Killer", "ฆาตกร"), "swords", T("Hunting and hooking", "ล่าและแขวน"))

    local hunt = tab:AddLeftGroupbox(T("Hunt", "ล่า"), "target")
    hunt:AddToggle("KillAura", { Text = T("Auto slash", "ฟันอัตโนมัติ"), Description = T("Rage jumps behind anyone in range, Legit only swings at whoever is in front of you", "Rage วาร์ปไปฟันทุกคนในระยะ / Legit ฟันเฉพาะคนตรงหน้า"), Risky = true }):AddKeyPicker("KillAuraKey", { Default = "None", Mode = "Toggle" })
    hunt:AddToggle("SmartHitbox", { Text = T("Reach Assist", "ช่วยเพิ่มระยะฟัน"), Description = T("Legit swings still land on targets a few studs out of reach", "โหมด Legit ฟันโดนแม้เป้าอยู่เกินระยะนิดหน่อย"), Risky = true })
    hunt:AddDropdown("SlashMode", { Text = T("Slash mode", "โหมดฟัน"), Values = { "Rage", "Legit" }, Default = "Rage" })
    hunt:AddSlider("AuraRange", { Text = T("Range", "ระยะ"), Min = 10, Max = 500, Default = 500, Suffix = "m" })

    local chores = tab:AddRightGroupbox(T("Hooks & Generators", "ตะขอและเครื่องปั่นไฟ"), "gear")
    chores:AddToggle("AutoHook", { Text = T("Auto carry + hook", "แบกและแขวนอัตโนมัติ"), Description = T("Picks up anyone downed and hooks them", "แบกคนล้มแล้วแขวนตะขอให้"), Risky = true })
    chores:AddToggle("AutoBreakGens", { Text = T("Auto kick generators", "เตะเครื่องปั่นไฟอัตโนมัติ"), Description = T("Kicks the most repaired generator when nobody is in range", "เตะเครื่องที่ซ่อมไปเยอะสุดตอนไม่มีเป้า"), Risky = true })

    local defense = tab:AddRightGroupbox(T("Defense", "ป้องกัน"), "shield")
    defense:AddToggle("AntiStun", { Text = T("Anti pallet stun (beta)", "กันพาเลทสตัน (beta)") })
    PatipanStudio.UI.NeedCap("AntiStun", "Connections")
    defense:AddToggle("AntiBlind", { Text = T("Anti blind (beta)", "กันแสงไฟฉาย (beta)"), Description = T("Flashlights no longer blind you", "ไม่โดนไฟฉายแยงตา") })
    PatipanStudio.UI.NeedCap("AntiBlind", "Connections")
    defense:AddToggle("FreeTurn", { Text = T("No turn limit", "หมุนตัวได้อิสระ"), Description = T("Keep turning while attacking or lunging", "หันตัวได้ตอนฟันและพุ่ง") })
end

function PatipanStudio.UI.BuildPlayer(window)
    window:AddTabSection(T("Player", "ผู้เล่น"))
    local tab = window:AddTab(T("Player", "ผู้เล่น"), "player", T("Movement, world and teleport", "การเคลื่อนที่ โลก และวาร์ป"))

    local move = tab:AddLeftGroupbox(T("Movement", "การเคลื่อนที่"), "zap")
    move:AddToggle("Speed", { Text = T("Speed", "วิ่งเร็ว"), Risky = true }):AddKeyPicker("SpeedKey", { Default = "None", Mode = "Toggle" })
    move:AddSlider("SpeedValue", { Text = T("Walk speed", "ความเร็ว"), Min = 16, Max = 60, Default = 24 })
    move:AddToggle("NoSlow", { Text = T("No slow", "ไม่โดนสโลว์"), Description = T("Never drops below your normal run speed", "ความเร็วไม่ต่ำกว่าวิ่งปกติ") })
    move:AddToggle("NoFall", { Text = T("No fall (beta)", "ไม่เซตอนตก (beta)"), Description = T("No landing stumble after a drop", "ลงพื้นแล้วไม่เซ") })
    PatipanStudio.UI.NeedCap("NoFall", "Namecall")
    move:AddToggle("Noclip", { Text = T("Noclip", "เดินทะลุ") }):AddKeyPicker("NoclipKey", { Default = "None", Mode = "Toggle" })
    move:AddToggle("InfiniteJump", { Text = T("Infinite jump", "กระโดดไม่จำกัด"), Description = T("Jump anywhere, even mid-air", "กระโดดได้ทุกที่ แม้กลางอากาศ") })

    local world = tab:AddRightGroupbox(T("World", "โลก"), "star")
    world:AddToggle("Fullbright", { Text = T("Fullbright", "สว่างทั้งแมพ") })
    world:AddToggle("AntiShake", { Text = T("Anti camera shake", "กันจอสั่น") })
    PatipanStudio.UI.NeedCap("AntiShake", "Connections")
    world:AddToggle("NoFog", { Text = T("No fog", "ไม่มีหมอก") })
    world:AddToggle("AntiAfk", { Text = T("Anti AFK", "กันหลุด AFK"), Callback = PatipanStudio.UI.Detach(PatipanStudio.Player.AntiAfk.Arm) })

    PatipanStudio.UI.BuildTeleport(tab)
end

function PatipanStudio.UI.BuildShop(window)
    local tab = window:AddTab(T("Shop", "ร้านค้า"), "shop", T("Perks, items and killers", "เพิร์ค ไอเทม ฆาตกร"))

    local perks = tab:AddLeftGroupbox(T("Perks", "เพิร์ค"), "star")
    perks:AddToggle("AutoBuyPerks", { Text = T("Auto buy perks", "ซื้อเพิร์คอัตโนมัติ"), Description = T("Unlocks every perk you can afford with Gears", "ปลดล็อกเพิร์คทุกตัวที่ Gears พอ") })
    perks:AddToggle("AutoLevelPerks", { Text = T("Auto level perks", "อัปเลเวลเพิร์คอัตโนมัติ"), Description = T("Spends Screws to level owned perks", "ใช้ Screws อัปเลเวลเพิร์คที่มี") })
    perks:AddSlider("KeepScrews", { Text = T("Keep Screws", "เก็บ Screws ไว้"), Description = T("Never spends below this", "ไม่ใช้ต่ำกว่าจำนวนนี้"), Min = 0, Max = 20000, Default = 0 })
    perks:AddButton({ Text = T("Buy + Level Now", "ซื้อ + อัปตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        local bought, leveled = PatipanStudio.Shop.Locked(PatipanStudio.Shop.BuyPerks), PatipanStudio.Shop.Locked(PatipanStudio.Shop.LevelPerks)
        Library:Notify(T("Perks", "เพิร์ค"), ("Bought %d, leveled %d"):format(bought, leveled), 4, "Success")
    end) })

    local store = tab:AddRightGroupbox(T("Items & Killers", "ไอเทมและฆาตกร"), "coin")
    local items = store:AddDropdown("ShopItems", { Text = T("Items", "ไอเทม"), Values = PatipanStudio.UI.List(PatipanStudio.Shop.Names, "Items"), Multi = true, Default = {}, AllowNull = true, Searchable = true })
    store:AddButton({ Text = T("Buy Selected Items", "ซื้อไอเทมที่เลือก"), Func = PatipanStudio.UI.Detach(function()
        Library:Notify(T("Shop", "ร้านค้า"), ("Bought %d items"):format(PatipanStudio.Shop.Locked(PatipanStudio.Shop.BuyList, "Item", items.Value)), 4, "Coin")
    end) })
    local killers = store:AddDropdown("ShopKillers", { Text = T("Killers", "ฆาตกร"), Values = PatipanStudio.UI.List(PatipanStudio.Shop.Names, "Killers"), Multi = true, Default = {}, AllowNull = true, Searchable = true })
    store:AddButton({ Text = T("Buy Selected Killers", "ซื้อฆาตกรที่เลือก"), Func = PatipanStudio.UI.Detach(function()
        Library:Notify(T("Shop", "ร้านค้า"), ("Bought %d killers"):format(PatipanStudio.Shop.Locked(PatipanStudio.Shop.BuyList, "Killer", killers.Value)), 4, "Coin")
    end) })
    store:AddButton({ Text = T("Refresh lists", "รีเฟรชรายการ"), Func = PatipanStudio.UI.Detach(function()
        items:SetValues(PatipanStudio.Shop.Names("Items"))
        killers:SetValues(PatipanStudio.Shop.Names("Killers"))
    end) })
end

---@param tab table  Player tab, the teleport group sits on its right side
function PatipanStudio.UI.BuildTeleport(tab)
    local box = tab:AddRightGroupbox(T("Teleport", "วาร์ป"), "pipe")
    local places = box:AddDropdown("TeleportTarget", { Text = T("Destination", "ปลายทาง"), Values = PatipanStudio.UI.List(PatipanStudio.Teleport.Places), Default = "Nearest Generator", Searchable = true })
    box:AddButton({ Text = T("Teleport Now", "วาร์ปตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        if not PatipanStudio.Teleport.Go(places.Value) then
            Library:Notify(T("Teleport", "วาร์ป"), T("Destination not found this round", "ไม่พบปลายทางในรอบนี้"), 3, "Warning")
        end
    end) }):AddButton({ Text = T("Refresh", "รีเฟรช"), Func = PatipanStudio.UI.Detach(function()
        places:SetValues(PatipanStudio.Teleport.Places())
    end) })
end

function PatipanStudio.UI.BuildVisuals(window)
    window:AddTabSection(T("Visuals", "การมองเห็น"))
    local tab = window:AddVisualsTab({ Provider = PatipanStudio.Esp.Targets, Preview = true })
    local objects = tab:AddLeftGroupbox(T("Objects", "วัตถุ"), "eye")
    objects:AddToggle("EspGenerators", { Text = T("Generators + progress", "เครื่องปั่นไฟ + ความคืบหน้า") })
    objects:AddToggle("EspHooks", { Text = T("Hooks", "ตะขอ") })
    objects:AddToggle("EspGates", { Text = T("Exit gates", "ประตูทางออก") })
    objects:AddToggle("EspPallets", { Text = T("Pallets", "พาเลท") })
    objects:AddToggle("EspWindows", { Text = T("Windows", "หน้าต่าง") })
end

function PatipanStudio.UI.RefreshStatus()
    local labels = PatipanStudio.UI.Labels
    if not (labels.Role and labels.Survivor and labels.Killer and labels.Esp and labels.Shop) then return end
    local dist = PatipanStudio.Alert.Distance
    labels.Role:SetContent((PatipanStudio.Player.Role() or "-") .. " · gens left " .. PatipanStudio.Map.GensLeft() .. (dist and (" · killer %dm"):format(dist) or ""))
    labels.Survivor:SetContent(("%s · checks %d · dodges %d · escapes %d"):format(PatipanStudio.Survivor.Status, PatipanStudio.SkillCheck.Checks, PatipanStudio.Guard.Dodges, PatipanStudio.Survivor.Escapes))
    labels.Killer:SetContent(PatipanStudio.Killer.Status .. " · stuns dodged " .. PatipanStudio.AntiStun.Count)
    labels.Esp:SetContent(PatipanStudio.Esp.GetStatus())
    labels.Shop:SetContent(PatipanStudio.Shop.Status)
end

---Flips the menu toggles of jobs the scheduler halted and says why; runs on the library's own clean thread.
function PatipanStudio.UI.DrainHalts()
    local halts = PatipanStudio.Scheduler.Halts
    if not halts[1] then return end
    PatipanStudio.Scheduler.Halts = {}
    for _, halt in ipairs(halts) do
        Util.Try("halt", function()
            for _, idx in ipairs(halt.Toggles) do
                local toggle = Library.Toggles[idx]
                if toggle and toggle.Value then toggle:SetValue(false) end
            end
            Library:Notify("Violence District", halt.Message, 6, "Warning")
        end)
    end
end

function PatipanStudio.UI.Pump()
    PatipanStudio.UI.DrainHalts()
    PatipanStudio.UI.RefreshStatus()
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    for _, section in ipairs({ "BuildMain", "BuildSurvivor", "BuildKiller", "BuildPlayer", "BuildShop", "BuildVisuals" }) do
        Util.Try("ui " .. section, PatipanStudio.UI[section], window)
    end
    window:AddTabSection(T("Other", "อื่นๆ"))
    Util.Try("ui settings", window.AddSettingsTab, window)

    for key in pairs(PatipanStudio.Options) do
        local widget = Library.Options[key] or Library.Toggles[key]
        if widget then PatipanStudio.UI.Bind(widget, key) end
    end
    Util.Try("ui gate", PatipanStudio.UI.GateRemotes)
end

---Toggles whose game remote is gone refuse to turn on and say why, instead of erroring every tick.
function PatipanStudio.UI.GateRemotes()
    if not Library.Compat then return end
    local reason = T("Not found after a game update", "หาไม่เจอหลังเกมอัปเดต")
    for idx in pairs(GameLib.Needs) do
        local missing = GameLib.Missing(idx)
        if missing and Library.Toggles[idx] then
            Library.Compat.Block(idx, reason)
            warn("[ViolenceDistrict] " .. idx .. " off, missing remote " .. missing)
        end
    end
end

---@return boolean  false when the menu could not load
local function BuildInterface()
    Library = Util.LoadLibrary()
    if not Library then return false end
    pcall(MarioBanner.Step, "UI library")
    PatipanStudio.Library = Library
    T = function(en, th) return Library:T(en, th) end
    Library:CreateWindow({
        Title = "PatipanStudio",
        SubTitle = "Violence District by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = PatipanStudio.Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        Intro = PatipanStudio.Config.Intro,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            task.defer(Util.Try, "boot", PatipanStudio.Boot)
            Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.Pump)
            task.defer(Util.Try, "autoload", Library.LoadAutoloadConfig, Library)
        end,
    })
    Library:OnUnload(function()
        PatipanStudio:Unload()
    end)
    return true
end

function PatipanStudio.Boot()
    PatipanStudio:Connect(LocalPlayer.CharacterAdded, function(character)
        PatipanStudio.Survivor.Job = nil
        PatipanStudio.Movement.Release()
        PatipanStudio.Player:Bind(character)
    end)

    PatipanStudio.Movement.Start()
    PatipanStudio.SkillCheck.Start()
    PatipanStudio.AntiStun.Start()

    PatipanStudio.Scheduler.Every("Survivor", PatipanStudio.Config.RepairTick, PatipanStudio.Survivor.Step, { "AutoRepair", "AutoHeal", "AutoUnhook", "InstantEscape" }, { Core = true, Restore = PatipanStudio.Survivor.Finish })
    PatipanStudio.Scheduler.Every("Guard", PatipanStudio.Config.GuardTick, PatipanStudio.Guard.Step, { "AutoDodge", "AutoSelfUnhook" })
    PatipanStudio.Scheduler.Every("Block", 1, PatipanStudio.Block.Step, { "PerfectSkillCheck", "AntiStun", "AntiBlind", "AntiShake", "NoFall" }, { Restore = PatipanStudio.Block.Release })
    PatipanStudio.Scheduler.Every("Parry", PatipanStudio.Config.GuardTick, PatipanStudio.Parry.Step, { "AutoParry", "NoParryCooldown" })
    PatipanStudio.Scheduler.Every("Killer", 0.1, PatipanStudio.Killer.Step, { "KillAura", "AutoHook", "AutoBreakGens" })
    PatipanStudio.Scheduler.Every("World", 0.5, PatipanStudio.World.Step, { "Fullbright", "NoFog" }, { Restore = PatipanStudio.World.Restore })
    PatipanStudio.Scheduler.Every("Role", 3, PatipanStudio.Role.Step)
    PatipanStudio.Scheduler.Every("Alert", 0.5, PatipanStudio.Alert.Step, { "KillerAlert" }, { Core = true })
    PatipanStudio.Scheduler.Every("Shop", PatipanStudio.Config.ShopInterval, PatipanStudio.Shop.Step, { "AutoBuyPerks", "AutoLevelPerks" })
    PatipanStudio.Scheduler.Every("ObjectEsp", PatipanStudio.Config.ObjectEspRefresh, PatipanStudio.Esp.Step, { "EspGenerators", "EspHooks", "EspGates", "EspPallets", "EspWindows" }, { Core = true })
    PatipanStudio.Scheduler.Boot()
end

function PatipanStudio:Unload()
    self.State.Alive = false
    if environment.ViolenceDistrictUnload == self.UnloadFn then environment.ViolenceDistrictUnload = nil end
    table.clear(PatipanStudio.Scheduler.Jobs)
    PatipanStudio.Survivor.Finish()
    PatipanStudio.Block.Release()
    PatipanStudio.Movement.Release()
    PatipanStudio.World.Restore()
    PatipanStudio.Esp.Clear()
    for _, connection in ipairs(self.State.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.State.Connections)
end

PatipanStudio.UnloadFn = function()
    if PatipanStudio.Library and not PatipanStudio.Library.Unloaded then
        PatipanStudio.Library:Unload()
    else
        PatipanStudio:Unload()
    end
end
environment.ViolenceDistrictUnload = PatipanStudio.UnloadFn

if LocalPlayer.Character then
    PatipanStudio.Player:Bind(LocalPlayer.Character)
end

pcall(MarioBanner.Step, "Systems")
if BuildInterface() then
    pcall(MarioBanner.Step, "Interface")
    pcall(MarioBanner.Ready)
end