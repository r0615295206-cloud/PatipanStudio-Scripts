if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if game.GameId ~= 10031505426 then
    LocalPlayer:Kick("PatipanStudio: this script is for FPS AirDrop Arena only")
    return
end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
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

local environment = getgenv and getgenv() or _G
if type(environment.AirDropArenaUnload) == "function" then
    pcall(environment.AirDropArenaUnload)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local osClock = os.clock
local vector3New, cframeLookAt = Vector3.new, CFrame.lookAt

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-10", "Updated for Season 5\nAuto Lottery in Auto Claim\nTeleport to and spectate any player\nItem pictures in every item list\nHalloween menu" },
        { "2026-10-05", "Fixed shots not killing: ammo spam, knife in hand\nAuto reload between fights, Auto ammo\nHealth bars on ESP now go down\nNew Rewards tab and Triggerbot\nSilent Aim, Aimbot, Ragebot each have their own settings" },
    },
    SaveFolder = "AirDrop Arena",
    Intro = true,
    AlertTries = 20,
    AlertGap = 0.5,
    LoadTimeout = 10,
    RequireTimeout = 5,
    MaxFails = 5,
    FailWindow = 10,
    StatusInterval = 1,
    DefaultRange = 1000,
    RefireGap = 0.15,
    AimRenderPriority = Enum.RenderPriority.Camera.Value + 1,
    FovColor = Color3.fromRGB(232, 160, 76),
    SilentFovColor = Color3.fromRGB(255, 80, 80),
    CombatToggles = { "SilentAim", "Ragebot", "Aimbot", "Triggerbot", "ShowFov", "ShowSilentFov" },
    ConfigFeatures = { "AutoGear", "AutoAmmo", "AutoValuables", "AutoBuffs", "AutoAirDrop", "AutoHeal" },
    RemoteFeatures = { "SilentAim", "Ragebot", "AutoGear", "AutoAmmo", "AutoValuables", "AutoBuffs", "AutoAirDrop", "AutoHeal", "InstantRespawn", "AutoRejoin", "AutoClaim", "AutoOpenBoxes" },
    GcFeatures = { "AutoClaim", "AutoOpenBoxes" },
    GunToggles = { "NoSpread", "NoRecoil", "InstantAds" },
    LootEspToggles = { "LootEspAirDrop", "LootEspCrate", "LootEspItem" },
    GunScanInterval = 8,
    ModProps = { 72, 73, 82 },
    GunSlots = { 1, 2, 4 },
    AmmoBatch = 6,
    ReloadSlack = 0.3,
    MeleePart = 3,
    NoticeProto = 2005,
    HuntSyncPause = 1.5,
    SwitchGap = 1,
    HitForget = 8,
    KillSamples = 20,
    BaseHp = 100,
    AdsSpeed = 1000,
    RespawnGap = 0.5,
    LootRetry = 15,
    StatScanGap = 2,
    LobbyRejoin = 5,
    HealGap = 0.4,
    HealUrgent = 35,
    CurrencyType = 1,
    TriggerRange = 1000,
    GunTypes = { [4] = true, [5] = true },
    ClaimKinds = { "Tasks", "Season", "Online gifts", "Sign-in", "Update gift", "Lottery" },
    GoldId = 1,
    BuffType = 24,
    CodeGap = 0.6,
    ClaimGap = 60,
    BoxIds = { 2001, 2040 },
    BuyAmountMax = 100,
    ItemScan = 400,
    TeleportBehind = 4,
    OpenBatch = 20,
    OpenGap = 0.25,
    GearSlots = {
        [4] = { "Primary", { 1 } },
        [5] = { "Pistol", { 4 } },
        [8] = { "Helmet", { 5 } },
        [9] = { "Armor", { 6 } },
    },
    SlotLabels = {
        MainWeapon1 = "Primary", MainWeapon2 = "Primary", SecondaryWeapon = "Pistol", Melee = "Melee",
        Helmet = "Helmet", BodyArmor = "Armor", Shoe = "Shoes", Gloves = "Gloves",
    },
    LootColors = {
        AirDrop = Color3.fromRGB(255, 80, 80),
        Crate = Color3.fromRGB(80, 170, 255),
        Item = Color3.fromRGB(255, 196, 64),
    },
    FallbackProto = {
        Blaster_ShootReq = 27001,
        DropItem_PickWorldItemReq = 26002,
        Battlefield_DeployReq = 25001,
        Blaster_BulletHitNotify = 27505,
        Battlefield_S2CCustomSyncNotify = 25507,
        Battlefield_EntityDeathNotify = 25508,
    },
    BoneParts = {
        Head = { "Head" },
        Torso = { "UpperTorso", "Torso", "HumanoidRootPart" },
    },
}

PatipanStudio.State = {
    Alive = true,
    Connections = {},
    Halted = {},
    Notices = {},
    Target = nil,
    AimHead = nil,
    AimBody = nil,
    LockPart = nil,
    SoulSince = nil,
    AimEntity = nil,
    Firing = false,
    LastShot = 0,
    Kills = 0,
    LastRespawn = 0,
    Hits = 0,
    Tried = {},
    AirDrops = 0,
    AirDropAt = 0,
    Looted = 0,
    Valuables = 0,
    LastLoot = "-",
}

PatipanStudio.Options = {
    TargetPlayer = false,
    Spectate = false,
    Hunt = false,
    HuntMode = "Behind",
    HuntDistance = 15,
    HuntHeight = 10,
    HuntIdle = 0.6,
    HuntMaxWarp = 0,
    SilentAim = false,
    SilentHitChance = 100,
    SilentHeadChance = 100,
    SilentPriority = "Crosshair",
    SilentFov = 250,
    ShowSilentFov = false,
    SilentMaxDistance = 1000,
    Ragebot = false,
    RageMaxDistance = 1000,
    TargetBots = true,
    AimBone = "Head",
    AimPriority = "Crosshair",
    AimFov = 200,
    ShowFov = false,
    AimMaxDistance = 1000,
    Aimbot = false,
    AimSmooth = 1,
    AimSticky = false,
    Triggerbot = false,
    TriggerDelay = 0,
    TriggerChance = 100,
    InstantRespawn = false,
    RespawnDelay = 0,
    AutoRejoin = false,
    AutoHeal = false,
    HealAt = 70,
    HealMeds = {},
    AutoAmmo = false,
    SmartReload = false,
    ReloadAt = 50,
    NoSpread = false,
    NoRecoil = false,
    InstantAds = false,
    AutoGear = false,
    LootGear = { Primary = true, Pistol = true, Helmet = true, Armor = true, Shoes = true, Gloves = true, Melee = true },
    AutoValuables = false,
    LootCurrency = {},
    LootBuffs = {},
    GearScore = "Damage per second",
    AutoAirDrop = false,
    LootEspAirDrop = false,
    LootEspCrate = false,
    LootEspItem = false,
    LootEspRange = 400,
    SuperSlide = false,
    SlideSpeed = 120,
    Speed = false,
    SpeedValue = 40,
    InfiniteJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 60,
    Fullbright = false,
    CameraFov = false,
    CameraFovValue = 90,
    AntiAfk = false,
    AutoBuffs = false,
    AutoClaim = false,
    ClaimKinds = {},
    AutoOpenBoxes = false,
    OpenBoxList = {},
    BuyBox = "",
    BuyAmount = 1,
    KeepGold = 50000,
    AdminAlert = false,
    AdminHop = false,
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

Util.Request = Resolve(request, http_request, syn and syn.request, http and http.request)
Util.SetClipboard = Resolve(setclipboard, toclipboard)
Util.GetNamecall = Resolve(getnamecallmethod)
Util.GetGc = Resolve(getgc)

PatipanStudio.Caps = setmetatable({}, {
    __index = function(_, name)
        local lib = PatipanStudio.Library
        return lib ~= nil and lib.Compat.Caps[name] == true
    end,
})

---@return string  response body, throws if every transport fails
function Util.HttpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then return body end
    if not Util.Request then error("HttpGet failed: " .. url) end

    local sent, response = pcall(Util.Request, { Url = url, Method = "GET" })
    local code = sent and type(response) == "table" and tonumber(response.StatusCode)
    if code == 200 and type(response.Body) == "string" then return response.Body end
    error(("HttpGet %s: %s"):format(url, sent and ("status " .. tostring(code)) or tostring(response)))
end

---@param detail any  logged with context, the player only sees text
function Util.Alert(text, detail)
    warn("[AirDropArena] menu:", detail or text)
    task.spawn(function()
        for _ = 1, PatipanStudio.Config.AlertTries do
            local shown = pcall(StarterGui.SetCore, StarterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 })
            if shown then return end
            task.wait(PatipanStudio.Config.AlertGap)
        end
    end)
end

---@return table?  the UI library, nil once the player was told why
function Util.LoadLibrary(url)
    local fetched, source = pcall(Util.HttpGet, url)
    if not (fetched and type(source) == "string" and source:sub(-64):find("return Library%s*$")) then
        Util.Alert("Could not download the menu. Check your connection and run it again.", fetched and ("bad body, " .. #tostring(source) .. " bytes") or source)
        return nil
    end

    local chunk, compileErr = loadstring(source)
    if type(chunk) ~= "function" then
        Util.Alert("The menu failed to load on this executor: " .. tostring(compileErr))
        return nil
    end
    local ran, lib = pcall(chunk)
    if not ran or type(lib) ~= "table" then
        Util.Alert("The menu failed to load on this executor: " .. tostring(lib))
        return nil
    end
    return lib
end

---@return boolean  false after a warning with context
function Util.Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[AirDropArena] " .. label .. ":", err) end
    return ok
end

function Util.Copy(text)
    if not Util.SetClipboard then return false end
    Util.SetClipboard(text)
    return true
end

---@param gui Instance  parented to gethui, then CoreGui, then PlayerGui
function Util.Mount(gui)
    local ok, hui = pcall(gethui)
    if ok and typeof(hui) == "Instance" and pcall(function() gui.Parent = hui end) then return end
    if pcall(function() gui.Parent = game:GetService("CoreGui") end) then return end
    gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", PatipanStudio.Config.LoadTimeout)
end

---@return ScreenGui  full-screen layer for the FOV ring, made on first use
function Util.Screen()
    if Util.Overlay and Util.Overlay.Parent then return Util.Overlay end
    local screen = Instance.new("ScreenGui")
    screen.Name, screen.ResetOnSpawn, screen.IgnoreGuiInset = "PatipanStudioAirDrop", false, true
    Util.Mount(screen)
    Util.Overlay = screen
    return screen
end

function PatipanStudio:Connect(signal, handler)
    local conn = signal:Connect(handler)
    table.insert(self.State.Connections, conn)
    return conn
end

PatipanStudio.GameLib = { Missing = {} }
local GameLib = PatipanStudio.GameLib

---@return boolean, any  retried from an identity-2 thread, only when the executor really switches
function GameLib.RequireAsGame(module)
    local finished, ok, loaded = false, false, nil
    task.spawn(function()
        pcall(setthreadidentity, 2)
        local read, identity = pcall(getthreadidentity)
        if read and identity == 2 then ok, loaded = pcall(require, module) end
        finished = true
    end)
    local deadline = osClock() + PatipanStudio.Config.RequireTimeout
    repeat
        if finished then break end
        task.wait()
    until osClock() > deadline
    return ok, loaded
end

---@return any  nil when this executor can't load it (never throws)
function GameLib.Require(module)
    if not (module and module:IsA("ModuleScript")) then return nil end
    local ok, loaded = pcall(require, module)
    if ok then return loaded end
    local again, retried = GameLib.RequireAsGame(module)
    if again then return retried end

    GameLib.Missing[module.Name] = true
    warn("[AirDropArena] require " .. module.Name .. ":", loaded)
    return nil
end

---@param root Instance?  expected parent, the rest of ReplicatedStorage is searched when it moved
---@return Instance?       nil after a warning that names it
function GameLib.Find(root, name, class)
    local found = root and root:FindFirstChild(name, true)
    if not (found and found:IsA(class)) then found = ReplicatedStorage:FindFirstChild(name, true) end
    if found and found:IsA(class) then return found end
    GameLib.Missing[name] = "Absent"
    warn("[AirDropArena] " .. class .. " " .. name .. " not found, features that need it are blocked")
    return nil
end

do
    local timeout = PatipanStudio.Config.LoadTimeout
    local remotes = ReplicatedStorage:WaitForChild("RemoteEvent", timeout)
    local scripts = ReplicatedStorage:WaitForChild("Scripts", timeout)
    GameLib.Main = remotes and remotes:WaitForChild("Main", timeout) or GameLib.Find(remotes, "Main", "RemoteEvent")
    GameLib.ProtoId = GameLib.Require(GameLib.Find(scripts, "ProtoId", "ModuleScript")) or {}
    GameLib.Configs = GameLib.Require(GameLib.Find(scripts, "ConfigManager", "ModuleScript")) or {}
    GameLib.BagEnum = GameLib.Require(scripts and scripts:FindFirstChild("BagEnum", true))
    local enums = GameLib.Require(scripts and scripts:FindFirstChild("CustomEnum", true))
    GameLib.TaskState = type(enums) == "table" and type(enums.TaskState) == "table" and enums.TaskState or { done = 4 }
    GameLib.AdminIds = GameLib.Require(scripts and scripts:FindFirstChild("AdminConst", true))
end

PatipanStudio.Proto = setmetatable({}, {
    __index = function(self, name)
        local id = GameLib.ProtoId[name] or PatipanStudio.Config.FallbackProto[name]
        rawset(self, name, id)
        return id
    end,
})

PatipanStudio.ItemNames = setmetatable({}, {
    __index = function(self, itemId)
        local items = GameLib.Configs.ItemConfig
        local ok, cfg = pcall(function() return items:GetItemConfigById(itemId) end)
        local name = ok and type(cfg) == "table" and (cfg.name or cfg.Name) or tostring(itemId)
        rawset(self, itemId, tostring(name))
        return self[itemId]
    end,
})

PatipanStudio.Net = {}

---@param payload table  proto argument table
function PatipanStudio.Net.Send(name, payload)
    local id = PatipanStudio.Proto[name]
    if not (id and GameLib.Main) then return false end
    GameLib.Main:FireServer({ id, payload })
    return true
end

PatipanStudio.Player = {}

function PatipanStudio.Player.Root()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function PatipanStudio.Player.Humanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function PatipanStudio.Player.EntityId()
    local char = LocalPlayer.Character
    return char and char:GetAttribute("EntityId") or LocalPlayer.UserId
end

function PatipanStudio.Player.InBattle()
    local char = LocalPlayer.Character
    return char ~= nil and char:GetAttribute("EntityState") == 1
end

---@return boolean  true while dead or spectating a match
function PatipanStudio.Player.IsSoul()
    local char = LocalPlayer.Character
    local state = char and char:GetAttribute("EntityState")
    return state == 2 or state == 4
end

PatipanStudio.Target = {}

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
local losFilter = table.create(3)

---@param withBots boolean?  include bots even when Target Bots is off (ESP)
---@return Model[]  every character and bot that could be shot
function PatipanStudio.Target.Candidates(withBots)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then table.insert(list, player.Character) end
    end
    local fx = (withBots or PatipanStudio.Options.TargetBots) and Workspace:FindFirstChild("Fx")
    if fx then
        for _, model in ipairs(fx:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("EntityId") then list[#list + 1] = model end
        end
    end
    return list
end

function PatipanStudio.Target.IsEnemy(model)
    if model == LocalPlayer.Character or not model:GetAttribute("EntityId") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local state = model:GetAttribute("EntityState")
    if state ~= nil and state ~= 1 then return false end

    return not PatipanStudio.Target.SameTeam(model)
end

function PatipanStudio.Target.SameTeam(model)
    local mine = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("TeamId")
    return mine ~= nil and mine ~= -1 and mine == model:GetAttribute("TeamId")
end

function PatipanStudio.Target.Part(model, bone)
    for _, name in ipairs(PatipanStudio.Config.BoneParts[bone] or PatipanStudio.Config.BoneParts.Head) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return model:FindFirstChild("HumanoidRootPart")
end

function PatipanStudio.Target.Visible(from, model, point)
    losFilter[1], losFilter[2], losFilter[3] = LocalPlayer.Character, model, Workspace.CurrentCamera
    losParams.FilterDescendantsInstances = losFilter
    return Workspace:Raycast(from, point - from, losParams) == nil
end

PatipanStudio.Target.Profiles = { Silent = {}, Rage = {}, Aim = {} }

---@param kind string  "Silent", "Rage" or "Aim"; each aim system keeps its own settings
---@return table        { Fov, Bone, Priority, Range }, Fov 0 = no FOV limit
function PatipanStudio.Target.Profile(kind)
    local opts, profile = PatipanStudio.Options, PatipanStudio.Target.Profiles[kind]
    if kind == "Silent" then
        profile.Fov, profile.Bone, profile.Priority, profile.Range = opts.SilentFov, "Head", opts.SilentPriority, opts.SilentMaxDistance
    elseif kind == "Rage" then
        profile.Fov, profile.Bone, profile.Priority, profile.Range = 0, "Head", "Distance", opts.RageMaxDistance
    else
        profile.Fov, profile.Bone, profile.Priority, profile.Range = opts.AimFov, opts.AimBone, opts.AimPriority, opts.AimMaxDistance
    end
    return profile
end

---@return BasePart?, number?, boolean?  aim part, screen distance, on screen; nil when out of range, FOV or sight
function PatipanStudio.Target.Check(model, profile, cam, origin, center)
    if not PatipanStudio.Target.IsEnemy(model) then return nil end
    local part = PatipanStudio.Target.Part(model, profile.Bone)
    if not part or (part.Position - origin).Magnitude > profile.Range then return nil end
    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
    local screenDist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
    if profile.Fov > 0 and (not onScreen or screenDist > profile.Fov) then return nil end
    if not PatipanStudio.Target.Visible(origin, model, part.Position) then return nil end
    return part, screenDist, onScreen
end

---@return Model?, BasePart?
function PatipanStudio.Target.Pick(profile)
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local center = cam.ViewportSize / 2
    local best, bestPart, bestScore

    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        local part, screenDist, onScreen = PatipanStudio.Target.Check(model, profile, cam, origin, center)
        if not part then continue end
        local score = (part.Position - origin).Magnitude
        if profile.Priority == "Crosshair" then
            score = onScreen and screenDist or 1e6 + score
        elseif profile.Priority == "Health" then
            local hum = model:FindFirstChildOfClass("Humanoid")
            score = hum and hum.Health or score
        end
        if not bestScore or score < bestScore then
            best, bestPart, bestScore = model, part, score
        end
    end
    return best, bestPart
end

---@param keep Model?  previous lock, kept while still valid when Sticky is on
---@return BasePart?
function PatipanStudio.Target.Lock(keep)
    local profile = PatipanStudio.Target.Profile("Aim")
    if keep and PatipanStudio.Options.AimSticky then
        local cam = Workspace.CurrentCamera
        local part = PatipanStudio.Target.Check(keep, profile, cam, cam.CFrame.Position, cam.ViewportSize / 2)
        if part then return part end
    end
    local _, part = PatipanStudio.Target.Pick(profile)
    return part
end

function PatipanStudio.Target.Label(model)
    local player = Players:GetPlayerFromCharacter(model)
    return player and player.DisplayName or ("[Bot] " .. model.Name)
end

PatipanStudio.Combat = { Unhook = nil, PressedAt = 0, Want = false, Refire = false, Pumping = false, Circles = {}, Parts = {}, ReloadedAt = 0, SwitchedAt = 0, TriggerSeen = nil, TriggerSince = 0, TriggerRoll = false }

---@param shot table  27001 payload, edited in place; must not namecall
function PatipanStudio.Combat.Rewrite(shot)
    local state, opts = PatipanStudio.State, PatipanStudio.Options
    local entityId = state.AimEntity
    if not entityId or math.random(100) > opts.SilentHitChance then return end
    local part = (math.random(100) <= opts.SilentHeadChance and state.AimHead) or state.AimBody or state.AimHead
    if not (part and part.Parent) then return end
    local dirs = shot.rayDirections
    if type(dirs) ~= "table" or #dirs == 0 then return end

    local origin = typeof(shot.origin) == "CFrame" and shot.origin.Position or Workspace.CurrentCamera.CFrame.Position
    local offset = part.Position - origin
    local dist = offset.Magnitude
    local range = typeof(dirs[1]) == "Vector3" and dirs[1].Magnitude or PatipanStudio.Config.DefaultRange
    if dist > range or dist < 1e-3 then return end

    local unit = offset.Unit
    local results = table.create(#dirs)
    for index, dir in ipairs(dirs) do
        dirs[index] = unit * (typeof(dir) == "Vector3" and dir.Magnitude or range)
        results[index] = { instance = part, normal = -unit, distance = dist, taggedEntityId = entityId, isTeammate = false }
    end
    shot.rayResults = results
end

function PatipanStudio.Combat.Aiming()
    local opts = PatipanStudio.Options
    return opts.SilentAim or opts.Ragebot
end

function PatipanStudio.Combat.InstallHook()
    local combat = PatipanStudio.Combat
    if combat.Unhook or not GameLib.Main or not PatipanStudio.Caps.Namecall then return end
    local main, getMethod = GameLib.Main, Util.GetNamecall
    local old
    local ok, original, unhook = pcall(PatipanStudio.Library.Compat.HookMeta, game, "__namecall", function(self, ...)
        if self == main and PatipanStudio.State.Alive and PatipanStudio.Combat.Aiming() and getMethod() == "FireServer" then
            local packet = ...
            if type(packet) == "table" and packet[1] == PatipanStudio.Proto.Blaster_ShootReq and type(packet[2]) == "table" then
                PatipanStudio.State.LastShot = osClock()
                local rewritten, err = pcall(PatipanStudio.Combat.Rewrite, packet[2])
                if not rewritten then warn("[AirDropArena] rewrite:", err) end
            end
        end
        return old(self, ...)
    end)
    if not (ok and type(original) == "function") then
        warn("[AirDropArena] shot hook:", ok and "executor refused the hook" or original)
        return
    end
    old, combat.Unhook = original, unhook
end

function PatipanStudio.Combat.RemoveHook()
    local unhook = PatipanStudio.Combat.Unhook
    if not unhook then return end
    PatipanStudio.Combat.Unhook = nil
    Util.Try("shot unhook", unhook)
end

function PatipanStudio.Combat.SyncHook()
    if PatipanStudio.Combat.Aiming() then
        PatipanStudio.Combat.InstallHook()
    else
        PatipanStudio.Combat.RemoveHook()
    end
end

---@return table?  the game's input behaviour for your character (BeginFire/EndFire)
function PatipanStudio.Combat.Behavior()
    local combat = PatipanStudio.Combat
    if combat.Input and rawget(combat.Input, "owner") then return combat.Input end
    combat.Input = nil
    if not PatipanStudio.Caps.Gc or osClock() - (combat.LastScan or 0) < PatipanStudio.Config.StatScanGap then return nil end
    combat.LastScan = osClock()
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and rawget(entry, "owner") and type(entry.BeginFire) == "function" and type(entry.FastKnife) == "function" then
            combat.Input = entry
            return entry
        end
    end
    return nil
end

---@return boolean  true once the press reached the game; a timed-out deferred call still lands later
function PatipanStudio.Combat.Press(down)
    local input = PatipanStudio.Combat.Behavior()
    local sent, err = false, nil
    if input then
        sent, err = pcall(PatipanStudio.Library.Compat.Call, down and input.BeginFire or input.EndFire, input)
        sent = sent or tostring(err):find("timed out", 1, true) ~= nil
    end
    if not sent then
        local center = Workspace.CurrentCamera.ViewportSize / 2
        sent = pcall(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager, center.X, center.Y, 0, down, game, 0)
    end
    if not sent then return false end

    PatipanStudio.State.Firing = down
    if down then PatipanStudio.Combat.PressedAt = osClock() end
    return true
end

function PatipanStudio.Combat.Pending()
    local combat, firing = PatipanStudio.Combat, PatipanStudio.State.Firing
    return combat.Want ~= firing or (combat.Refire and firing)
end

function PatipanStudio.Combat.PressNext()
    local combat, firing = PatipanStudio.Combat, PatipanStudio.State.Firing
    local refire = combat.Refire and firing
    combat.Refire = false
    local sent = false
    if refire or combat.Want ~= firing then sent = PatipanStudio.Combat.Press(not refire and combat.Want) end
    combat.Pumping = false

    if sent and not refire and PatipanStudio.Combat.Pending() then PatipanStudio.Combat.Pump() end
end

function PatipanStudio.Combat.Pump()
    local combat = PatipanStudio.Combat
    if combat.Pumping then return end
    combat.Pumping = true
    task.defer(PatipanStudio.Combat.PressNext)
end

---@param want boolean  keeps auto guns held and re-clicks semi-auto ones
function PatipanStudio.Combat.Fire(want)
    local combat, state = PatipanStudio.Combat, PatipanStudio.State
    combat.Want = want
    if want and state.Firing and not combat.Pumping then
        local now, gap = osClock(), PatipanStudio.Config.RefireGap
        combat.Refire = now - combat.PressedAt > gap and now - state.LastShot > gap
    end
    if PatipanStudio.Combat.Pending() then PatipanStudio.Combat.Pump() end
end

---@return table  { Drawing = circle } or a Gui ring when the executor has no Drawing
function PatipanStudio.Combat.NewCircle(color)
    if PatipanStudio.Caps.Drawing then
        local circle = Drawing.new("Circle")
        circle.Thickness, circle.NumSides, circle.Filled, circle.Color = 1.5, 64, false, color
        return { Drawing = circle }
    end

    local ring = Instance.new("Frame")
    ring.AnchorPoint, ring.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
    local stroke = Instance.new("UIStroke")
    stroke.Thickness, stroke.Color = 1.5, color
    stroke.Parent = ring
    ring.Parent = Util.Screen()
    return { Ring = ring }
end

function PatipanStudio.Combat.UpdateCircles()
    local opts, config = PatipanStudio.Options, PatipanStudio.Config
    PatipanStudio.Combat.UpdateCircle("Aim", opts.ShowFov, opts.AimFov, config.FovColor)
    PatipanStudio.Combat.UpdateCircle("Silent", opts.ShowSilentFov, opts.SilentFov, config.SilentFovColor)
end

function PatipanStudio.Combat.UpdateCircle(key, show, radius, color)
    local circles = PatipanStudio.Combat.Circles
    local circle = circles[key]
    if not circle then
        if not show then return end
        circle = PatipanStudio.Combat.NewCircle(color)
        circles[key] = circle
    end

    local center = Workspace.CurrentCamera.ViewportSize / 2
    if circle.Drawing then
        circle.Drawing.Visible, circle.Drawing.Position, circle.Drawing.Radius = show, center, radius
        return
    end
    circle.Ring.Visible = show
    circle.Ring.Position = UDim2.fromOffset(center.X, center.Y)
    circle.Ring.Size = UDim2.fromOffset(radius * 2, radius * 2)
end

local triggerParams = RaycastParams.new()
triggerParams.FilterType = Enum.RaycastFilterType.Exclude

---@return boolean  true while the crosshair sits on an enemy long enough to shoot
function PatipanStudio.Combat.TriggerWant()
    local combat, opts = PatipanStudio.Combat, PatipanStudio.Options
    local cam = Workspace.CurrentCamera
    triggerParams.FilterDescendantsInstances = { LocalPlayer.Character, cam }
    local hit = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * PatipanStudio.Config.TriggerRange, triggerParams)
    local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
    while model and not model:GetAttribute("EntityId") do
        model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
    end
    if not (model and PatipanStudio.Target.IsEnemy(model)) then
        combat.TriggerSeen = nil
        return false
    end
    if combat.TriggerSeen ~= model then
        combat.TriggerSeen, combat.TriggerSince = model, osClock()
        combat.TriggerRoll = math.random(100) <= opts.TriggerChance
    end
    return combat.TriggerRoll and osClock() - combat.TriggerSince >= opts.TriggerDelay / 1000
end

---@return table  equip part -> live gun object; stale copies lose their blaster field
function PatipanStudio.Combat.ScanGuns()
    local combat = PatipanStudio.Combat
    for part, gun in pairs(combat.Parts) do
        if rawget(gun, "blaster") == nil then combat.Parts[part] = nil end
    end
    local char = LocalPlayer.Character
    local using = char and char:GetAttribute("UseEPos")
    if not using or combat.Parts[using] or not PatipanStudio.Caps.Gc then return combat.Parts end
    for _, entry in ipairs(Util.GetGc(true)) do
        local part = type(entry) == "table" and rawget(entry, "islocalplayer") == true and rawget(entry, "blaster") ~= nil and rawget(entry, "blasterPart")
        if part then combat.Parts[part] = entry end
    end
    return combat.Parts
end

---@return table?  the gun in your hands right now
function PatipanStudio.Combat.HeldGun()
    local char = LocalPlayer.Character
    local using = char and char:GetAttribute("UseEPos")
    local gun = using and PatipanStudio.Combat.Parts[using]
    return gun and rawget(gun, "blaster") ~= nil and gun or nil
end

function PatipanStudio.Combat.GunStep()
    local opts = PatipanStudio.Options
    if not (PatipanStudio.Combat.Aiming() or opts.Triggerbot or opts.SmartReload) then return end
    if not PatipanStudio.Player.InBattle() then return end
    PatipanStudio.Combat.ScanGuns()
    if PatipanStudio.Combat.Aiming() then PatipanStudio.Combat.DrawGun() end
    if opts.SmartReload then PatipanStudio.Combat.Reload() end
end

---@return boolean  switched from the knife back to a gun so aim features can hit at range
function PatipanStudio.Combat.DrawGun()
    local combat = PatipanStudio.Combat
    local char = LocalPlayer.Character
    if not char or char:GetAttribute("UseEPos") ~= PatipanStudio.Config.MeleePart then return false end
    if osClock() - combat.SwitchedAt < PatipanStudio.Config.SwitchGap then return false end
    local input = PatipanStudio.Combat.Behavior()
    if not (input and type(input.SwitchBlaster) == "function") then return false end
    for _, part in ipairs(PatipanStudio.Config.GunSlots) do
        local worn = char:GetAttribute("EPos_" .. part)
        if type(worn) ~= "string" or worn:match("^I_(%d+)") == "0" then continue end
        combat.SwitchedAt = osClock()
        local ok, err = pcall(PatipanStudio.Library.Compat.Call, input.SwitchBlaster, input, part)
        if not ok and not tostring(err):find("timed out", 1, true) then warn("[AirDropArena] switch:", err) end
        return true
    end
    return false
end

---@return boolean  a reload was started; only between fights and below the set magazine level
function PatipanStudio.Combat.Reload()
    local combat, opts = PatipanStudio.Combat, PatipanStudio.Options
    local gun = PatipanStudio.Combat.HeldGun()
    local map = gun and rawget(gun, "propMap")
    local ammo, size = gun and rawget(gun, "ammo"), map and tonumber(map[71])
    if not (type(ammo) == "number" and size and size > 1) then return false end
    if ammo >= size or ammo / size * 100 > opts.ReloadAt and ammo > 0 then return false end
    if PatipanStudio.State.Target and ammo > 0 then return false end
    if osClock() - combat.ReloadedAt < (tonumber(map[78]) or 2) + PatipanStudio.Config.ReloadSlack then return false end
    local input = PatipanStudio.Combat.Behavior()
    if not (input and type(input.BeginReload) == "function") then return false end
    combat.ReloadedAt = osClock()
    local ok, err = pcall(PatipanStudio.Library.Compat.Call, input.BeginReload, input)
    if not ok and not tostring(err):find("timed out", 1, true) then warn("[AirDropArena] reload:", err) end
    return true
end

function PatipanStudio.Combat.Clear()
    local state = PatipanStudio.State
    state.Target, state.AimHead, state.AimBody, state.AimEntity, state.LockPart = nil, nil, nil, nil, nil
end

function PatipanStudio.Combat.Step()
    local opts, state = PatipanStudio.Options, PatipanStudio.State
    PatipanStudio.Combat.UpdateCircles()

    local active = PatipanStudio.Combat.Aiming() or opts.Aimbot or opts.Triggerbot
    if not (active and PatipanStudio.Player.InBattle()) then
        PatipanStudio.Combat.Clear()
        PatipanStudio.Combat.Fire(false)
        return
    end

    local target
    if opts.Ragebot then
        target = PatipanStudio.Target.Pick(PatipanStudio.Target.Profile("Rage"))
    elseif opts.SilentAim then
        target = PatipanStudio.Target.Pick(PatipanStudio.Target.Profile("Silent"))
    end
    state.AimHead = target and PatipanStudio.Target.Part(target, "Head")
    state.AimBody = target and PatipanStudio.Target.Part(target, "Torso")
    state.AimEntity = target and target:GetAttribute("EntityId")

    local locked = state.LockPart and state.LockPart.Parent
    state.LockPart = opts.Aimbot and PatipanStudio.Target.Lock(locked) or nil
    state.Target = target or (state.LockPart and state.LockPart.Parent)

    local trigger = opts.Triggerbot and PatipanStudio.Combat.TriggerWant()
    local held = PatipanStudio.Combat.HeldGun()
    local empty = held ~= nil and rawget(held, "ammo") == 0
    PatipanStudio.Combat.Fire(not empty and ((target ~= nil and opts.Ragebot) or trigger == true))
end

function PatipanStudio.Combat.OnServer(packet)
    if type(packet) ~= "table" or type(packet[2]) ~= "table" then return end
    local id, body = packet[1], packet[2]
    if id == PatipanStudio.Proto.Blaster_BulletHitNotify then
        if body.killerEntityId ~= PatipanStudio.Player.EntityId() then return end
        PatipanStudio.State.Hits += 1
        PatipanStudio.Damage.OnHit(body.targetEntityId)
    elseif id == PatipanStudio.Proto.Battlefield_EntityDeathNotify then
        local mine = body.killerEntityId == PatipanStudio.Player.EntityId()
        if mine then PatipanStudio.State.Kills += 1 end
        PatipanStudio.Damage.OnDeath(body.entityId, mine)
    elseif id == PatipanStudio.Config.NoticeProto then
        PatipanStudio.Hunt.OnNotice(body.context)
    elseif id == PatipanStudio.Proto.Battlefield_S2CCustomSyncNotify then
        PatipanStudio.Loot.OnSync(body)
    end
end

function PatipanStudio.Combat.LockCamera()
    local part = PatipanStudio.State.LockPart
    if not (PatipanStudio.Options.Aimbot and part and part.Parent) then return end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local want = (part.Position - origin).Unit
    local smooth = math.max(PatipanStudio.Options.AimSmooth, 1)
    local look = smooth <= 1 and want or cam.CFrame.LookVector:Lerp(want, 1 / smooth).Unit
    cam.CFrame = cframeLookAt(origin, origin + look)
end

function PatipanStudio.Combat.Rest()
    PatipanStudio.Combat.Clear()
    PatipanStudio.Combat.Fire(false)
    PatipanStudio.Combat.UpdateCircles()
end

function PatipanStudio.Combat.Start()
    RunService:BindToRenderStep("PatipanStudioAim", PatipanStudio.Config.AimRenderPriority, PatipanStudio.Combat.LockCamera)
    PatipanStudio:Connect(RunService.Heartbeat, function()
        local ok, err = pcall(PatipanStudio.Combat.Step)
        if ok then
            PatipanStudio.Faults.Clear("Combat")
        else
            PatipanStudio.Faults.Report("Combat", err, PatipanStudio.Config.CombatToggles, PatipanStudio.Combat.Rest)
        end
    end)
    if GameLib.Main then PatipanStudio:Connect(GameLib.Main.OnClientEvent, PatipanStudio.Combat.OnServer) end
end

function PatipanStudio.Combat.Unload()
    PatipanStudio.Combat.Fire(false)
    PatipanStudio.Combat.RemoveHook()
    pcall(RunService.UnbindFromRenderStep, RunService, "PatipanStudioAim")
    for key, circle in pairs(PatipanStudio.Combat.Circles) do
        PatipanStudio.Combat.Circles[key] = nil
        if circle.Drawing then
            pcall(function() circle.Drawing:Remove() end)
        else
            circle.Ring:Destroy()
        end
    end
end

function PatipanStudio.Combat.GetStatus()
    local state = PatipanStudio.State
    local target = state.Target and PatipanStudio.Target.Label(state.Target) or "none"
    return string.format("Target: %s | Hits %d | Kills %d | Guns %d",
        target, state.Hits, state.Kills, PatipanStudio.Guns.Count)
end

PatipanStudio.Guns = {
    Known = setmetatable({}, { __mode = "k" }),
    Saved = setmetatable({}, { __mode = "k" }),
    Count = 0,
    LastScan = 0,
    Signature = "",
}

function PatipanStudio.Guns.Wanted()
    local opts = PatipanStudio.Options
    return opts.NoSpread or opts.NoRecoil or opts.InstantAds
end

function PatipanStudio.Guns.Scan()
    if not PatipanStudio.Caps.Gc then return end
    local known, count = PatipanStudio.Guns.Known, 0
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and rawget(entry, "islocalplayer") == true and type(rawget(entry, "propMap")) == "table" then
            known[entry] = true
            count += 1
        end
    end
    PatipanStudio.Guns.Count = count
    PatipanStudio.Guns.LastScan = osClock()
end

---@return string  changes whenever the held loadout changes
function PatipanStudio.Guns.LoadoutSignature()
    local char = LocalPlayer.Character
    local folder = char and char:FindFirstChild("Blaster")
    if not folder then return "" end
    local names = {}
    for _, child in ipairs(folder:GetChildren()) do names[#names + 1] = child.Name end
    return table.concat(names, "|")
end

---@return number?  nil keeps the original value
function PatipanStudio.Guns.Desired(id, base)
    local opts = PatipanStudio.Options
    if (id == 72 or id == 73) and opts.NoSpread then return 0 end
    if id == 82 and opts.InstantAds then return PatipanStudio.Config.AdsSpeed end
    return nil
end

local function NoRecoilRate() return 0 end
local function NoRecoil() end

function PatipanStudio.Guns.ApplyRecoil(blaster, saved)
    if PatipanStudio.Options.NoRecoil then
        if saved.Recoil then return end
        saved.Recoil = { rawget(blaster, "GetRecoilRate") or false, rawget(blaster, "Recoil") or false }
        rawset(blaster, "GetRecoilRate", NoRecoilRate)
        rawset(blaster, "Recoil", NoRecoil)
    elseif saved.Recoil then
        rawset(blaster, "GetRecoilRate", saved.Recoil[1] or nil)
        rawset(blaster, "Recoil", saved.Recoil[2] or nil)
        saved.Recoil = nil
    end
end

function PatipanStudio.Guns.Apply()
    local savedAll = PatipanStudio.Guns.Saved
    for blaster in pairs(PatipanStudio.Guns.Known) do
        local map = rawget(blaster, "propMap")
        if type(map) ~= "table" then continue end
        local saved = savedAll[blaster] or {}
        savedAll[blaster] = saved

        for _, id in ipairs(PatipanStudio.Config.ModProps) do
            local base = saved[id] or map[id]
            if type(base) ~= "number" then continue end
            local want = PatipanStudio.Guns.Desired(id, base)
            if want then
                saved[id], map[id] = base, want
            elseif saved[id] then
                map[id], saved[id] = saved[id], nil
            end
        end
        PatipanStudio.Guns.ApplyRecoil(blaster, saved)
    end
end

function PatipanStudio.Guns.Step()
    if not PatipanStudio.Guns.Wanted() and next(PatipanStudio.Guns.Saved) == nil then return end
    local signature = PatipanStudio.Guns.LoadoutSignature()
    if PatipanStudio.Guns.Wanted() and (signature ~= PatipanStudio.Guns.Signature or osClock() - PatipanStudio.Guns.LastScan > PatipanStudio.Config.GunScanInterval) then
        PatipanStudio.Guns.Signature = signature
        PatipanStudio.Guns.Scan()
    end
    PatipanStudio.Guns.Apply()
end

function PatipanStudio.Guns.Restore()
    for _, key in ipairs(PatipanStudio.Config.GunToggles) do
        PatipanStudio.Options[key] = false
    end
    PatipanStudio.Guns.Apply()
    table.clear(PatipanStudio.Guns.Saved)
end

PatipanStudio.Loot = { Marks = {} }

function PatipanStudio.Loot.Folder()
    return Workspace:FindFirstChild("DropItemFloder")
end

---@return string?  "AirDrop", "Crate" or "Item"
function PatipanStudio.Loot.Kind(model)
    if model.Name == "AirDrop" or model:GetAttribute("AirDropClientModel") then return "AirDrop" end
    local bagType = model:GetAttribute("BagType")
    if bagType == 20000 then return "Crate" end
    if bagType == 10000 or model:GetAttribute("ItemId") then return "Item" end
    return nil
end

function PatipanStudio.Loot.Label(model, kind)
    if kind == "Item" then
        local id = model:GetAttribute("ItemId")
        return id and PatipanStudio.ItemNames[id] or "Item"
    end
    return kind == "AirDrop" and "Air Drop" or "Crate"
end

---@return table?  the game's drop manager, holds every bag the client knows about
function PatipanStudio.Loot.Manager()
    local cached = PatipanStudio.Loot.DropManager
    if cached or not PatipanStudio.Caps.Gc then return cached end
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and rawget(entry, "dropItems") and type(rawget(entry, "BagController")) == "table" then
            PatipanStudio.Loot.DropManager = entry
            return entry
        end
    end
    return nil
end

function PatipanStudio.Loot.ItemConfig(configId)
    local items = GameLib.Configs.ItemConfig
    if not items then return nil end
    local ok, cfg = pcall(items.GetItemConfigById, items, configId)
    return ok and type(cfg) == "table" and cfg or nil
end

---@return table  item type -> { label, { equip slots } }, read from the game so new gear slots show up by themselves
function PatipanStudio.Loot.Slots()
    if PatipanStudio.Loot.SlotMap then return PatipanStudio.Loot.SlotMap end
    local enum = GameLib.BagEnum
    local names, types = enum and enum.EquipMentPosMap, enum and enum.EquipMentPosToItemTypeMap
    if type(names) ~= "table" or type(types) ~= "table" then
        PatipanStudio.Loot.SlotMap = PatipanStudio.Config.GearSlots
        return PatipanStudio.Loot.SlotMap
    end
    local map = {}
    for name, pos in pairs(names) do
        local itemType = type(pos) == "number" and types[pos]
        if not itemType or name == "Min" or name == "Max" then continue end
        local entry = map[itemType] or { PatipanStudio.Config.SlotLabels[name] or name, {} }
        table.insert(entry[2], pos)
        map[itemType] = entry
    end
    PatipanStudio.Loot.SlotMap = map
    return map
end

---@return string[]  gear labels for the loot filter
function PatipanStudio.Loot.SlotLabels()
    local labels, seen = {}, {}
    for _, entry in pairs(PatipanStudio.Loot.Slots()) do
        if not seen[entry[1]] then
            seen[entry[1]] = true
            labels[#labels + 1] = entry[1]
        end
    end
    table.sort(labels)
    return labels
end

PatipanStudio.Loot.GunStats = {}

---@return table  { damage, rpm, rays, ammo item ids } from the game's weapon table, nil for non-guns
function PatipanStudio.Loot.Gun(itemId)
    local cache = PatipanStudio.Loot.GunStats
    if cache[itemId] ~= nil then return cache[itemId] or nil end
    local blasters = GameLib.Configs.BlasterConfig
    local ok, cfg = pcall(function() return blasters:GetBlasterConfigById(itemId) end)
    local att = ok and type(cfg) == "table" and cfg.attMap
    local ammo = ok and type(cfg) == "table" and type(cfg.bulletIds) == "table" and cfg.bulletIds or {}
    local stats = type(att) == "table" and tonumber(att[77]) and { tonumber(att[77]), tonumber(att[70]) or 60, tonumber(att[74]) or 1, ammo } or false
    cache[itemId] = stats
    return stats or nil
end

---@return number  higher = better within one item type
function PatipanStudio.Loot.Score(cfg)
    local mode = PatipanStudio.Options.GearScore
    local gun = mode ~= "Rarity" and PatipanStudio.Config.GunTypes[cfg.type] and PatipanStudio.Loot.Gun(cfg.id)
    if gun then
        local perShot = gun[1] * gun[3]
        return mode == "Damage per shot" and perShot or perShot * gun[2] / 60
    end
    return (cfg.quality or 0) * 1e7 + (cfg.value or 0)
end

---@return string?  buff family ("Atk", "FireRate" ...) of a buff item name
function PatipanStudio.Loot.BuffKind(name)
    return type(name) == "string" and name:match("^([%a]+)%+") or nil
end

---@return string[], string[]  currency names, buff families; read from the game's item table
function PatipanStudio.Loot.Kinds()
    if PatipanStudio.Loot.KindLists then return table.unpack(PatipanStudio.Loot.KindLists) end
    local currencies, buffs, seen = {}, {}, {}
    for id = 1, PatipanStudio.Config.ItemScan do
        local cfg = PatipanStudio.Loot.ItemConfig(id)
        local name = cfg and cfg.name
        if type(name) ~= "string" or seen[name] or name:find("[\128-\255]") then continue end
        if cfg.type == PatipanStudio.Config.CurrencyType then
            seen[name] = true
            currencies[#currencies + 1] = name
        elseif cfg.type == PatipanStudio.Config.BuffType then
            local kind = PatipanStudio.Loot.BuffKind(name)
            if kind and not seen[kind] then
                seen[kind] = true
                buffs[#buffs + 1] = kind
            end
        end
    end
    PatipanStudio.Loot.KindLists = { currencies, buffs }
    return currencies, buffs
end

---@param slots number[]  equip slots that take this item type
---@return number           score of the weakest item worn in them, 0 when one is empty, huge when you have none of these slots
function PatipanStudio.Loot.WornScore(slots)
    local char = LocalPlayer.Character
    local weakest = math.huge
    for _, slot in ipairs(slots) do
        local worn = char and char:GetAttribute("EPos_" .. slot)
        if worn == nil then continue end
        local id = type(worn) == "string" and tonumber(worn:match("^I_(%d+)"))
        local cfg = id and id > 0 and PatipanStudio.Loot.ItemConfig(id)
        weakest = math.min(weakest, cfg and PatipanStudio.Loot.Score(cfg) or 0)
    end
    return weakest
end

---@return table  item ids lying in any bag on the map
function PatipanStudio.Loot.OnMap(bags)
    local present = {}
    for _, bag in pairs(bags) do
        for _, item in pairs(type(bag.itemMap) == "table" and bag.itemMap or {}) do present[item.configId] = true end
    end
    return present
end

---@return boolean  false for a gun whose ammo is nowhere on the map, so you never swap to a gun you can't feed
function PatipanStudio.Loot.Feedable(cfg, present)
    local gun = PatipanStudio.Config.GunTypes[cfg.type] and PatipanStudio.Loot.Gun(cfg.id)
    if not gun or #gun[4] == 0 then return true end
    for _, ammo in ipairs(gun[4]) do
        if present[ammo] then return true end
    end
    return false
end

---@return table[]  { bagUid, itemUid, name } for every slot that has a better item lying around
function PatipanStudio.Loot.Upgrades()
    local manager = PatipanStudio.Loot.Manager()
    local bags = manager and manager.BagController.bagMap
    if type(bags) ~= "table" then return {} end
    local wanted, slots = PatipanStudio.Options.LootGear, PatipanStudio.Loot.Slots()
    local present = PatipanStudio.Loot.OnMap(bags)
    local best = {}
    for bagUid, bag in pairs(bags) do
        for itemUid, item in pairs(type(bag.itemMap) == "table" and bag.itemMap or {}) do
            local cfg = PatipanStudio.Loot.ItemConfig(item.configId)
            local gear = cfg and slots[cfg.type]
            if not (gear and wanted[gear[1]] and PatipanStudio.Loot.Feedable(cfg, present)) then continue end
            local tried = PatipanStudio.State.Tried[itemUid]
            if tried and osClock() - tried < PatipanStudio.Config.LootRetry then continue end
            local score = PatipanStudio.Loot.Score(cfg)
            local top = best[cfg.type]
            if not top or score > top[4] then best[cfg.type] = { bagUid, itemUid, cfg.name, score } end
        end
    end

    local list = {}
    for itemType, pick in pairs(best) do
        if pick[4] > PatipanStudio.Loot.WornScore(slots[itemType][2]) then list[#list + 1] = pick end
    end
    return list
end

---@return number  items requested
function PatipanStudio.Loot.TakeUpgrades()
    if not PatipanStudio.Player.InBattle() then return 0 end
    local got = 0
    for _, pick in ipairs(PatipanStudio.Loot.Upgrades()) do
        if PatipanStudio.Loot.Pick(pick[1], pick[2], pick[3]) then got += 1 end
    end
    PatipanStudio.State.Looted += got
    return got
end

---@param types table  { Currency = bool, Buff = bool }
---@return number      items requested from every bag on the map
function PatipanStudio.Loot.TakeValuables(types)
    local manager = PatipanStudio.Loot.Manager()
    local bags = manager and manager.BagController.bagMap
    if not (type(bags) == "table" and PatipanStudio.Player.InBattle()) then return 0 end
    local got = 0
    for bagUid, bag in pairs(bags) do
        for itemUid, item in pairs(type(bag.itemMap) == "table" and bag.itemMap or {}) do
            local cfg = PatipanStudio.Loot.ItemConfig(item.configId)
            if not cfg then continue end
            local opts = PatipanStudio.Options
            local wanted = (types.Currency and cfg.type == PatipanStudio.Config.CurrencyType and opts.LootCurrency[cfg.name])
                or (types.Buff and cfg.type == PatipanStudio.Config.BuffType and opts.LootBuffs[PatipanStudio.Loot.BuffKind(cfg.name) or ""])
            if not wanted then continue end
            if PatipanStudio.Loot.Pick(bagUid, itemUid, cfg.name) then got += 1 end
        end
    end
    PatipanStudio.State.Valuables += got
    return got
end

---@return table  ammo item ids for every gun you carry
function PatipanStudio.Loot.AmmoWanted()
    local set, char = {}, LocalPlayer.Character
    for _, slot in ipairs(PatipanStudio.Config.GunSlots) do
        local worn = char and char:GetAttribute("EPos_" .. slot)
        local id = type(worn) == "string" and tonumber(worn:match("^I_(%d+)"))
        local gun = id and id > 0 and PatipanStudio.Loot.Gun(id)
        for _, ammo in ipairs(gun and gun[4] or {}) do set[ammo] = true end
    end
    return set
end

---@return number  ammo stacks requested for the guns you carry, from anywhere on the map
function PatipanStudio.Loot.TakeAmmo()
    local manager = PatipanStudio.Loot.Manager()
    local bags = manager and manager.BagController.bagMap
    if not (type(bags) == "table" and PatipanStudio.Player.InBattle()) then return 0 end
    local wanted, got = PatipanStudio.Loot.AmmoWanted(), 0
    for bagUid, bag in pairs(bags) do
        for itemUid, item in pairs(type(bag.itemMap) == "table" and bag.itemMap or {}) do
            if not wanted[item.configId] then continue end
            if PatipanStudio.Loot.Pick(bagUid, itemUid, PatipanStudio.ItemNames[item.configId]) then got += 1 end
            if got >= PatipanStudio.Config.AmmoBatch then return got end
        end
    end
    return got
end

function PatipanStudio.Loot.AmmoStep()
    if PatipanStudio.Options.AutoAmmo then PatipanStudio.Loot.TakeAmmo() end
end

function PatipanStudio.Loot.ValuablesStep()
    local opts = PatipanStudio.Options
    if not (opts.AutoValuables or opts.AutoBuffs) then return end
    PatipanStudio.Loot.TakeValuables({ Currency = opts.AutoValuables, Buff = opts.AutoBuffs })
end

function PatipanStudio.Loot.GearStep()
    if not PatipanStudio.Options.AutoGear then return end
    PatipanStudio.Loot.TakeUpgrades()
end

---@return boolean  false when skipped or not sent
function PatipanStudio.Loot.Pick(bagUid, itemUid, name)
    local tried = PatipanStudio.State.Tried
    if tried[itemUid] and osClock() - tried[itemUid] < PatipanStudio.Config.LootRetry then return false end
    tried[itemUid] = osClock()
    if not PatipanStudio.Net.Send("DropItem_PickWorldItemReq", { bagUid = bagUid, itemUid = itemUid }) then return false end
    PatipanStudio.State.LastLoot = name or PatipanStudio.State.LastLoot
    return true
end

---@return number  items requested from every air drop on the map; gear only when it beats what you wear
function PatipanStudio.Loot.EmptyAirDrops()
    local manager, folder = PatipanStudio.Loot.Manager(), PatipanStudio.Loot.Folder()
    local bags = manager and manager.BagController.bagMap
    if not (type(bags) == "table" and folder and GameLib.Configs.ItemConfig and PatipanStudio.Player.InBattle()) then return 0 end
    local got, taken = 0, {}
    for _, model in ipairs(folder:GetChildren()) do
        local bagUid = model:GetAttribute("BagUid")
        local bag = PatipanStudio.Loot.Kind(model) == "AirDrop" and bagUid and bags[bagUid]
        if not bag then continue end
        for itemUid, item in pairs(bag.itemMap) do
            local cfg = PatipanStudio.Loot.ItemConfig(item.configId)
            local gear = cfg and PatipanStudio.Loot.Slots()[cfg.type]
            if gear and (taken[cfg.type] or PatipanStudio.Loot.Score(cfg) <= PatipanStudio.Loot.WornScore(gear[2])) then continue end
            if PatipanStudio.Loot.Pick(bagUid, itemUid, cfg and cfg.name) then
                got += 1
                if gear then taken[cfg.type] = true end
            end
        end
    end
    PatipanStudio.State.AirDrops += got
    return got
end

function PatipanStudio.Loot.AirDropStep()
    if PatipanStudio.Options.AutoAirDrop then PatipanStudio.Loot.EmptyAirDrops() end
end

function PatipanStudio.Loot.OnSync(body)
    local timer = body.airdptime
    if type(timer) == "table" and type(timer.endstamp) == "number" then PatipanStudio.State.AirDropAt = timer.endstamp end
end

function PatipanStudio.Loot.Mark(model, kind)
    local gui = Instance.new("BillboardGui")
    gui.Name, gui.AlwaysOnTop, gui.Size, gui.StudsOffset = "PatipanStudioLoot", true, UDim2.fromOffset(180, 20), vector3New(0, 2, 0)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency, label.Size, label.Font, label.TextSize = 1, UDim2.fromScale(1, 1), Enum.Font.GothamBold, 12
    label.TextColor3, label.TextStrokeTransparency = PatipanStudio.Config.LootColors[kind], 0.3
    label.Parent = gui
    gui.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    Util.Mount(gui)
    return { Gui = gui, Label = label }
end

function PatipanStudio.Loot.ClearMarks()
    for _, mark in pairs(PatipanStudio.Loot.Marks) do mark.Gui:Destroy() end
    table.clear(PatipanStudio.Loot.Marks)
end

function PatipanStudio.Loot.EspStep()
    local opts = PatipanStudio.Options
    local marks = PatipanStudio.Loot.Marks
    local show = { AirDrop = opts.LootEspAirDrop, Crate = opts.LootEspCrate, Item = opts.LootEspItem }
    if not (show.AirDrop or show.Crate or show.Item) then
        if next(marks) ~= nil then PatipanStudio.Loot.ClearMarks() end
        return
    end

    local folder, hrp = PatipanStudio.Loot.Folder(), PatipanStudio.Player.Root()
    local seen = {}
    if folder and hrp then
        for _, model in ipairs(folder:GetChildren()) do
            local kind = PatipanStudio.Loot.Kind(model)
            if not (kind and show[kind]) then continue end
            local dist = (model:GetPivot().Position - hrp.Position).Magnitude
            if dist > opts.LootEspRange and kind ~= "AirDrop" then continue end
            seen[model] = true
            marks[model] = marks[model] or PatipanStudio.Loot.Mark(model, kind)
            local opened = kind == "AirDrop" and model:GetAttribute("AirDropOpened") and " (opened)" or ""
            marks[model].Label.Text = string.format("%s%s [%dm]", PatipanStudio.Loot.Label(model, kind), opened, math.floor(dist))
        end
    end

    for model, mark in pairs(marks) do
        if not seen[model] then
            mark.Gui:Destroy()
            marks[model] = nil
        end
    end
end

PatipanStudio.Slide = { Skill = nil, LastScan = 0, Dir = nil }

---@return table?  the game's slide skill object for you
function PatipanStudio.Slide.Find()
    local slide = PatipanStudio.Slide
    if slide.Skill then return slide.Skill end
    if not PatipanStudio.Caps.Gc or osClock() - slide.LastScan < PatipanStudio.Config.StatScanGap then return nil end
    slide.LastScan = osClock()
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and rawget(entry, "slideRequestId") ~= nil and rawget(entry, "owner") and getmetatable(entry) then
            slide.Skill = entry
            return entry
        end
    end
    return nil
end

function PatipanStudio.Slide.OnHeartbeat()
    local slide = PatipanStudio.Slide
    local skill = PatipanStudio.Options.SuperSlide and PatipanStudio.Slide.Find()
    local hrp, hum = PatipanStudio.Player.Root(), PatipanStudio.Player.Humanoid()
    if not (skill and hrp and hum and rawget(skill, "slideActive")) then
        slide.Dir = nil
        return
    end
    if not slide.Dir then
        local move = hum.MoveDirection * vector3New(1, 0, 1)
        local look = Workspace.CurrentCamera.CFrame.LookVector * vector3New(1, 0, 1)
        slide.Dir = move.Magnitude > 0.1 and move.Unit or look.Unit
    end
    local vel, speed = hrp.AssemblyLinearVelocity, PatipanStudio.Options.SlideSpeed
    hrp.AssemblyLinearVelocity = vector3New(slide.Dir.X * speed, vel.Y, slide.Dir.Z * speed)
end

PatipanStudio.Movement = { Collided = {} }

function PatipanStudio.Movement.OnHeartbeat(dt)
    local opts = PatipanStudio.Options
    if not (opts.Speed or opts.Fly) then return end
    local hrp, hum = PatipanStudio.Player.Root(), PatipanStudio.Player.Humanoid()
    if not (hrp and hum) or hum.Health <= 0 then return end

    if opts.Fly then
        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical += 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical -= 1 end
        local dir = hum.MoveDirection + vector3New(0, vertical, 0)
        hrp.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * opts.FlySpeed or Vector3.zero
        return
    end

    local extra = opts.SpeedValue - hum.WalkSpeed
    if extra > 0 and hum.MoveDirection.Magnitude > 0 then
        hrp.CFrame += hum.MoveDirection * extra * dt
    end
end

function PatipanStudio.Movement.OnStepped()
    local saved = PatipanStudio.Movement.Collided
    local char = LocalPlayer.Character
    if not PatipanStudio.Options.Noclip then
        if next(saved) == nil then return end
        for part in pairs(saved) do
            if part.Parent then part.CanCollide = true end
        end
        table.clear(saved)
        return
    end
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.CanCollide then
            saved[part] = true
            part.CanCollide = false
        end
    end
end

function PatipanStudio.Movement.OnJumpRequest()
    if not PatipanStudio.Options.InfiniteJump then return end
    local hum = PatipanStudio.Player.Humanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end

function PatipanStudio.Movement.Start()
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Movement.OnHeartbeat)
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Slide.OnHeartbeat)
    PatipanStudio:Connect(RunService.Stepped, PatipanStudio.Movement.OnStepped)
    PatipanStudio:Connect(UserInputService.JumpRequest, PatipanStudio.Movement.OnJumpRequest)
end

function PatipanStudio.Movement.StopFly()
    local hrp = PatipanStudio.Player.Root()
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
end

PatipanStudio.World = { Saved = nil, FovSaved = nil }

function PatipanStudio.World.Step()
    local saved = PatipanStudio.World.Saved
    if PatipanStudio.Options.Fullbright then
        if not saved then
            PatipanStudio.World.Saved = { Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient }
        end
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd = 2, 14, 1e6
        Lighting.GlobalShadows, Lighting.Ambient = false, Color3.fromRGB(178, 178, 178)
    elseif saved then
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient = table.unpack(saved)
        PatipanStudio.World.Saved = nil
    end
end

function PatipanStudio.World.OnRender()
    local cam = Workspace.CurrentCamera
    if PatipanStudio.Options.CameraFov then
        PatipanStudio.World.FovSaved = PatipanStudio.World.FovSaved or cam.FieldOfView
        cam.FieldOfView = PatipanStudio.Options.CameraFovValue
    elseif PatipanStudio.World.FovSaved then
        cam.FieldOfView = PatipanStudio.World.FovSaved
        PatipanStudio.World.FovSaved = nil
    end
end

function PatipanStudio.World.OnIdled()
    if not PatipanStudio.Options.AntiAfk then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end

function PatipanStudio.World.Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

function PatipanStudio.World.Hop()
    local body = Util.HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId))
    local ok, list = pcall(HttpService.JSONDecode, HttpService, body)
    for _, server in ipairs(ok and list.data or {}) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            return true
        end
    end
    return false
end

---@return Model?  that player's character, if it's alive in the match
function PatipanStudio.World.Body(name)
    local plr = name and Players:FindFirstChild(name)
    local char = plr and plr.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return nil end
    return char
end

---@return boolean  false when the player has no body right now
function PatipanStudio.World.TeleportTo(name)
    local char, root = PatipanStudio.World.Body(name), PatipanStudio.Player.Root()
    if not (char and root) then return false end
    root.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, PatipanStudio.Config.TeleportBehind)
    return true
end

function PatipanStudio.World.Spectate(name)
    local cam = Workspace.CurrentCamera
    local char = name and PatipanStudio.World.Body(name)
    local hum = char and char:FindFirstChildOfClass("Humanoid") or PatipanStudio.Player.Humanoid()
    if cam and hum then cam.CameraSubject = hum end
end

PatipanStudio.Respawn = {}

function PatipanStudio.Respawn.Now()
    local state = PatipanStudio.State
    if osClock() - state.LastRespawn < PatipanStudio.Config.RespawnGap then return false end
    state.LastRespawn = osClock()
    return PatipanStudio.Net.Send("Battlefield_DeployReq")
end

function PatipanStudio.Respawn.Step()
    local state = PatipanStudio.State
    if not PatipanStudio.Player.IsSoul() then
        state.SoulSince = nil
        return
    end
    state.SoulSince = state.SoulSince or osClock()
    if not PatipanStudio.Options.InstantRespawn or osClock() - state.SoulSince < PatipanStudio.Options.RespawnDelay then return end
    PatipanStudio.Respawn.Now()
end

function PatipanStudio.Respawn.Rejoin()
    local char = LocalPlayer.Character
    if not PatipanStudio.Options.AutoRejoin or not (char and char:GetAttribute("EntityState") == 0) then
        PatipanStudio.Farm.LobbySince = nil
        return
    end
    PatipanStudio.Farm.LobbySince = PatipanStudio.Farm.LobbySince or osClock()
    if osClock() - PatipanStudio.Farm.LobbySince > PatipanStudio.Config.LobbyRejoin then PatipanStudio.Respawn.Now() end
end

function PatipanStudio.Respawn.Watch(char)
    if PatipanStudio.Respawn.Conn then PatipanStudio.Respawn.Conn:Disconnect() end
    PatipanStudio.Respawn.Conn = char:GetAttributeChangedSignal("EntityState"):Connect(function()
        PatipanStudio.Heal.Stats, PatipanStudio.Slide.Skill, PatipanStudio.Combat.Input = nil, nil, nil
        PatipanStudio.Respawn.Step()
    end)
end

PatipanStudio.Heal = { Stats = nil, LastScan = 0, LastHeal = 0, Healed = 0 }

---@return table?  the game's live stat table for you (curHp, maxHp)
function PatipanStudio.Heal.Player()
    local heal = PatipanStudio.Heal
    if heal.Stats and type(rawget(heal.Stats, "curHp")) == "number" then return heal.Stats end
    if not PatipanStudio.Caps.Gc or osClock() - heal.LastScan < PatipanStudio.Config.StatScanGap then return nil end
    heal.LastScan = osClock()
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and type(rawget(entry, "curHp")) == "number" and rawget(entry, "maxSp") ~= nil then
            heal.Stats = entry
            return entry
        end
    end
    return nil
end

---@return number?, number?
function PatipanStudio.Heal.Health()
    local stats = PatipanStudio.Heal.Player()
    if not stats then return nil end
    return stats.curHp, stats.maxHp
end

---@return table  configId -> hp restored
function PatipanStudio.Heal.Values()
    local cached = PatipanStudio.Heal.Cache
    if cached then return cached end
    local medicine = GameLib.Configs.MedicineConfig
    local values = {}
    for id, entry in pairs(type(medicine) == "table" and type(medicine.datamap) == "table" and medicine.datamap or {}) do
        if type(entry) == "table" and type(entry.value) == "number" then values[id] = entry.value end
    end
    PatipanStudio.Heal.Cache = values
    return values
end

---@return string[]  names of every med the game has
function PatipanStudio.Heal.Names()
    local names = {}
    for id in pairs(PatipanStudio.Heal.Values()) do
        if PatipanStudio.Loot.ItemConfig(id) then names[#names + 1] = PatipanStudio.ItemNames[id] end
    end
    table.sort(names)
    return names
end

---@param missing number  hp to fill
---@param urgent boolean  take the biggest one
---@return table?  { bagUid, itemUid, name }
function PatipanStudio.Heal.PickMed(missing, urgent)
    local manager = PatipanStudio.Loot.Manager()
    local bags = manager and manager.BagController.bagMap
    if type(bags) ~= "table" then return nil end
    local values, tried, allowed = PatipanStudio.Heal.Values(), PatipanStudio.State.Tried, PatipanStudio.Options.HealMeds
    local best, bestScore
    for bagUid, bag in pairs(bags) do
        for itemUid, item in pairs(type(bag.itemMap) == "table" and bag.itemMap or {}) do
            local heal = values[item.configId]
            if not heal or not allowed[PatipanStudio.ItemNames[item.configId]] or (tried[itemUid] and osClock() - tried[itemUid] < PatipanStudio.Config.LootRetry) then continue end
            local score = urgent and -heal or math.abs(missing - heal)
            if not bestScore or score < bestScore then best, bestScore = { bagUid, itemUid, item.configId }, score end
        end
    end
    if best then best[3] = PatipanStudio.ItemNames[best[3]] end
    return best
end

---@return boolean  a med was taken
function PatipanStudio.Heal.Now()
    local hp, maxHp = PatipanStudio.Heal.Health()
    if not (hp and maxHp and hp < maxHp and PatipanStudio.Player.InBattle()) then return false end
    local urgent = hp / maxHp * 100 <= PatipanStudio.Config.HealUrgent
    local med = PatipanStudio.Heal.PickMed(maxHp - hp, urgent)
    if not (med and PatipanStudio.Loot.Pick(med[1], med[2], med[3])) then return false end
    PatipanStudio.Heal.LastHeal = osClock()
    PatipanStudio.Heal.Healed += 1
    return true
end

function PatipanStudio.Heal.Step()
    if not PatipanStudio.Options.AutoHeal then return end
    if osClock() - PatipanStudio.Heal.LastHeal < PatipanStudio.Config.HealGap then return end
    local hp, maxHp = PatipanStudio.Heal.Health()
    if not (hp and maxHp) or hp / maxHp * 100 > PatipanStudio.Options.HealAt then return end
    PatipanStudio.Heal.Now()
end

function PatipanStudio.Heal.GetStatus()
    local hp, maxHp = PatipanStudio.Heal.Health()
    if not hp then return "HP unknown" end
    return string.format("HP %d/%d | Meds used %d", math.floor(hp), math.floor(maxHp), PatipanStudio.Heal.Healed)
end

PatipanStudio.Hunt = { LastSeen = 0, Jumps = 0, PausedUntil = 0, Desyncs = 0 }

---@return Model?  closest living enemy anywhere on the map
function PatipanStudio.Hunt.Nearest()
    local hrp = PatipanStudio.Player.Root()
    if not hrp then return nil end
    local best, bestDist
    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        local root = PatipanStudio.Target.IsEnemy(model) and model:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local dist = (root.Position - hrp.Position).Magnitude
        if not bestDist or dist < bestDist then best, bestDist = model, dist end
    end
    return best
end

function PatipanStudio.Hunt.Step()
    if not (PatipanStudio.Options.Hunt and PatipanStudio.Player.InBattle()) then return end
    if PatipanStudio.State.Target then
        PatipanStudio.Hunt.LastSeen = osClock()
        return
    end
    local opts, hunt = PatipanStudio.Options, PatipanStudio.Hunt
    if osClock() - hunt.LastSeen < opts.HuntIdle or osClock() < hunt.PausedUntil then return end
    local enemy, hrp = PatipanStudio.Hunt.Nearest(), PatipanStudio.Player.Root()
    if not (enemy and hrp) then return end
    local root = enemy.HumanoidRootPart
    local facing = root.CFrame.LookVector * vector3New(1, 0, 1)
    facing = facing.Magnitude > 0.1 and facing.Unit or vector3New(1, 0, 0)
    local offset = (opts.HuntMode == "Front" and facing or opts.HuntMode == "Above" and Vector3.zero or -facing) * opts.HuntDistance
    local goal = root.Position + offset + vector3New(0, opts.HuntHeight, 0)
    local delta = goal - hrp.Position
    local partial = opts.HuntMaxWarp > 0 and delta.Magnitude > opts.HuntMaxWarp
    if partial then goal = hrp.Position + delta.Unit * opts.HuntMaxWarp end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.lookAt(goal, root.Position)
    if not partial then hunt.LastSeen = osClock() end
    hunt.Jumps += 1
end

---@param text string  server notice; a movement desync means it pulled us back, so stop warping for a moment
function PatipanStudio.Hunt.OnNotice(text)
    if type(text) ~= "string" or not text:find("out of sync", 1, true) then return end
    PatipanStudio.Hunt.PausedUntil = osClock() + PatipanStudio.Config.HuntSyncPause
    PatipanStudio.Hunt.Desyncs += 1
end

PatipanStudio.Farm = { Bag = nil, Start = nil, Totals = {}, LobbySince = nil }

---@return table?  your persistent currency bag (gold, ore, crystals)
function PatipanStudio.Farm.CurrencyBag()
    local farm = PatipanStudio.Farm
    if farm.Bag and type(rawget(farm.Bag, "itemMap")) == "table" then return farm.Bag end
    if not PatipanStudio.Caps.Gc then return nil end
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and rawget(entry, "bagType") == PatipanStudio.Config.CurrencyType and type(rawget(entry, "itemMap")) == "table" and rawget(entry, "controller") then
            farm.Bag = entry
            return entry
        end
    end
    return nil
end

function PatipanStudio.Farm.Sample()
    local bag = PatipanStudio.Farm.CurrencyBag()
    if not bag then return end
    local totals = {}
    for _, item in pairs(bag.itemMap) do totals[PatipanStudio.ItemNames[item.configId]] = item.num end
    PatipanStudio.Farm.Totals = totals
    if not PatipanStudio.Farm.Start then PatipanStudio.Farm.Start = { osClock(), table.clone(totals), PatipanStudio.State.Kills } end
end

---@return string  gains per hour since the script started
function PatipanStudio.Farm.GetStatus()
    local start = PatipanStudio.Farm.Start
    if not start then return "-" end
    local hours = math.max(osClock() - start[1], 60) / 3600
    local seen, names, parts = {}, {}, {}
    for _, totals in ipairs({ PatipanStudio.Farm.Totals, start[2] }) do
        for name in pairs(totals) do
            if not seen[name] then seen[name] = true table.insert(names, name) end
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local gained = (PatipanStudio.Farm.Totals[name] or 0) - (start[2][name] or 0)
        parts[#parts + 1] = string.format("%s +%d (%d/h)", name, gained, math.floor(gained / hours))
    end
    local kills = PatipanStudio.State.Kills - start[3]
    parts[#parts + 1] = string.format("Kills %d (%d/h)", kills, math.floor(kills / hours))
    return table.concat(parts, " | ")
end

PatipanStudio.Rewards = { Owner = nil, Services = {}, Pending = {}, Claimed = 0, Last = "-" }

---@return table?  the game's player object (Task, Season, Online, SignIn, Bag ...)
function PatipanStudio.Rewards.Data()
    local rewards = PatipanStudio.Rewards
    local cached = rewards.Owner
    if cached and type(rawget(cached, "Task")) == "table" then return cached end
    if not PatipanStudio.Caps.Gc then return nil end
    for _, entry in ipairs(Util.GetGc(true)) do
        local tasks = type(entry) == "table" and rawget(entry, "Task")
        if type(tasks) == "table" and rawget(tasks, "player") == entry and type(rawget(entry, "Season")) == "table" then
            rewards.Owner = entry
            return entry
        end
    end
    return nil
end

---@return table?  the game service table that owns this method
function PatipanStudio.Rewards.Service(method)
    local services = PatipanStudio.Rewards.Services
    if services[method] then return services[method] end
    if not PatipanStudio.Caps.Gc then return nil end
    for _, entry in ipairs(Util.GetGc(true)) do
        if type(entry) == "table" and type(rawget(entry, method)) == "function" then
            services[method] = entry
            return entry
        end
    end
    return nil
end

---@return number  how many of this item you own
function PatipanStudio.Rewards.Count(itemId)
    local data = PatipanStudio.Rewards.Data()
    local ok, count = pcall(function() return data:GetItemNum(itemId) end)
    return ok and tonumber(count) or 0
end

---@return number  claims sent
function PatipanStudio.Rewards.Tasks(data)
    local tasks, sent = data.Task, 0
    local done = GameLib.TaskState.done
    local ok, newbie = pcall(tasks.GetCanRewardTaskId, tasks)
    if ok and type(newbie) == "table" and #newbie > 0 and PatipanStudio.Net.Send("Task_ReceiveNewbieTaskReq", newbie) then sent += 1 end

    for _, kind in pairs(type(tasks.taskList) == "table" and tasks.taskList or {}) do
        for taskId, info in pairs(kind) do
            if type(info) ~= "table" or info.state ~= done then continue end
            if PatipanStudio.Net.Send("Task_ReceiveTaskAwardReq", { taskId = taskId }) then sent += 1 end
        end
    end
    pcall(tasks.ReceiveWeekReward, tasks)
    return sent
end

function PatipanStudio.Rewards.Season(data)
    local season, sent = data.Season, 0
    local done = GameLib.TaskState.done
    local list = type(season.seasonTask) == "table" and season.seasonTask.taskList
    for _, kind in pairs(type(list) == "table" and list or {}) do
        for taskId, info in pairs(kind) do
            if type(info) == "table" and info.state == done and PatipanStudio.Net.Send("Season_ReceiveTask", taskId) then sent += 1 end
        end
    end

    local ok, can = pcall(season.GetCanReceivePassAward, season)
    if ok and can and PatipanStudio.Net.Send("Season_RequireReceiveAllAward", {}) then sent += 1 end

    local rank = PatipanStudio.Rewards.Service("ReceiveRankAward")
    local okLv, rankLv = pcall(season.GetRankLv, season)
    for lv = 1, okLv and tonumber(rankLv) or 0 do
        local open, state = pcall(season.CanReceiveRankLv, season, lv)
        if not (open and state and rank) then continue end
        if pcall(rank.ReceiveRankAward, rank, lv) then sent += 1 end
    end
    return sent
end

function PatipanStudio.Rewards.Daily(data, kinds)
    local sent, now = 0, Workspace:GetServerTimeNow()
    local online = data.Online
    local gifts = kinds["Online gifts"] and type(online.receiveStateList) == "table" and online.receiveStateList or {}
    for index, gift in ipairs(gifts) do
        if gift.receiveState or (gift.timeStamp or math.huge) > now then continue end
        if PatipanStudio.Net.Send("Online_ReceiveGiftReq", { receiveIdx = index }) then sent += 1 end
    end

    local sign = data.SignIn
    local okDay, day = pcall(sign.GetSignDay, sign)
    local info = type(sign.sign_day_info) == "table" and sign.sign_day_info
    if kinds["Sign-in"] and okDay and tonumber(day) and info and not info[day] and PatipanStudio.Net.Send("Sign_RequireSigned", { signDay = day }) then sent += 1 end

    local update = data.GameUpdate
    local okAward, award = pcall(update.GetUpdateVerAward, update)
    if kinds["Update gift"] and okAward and award and pcall(update.ReqReceiveCurVerAward, update) then sent += 1 end
    return sent
end

---@return number  claims sent in this pass
function PatipanStudio.Rewards.ClaimAll()
    local data = PatipanStudio.Rewards.Data()
    if not data then return 0 end
    local sent, kinds = 0, PatipanStudio.Options.ClaimKinds
    local steps = {
        { kinds.Tasks, PatipanStudio.Rewards.Tasks },
        { kinds.Season, PatipanStudio.Rewards.Season },
        { kinds["Online gifts"] or kinds["Sign-in"] or kinds["Update gift"], PatipanStudio.Rewards.Daily },
        { kinds.Lottery, PatipanStudio.Rewards.Lottery },
    }
    for _, entry in ipairs(steps) do
        if not entry[1] then continue end
        local ok, got = pcall(entry[2], data, kinds)
        if ok then sent += got else warn("[AirDropArena] claim:", got) end
    end
    PatipanStudio.Rewards.Claimed += sent
    if sent > 0 then PatipanStudio.Rewards.Last = os.date("%H:%M") .. " +" .. sent end
    return sent
end

---@return number, number  codes that paid out, gold gained
function PatipanStudio.Rewards.RedeemCodes()
    local codes = GameLib.Configs.CodeConfig
    local ok, keys = pcall(function() return codes:GetListKey() end)
    if not (ok and type(keys) == "table") then return 0, 0 end
    local paid, gold = 0, 0
    for _, code in ipairs(keys) do
        local before = PatipanStudio.Rewards.Count(PatipanStudio.Config.GoldId)
        if not PatipanStudio.Net.Send("PlayerChat_C2SCode", code) then break end
        task.wait(PatipanStudio.Config.CodeGap)
        local gained = PatipanStudio.Rewards.Count(PatipanStudio.Config.GoldId) - before
        if gained > 0 then paid, gold = paid + 1, gold + gained end
    end
    return paid, gold
end

---@return table[]  { id, name, price } for every box the shop sells for gold
function PatipanStudio.Rewards.Boxes()
    if PatipanStudio.Rewards.BoxList then return PatipanStudio.Rewards.BoxList end
    local shop, list = GameLib.Configs.ShopConfig, {}
    for id = PatipanStudio.Config.BoxIds[1], PatipanStudio.Config.BoxIds[2] do
        local ok, cfg = pcall(function() return shop:GetSkinLotteryConfigById(id) end)
        if ok and type(cfg) == "table" then list[#list + 1] = { id, PatipanStudio.ItemNames[id], tonumber(cfg.coinVal) or 0 } end
    end
    PatipanStudio.Rewards.BoxList = list
    return list
end

---@return number  boxes opened
function PatipanStudio.Rewards.OpenBoxes()
    local opened = 0
    local allowed = PatipanStudio.Options.OpenBoxList
    for _, box in ipairs(PatipanStudio.Rewards.Boxes()) do
        if not allowed[box[2]] then continue end
        local owned = PatipanStudio.Rewards.Count(box[1])
        for _ = 1, math.min(owned, PatipanStudio.Config.OpenBatch) do
            if not PatipanStudio.Net.Send("Bag_C2SOpenSkinBoxReq", { id = box[1], num = 1 }) then return opened end
            opened += 1
            task.wait(PatipanStudio.Config.OpenGap)
        end
    end
    return opened
end

---@return number  boxes bought, stops at the gold you keep
function PatipanStudio.Rewards.BuyBoxes()
    local opts, bought = PatipanStudio.Options, 0
    local box
    for _, entry in ipairs(PatipanStudio.Rewards.Boxes()) do
        if entry[2] == opts.BuyBox and entry[3] > 0 then box = entry end
    end
    if not box then return 0 end
    local spare = PatipanStudio.Rewards.Count(PatipanStudio.Config.GoldId) - opts.KeepGold
    local amount = math.min(opts.BuyAmount, math.floor(spare / box[3]))
    for _ = 1, amount do
        if not PatipanStudio.Net.Send("Bag_C2SBuySkinBoxReq", { id = box[1], num = 1 }) then break end
        bought += 1
        task.wait(PatipanStudio.Config.OpenGap)
    end
    return bought
end

---@return number  digits filled plus past draws claimed
function PatipanStudio.Rewards.Lottery(data)
    local lottery = data and data.Lottery
    if type(lottery) ~= "table" then return 0 end
    local sent = 0
    local today = type(lottery.datamap) == "table" and lottery.datamap.listarray
    local picks = {}
    for pos, slot in ipairs(type(today) == "table" and today or {}) do
        if type(slot) == "table" and not slot.lock and slot.value == -1 then
            picks[#picks + 1] = { pos = pos, value = math.random(0, 9) }
        end
    end
    if #picks > 0 and PatipanStudio.Net.Send("Lottery_C2SCustom", { action = "SetTicket", data = picks }) then sent += #picks end

    for _, draw in ipairs(type(lottery.history) == "table" and lottery.history or {}) do
        if type(draw) ~= "table" or draw.isclaim or not draw.id then continue end
        if PatipanStudio.Net.Send("Lottery_C2SCustom", { action = "ClaimReward", data = { id = draw.id } }) then sent += 1 end
    end
    return sent
end

---@param action string  "Claim", "Codes", "Open", "Buy"
function PatipanStudio.Rewards.Request(action)
    PatipanStudio.Rewards.Pending[action] = true
end

function PatipanStudio.Rewards.Step()
    local rewards, opts = PatipanStudio.Rewards, PatipanStudio.Options
    local pending = rewards.Pending
    local now = osClock()
    if pending.Claim or (opts.AutoClaim and now - (rewards.LastClaim or 0) > PatipanStudio.Config.ClaimGap) then
        pending.Claim, rewards.LastClaim = nil, now
        PatipanStudio.UI.Queue("Rewards", ("Claimed %d rewards"):format(rewards.ClaimAll()))
    end
    if pending.Codes then
        pending.Codes = nil
        local paid, gold = rewards.RedeemCodes()
        PatipanStudio.UI.Queue("Codes", paid > 0 and ("%d codes worked, +%d gold"):format(paid, gold) or "No code paid out (all used or expired)")
    end
    if pending.Open or opts.AutoOpenBoxes then
        local manual = pending.Open
        pending.Open = nil
        local opened = rewards.OpenBoxes()
        if manual or opened > 0 then PatipanStudio.UI.Queue("Boxes", ("Opened %d boxes"):format(opened)) end
    end
    if pending.Buy then
        pending.Buy = nil
        PatipanStudio.UI.Queue("Boxes", ("Bought %d boxes"):format(rewards.BuyBoxes()))
    end
end

function PatipanStudio.Rewards.GetStatus()
    return ("Sent %d | Last %s"):format(PatipanStudio.Rewards.Claimed, PatipanStudio.Rewards.Last)
end

PatipanStudio.Admin = { Seen = {} }

---@return string?  name of a staff member in this server
function PatipanStudio.Admin.Find()
    local list = GameLib.AdminIds
    if type(list) ~= "table" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and list[player.UserId] then return player.Name end
    end
    return nil
end

function PatipanStudio.Admin.Step()
    local opts = PatipanStudio.Options
    if not (opts.AdminAlert or opts.AdminHop) then return end
    local name = PatipanStudio.Admin.Find()
    if not name then return end
    if not PatipanStudio.Admin.Seen[name] then
        PatipanStudio.Admin.Seen[name] = true
        PatipanStudio.UI.Queue("PatipanStudio", "Staff in server: " .. name)
    end
    if opts.AdminHop then PatipanStudio.World.Hop() end
end

PatipanStudio.Damage = { Hits = {}, Last = {}, Samples = {} }

---@return number  confirmed hits it takes to kill, learned from your own kills
function PatipanStudio.Damage.HitsToKill()
    local samples = PatipanStudio.Damage.Samples
    if #samples == 0 then
        local char = LocalPlayer.Character
        local worn = char and char:GetAttribute("EPos_1")
        local id = type(worn) == "string" and tonumber(worn:match("^I_(%d+)"))
        local gun = id and PatipanStudio.Loot.Gun(id)
        return gun and math.max(1, math.ceil(PatipanStudio.Config.BaseHp / gun[1])) or 5
    end
    local total = 0
    for _, n in ipairs(samples) do total += n end
    return total / #samples
end

function PatipanStudio.Damage.OnHit(entityId)
    local damage = PatipanStudio.Damage
    damage.Hits[entityId] = (damage.Hits[entityId] or 0) + 1
    damage.Last[entityId] = osClock()
end

function PatipanStudio.Damage.OnDeath(entityId, mine)
    local damage = PatipanStudio.Damage
    local hits = damage.Hits[entityId]
    damage.Hits[entityId], damage.Last[entityId] = nil, nil
    if not (mine and hits and hits > 0) then return end
    table.insert(damage.Samples, hits)
    if #damage.Samples > PatipanStudio.Config.KillSamples then table.remove(damage.Samples, 1) end
end

---@return number  0..1 health left, estimated from your confirmed hits (the server never sends enemy health)
function PatipanStudio.Damage.Fraction(entityId)
    local damage = PatipanStudio.Damage
    local hits = entityId and damage.Hits[entityId]
    if not hits then return 1 end
    if osClock() - damage.Last[entityId] > PatipanStudio.Config.HitForget then
        damage.Hits[entityId], damage.Last[entityId] = nil, nil
        return 1
    end
    return math.clamp(1 - hits / PatipanStudio.Damage.HitsToKill(), 0.05, 1)
end

PatipanStudio.Esp = { Count = 0 }

---@return table[]  targets in the shape Library.Visuals expects
function PatipanStudio.Esp.Targets()
    local list = {}
    for _, model in ipairs(PatipanStudio.Target.Candidates(true)) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        list[#list + 1] = {
            Model = model,
            Name = PatipanStudio.Target.Label(model),
            Health = math.floor(PatipanStudio.Damage.Fraction(model:GetAttribute("EntityId")) * PatipanStudio.Config.BaseHp),
            MaxHealth = PatipanStudio.Config.BaseHp,
            Friendly = PatipanStudio.Target.SameTeam(model),
            Root = model:FindFirstChild("HumanoidRootPart"),
        }
    end
    PatipanStudio.Esp.Count = #list
    return list
end

function PatipanStudio.Esp.GetStatus()
    local visuals = PatipanStudio.Library and PatipanStudio.Library.Visuals
    if not (visuals and visuals:Get("Enabled")) then return "Off" end
    return PatipanStudio.Esp.Count .. " targets"
end

PatipanStudio.Faults = { Streaks = {} }

function PatipanStudio.Faults.Clear(name)
    PatipanStudio.Faults.Streaks[name] = nil
end

function PatipanStudio.Faults.Wanted(toggles)
    for _, key in ipairs(toggles) do
        if PatipanStudio.Options[key] then return true end
    end
    return false
end

---@param restore function?  the feature's own off path, run once
function PatipanStudio.Faults.Stop(name, err, toggles, restore)
    warn("[AirDropArena] " .. name .. " stopped:", err)
    for _, key in ipairs(toggles) do PatipanStudio.Options[key] = false end
    if restore then Util.Try(name .. " restore", restore) end
    table.insert(PatipanStudio.State.Halted, { name, tostring(err):match("^[^\n]*"), toggles })
end

---@param toggles string[]   switched off once the feature keeps failing; empty = never stops, warns once per streak
---@param restore function?  run once when the feature stops
---@return boolean           true while the feature is stopped
function PatipanStudio.Faults.Report(name, err, toggles, restore)
    local now = osClock()
    local streak = PatipanStudio.Faults.Streaks[name]
    if not streak or (streak.Halted and PatipanStudio.Faults.Wanted(toggles)) then
        streak = { Count = 0, First = now, Warned = false, Halted = false }
        PatipanStudio.Faults.Streaks[name] = streak
    end
    streak.Count += 1
    if streak.Warned then return streak.Halted end
    if streak.Count < PatipanStudio.Config.MaxFails or now - streak.First < PatipanStudio.Config.FailWindow then return false end

    streak.Warned = true
    if #toggles == 0 then
        warn("[AirDropArena] " .. name .. " keeps failing:", err)
        return false
    end
    streak.Halted = true
    PatipanStudio.Faults.Stop(name, err, toggles, restore)
    return true
end

PatipanStudio.Scheduler = { Jobs = {}, Booted = false }

---@param toggles string[]?  options that keep the job alive; turned off if it keeps failing
---@param restore function?  the job's off path, run once if it gets stopped
function PatipanStudio.Scheduler.Every(name, interval, fn, toggles, restore)
    PatipanStudio.Scheduler.Jobs[name] = { Interval = interval, Fn = fn, Last = 0, Running = false, Toggles = toggles or {}, Restore = restore }
end

function PatipanStudio.Scheduler.Settle(name, job)
    local err = job.Error
    job.Error = nil
    if err == false then
        PatipanStudio.Faults.Clear(name)
        return
    end
    job.Halted = PatipanStudio.Faults.Report(name, err, job.Toggles, job.Restore)
end

function PatipanStudio.Scheduler.Step()
    local now = osClock()
    for name, job in pairs(PatipanStudio.Scheduler.Jobs) do
        if job.Running then continue end
        if job.Error ~= nil then PatipanStudio.Scheduler.Settle(name, job) end
        if job.Halted then
            if not PatipanStudio.Faults.Wanted(job.Toggles) then continue end
            job.Halted = false
            PatipanStudio.Faults.Clear(name)
        end
        if now - job.Last < job.Interval then continue end

        job.Last, job.Running = now, true
        task.spawn(function()
            local ok, err = pcall(job.Fn)
            job.Error = not ok and tostring(err) or false
            job.Running = false
        end)
    end
end

function PatipanStudio.Scheduler.Boot()
    if PatipanStudio.Scheduler.Booted then return end
    PatipanStudio.Scheduler.Booted = true
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.Scheduler.Step)
end

PatipanStudio.Look = {}

---@return table  item name -> config, built once from the game's item table
function PatipanStudio.Look.Index()
    if PatipanStudio.Look.ByName then return PatipanStudio.Look.ByName end
    local byName = {}
    for id = 1, PatipanStudio.Config.ItemScan do
        local cfg = PatipanStudio.Loot.ItemConfig(id)
        if cfg and type(cfg.name) == "string" and not byName[cfg.name] then byName[cfg.name] = cfg end
    end
    for _, box in ipairs(PatipanStudio.Rewards.Boxes()) do
        byName[box[2]] = byName[box[2]] or PatipanStudio.Loot.ItemConfig(box[1])
    end
    PatipanStudio.Look.ByName = byName
    return byName
end

---@return Color3?  the colour the game paints this quality with
function PatipanStudio.Look.Color(quality)
    local helper = PatipanStudio.Look.Quality
    if helper == nil then
        local scripts = ReplicatedStorage:FindFirstChild("Scripts")
        helper = GameLib.Require(scripts and scripts:FindFirstChild("QualityHelper", true)) or false
        PatipanStudio.Look.Quality = helper
    end
    if not (helper and quality) then return nil end
    local ok, color = pcall(helper.GetQualityConfig, helper.TextQualityColor, quality, nil)
    return ok and typeof(color) == "Color3" and color or nil
end

---Gives an item dropdown the game's pictures and rarity colours.
function PatipanStudio.Look.Decorate(dropdown)
    if not (dropdown and dropdown.SetImages) then return end
    local index, images, colors = PatipanStudio.Look.Index(), {}, {}
    for _, label in ipairs(dropdown.Values or {}) do
        local cfg = index[label]
        if not cfg then continue end
        images[label] = cfg.tex or cfg.texhd
        colors[label] = PatipanStudio.Look.Color(cfg.quality)
    end
    dropdown:SetImages(images, colors)
end

PatipanStudio.UI = { Labels = {} }
local Library, T

function PatipanStudio.UI.Detach(fn)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(fn, table.unpack(packed, 1, packed.n))
            if not ok then warn("[AirDropArena] ui:", err) end
        end)
    end
end

function PatipanStudio.UI.Bind(widget, key)
    local function Apply(value) PatipanStudio.Options[key] = value end
    Apply(widget.Value)
    widget:OnChanged(Apply)
end

---@param got number   items taken
---@param none string  shown when nothing was taken
function PatipanStudio.UI.Report(title, got, done, none)
    if got > 0 then
        Library:Notify(title, done:format(got), 4, "Success")
    else
        Library:Notify(title, none, 4, "Info")
    end
end

function PatipanStudio.UI.BuildMain(window)
    window:AddTabSection(T("Main", "หลัก"))
    local tab = window:AddTab(T("Main", "หลัก"), "mushroom", T("Status and links", "สถานะและลิงก์"))

    local status = tab:AddLeftGroupbox(T("Status", "สถานะ"), "star")
    PatipanStudio.UI.Labels.Farm = status:AddParagraph({ Title = T("Farm", "ฟาร์ม"), Content = "-" })
    PatipanStudio.UI.Labels.Heal = status:AddParagraph({ Title = T("Health", "เลือด"), Content = "-" })
    PatipanStudio.UI.Labels.Combat = status:AddParagraph({ Title = T("Combat", "การต่อสู้"), Content = "-" })
    PatipanStudio.UI.Labels.Rewards = status:AddParagraph({ Title = T("Rewards", "รางวัล"), Content = "-" })

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

    local live = tab:AddRightGroupbox(T("Loot and ESP", "ของดรอปและ ESP"), "coin")
    PatipanStudio.UI.Labels.Loot = live:AddParagraph({ Title = T("Loot", "ของดรอป"), Content = "-" })
    PatipanStudio.UI.Labels.Esp = live:AddParagraph({ Title = T("ESP", "ESP"), Content = "-" })
end

function PatipanStudio.UI.BuildCombat(window)
    window:AddTabSection(T("Combat", "การต่อสู้"))
    local tab = window:AddTab(T("Aim", "เล็ง"), "target", T("Silent aim, ragebot, aimbot, triggerbot", "ไซเลนต์เอม เรจบอท เล็งอัตโนมัติ ยิงอัตโนมัติ"))
    local priorities = { "Crosshair", "Distance", "Health" }

    local silent = tab:AddLeftGroupbox(T("Silent Aim", "ไซเลนต์เอม"), "bomb", "OP")
    silent:AddToggle("SilentAim", { Text = T("Silent aim", "ไซเลนต์เอม"), Description = T("Your shots hit the target in the FOV", "กระสุนวิ่งเข้าเป้าในวง FOV") })
        :AddKeyPicker("SilentAimKey", { Default = "None", Mode = "Toggle" })
    silent:AddSlider("SilentHitChance", { Text = T("Hit chance", "โอกาสโดน"), Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    silent:AddSlider("SilentHeadChance", { Text = T("Headshot chance", "โอกาสโดนหัว"), Min = 0, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    silent:AddDropdown("SilentPriority", { Text = T("Target priority", "เลือกเป้าตาม"), Values = priorities, Default = "Crosshair" })
    silent:AddSlider("SilentFov", { Text = T("FOV", "ระยะมอง"), Min = 20, Max = 1000, Default = 250, Suffix = "px" })
    silent:AddToggle("ShowSilentFov", { Text = T("Show FOV circle", "แสดงวงระยะมอง") })
    silent:AddSlider("SilentMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 2000, Default = 1000, Suffix = "m" })
    Library.Compat.NeedCap("SilentAim", "Namecall")

    local rage = tab:AddLeftGroupbox(T("Ragebot", "เรจบอท"), "bomb")
    rage:AddToggle("Ragebot", { Text = T("Ragebot", "เรจบอท"), Description = T("Shoots every enemy in sight on its own", "ยิงศัตรูทุกตัวที่มองเห็นเอง") })
        :AddKeyPicker("RagebotKey", { Default = "None", Mode = "Toggle" })
    rage:AddSlider("RageMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 2000, Default = 1000, Suffix = "m" })
    Library.Compat.NeedCap("Ragebot", "Namecall")

    local aim = tab:AddRightGroupbox(T("Aimbot", "เล็งอัตโนมัติ"), "target")
    aim:AddToggle("Aimbot", { Text = T("Aimbot", "เล็งอัตโนมัติ"), Description = T("Locks your view onto the enemy in the FOV", "ล็อคกล้องไปที่ศัตรูในวง FOV"), Tooltip = T("Right-click or long-press the key to change Hold / Toggle / Always", "คลิกขวาหรือกดค้างที่ปุ่มคีย์เพื่อเปลี่ยน Hold / Toggle / Always") })
        :AddKeyPicker("AimbotKey", { Default = "X", Mode = "Hold" })
    aim:AddSlider("AimSmooth", { Text = T("Smoothness", "ความนุ่ม"), Min = 1, Max = 20, Default = 1, Rounding = 0 })
    aim:AddCheckbox("AimSticky", { Text = T("Sticky target", "ล็อคเป้าเดิม") })
    aim:AddDropdown("AimBone", { Text = T("Aim part", "จุดที่เล็ง"), Values = { "Head", "Torso" }, Default = "Head" })
    aim:AddDropdown("AimPriority", { Text = T("Target priority", "เลือกเป้าตาม"), Values = priorities, Default = "Crosshair" })
    aim:AddSlider("AimFov", { Text = T("FOV", "ระยะมอง"), Min = 20, Max = 800, Default = 200, Suffix = "px" })
    aim:AddToggle("ShowFov", { Text = T("Show FOV circle", "แสดงวงระยะมอง") })
    aim:AddSlider("AimMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 2000, Default = 1000, Suffix = "m" })

    local trigger = tab:AddRightGroupbox(T("Triggerbot", "ยิงอัตโนมัติ"), "crosshair")
    trigger:AddToggle("Triggerbot", { Text = T("Triggerbot", "ยิงอัตโนมัติ"), Description = T("Fires when your crosshair is on an enemy", "ยิงเองเมื่อเป้าเล็งอยู่บนศัตรู") })
        :AddKeyPicker("TriggerbotKey", { Default = "None", Mode = "Toggle" })
    trigger:AddSlider("TriggerDelay", { Text = T("Reaction delay", "หน่วงก่อนยิง"), Min = 0, Max = 500, Default = 0, Rounding = 0, Suffix = "ms" })
    trigger:AddSlider("TriggerChance", { Text = T("Fire chance", "โอกาสยิง"), Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    trigger:AddCheckbox("TargetBots", { Text = T("Include bots", "รวมบอท"), Default = true })

    PatipanStudio.UI.BuildSurvival(window)
end

function PatipanStudio.UI.BuildSurvival(window)
    local tab = window:AddTab(T("Survival", "เอาตัวรอด"), "heart", T("Hunt, healing, respawn and gun mods", "ล่าศัตรู ฮีล เกิดใหม่ และม็อดปืน"))

    local hunt = tab:AddLeftGroupbox(T("Hunt", "ล่าศัตรู"), "zap")
    hunt:AddToggle("Hunt", { Text = T("Hunt", "ล่าศัตรู"), Description = T("Warps to the closest enemy whenever nobody is in sight", "วาร์ปไปหาศัตรูที่ใกล้สุดเมื่อไม่เห็นใคร") })
    hunt:AddDropdown("HuntMode", { Text = T("Position", "ตำแหน่ง"), Values = { "Behind", "Above", "Front" }, Default = "Behind" })
    hunt:AddSlider("HuntDistance", { Text = T("Distance", "ระยะห่าง"), Min = 0, Max = 60, Default = 15, Rounding = 0, Suffix = "m" })
    hunt:AddSlider("HuntHeight", { Text = T("Height", "ความสูง"), Min = 0, Max = 40, Default = 10, Rounding = 0, Suffix = "m" })
    hunt:AddSlider("HuntMaxWarp", { Text = T("Max warp per jump", "วาร์ปไกลสุดต่อครั้ง"), Min = 0, Max = 400, Default = 0, Rounding = 0, Suffix = "m", Tooltip = T("0 = no limit", "0 = ไม่จำกัด") })
    hunt:AddSlider("HuntIdle", { Text = T("Wait before warp", "รอก่อนวาร์ป"), Min = 0, Max = 5, Default = 0.6, Rounding = 1, Suffix = "s" })

    local life = tab:AddLeftGroupbox(T("Respawn", "เกิดใหม่"), "heart")
    life:AddToggle("InstantRespawn", { Text = T("Auto respawn", "เกิดใหม่อัตโนมัติ"), Description = T("Respawns as soon as the game allows", "เกิดใหม่เองทันทีที่เกมอนุญาต") })
    life:AddSlider("RespawnDelay", { Text = T("Respawn delay", "หน่วงก่อนเกิด"), Min = 0, Max = 10, Default = 0, Rounding = 1, Suffix = "s" })
    life:AddToggle("AutoRejoin", { Text = T("Auto rejoin match", "เข้าแมตช์ใหม่อัตโนมัติ"), Description = T("Jumps back into a match when you sit in the lobby", "กลับเข้าแมตช์เองเมื่อค้างอยู่ในล็อบบี้") })
    life:AddButton({ Text = T("Respawn Now", "เกิดใหม่ตอนนี้"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.State.LastRespawn = 0
        PatipanStudio.Respawn.Now()
    end) })

    local heal = tab:AddRightGroupbox(T("Auto Heal", "ฮีลอัตโนมัติ"), "heart")
    heal:AddToggle("AutoHeal", { Text = T("Auto heal", "ฮีลอัตโนมัติ"), Description = T("Grabs a med from anywhere on the map when you get hurt", "ดึงยาจากทุกที่ในแมพมาใช้เมื่อเลือดลด") })
    heal:AddSlider("HealAt", { Text = T("Heal below", "ฮีลเมื่อเลือดต่ำกว่า"), Min = 10, Max = 99, Default = 70, Rounding = 0, Suffix = "%" })
    local meds = PatipanStudio.Heal.Names()
    PatipanStudio.Look.Decorate(heal:AddDropdown("HealMeds", { Text = T("Meds to use", "ยาที่ใช้"), Values = meds, Default = meds, Multi = true, AllowNull = true }))
    heal:AddButton({ Text = T("Heal Now", "ฮีลตอนนี้"), Style = "Success", Func = PatipanStudio.UI.Detach(function()
        if not PatipanStudio.Heal.Now() then Library:Notify("Heal", "No med on the map or HP is full", 3, "Info") end
    end) })

    local gun = tab:AddRightGroupbox(T("Gun Mods", "ม็อดปืน"), "swords")
    gun:AddToggle("SmartReload", { Text = T("Auto reload", "รีโหลดอัตโนมัติ"), Description = T("Tops up your magazine while nobody is in sight", "เติมแม็กตอนไม่มีศัตรูในสายตา") })
    gun:AddSlider("ReloadAt", { Text = T("Reload below", "รีโหลดเมื่อกระสุนต่ำกว่า"), Min = 10, Max = 95, Default = 50, Rounding = 0, Suffix = "%" })
    gun:AddToggle("NoSpread", { Text = T("No spread", "ยิงไม่กระจาย") })
    gun:AddToggle("NoRecoil", { Text = T("No recoil", "ไม่มีแรงถีบ") })
    gun:AddToggle("InstantAds", { Text = T("Instant aim down sights", "เล็งศูนย์ทันที") })
    for _, idx in ipairs(PatipanStudio.Config.GunToggles) do
        Library.Compat.NeedCap(idx, "Gc")
    end
end

function PatipanStudio.UI.BuildLoot(window)
    window:AddTabSection(T("Farming", "ฟาร์ม"))
    local tab = window:AddTab(T("Loot", "ของดรอป"), "coin", T("Gear, valuables and air drops from anywhere", "ของ ของมีค่า และแอร์ดรอปจากทุกที่"))

    local gear = tab:AddLeftGroupbox(T("Best Gear", "ของดีที่สุด"), "star")
    gear:AddToggle("AutoGear", { Text = T("Auto loot best gear", "เก็บของดีสุดอัตโนมัติ"), Description = T("Grabs better guns and armor from any crate on the map", "ดึงปืนและเกราะที่ดีกว่าจากกล่องทุกใบในแมพ") })
    local gearLabels = PatipanStudio.Loot.SlotLabels()
    gear:AddDropdown("LootGear", { Text = T("Gear types", "ประเภทของ"), Values = gearLabels, Default = gearLabels, Multi = true, AllowNull = true })
    gear:AddToggle("AutoAmmo", { Text = T("Auto ammo", "กระสุนอัตโนมัติ"), Description = T("Takes ammo for your guns from anywhere on the map", "ดึงกระสุนที่ตรงกับปืนจากทุกที่ในแมพ") })
    gear:AddDropdown("GearScore", { Text = T("Rank guns by", "จัดอันดับปืนตาม"), Values = { "Damage per second", "Damage per shot", "Rarity" }, Default = "Damage per second" })
    gear:AddButton({ Text = T("Loot Best Now", "เก็บของดีสุดตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Report("Loot", PatipanStudio.Loot.TakeUpgrades(), "Took %d upgrades", "Nothing better on the map")
    end) })

    local money = tab:AddRightGroupbox(T("Valuables", "ของมีค่า"), "coin")
    money:AddToggle("AutoValuables", { Text = T("Auto loot valuables", "เก็บของมีค่าอัตโนมัติ"), Description = T("Takes ore, crystals and gold from every crate on the map", "เก็บแร่ คริสตัล และทองจากกล่องทุกใบในแมพ") })
    local currencies, buffs = PatipanStudio.Loot.Kinds()
    PatipanStudio.Look.Decorate(money:AddDropdown("LootCurrency", { Text = T("Valuables to take", "ของมีค่าที่เก็บ"), Values = currencies, Default = currencies, Multi = true, AllowNull = true, Searchable = true }))
    money:AddToggle("AutoBuffs", { Text = T("Auto loot buffs", "เก็บบัฟอัตโนมัติ"), Description = T("Takes damage, fire rate, ammo and health buffs from every crate", "เก็บบัฟดาเมจ ยิงเร็ว กระสุน และเลือดจากกล่องทุกใบ") })
    money:AddDropdown("LootBuffs", { Text = T("Buffs to take", "บัฟที่เก็บ"), Values = buffs, Default = buffs, Multi = true, AllowNull = true })
    money:AddButton({ Text = T("Loot Valuables Now", "เก็บของมีค่าตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Report("Loot", PatipanStudio.Loot.TakeValuables({ Currency = true, Buff = true }), "Took %d items", "No valuables on the map")
    end) })

    local drop = tab:AddRightGroupbox(T("Air Drop", "แอร์ดรอป"), "flag")
    drop:AddToggle("AutoAirDrop", { Text = T("Auto air drop", "แอร์ดรอปอัตโนมัติ"), Description = T("Takes air drop loot from anywhere on the map", "เก็บของในแอร์ดรอปได้จากทุกที่ในแมพ") })
    drop:AddButton({ Text = T("Loot Air Drops Now", "เก็บแอร์ดรอปตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.UI.Report("Air Drop", PatipanStudio.Loot.EmptyAirDrops(), "Took %d items", "Nothing to take")
    end) })
end

function PatipanStudio.UI.BuildRewards(window)
    local tab = window:AddTab(T("Rewards", "รางวัล"), "qblock", T("Tasks, season pass, gifts, codes and boxes", "ภารกิจ ซีซั่นพาส ของขวัญ โค้ด และกล่อง"))

    local claim = tab:AddLeftGroupbox(T("Claim", "รับรางวัล"), "star")
    claim:AddToggle("AutoClaim", { Text = T("Auto claim", "รับรางวัลอัตโนมัติ"), Description = T("Tasks, season pass, rank rewards, online gifts, sign-in and update gifts", "ภารกิจ ซีซั่นพาส รางวัลแรงก์ ของขวัญออนไลน์ เช็คอิน และของขวัญอัปเดต") })
    local kinds = PatipanStudio.Config.ClaimKinds
    claim:AddDropdown("ClaimKinds", { Text = T("Rewards to claim", "รางวัลที่รับ"), Values = kinds, Default = kinds, Multi = true, AllowNull = true })
    claim:AddButton({ Text = T("Claim All Now", "รับทั้งหมดตอนนี้"), Style = "Success", Func = function() PatipanStudio.Rewards.Request("Claim") end })

    local codes = tab:AddLeftGroupbox(T("Codes", "โค้ด"), "key")
    codes:AddButton({ Text = T("Redeem All Codes", "ใช้โค้ดทั้งหมด"), Style = "Primary", Func = function() PatipanStudio.Rewards.Request("Codes") end })

    local boxes = tab:AddRightGroupbox(T("Boxes", "กล่อง"), "qblock")
    boxes:AddToggle("AutoOpenBoxes", { Text = T("Auto open boxes", "เปิดกล่องอัตโนมัติ"), Description = T("Opens every skin and weapon box you own", "เปิดกล่องสกินและกล่องปืนทุกใบที่มี") })
    local owned = {}
    for _, box in ipairs(PatipanStudio.Rewards.Boxes()) do
        if not table.find(owned, box[2]) then owned[#owned + 1] = box[2] end
    end
    PatipanStudio.Look.Decorate(boxes:AddDropdown("OpenBoxList", { Text = T("Boxes to open", "กล่องที่เปิด"), Values = owned, Default = owned, Multi = true, AllowNull = true, Searchable = true }))
    boxes:AddButton({ Text = T("Open Boxes Now", "เปิดกล่องตอนนี้"), Func = function() PatipanStudio.Rewards.Request("Open") end })

    local shop = tab:AddRightGroupbox(T("Buy Boxes", "ซื้อกล่อง"), "coin")
    local names = {}
    for _, box in ipairs(PatipanStudio.Rewards.Boxes()) do
        if box[3] > 0 then names[#names + 1] = box[2] end
    end
    PatipanStudio.Look.Decorate(shop:AddDropdown("BuyBox", { Text = T("Box", "กล่อง"), Values = names, Default = names[1] }))
    shop:AddSlider("BuyAmount", { Text = T("Amount", "จำนวน"), Min = 1, Max = PatipanStudio.Config.BuyAmountMax, Default = 1, Rounding = 0 })
    shop:AddSlider("KeepGold", { Text = T("Keep gold", "เก็บทองไว้"), Min = 0, Max = 1000000, Default = 50000, Rounding = 0 })
    shop:AddButton({ Text = T("Buy Now", "ซื้อตอนนี้"), Func = function() PatipanStudio.Rewards.Request("Buy") end })
end

function PatipanStudio.UI.BuildVisuals(window)
    window:AddTabSection(T("Visuals", "การมองเห็น"))
    window:AddVisualsTab({ Provider = PatipanStudio.Esp.Targets, Preview = true })

    local tab = window:AddTab(T("Loot ESP", "มองเห็นของ"), "eye", T("Air drops, crates and items", "แอร์ดรอป กล่อง และไอเทม"))
    local esp = tab:AddLeftGroupbox(T("Loot ESP", "มองเห็นของ"), "eye")
    esp:AddToggle("LootEspAirDrop", { Text = T("Air drops", "แอร์ดรอป") })
    esp:AddToggle("LootEspCrate", { Text = T("Crates", "กล่อง") })
    esp:AddToggle("LootEspItem", { Text = T("Items", "ไอเทม") })

    local range = tab:AddRightGroupbox(T("Range", "ระยะ"), "eye")
    range:AddSlider("LootEspRange", { Text = T("Range", "ระยะ"), Min = 50, Max = 2000, Default = 400, Suffix = "m" })
end

function PatipanStudio.UI.BuildMisc(window)
    window:AddTabSection(T("Misc", "อื่นๆ"))
    local tab = window:AddTab(T("Player", "ผู้เล่น"), "oneup", T("Movement, world, server", "การเคลื่อนที่ โลก เซิร์ฟเวอร์"))

    local move = tab:AddLeftGroupbox(T("Movement", "การเคลื่อนที่"), "zap")
    move:AddToggle("Speed", { Text = T("Speed", "วิ่งเร็ว") }):AddKeyPicker("SpeedKey", { Default = "None", Mode = "Toggle" })
    move:AddSlider("SpeedValue", { Text = T("Speed", "ความเร็ว"), Min = 16, Max = 120, Default = 40, Rounding = 0 })
    move:AddToggle("InfiniteJump", { Text = T("Infinite jump", "กระโดดไม่จำกัด") })
    move:AddToggle("Noclip", { Text = T("Noclip", "ทะลุกำแพง") }):AddKeyPicker("NoclipKey", { Default = "None", Mode = "Toggle" })

    local others = tab:AddLeftGroupbox(T("Players", "ผู้เล่น"), "oneup")
    others:AddDropdown("TargetPlayer", { Text = T("Player", "ผู้เล่น"), SpecialType = "Player", AllowNull = true, Searchable = true })
    others:AddButton({ Text = T("Teleport", "วาร์ปไปหา"), Func = function()
        if not PatipanStudio.World.TeleportTo(PatipanStudio.Options.TargetPlayer) then
            Library:Notify(T("Players", "ผู้เล่น"), T("That player isn't in the match", "ผู้เล่นคนนี้ไม่ได้อยู่ในแมตช์"), 4, "Warning")
        end
    end })
    others:AddToggle("Spectate", { Text = T("Spectate", "ส่องผู้เล่น"), Callback = function(on)
        PatipanStudio.World.Spectate(on and PatipanStudio.Options.TargetPlayer or nil)
    end })

    local fly = tab:AddLeftGroupbox(T("Fly", "บิน"), "star")
    fly:AddToggle("Fly", { Text = T("Fly", "บิน"), Description = T("Space up, Ctrl down", "Space ขึ้น Ctrl ลง"), Callback = function(on)
        if not on then PatipanStudio.Movement.StopFly() end
    end }):AddKeyPicker("FlyKey", { Default = "None", Mode = "Toggle" })
    fly:AddSlider("FlySpeed", { Text = T("Fly speed", "ความเร็วบิน"), Min = 20, Max = 200, Default = 60, Rounding = 0 })

    local slide = tab:AddRightGroupbox(T("Slide", "สไลด์"), "zap")
    slide:AddToggle("SuperSlide", { Text = T("Slide boost", "สไลด์ไกล"), Description = T("Faster and longer slides", "สไลด์เร็วและไกลขึ้น") })
    slide:AddSlider("SlideSpeed", { Text = T("Slide speed", "ความเร็วสไลด์"), Min = 60, Max = 300, Default = 120, Rounding = 0 })
    Library.Compat.NeedCap("SuperSlide", "Gc")

    local world = tab:AddRightGroupbox(T("World", "โลก"), "globe")
    world:AddToggle("Fullbright", { Text = T("Fullbright", "สว่างทั้งแมพ") })
    world:AddToggle("CameraFov", { Text = T("Camera FOV", "มุมกล้อง") })
    world:AddSlider("CameraFovValue", { Text = T("FOV", "มุมกล้อง"), Min = 50, Max = 120, Default = 90, Rounding = 0 })

    local server = tab:AddRightGroupbox(T("Server", "เซิร์ฟเวอร์"), "castle")
    server:AddToggle("AntiAfk", { Text = T("Anti AFK", "กันหลุด AFK") })
    server:AddToggle("AdminAlert", { Text = T("Staff alert", "เตือนเมื่อมีทีมงาน"), Description = T("Tells you when a game staff member is in your server", "แจ้งเมื่อทีมงานเกมอยู่ในเซิร์ฟ") })
    server:AddToggle("AdminHop", { Text = T("Leave when staff joins", "ย้ายเซิร์ฟเมื่อทีมงานเข้า") })
    server:AddButton({ Text = T("Rejoin", "เข้าใหม่"), Func = PatipanStudio.UI.Detach(PatipanStudio.World.Rejoin) })
        :AddButton({ Text = T("Server hop", "ย้ายเซิร์ฟ"), Func = PatipanStudio.UI.Detach(function()
            if not PatipanStudio.World.Hop() then Library:Notify(T("Server", "เซิร์ฟเวอร์"), T("No other server found", "ไม่เจอเซิร์ฟอื่น"), 4, "Warning") end
        end) })
end

function PatipanStudio.UI.RefreshStatus()
    local labels, state = PatipanStudio.UI.Labels, PatipanStudio.State
    if labels.Combat then labels.Combat:SetContent(PatipanStudio.Combat.GetStatus()) end
    if labels.Loot then
        local wait = math.max(0, math.floor(state.AirDropAt - Workspace:GetServerTimeNow()))
        local eta = wait > 0 and ("next in %ds"):format(wait) or "-"
        labels.Loot:SetContent(string.format("Gear %d | Valuables %d | Air drop items %d (%s) | Last: %s", state.Looted, state.Valuables, state.AirDrops, eta, state.LastLoot))
    end
    if labels.Esp then labels.Esp:SetContent(PatipanStudio.Esp.GetStatus()) end
    if labels.Heal then labels.Heal:SetContent(PatipanStudio.Heal.GetStatus()) end
    if labels.Farm then labels.Farm:SetContent(PatipanStudio.Farm.GetStatus()) end
    if labels.Rewards then labels.Rewards:SetContent(PatipanStudio.Rewards.GetStatus()) end
end

---@param text string  shown by the UI pump; worker threads that touched game code can't drive the UI
function PatipanStudio.UI.Queue(title, text)
    table.insert(PatipanStudio.State.Notices, { title, text })
end

function PatipanStudio.UI.ShowNotices()
    local notices = PatipanStudio.State.Notices
    if #notices == 0 then return end
    local pending = table.clone(notices)
    table.clear(notices)
    for _, notice in ipairs(pending) do Library:Notify(notice[1], notice[2], 5, "Info") end
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
            if toggle and toggle.Value == true then Util.Try("halt " .. key, toggle.SetValue, toggle, false) end
        end
        Library:Notify("PatipanStudio", name .. " stopped: " .. reason, 6, "Error")
    end
end

function PatipanStudio.UI.HookOnDemand()
    for _, idx in ipairs({ "SilentAim", "Ragebot" }) do
        local toggle = Library.Options[idx]
        if toggle then toggle:OnChanged(function() task.defer(PatipanStudio.Combat.SyncHook) end) end
    end
end

function PatipanStudio.UI.GuardConfigFeatures()
    local unsupported = T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
    local outdated = T("Changed by a game update, wait for a script update", "เกมอัปเดตแล้ว รอสคริปต์อัปเดต")
    local missing = GameLib.Missing.ConfigManager
    for _, idx in ipairs(PatipanStudio.Config.ConfigFeatures) do
        if missing then
            Library.Compat.Block(idx, missing == "Absent" and outdated or unsupported)
        else
            Library.Compat.NeedCap(idx, "Gc")
        end
    end

    for _, idx in ipairs(PatipanStudio.Config.GcFeatures) do
        Library.Compat.NeedCap(idx, "Gc")
    end

    if GameLib.Main then return end
    for _, idx in ipairs(PatipanStudio.Config.RemoteFeatures) do
        local option = Library.Options[idx]
        if option and not option.Blocked then Library.Compat.Block(option, outdated) end
    end
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    local sections = {
        { "main tab", PatipanStudio.UI.BuildMain },
        { "combat tab", PatipanStudio.UI.BuildCombat },
        { "loot tab", PatipanStudio.UI.BuildLoot },
        { "rewards tab", PatipanStudio.UI.BuildRewards },
        { "visuals tab", PatipanStudio.UI.BuildVisuals },
        { "misc tab", PatipanStudio.UI.BuildMisc },
    }
    for _, section in ipairs(sections) do
        Util.Try(section[1], section[2], window)
    end
    Util.Try("settings tab", window.AddSettingsTab, window)

    for key in pairs(PatipanStudio.Options) do
        local widget = Library.Options[key]
        if widget then Util.Try("bind " .. key, PatipanStudio.UI.Bind, widget, key) end
    end
    Util.Try("hooks", PatipanStudio.UI.HookOnDemand)
    Util.Try("feature guards", PatipanStudio.UI.GuardConfigFeatures)

    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.RefreshStatus)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.ShowHalted)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.ShowNotices)
end

---@return boolean  false when the menu could not be shown
local function BuildInterface()
    Library = Util.LoadLibrary(PatipanStudio.Config.UiSource)
    if not Library then return false end
    pcall(MarioBanner.Step, "UI library")
    PatipanStudio.Library = Library
    T = function(en, th) return Library:T(en, th) end

    local opened, err = pcall(Library.CreateWindow, Library, {
        Title = "PatipanStudio",
        SubTitle = "FPS AirDrop Arena by PatipanStudio",
        MenuKey = Enum.KeyCode.LeftControl,
        ConfigFolder = PatipanStudio.Config.SaveFolder,
        Language = "Auto",
        Theme = "Halloween",
        Intro = PatipanStudio.Config.Intro,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            task.defer(Util.Try, "boot", PatipanStudio.Boot)
            task.defer(Util.Try, "autoload config", Library.LoadAutoloadConfig, Library)
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
    Util.Try("combat", PatipanStudio.Combat.Start)
    Util.Try("movement", PatipanStudio.Movement.Start)
    PatipanStudio:Connect(LocalPlayer.Idled, PatipanStudio.World.OnIdled)
    PatipanStudio:Connect(RunService.RenderStepped, PatipanStudio.World.OnRender)
    if LocalPlayer.Character then PatipanStudio.Respawn.Watch(LocalPlayer.Character) end
    PatipanStudio:Connect(LocalPlayer.CharacterAdded, PatipanStudio.Respawn.Watch)

    local config = PatipanStudio.Config
    PatipanStudio.Scheduler.Every("Gun Mods", 0.5, PatipanStudio.Guns.Step, config.GunToggles, PatipanStudio.Guns.Restore)
    PatipanStudio.Scheduler.Every("Auto Air Drop", 1, PatipanStudio.Loot.AirDropStep, { "AutoAirDrop" })
    PatipanStudio.Scheduler.Every("Loot ESP", 0.5, PatipanStudio.Loot.EspStep, config.LootEspToggles, PatipanStudio.Loot.ClearMarks)
    PatipanStudio.Scheduler.Every("Fullbright", 0.5, PatipanStudio.World.Step, { "Fullbright" }, PatipanStudio.World.Step)
    PatipanStudio.Scheduler.Every("Auto Respawn", 0.5, PatipanStudio.Respawn.Step, { "InstantRespawn" })
    PatipanStudio.Scheduler.Every("Best Gear", 0.5, PatipanStudio.Loot.GearStep, { "AutoGear" })
    PatipanStudio.Scheduler.Every("Auto Ammo", 1, PatipanStudio.Loot.AmmoStep, { "AutoAmmo" })
    PatipanStudio.Scheduler.Every("Guns in hand", 0.2, PatipanStudio.Combat.GunStep)
    PatipanStudio.Scheduler.Every("Valuables", 1, PatipanStudio.Loot.ValuablesStep, { "AutoValuables" })
    PatipanStudio.Scheduler.Every("Auto Heal", 0.1, PatipanStudio.Heal.Step, { "AutoHeal" })
    PatipanStudio.Scheduler.Every("Farm stats", 2, PatipanStudio.Farm.Sample)
    PatipanStudio.Scheduler.Every("Auto Rejoin", 2, PatipanStudio.Respawn.Rejoin, { "AutoRejoin" })
    PatipanStudio.Scheduler.Every("Hunt", 0.5, PatipanStudio.Hunt.Step, { "Hunt" })
    PatipanStudio.Scheduler.Every("Rewards", 1, PatipanStudio.Rewards.Step)
    PatipanStudio.Scheduler.Every("Staff", 3, PatipanStudio.Admin.Step)
    Util.Try("scheduler", PatipanStudio.Scheduler.Boot)
end

local function UnloadHub()
    if PatipanStudio.Library and not PatipanStudio.Library.Unloaded then
        PatipanStudio.Library:Unload()
    else
        PatipanStudio:Unload()
    end
end

function PatipanStudio:Unload()
    self.State.Alive = false
    if environment.AirDropArenaUnload == UnloadHub then environment.AirDropArenaUnload = nil end
    PatipanStudio.Combat.Unload()
    PatipanStudio.Guns.Restore()
    for _, key in ipairs({ "Fullbright", "CameraFov", "Noclip", "Fly", "Speed" }) do
        PatipanStudio.Options[key] = false
    end
    pcall(PatipanStudio.Loot.ClearMarks)
    pcall(PatipanStudio.World.Step)
    pcall(PatipanStudio.World.OnRender)
    pcall(PatipanStudio.Movement.OnStepped)
    for _, conn in ipairs(self.State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.State.Connections)
    if PatipanStudio.Respawn.Conn then
        PatipanStudio.Respawn.Conn:Disconnect()
        PatipanStudio.Respawn.Conn = nil
    end
    if Util.Overlay then
        Util.Overlay:Destroy()
        Util.Overlay = nil
    end
end

environment.AirDropArenaUnload = UnloadHub

pcall(MarioBanner.Step, "Systems")
if not BuildInterface() then return end
pcall(MarioBanner.Step, "Interface")
pcall(MarioBanner.Ready)