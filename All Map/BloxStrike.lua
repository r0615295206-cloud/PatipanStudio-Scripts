if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

if game.GameId ~= 7633926880 then
    LocalPlayer:Kick("PatipanStudio: this script is for BloxStrike only")
    return
end

---@return function  the game's own print when the executor exposes it
local function RuntimePrint()
    local ok, renv = pcall(getrenv)
    return ok and type(renv) == "table" and type(renv.print) == "function" and renv.print or print
end

local MarioBanner = {
    Print = RuntimePrint(),
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

pcall(MarioBanner.Show)
pcall(MarioBanner.Step, "Core")

local environment = getgenv and getgenv() or _G
if environment.BloxStrikeUnload then pcall(environment.BloxStrikeUnload) end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local vector2New = Vector2.new
local cframeLookAt = CFrame.lookAt
local osClock = os.clock

local Library, T

local PatipanStudio = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

PatipanStudio.Config = {
    UiSource = "https://raw.githubusercontent.com/r0615295206-cloud/PatipanStudio-Scripts/refs/heads/main/ui.lua",
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-10", "Silent Aim and Ragebot hit again after the game update\nFixed the game crashing when you shoot\nFixed ESP Team Check and health\nAim and ESP now include bots\nSkin pictures, turning skins off restores the stock look\nAuto Rebuy works from round 1, No Flash/No Smoke/FOV restore when off" },
        { "2026-10-03", "Classic PatipanStudio UI is back\nBetter executor support\nImproved Combat & Movement" },
    },
    SaveFolder = "BloxStrike",
    StatusInterval = 1,
    AimRenderPriority = Enum.RenderPriority.Camera.Value + 1,
    RefireGap = 0.12,
    TriggerRay = 2000,
    SilentFocusTime = 1,
    SeeThrough = { "Characters", "Debris", "ThirdPersonWeaponStash" },
    EspCacheMax = 256,
    SoundSelfRange = 6,
    GhostSnap = 45,
    LeadExtra = 0.02,
    LeadMaxSpeed = 60,
    SpreadMethods = { "getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig", "getBaseSpreadForConfig", "getBaseSpread" },
    SoundMaxMarks = 24,
    SoundColor = Color3.fromRGB(255, 196, 64),
    RedeemGap = 1.1,
    RebuyGap = 0.25,
    AlertTries = 20,
    AlertGap = 0.5,
    RequireTimeout = 5,
    MaxFails = 5,
    FailWindow = 10,
    CombatToggles = { "Aimbot", "Triggerbot", "Ragebot", "AimbotShowFov", "SilentShowFov" },
    ModuleFeatures = {
        Net = { "AutoRebuy" },
        Character = { "BunnyHop" },
        Skins = { "SkinChanger" },
    },
    Codes = {
        "1MGROUPMEMBERS", "MYFAULTYALL", "RIANOMINATED2026", "LORE", "DUST_II", "MICHAELSRETURN",
        "FREEDOM", "HAPPYBDAYYUUTO", "GAMEBROKE318", "OHNEPIXEL", "NEBULA", "REACTORDELAY", "BUTTERFLYCASE", "TRADEUPS",
    },
    BoneParts = {
        Head = { "Head" },
        Torso = { "UpperTorso", "Torso", "HumanoidRootPart" },
    },
    BuyStates = { ["Buy Period"] = true, ["Warmup"] = true },
    StickySlack = 1.5,
    HopGap = 0.05,
    HookSettle = 1,
    SkinFile = "BloxStrike/skins.json",
    SkinWears = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" },
    SkinKinds = { Melee = "Knives", Glove = "Gloves", Grenade = "Grenades", C4 = "Gear", ["Zeus x27"] = "Gear" },
    SkinOrder = { "Pistol", "SMG", "Rifle", "Sniper", "Heavy", "Shotgun", "Machine Gun", "Knives", "Gloves", "Grenades", "Gear" },
    SkinRanks = { Forbidden = 9, Special = 8, Red = 7, Pink = 6, Purple = 5, Blue = 4, LightBlue = 3, Gray = 2, White = 1 },
    SkinMainRows = 5,
    SkinArms = { ["Left Arm"] = true, ["Right Arm"] = true },
    GloveKey = "@Glove",
    FovColors = {
        Aimbot = Color3.fromRGB(232, 160, 76),
        Silent = Color3.fromRGB(110, 170, 255),
    },
    EspFocusColor = Color3.fromRGB(255, 214, 64),
    FovLayer = 50,
}

PatipanStudio.State = {
    Alive = true,
    Connections = {},
    Halted = {},
    Notices = {},
    AimTarget = nil,
    AimPart = nil,
    RageTarget = nil,
    RagePart = nil,
    SilentTarget = nil,
    Firing = false,
    PressedAt = 0,
    LastShot = 0,
    Shots = 0,
    Redirected = 0,
    Bought = {},
    LightSaved = nil,
    FovSaved = nil,
    ViewSaved = nil,
    Hooks = {},
    TriggerWarned = false,
    HopAt = 0,
    HopCrouched = false,
    SpaceHeld = false,
    FovBound = false,
    FovBase = 0,
}

PatipanStudio.Options = {
    Aimbot = false,
    AimbotSmooth = 1,
    AimbotBone = "Head",
    AimbotPriority = "Crosshair",
    AimbotFov = 150,
    AimbotShowFov = false,
    AimbotVisible = true,
    AimbotSticky = true,
    AimbotMaxDistance = 1500,
    SilentAim = false,
    SilentHitChance = 100,
    SilentHeadChance = 100,
    SilentPriority = "Crosshair",
    SilentFov = 220,
    SilentShowFov = false,
    SilentVisible = true,
    SilentMaxDistance = 2000,
    SilentPredict = false,
    Triggerbot = false,
    TriggerDelay = 0,
    TriggerHitChance = 100,
    Ragebot = false,
    RageVisible = true,
    RageMaxDistance = 2000,
    NoRecoil = false,
    NoSpread = false,
    Fullbright = false,
    NoFlash = false,
    NoSmoke = false,
    SoundEsp = false,
    SoundEspLife = 3,
    EspMemory = 5,
    CameraFov = false,
    CameraFovValue = 100,
    InfiniteJump = false,
    BunnyHop = false,
    BunnyCrouch = true,
    SkinChanger = false,
    AutoRebuy = false,
    AntiAfk = false,
}

PatipanStudio.Caps = setmetatable({}, {
    __index = function(_, name)
        return Library ~= nil and Library.Compat.Caps[name] == true
    end,
})

PatipanStudio.Util = {}

function PatipanStudio.Util.HttpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" then return body end
    local req = request or http_request or (syn and syn.request)
    if not req then error("no http") end

    local sent, response = pcall(req, { Url = url, Method = "GET" })
    if not sent then error(response) end
    local status = type(response) == "table" and tonumber(response.StatusCode)
    if status ~= 200 or type(response.Body) ~= "string" then error("http status " .. tostring(status)) end
    return response.Body
end

---@param detail any  extra context for the warn; the player only sees `text`
function PatipanStudio.Util.Alert(text, detail)
    warn("[BloxStrike] menu:", detail or text)
    task.spawn(function()
        for _ = 1, PatipanStudio.Config.AlertTries do
            if pcall(StarterGui.SetCore, StarterGui, "SendNotification", { Title = "PatipanStudio", Text = text, Duration = 10 }) then return end
            task.wait(PatipanStudio.Config.AlertGap)
        end
    end)
end

---@return table?  nil after the player was told on screen
function PatipanStudio.Util.LoadLibrary(url)
    local got, source = pcall(PatipanStudio.Util.HttpGet, url)
    local whole = got and type(source) == "string" and source:sub(-64):find("return Library%s*$") ~= nil
    if not whole then
        PatipanStudio.Util.Alert("Could not download the menu. Check your connection and run it again.", got and "truncated or not the menu" or source)
        return nil
    end
    local chunk, err = loadstring(source)
    if type(chunk) ~= "function" then
        PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(err))
        return nil
    end
    local ran, loaded = pcall(chunk)
    if ran and type(loaded) == "table" then return loaded end
    PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(loaded))
    return nil
end

function PatipanStudio.Util.Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[BloxStrike] " .. label .. ":", err) end
    return ok
end

function PatipanStudio.Util.Copy(text)
    local fn = setclipboard or toclipboard
    if not fn then return false end
    return pcall(fn, text)
end

---@return function?  original, nil when already hooked or the executor can't hook it
function PatipanStudio.Util.Hook(key, fn, replacement)
    if type(fn) ~= "function" or PatipanStudio.State.Hooks[key] or not PatipanStudio.Caps.HookFunction then return nil end
    local ok, original = pcall(hookfunction, fn, replacement)
    if not ok or type(original) ~= "function" then
        warn("[BloxStrike] hook " .. key .. ":", ok and "executor returned no original" or original)
        return nil
    end
    PatipanStudio.State.Hooks[key] = { Fn = fn, Original = original }
    return original
end

function PatipanStudio.Util.UnhookAll()
    for key, hook in pairs(PatipanStudio.State.Hooks) do
        local ok, err = pcall(Library.Compat.Unhook, hook.Fn, function() hookfunction(hook.Fn, hook.Original) end)
        if not ok then warn("[BloxStrike] unhook " .. key .. ":", err) end
    end
    table.clear(PatipanStudio.State.Hooks)
end

function PatipanStudio.Util.Decode(raw)
    if type(raw) ~= "string" then return nil end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and decoded or nil
end

function PatipanStudio:Connect(signal, handler)
    local conn = signal:Connect(handler)
    table.insert(self.State.Connections, conn)
    return conn
end

PatipanStudio.GameLib = { Missing = {} }

---@param parent Instance?     where it lives today
---@param home string          parent name a moved copy must still have
---@return Instance?           nil after a warning that names it
function PatipanStudio.GameLib.Find(parent, name, class, home)
    local found = parent and parent:FindFirstChild(name)
    if found and found:IsA(class) then return found end
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == name and desc:IsA(class) and desc.Parent and desc.Parent.Name == home then return desc end
    end
    PatipanStudio.GameLib.Missing[name] = "Absent"
    warn("[BloxStrike] " .. home .. "." .. name .. " not found, features that need it are blocked")
    return nil
end

---@return any  module, or nil when this executor can't require it (never throws)
function PatipanStudio.GameLib.Require(inst)
    if not (inst and inst:IsA("ModuleScript")) then return nil end
    local ok, mod = pcall(require, inst)
    if ok then return mod end

    local done, okAgain, again = false, false, nil
    task.spawn(function()
        pcall(setthreadidentity, 2)
        local read, identity = pcall(getthreadidentity)
        if read and identity == 2 then okAgain, again = pcall(require, inst) end
        done = true
    end)
    local deadline = osClock() + PatipanStudio.Config.RequireTimeout
    while not done and osClock() < deadline do task.wait() end
    if okAgain then return again end
    warn("[BloxStrike] require " .. inst.Name .. ":", mod)
    return nil
end

do
    local database = ReplicatedStorage:FindFirstChild("Database")
    local security = database and database:FindFirstChild("Security")
    local custom = database and database:FindFirstChild("Custom")
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    local find = PatipanStudio.GameLib.Find
    PatipanStudio.GameLib.Net = PatipanStudio.GameLib.Require(find(security, "Remotes", "ModuleScript", "Security"))
    PatipanStudio.GameLib.Character = PatipanStudio.GameLib.Require(find(controllers, "CharacterController", "ModuleScript", "Controllers"))
    PatipanStudio.GameLib.Camera = PatipanStudio.GameLib.Require(find(controllers, "CameraController", "ModuleScript", "Controllers"))
    PatipanStudio.GameLib.WeaponFolder = find(custom, "Weapons", "Folder", "Custom")
    PatipanStudio.GameLib.Rarities = PatipanStudio.GameLib.Require(find(custom, "Rarities", "ModuleScript", "GameStats"))
    local vfx = ReplicatedStorage:FindFirstChild("Components") and ReplicatedStorage.Components:FindFirstChild("VFXLibary", true)
    PatipanStudio.GameLib.Smoke = PatipanStudio.GameLib.Require(find(vfx, "CreateVoxelSmoke", "ModuleScript", "VFXLibary"))
    PatipanStudio.GameLib.Flash = PatipanStudio.GameLib.Require(find(vfx, "FlashEffect", "ModuleScript", "VFXLibary"))
end

PatipanStudio.Weapons = {}
do
    local folder = PatipanStudio.GameLib.WeaponFolder
    for _, module in ipairs(folder and folder:GetChildren() or {}) do
        local data = module:IsA("ModuleScript") and PatipanStudio.GameLib.Require(module)
        if type(data) == "table" and data.FireRate then PatipanStudio.Weapons[module.Name] = data end
    end
end

PatipanStudio.Player = {}

function PatipanStudio.Player.Character()
    local chars = Workspace:FindFirstChild("Characters")
    return (chars and chars:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
end

function PatipanStudio.Player.Alive()
    local char = PatipanStudio.Player.Character()
    return char ~= nil and char.Parent ~= nil and tostring(LocalPlayer:GetAttribute("Dead")) ~= "true"
end

function PatipanStudio.Player.Humanoid()
    local char = PatipanStudio.Player.Character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

---@return table?  the game's own local character state; nil outside a round
function PatipanStudio.Player.Body()
    local controller = PatipanStudio.GameLib.Character
    if not controller then return nil end
    local ok, body = pcall(controller.getCurrentCharacter)
    return ok and body or nil
end

function PatipanStudio.Player.Equipped()
    return PatipanStudio.Util.Decode(LocalPlayer:GetAttribute("CurrentEquipped"))
end

PatipanStudio.Target = { Motion = setmetatable({}, { __mode = "k" }) }

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
local losFilter = table.create(3)
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude

function PatipanStudio.Target.Candidates()
    local list = {}
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return list end
    for _, model in ipairs(chars:GetChildren()) do
        if model.Name ~= LocalPlayer.Name and model:IsA("Model") then list[#list + 1] = model end
    end
    return list
end

function PatipanStudio.Target.Owner(model)
    return Players:FindFirstChild(model.Name)
end

---@return string?  team of a character: owner's Team attribute, else the team that wears this character model
function PatipanStudio.Target.TeamOf(model)
    local owner = model and PatipanStudio.Target.Owner(model)
    local team = owner and owner:GetAttribute("Team")
    if team then return team end
    local look = model and model:GetAttribute("CharacterName")
    if not look then return nil end
    if look == Workspace:GetAttribute("CTCharacter") then return "Counter-Terrorists" end
    if look == Workspace:GetAttribute("TCharacter") then return "Terrorists" end
    return nil
end

function PatipanStudio.Target.MyTeam()
    return LocalPlayer:GetAttribute("Team") or PatipanStudio.Target.TeamOf(PatipanStudio.Player.Character())
end

function PatipanStudio.Target.IsEnemy(model)
    if tostring(model:GetAttribute("Dead")) == "true" then return false end
    if not PatipanStudio.Target.Owner(model) and model:GetAttribute("Health") == nil then return false end
    if PatipanStudio.Target.FreeForAll() then return true end
    local mine = PatipanStudio.Target.MyTeam()
    if mine == nil then return false end
    return PatipanStudio.Target.TeamOf(model) ~= mine
end

---Samples every enemy's head each frame so shots can lead a moving target.
function PatipanStudio.Target.Track()
    local motion, now = PatipanStudio.Target.Motion, osClock()
    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        local head = model:FindFirstChild("Head")
        if not head then continue end
        local last = motion[head]
        if last and now > last.Time then
            local step = (head.Position - last.Pos) / (now - last.Time)
            last.Vel = last.Vel and last.Vel:Lerp(step, 0.5) or step
            last.Pos, last.Time = head.Position, now
        else
            motion[head] = { Pos = head.Position, Time = now, Vel = Vector3.zero }
        end
    end
end

---@return Vector3  where the part will be once the shot reaches the server
function PatipanStudio.Target.Lead(part)
    if not PatipanStudio.Options.SilentPredict then return part.Position end
    local track = PatipanStudio.Target.Motion[part] or PatipanStudio.Target.Motion[part.Parent and part.Parent:FindFirstChild("Head")]
    local vel = track and track.Vel or Vector3.zero
    if vel.Magnitude > PatipanStudio.Config.LeadMaxSpeed then return part.Position end
    local ok, ping = pcall(LocalPlayer.GetNetworkPing, LocalPlayer)
    return part.Position + vel * ((ok and ping or 0.05) + PatipanStudio.Config.LeadExtra)
end

---@return boolean  true in Deathmatch, where the team picker is only cosmetic
function PatipanStudio.Target.FreeForAll()
    return tostring(Workspace:GetAttribute("Gamemode")):find("Deathmatch") ~= nil
end

function PatipanStudio.Target.Part(model, bone)
    for _, name in ipairs(PatipanStudio.Config.BoneParts[bone] or PatipanStudio.Config.BoneParts.Head) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return model:FindFirstChild("HumanoidRootPart")
end

function PatipanStudio.Target.Visible(from, model, point)
    local skip = { Workspace.CurrentCamera, model }
    for _, name in ipairs(PatipanStudio.Config.SeeThrough) do
        local folder = Workspace:FindFirstChild(name)
        if folder then skip[#skip + 1] = folder end
    end
    wallParams.FilterDescendantsInstances = skip
    return Workspace:Raycast(from, point - from, wallParams) == nil
end

---@param cfg table  { Bone, Fov?, Visible, MaxDistance, Priority }  Fov nil = whole map
---@return Model?, BasePart?
function PatipanStudio.Target.Pick(cfg)
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local center = cam.ViewportSize / 2
    local best, bestPart, bestScore

    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        if not PatipanStudio.Target.IsEnemy(model) then continue end
        local part = PatipanStudio.Target.Part(model, cfg.Bone)
        if not part then continue end
        local dist = (part.Position - origin).Magnitude
        if dist > cfg.MaxDistance then continue end

        local screen, onScreen = cam:WorldToViewportPoint(part.Position)
        local screenDist = (vector2New(screen.X, screen.Y) - center).Magnitude
        if cfg.Fov and (not onScreen or screenDist > cfg.Fov) then continue end
        if cfg.Visible and not PatipanStudio.Target.Visible(origin, model, part.Position) then continue end

        local score = dist
        if cfg.Priority == "Crosshair" then
            score = onScreen and screenDist or 1e6 + dist
        elseif cfg.Priority == "Health" then
            score = (tonumber(model:GetAttribute("Health")) or 100) * 1e4 + dist
        end
        if not bestScore or score < bestScore then best, bestPart, bestScore = model, part, score end
    end
    return best, bestPart
end

---@return boolean  still a valid lock, with a looser fov
function PatipanStudio.Target.StillValid(model, part, cfg)
    if not (model and part and part.Parent and PatipanStudio.Target.IsEnemy(model)) then return false end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    if (part.Position - origin).Magnitude > cfg.MaxDistance then return false end
    if cfg.Visible and not PatipanStudio.Target.Visible(origin, model, part.Position) then return false end
    if not cfg.Fov then return true end
    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
    local center = cam.ViewportSize / 2
    return onScreen and (vector2New(screen.X, screen.Y) - center).Magnitude <= cfg.Fov * PatipanStudio.Config.StickySlack
end

---@return Model?  enemy under the crosshair right now
function PatipanStudio.Target.UnderCrosshair()
    local cam = Workspace.CurrentCamera
    losFilter[1], losFilter[2], losFilter[3] = PatipanStudio.Player.Character(), cam, nil
    losParams.FilterDescendantsInstances = losFilter
    local hit = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * PatipanStudio.Config.TriggerRay, losParams)
    if not hit then return nil end
    local chars = Workspace:FindFirstChild("Characters")
    local model = hit.Instance
    while model and model.Parent ~= chars do model = model.Parent end
    if model and model:IsA("Model") and PatipanStudio.Target.IsEnemy(model) then return model end
    return nil
end

local function roll(percent)
    return percent >= 100 or math.random() * 100 < percent
end

PatipanStudio.Aimbot = {}

function PatipanStudio.Aimbot.Config()
    local o = PatipanStudio.Options
    return { Bone = o.AimbotBone, Fov = o.AimbotFov, Visible = o.AimbotVisible, MaxDistance = o.AimbotMaxDistance, Priority = o.AimbotPriority }
end

function PatipanStudio.Aimbot.Step()
    local state, o = PatipanStudio.State, PatipanStudio.Options
    if not o.Aimbot then state.AimTarget, state.AimPart = nil, nil return end
    local cfg = PatipanStudio.Aimbot.Config()
    if o.AimbotSticky and PatipanStudio.Target.StillValid(state.AimTarget, state.AimPart, cfg) then return end
    state.AimTarget, state.AimPart = PatipanStudio.Target.Pick(cfg)
end

---@param dt number  frame time from RenderStep
function PatipanStudio.Aimbot.Lock(dt)
    local o, state = PatipanStudio.Options, PatipanStudio.State
    local part, smooth = nil, 1
    if o.Ragebot and state.RagePart and state.RagePart.Parent then
        part = state.RagePart
    elseif o.Aimbot and state.AimPart and state.AimPart.Parent then
        part, smooth = state.AimPart, math.max(o.AimbotSmooth, 1)
    end
    if not part then return end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local want = (part.Position - origin).Unit
    local alpha = 1 - (1 - 1 / smooth) ^ ((dt or 1 / 60) * 60)
    local look = smooth <= 1 and want or cam.CFrame.LookVector:Lerp(want, alpha).Unit
    cam.CFrame = cframeLookAt(origin, origin + look)
end

PatipanStudio.Silent = {}

---@param forced boolean  ragebot shot: always hits, no fov
function PatipanStudio.Silent.Config(bone, forced)
    local o = PatipanStudio.Options
    if forced then return { Bone = bone, Visible = o.RageVisible, MaxDistance = o.RageMaxDistance, Priority = "Distance" } end
    return { Bone = bone, Fov = o.SilentFov, Visible = o.SilentVisible, MaxDistance = o.SilentMaxDistance, Priority = o.SilentPriority }
end

---@return BasePart?  part this shot should go to, nil = shoot where you look
function PatipanStudio.Silent.Aim()
    local o, state = PatipanStudio.Options, PatipanStudio.State
    state.SilentTarget = nil
    if not (o.SilentAim or o.Ragebot) then return nil end
    local forced = o.Ragebot
    if not forced and not roll(o.SilentHitChance) then return nil end
    local bone = (forced or roll(o.SilentHeadChance)) and "Head" or "Torso"
    local target, part = PatipanStudio.Target.Pick(PatipanStudio.Silent.Config(bone, forced))
    state.SilentTarget = target
    return part
end

---The server checks bullets against where you really look, so each new bullet turns the camera to the target and the view goes back as the shot is sent, before anything is drawn.
function PatipanStudio.Silent.InstallHook()
    local gun = PatipanStudio.Guns.FindClass()
    if gun then
        local original
        original = PatipanStudio.Util.Hook("Shoot", gun.shoot, function(...)
            local state = PatipanStudio.State
            state.LastShot = osClock()
            state.Shots += 1
            return original(...)
        end)
    end
    local bullet = PatipanStudio.Guns.FindBullet()
    if bullet and type(bullet.create) == "function" then
        local create
        create = PatipanStudio.Util.Hook("Bullet", bullet.create, function(...)
            PatipanStudio.Silent.Flick()
            return create(...)
        end)
    end
    PatipanStudio.Guns.HookSpread()

    local net = PatipanStudio.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.ShootWeapon
    if not packet then return end
    local send
    send = PatipanStudio.Util.Hook("Send", packet.Send, function(...)
        PatipanStudio.Silent.RestoreView()
        return send(...)
    end)
end

---Turns the camera onto the silent aim target for this bullet.
function PatipanStudio.Silent.Flick()
    local ok, part = pcall(PatipanStudio.Silent.Aim)
    local cam, state = Workspace.CurrentCamera, PatipanStudio.State
    if not (ok and part and cam) then return end
    state.ViewSaved = state.ViewSaved or cam.CFrame
    cam.CFrame = cframeLookAt(cam.CFrame.Position, PatipanStudio.Target.Lead(part))
    state.Redirected += 1
end

---Puts your view back before the game's camera runs, so silent aim never moves what you see.
function PatipanStudio.Silent.RestoreView()
    local state, cam = PatipanStudio.State, Workspace.CurrentCamera
    if not state.ViewSaved then return end
    if cam then cam.CFrame = state.ViewSaved end
    state.ViewSaved = nil
end

PatipanStudio.Trigger = {}

function PatipanStudio.Trigger.Press(down)
    if down and Library.Window and Library.Window.Visible then return end
    PatipanStudio.State.Firing = down
    if down then PatipanStudio.State.PressedAt = osClock() end
    local center = Workspace.CurrentCamera.ViewportSize / 2
    pcall(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager, center.X, center.Y, 0, down, game, 0)
end

---@param want boolean  holds auto guns and re-clicks semi-auto ones
function PatipanStudio.Trigger.Fire(want)
    local state, now = PatipanStudio.State, osClock()
    if not want then
        if state.Firing then PatipanStudio.Trigger.Press(false) end
        return
    end
    if not state.Firing then
        PatipanStudio.Trigger.Press(true)
        return
    end
    local gap = PatipanStudio.Config.RefireGap
    if now - state.PressedAt > gap and now - state.LastShot > gap then PatipanStudio.Trigger.Press(false) end
end

function PatipanStudio.Trigger.Wanted()
    local o, state = PatipanStudio.Options, PatipanStudio.State
    if not o.Triggerbot then return false end
    local model = PatipanStudio.Target.UnderCrosshair()
    if model ~= state.TriggerModel then
        state.TriggerModel = model
        state.TriggerSeen = model and osClock() or nil
        state.TriggerRoll = model ~= nil and roll(o.TriggerHitChance)
    end
    if not model or not state.TriggerRoll then return false end
    return osClock() - state.TriggerSeen >= o.TriggerDelay / 1000
end

PatipanStudio.Rage = {}

function PatipanStudio.Rage.Step()
    local state = PatipanStudio.State
    if not PatipanStudio.Options.Ragebot then state.RageTarget, state.RagePart = nil, nil return false end
    state.RageTarget, state.RagePart = PatipanStudio.Target.Pick(PatipanStudio.Silent.Config("Head", true))
    return state.RageTarget ~= nil
end

PatipanStudio.Combat = { Circles = {} }

---@return ScreenGui  made once; hidden gui first, then CoreGui, then PlayerGui
function PatipanStudio.Combat.Screen()
    local screen = PatipanStudio.Combat.Gui
    if screen and screen.Parent then return screen end

    screen = Instance.new("ScreenGui")
    screen.Name = "PatipanStudioFov"
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.DisplayOrder = PatipanStudio.Config.FovLayer

    local function Mount(parent) screen.Parent = parent end
    local okHui, hui = pcall(gethui)
    local mounted = okHui and hui ~= nil and pcall(Mount, hui)
    if not mounted then mounted = pcall(Mount, game:GetService("CoreGui")) end
    if not mounted then Mount(LocalPlayer:FindFirstChildOfClass("PlayerGui")) end

    PatipanStudio.Combat.Gui = screen
    return screen
end

---@return table  { Drawing = circle }, or { Frame = ring } drawn with Gui when Drawing is missing
function PatipanStudio.Combat.NewCircle(color)
    if PatipanStudio.Caps.Drawing then
        local circle = Drawing.new("Circle")
        circle.Thickness, circle.NumSides, circle.Filled, circle.Color = 1.5, 64, false, color
        return { Drawing = circle }
    end
    local frame = Instance.new("Frame")
    frame.AnchorPoint = vector2New(0.5, 0.5)
    frame.BackgroundTransparency = 1
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(1, 0)
    round.Parent = frame
    local edge = Instance.new("UIStroke")
    edge.Thickness, edge.Color = 1.5, color
    edge.Parent = frame
    frame.Parent = PatipanStudio.Combat.Screen()
    return { Frame = frame }
end

function PatipanStudio.Combat.Circle(key, show, radius)
    local circle = PatipanStudio.Combat.Circles[key]
    if not circle then
        if not show then return end
        circle = PatipanStudio.Combat.NewCircle(PatipanStudio.Config.FovColors[key])
        PatipanStudio.Combat.Circles[key] = circle
    end
    local center = Workspace.CurrentCamera.ViewportSize / 2
    local drawing, frame = circle.Drawing, circle.Frame
    if drawing then
        drawing.Visible, drawing.Position, drawing.Radius = show, center, radius
        return
    end
    frame.Visible = show
    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
end

function PatipanStudio.Combat.Step()
    local o, state = PatipanStudio.Options, PatipanStudio.State
    PatipanStudio.Combat.Circle("Aimbot", o.AimbotShowFov, o.AimbotFov)
    PatipanStudio.Combat.Circle("Silent", o.SilentShowFov, o.SilentFov)
    if not PatipanStudio.Player.Alive() then
        state.AimTarget, state.AimPart, state.RageTarget, state.RagePart, state.SilentTarget = nil, nil, nil, nil, nil
        PatipanStudio.Trigger.Fire(false)
        return
    end
    if o.SilentAim or o.Ragebot then PatipanStudio.Target.Track() end
    PatipanStudio.Aimbot.Step()
    local rage = PatipanStudio.Rage.Step()
    PatipanStudio.Trigger.Fire(rage or PatipanStudio.Trigger.Wanted())
end

function PatipanStudio.Combat.Rest()
    local state = PatipanStudio.State
    state.AimTarget, state.AimPart, state.RageTarget, state.RagePart, state.SilentTarget = nil, nil, nil, nil, nil
    PatipanStudio.Trigger.Fire(false)
    for key in pairs(PatipanStudio.Combat.Circles) do
        PatipanStudio.Combat.Circle(key, false, 0)
    end
end

function PatipanStudio.Combat.Start()
    RunService:BindToRenderStep("PatipanStudioView", Enum.RenderPriority.First.Value, PatipanStudio.Silent.RestoreView)
    RunService:BindToRenderStep("PatipanStudioAim", PatipanStudio.Config.AimRenderPriority, PatipanStudio.Aimbot.Lock)
    PatipanStudio:Connect(RunService.Heartbeat, function()
        local ok, err = pcall(PatipanStudio.Combat.Step)
        if ok then
            PatipanStudio.Faults.Clear("Combat")
        else
            PatipanStudio.Faults.Report("Combat", err, PatipanStudio.Config.CombatToggles, PatipanStudio.Combat.Rest)
        end
    end)
end

function PatipanStudio.Combat.Unload()
    PatipanStudio.Trigger.Fire(false)
    pcall(RunService.UnbindFromRenderStep, RunService, "PatipanStudioAim")
    pcall(RunService.UnbindFromRenderStep, RunService, "PatipanStudioView")
    for key, circle in pairs(PatipanStudio.Combat.Circles) do
        PatipanStudio.Combat.Circles[key] = nil
        if circle.Frame then
            circle.Frame:Destroy()
        else
            pcall(function() circle.Drawing:Remove() end)
        end
    end
    if PatipanStudio.Combat.Gui then
        PatipanStudio.Combat.Gui:Destroy()
        PatipanStudio.Combat.Gui = nil
    end
end

PatipanStudio.Guns = { Signature = nil, Warned = false }

function PatipanStudio.Guns.HookKick()
    local cam = PatipanStudio.GameLib.Camera
    if not cam then return end
    local kick, aim, rotation
    kick = PatipanStudio.Util.Hook("Kick", cam.weaponKick, function(...)
        if PatipanStudio.Options.NoRecoil then return end
        return kick(...)
    end)
    aim = PatipanStudio.Util.Hook("Recoil", cam.setWeaponRecoil, function(...)
        if PatipanStudio.Options.NoRecoil then return end
        return aim(...)
    end)
    rotation = PatipanStudio.Util.Hook("KickRotation", cam.getWeaponKickRotation, function(...)
        if PatipanStudio.Options.NoRecoil then return Vector3.zero end
        return rotation(...)
    end)
end

---@return boolean  true while any scope or zoom is up
function PatipanStudio.Guns.Scoped()
    if LocalPlayer:GetAttribute("IsSniperScoped") == true then return true end
    local cam = PatipanStudio.GameLib.Camera
    local getter = cam and cam.getTargetFOV
    if type(getter) ~= "function" then return false end
    local ok, target = pcall(getter)
    if not ok or type(target) ~= "number" then return false end

    local state = PatipanStudio.State
    if target > state.FovBase then state.FovBase = target end
    return target < state.FovBase
end

function PatipanStudio.Guns.StepFov()
    local camera, state = Workspace.CurrentCamera, PatipanStudio.State
    if not camera then return end
    if not PatipanStudio.Options.CameraFov then
        if state.FovSaved then camera.FieldOfView, state.FovSaved = state.FovSaved, nil end
        state.FovBase = 0
        return
    end
    if PatipanStudio.Guns.Scoped() then return end
    state.FovSaved = state.FovSaved or camera.FieldOfView
    camera.FieldOfView = PatipanStudio.Options.CameraFovValue
end

function PatipanStudio.Guns.BindFov()
    local state = PatipanStudio.State
    if state.FovBound then return end
    state.FovBound = true
    RunService:BindToRenderStep("PatipanStudioFov", Enum.RenderPriority.Camera.Value + 3, PatipanStudio.Guns.StepFov)
end

function PatipanStudio.Guns.UnbindFov()
    local state, camera = PatipanStudio.State, Workspace.CurrentCamera
    if state.FovSaved and camera then camera.FieldOfView, state.FovSaved = state.FovSaved, nil end
    state.FovBound = false
    pcall(RunService.UnbindFromRenderStep, RunService, "PatipanStudioFov")
end

function PatipanStudio.Guns.FindClass()
    if not PatipanStudio.Caps.Gc or not PatipanStudio.Caps.HookFunction then return nil end
    for _, entry in ipairs(getgc(true)) do
        if type(entry) == "table" and rawget(entry, "getSpread") and rawget(entry, "shoot") and rawget(entry, "setupRecoil") then return entry end
    end
    return nil
end

---@return table?  the bullet class that rolls spread for every shot
function PatipanStudio.Guns.FindBullet()
    if not PatipanStudio.Caps.Gc or not PatipanStudio.Caps.HookFunction then return nil end
    for _, entry in ipairs(getgc(true)) do
        if type(entry) == "table" and rawget(entry, "getTrueSpread") and rawget(entry, "getSpreadForConfig") then return entry end
    end
    return nil
end

---Every spread roll the bullet class makes returns 0 with No Spread, and while a silent aim shot is being built.
function PatipanStudio.Guns.HookSpread()
    local bullet = PatipanStudio.Guns.FindBullet()
    if not bullet then return end
    for _, method in ipairs(PatipanStudio.Config.SpreadMethods) do
        if type(bullet[method]) ~= "function" then continue end
        local original
        original = PatipanStudio.Util.Hook("Spread:" .. method, bullet[method], function(...)
            local value = original(...)
            if type(value) == "number" and (PatipanStudio.Options.NoSpread or PatipanStudio.State.ViewSaved) then return 0 end
            return value
        end)
    end
end

PatipanStudio.Esp = { Count = 0, Decoded = {}, CacheSize = 0, Ghosts = {}, Folder = nil }

---@return table?  JSON attribute decoded once per distinct raw string
function PatipanStudio.Esp.Attr(owner, key)
    local raw = owner:GetAttribute(key)
    if type(raw) ~= "string" then return nil end
    local esp = PatipanStudio.Esp
    if esp.Decoded[raw] == nil then
        esp.CacheSize += 1
        if esp.CacheSize > PatipanStudio.Config.EspCacheMax then table.clear(esp.Decoded) esp.CacheSize = 1 end
        esp.Decoded[raw] = PatipanStudio.Util.Decode(raw) or false
    end
    return esp.Decoded[raw] or nil
end

---@return string  " C4 Kit Helmet Scoped" style tags, "" when none
function PatipanStudio.Esp.Flags(owner)
    if not owner then return "" end
    local flags = {}
    local armor = PatipanStudio.Esp.Attr(owner, "Armor")
    local bomb = PatipanStudio.Esp.Attr(owner, "Slot5")
    if bomb and bomb.Weapon == "C4" then flags[#flags + 1] = "C4" end
    if owner:GetAttribute("HasDefuseKit") == true then table.insert(flags, "Kit") end
    if armor and type(armor.Type) == "string" and armor.Type:find("Helmet") then flags[#flags + 1] = "Helmet" end
    if owner:GetAttribute("IsSniperScoped") == true then flags[#flags + 1] = "Scoped" end
    return #flags > 0 and " " .. table.concat(flags, " ") or ""
end

---@return Model?  whatever aimbot, silent aim or ragebot is locked on
function PatipanStudio.Esp.Focus()
    local state = PatipanStudio.State
    local silent = osClock() - state.LastShot < PatipanStudio.Config.SilentFocusTime and state.SilentTarget or nil
    return state.AimTarget or silent or state.RageTarget
end

---@return table  one lasting stand-in per player, so a body that blinks in and out of view never rebuilds its box
function PatipanStudio.Esp.Ghost(name)
    local esp = PatipanStudio.Esp
    local ghost = esp.Ghosts[name]
    if ghost and ghost.Model.Parent then return ghost end
    if not (esp.Folder and esp.Folder.Parent) then
        esp.Folder = Instance.new("Folder")
        esp.Folder.Name = "PatipanStudioGhosts"
        esp.Folder.Parent = Workspace.CurrentCamera
    end
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name, root.Size, root.Transparency = "HumanoidRootPart", Vector3.new(2, 2, 1), 1
    root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = esp.Folder
    ghost = { Model = model, Root = root, Seen = 0, Heard = 0 }
    esp.Ghosts[name] = ghost
    return ghost
end

---@return table  Library.Visuals row for one player, live body or last known spot
function PatipanStudio.Esp.Row(ghost, model, owner, mine, focus)
    local equipped = owner and PatipanStudio.Esp.Attr(owner, "CurrentEquipped")
    local label = owner and owner.DisplayName or ghost.Model.Name
    if equipped and equipped.Name then label = label .. " [" .. equipped.Name .. "]" end
    local live = model and model:FindFirstChild("HumanoidRootPart")
    if not live then label = label .. " ?" end
    return {
        Model = ghost.Model,
        Root = live or ghost.Root,
        Adornee = model or false,
        Name = label .. PatipanStudio.Esp.Flags(owner),
        Health = tonumber(owner and owner:GetAttribute("Health")) or tonumber(model and model:GetAttribute("Health")) or 100,
        MaxHealth = tonumber(model and model:GetAttribute("MaxHealth")) or 100,
        Friendly = ghost.Friendly,
        Color = model ~= nil and model == focus and PatipanStudio.Config.EspFocusColor or nil,
    }
end

---@return table[]  targets in the shape Library.Visuals expects; bots count as enemies
function PatipanStudio.Esp.Targets()
    local esp, now = PatipanStudio.Esp, osClock()
    local list = {}
    local mine = PatipanStudio.Target.MyTeam()
    local ffa = PatipanStudio.Target.FreeForAll()
    local focus = PatipanStudio.Esp.Focus()
    pcall(PatipanStudio.Sound.Install)
    local live = {}
    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        if PatipanStudio.Esp.IsDead(model, PatipanStudio.Target.Owner(model)) then
            PatipanStudio.Esp.Forget(model.Name)
            continue
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local ghost = esp.Ghost(model.Name)
        ghost.Root.CFrame, ghost.Seen = hrp.CFrame, now
        ghost.Friendly = not ffa and mine ~= nil and PatipanStudio.Target.TeamOf(model) == mine
        live[model.Name] = true
        list[#list + 1] = esp.Row(ghost, model, PatipanStudio.Target.Owner(model), mine, focus)
    end
    local memory = PatipanStudio.Options.EspMemory
    for name, ghost in pairs(esp.Ghosts) do
        if live[name] then continue end
        local owner = Players:FindFirstChild(name)
        if owner and PatipanStudio.Esp.IsDead(nil, owner) then
            PatipanStudio.Esp.Forget(name)
            continue
        end
        local gone = not ghost.Model.Parent or (not owner and now - ghost.Seen > memory)
        if gone or now - math.max(ghost.Seen, ghost.Heard) > memory then
            if gone and not owner then
                ghost.Model:Destroy()
                esp.Ghosts[name] = nil
            end
            continue
        end
        list[#list + 1] = esp.Row(ghost, nil, owner, mine, focus)
    end
    esp.Count = #list
    return list
end

---@return boolean  true once a player or bot is dead, by body flag or 0 health
function PatipanStudio.Esp.IsDead(model, owner)
    if model and (tostring(model:GetAttribute("Dead")) == "true" or (tonumber(model:GetAttribute("Health")) or 1) <= 0) then return true end
    if owner and (owner:GetAttribute("Dead") == true or (tonumber(owner:GetAttribute("Health")) or 1) <= 0) then return true end
    return false
end

---Drops the remembered spot of someone who died, so no box stays where they fell.
function PatipanStudio.Esp.Forget(name)
    local ghost = PatipanStudio.Esp.Ghosts[name]
    if ghost then ghost.Seen, ghost.Heard = 0, 0 end
end

---Moves the stand-in of the hidden enemy closest to a footstep or shot, so hidden players keep a box.
function PatipanStudio.Esp.Hear(pos, weapon)
    local esp, now = PatipanStudio.Esp, osClock()
    local best, bestDist = nil, PatipanStudio.Config.GhostSnap
    for name, ghost in pairs(esp.Ghosts) do
        if ghost.Friendly or now - ghost.Seen < 0.3 then continue end
        local owner = Players:FindFirstChild(name)
        local equipped = owner and PatipanStudio.Esp.Attr(owner, "CurrentEquipped")
        if weapon and equipped and equipped.Name and equipped.Name ~= weapon then continue end
        local dist = (ghost.Root.Position - pos).Magnitude
        if dist < bestDist then best, bestDist = ghost, dist end
    end
    if not best then return end
    best.Root.CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0))
    best.Heard = now
end

PatipanStudio.Sound = { Marks = {}, Entry = nil, Original = nil, Folder = nil }

---Hooks into the game's own sound listener: every footstep and shot of every player arrives with its position, even behind walls.
function PatipanStudio.Sound.Install()
    local sound = PatipanStudio.Sound
    if sound.Entry then return true end
    local net = PatipanStudio.GameLib.Net
    local packet = net and net.Sound and net.Sound.ReplicateSound
    if not (packet and PatipanStudio.Caps.Upvalues) then return false end
    local ok, listeners = pcall(function() return getupvalues(packet.Listen)[1] end)
    if not ok or type(listeners) ~= "table" then return false end
    for _, entry in ipairs(listeners) do
        if type(entry) == "table" and type(entry.callback) == "function" then
            sound.Entry, sound.Original = entry, entry.callback
            entry.callback = function(info, ...)
                PatipanStudio.Util.Try("sound esp", PatipanStudio.Sound.Heard, info)
                return sound.Original(info, ...)
            end
            return true
        end
    end
    return false
end

function PatipanStudio.Sound.Uninstall()
    local sound = PatipanStudio.Sound
    if sound.Entry then sound.Entry.callback = sound.Original end
    sound.Entry, sound.Original = nil, nil
    for _, mark in ipairs(sound.Marks) do mark.Gui:Destroy() end
    table.clear(sound.Marks)
end

---@return boolean  true when the sound came from you or a teammate you can see
function PatipanStudio.Sound.Friendly(pos)
    local range = PatipanStudio.Config.SoundSelfRange
    local me = PatipanStudio.Player.Character()
    if me and (me:GetPivot().Position - pos).Magnitude < range then return true end
    if PatipanStudio.Target.FreeForAll() then return false end
    for _, model in ipairs(PatipanStudio.Target.Candidates()) do
        if not PatipanStudio.Target.IsEnemy(model) and (model:GetPivot().Position - pos).Magnitude < range then return true end
    end
    return false
end

function PatipanStudio.Sound.Heard(info)
    if type(info) ~= "table" or typeof(info.Position) ~= "Vector3" then return end
    local floor = info.Class == "FloorSounds"
    if not floor and info.Name ~= "Shoot" then return end
    if PatipanStudio.Sound.Friendly(info.Position) then return end
    PatipanStudio.Esp.Hear(info.Position, not floor and tostring(info.Class) or nil)
    if PatipanStudio.Options.SoundEsp then PatipanStudio.Sound.Mark(info.Position, floor and "Steps" or tostring(info.Class)) end
end

function PatipanStudio.Sound.Mark(pos, label)
    local sound = PatipanStudio.Sound
    if not (sound.Folder and sound.Folder.Parent) then
        sound.Folder = Instance.new("Folder")
        sound.Folder.Name = "PatipanStudioSounds"
        sound.Folder.Parent = Workspace.Terrain
    end
    if #sound.Marks >= PatipanStudio.Config.SoundMaxMarks then
        table.remove(sound.Marks, 1).Gui:Destroy()
    end
    local holder = Instance.new("Attachment")
    holder.WorldPosition = pos
    local gui = Instance.new("BillboardGui")
    gui.AlwaysOnTop, gui.Size, gui.LightInfluence = true, UDim2.fromOffset(120, 34), 0
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency, text.Size, text.Font, text.TextSize = 1, UDim2.fromScale(1, 1), Enum.Font.GothamBold, 13
    text.TextColor3, text.TextStrokeTransparency = PatipanStudio.Config.SoundColor, 0.3
    text.Parent = gui
    gui.Parent = holder
    holder.Parent = Workspace.Terrain
    gui.Adornee = holder
    sound.Marks[#sound.Marks + 1] = { Gui = holder, Text = text, Label = label, Born = osClock() }
end

---Fades markers and keeps their distance fresh.
function PatipanStudio.Sound.Step()
    local sound, life = PatipanStudio.Sound, PatipanStudio.Options.SoundEspLife
    local cam = Workspace.CurrentCamera
    for index = #sound.Marks, 1, -1 do
        local mark = sound.Marks[index]
        local age = osClock() - mark.Born
        if age > life or not PatipanStudio.Options.SoundEsp then
            mark.Gui:Destroy()
            table.remove(sound.Marks, index)
        else
            local dist = cam and math.floor((mark.Gui.WorldPosition - cam.CFrame.Position).Magnitude) or 0
            mark.Text.Text = ("%s\n%dm"):format(mark.Label, dist)
            mark.Text.TextTransparency = age / life * 0.8
        end
    end
end

PatipanStudio.World = {}

function PatipanStudio.World.Step()
    local opts, state = PatipanStudio.Options, PatipanStudio.State
    if opts.Fullbright then
        state.LightSaved = state.LightSaved or { Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient }
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows = 2, 14, 1e6, false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    elseif state.LightSaved then
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient = table.unpack(state.LightSaved)
        state.LightSaved = nil
    end
end

---No Flash and No Smoke stop the game from making the effect at all, and clear what is already on screen.
function PatipanStudio.World.HookEffects()
    local smoke, flash = PatipanStudio.GameLib.Smoke, PatipanStudio.GameLib.Flash
    if smoke and type(smoke.Create) == "function" then
        local create
        create = PatipanStudio.Util.Hook("Smoke", smoke.Create, function(...)
            if PatipanStudio.Options.NoSmoke then return nil end
            return create(...)
        end)
    end
    if flash and type(flash.Flash) == "function" then
        local blind
        blind = PatipanStudio.Util.Hook("Flash", flash.Flash, function(...)
            if PatipanStudio.Options.NoFlash then return nil end
            return blind(...)
        end)
    end
    if PatipanStudio.Options.NoSmoke and smoke then pcall(smoke.DestroyAll) end
    if PatipanStudio.Options.NoFlash and flash then pcall(flash.CancelFlash) end
end

function PatipanStudio.World.OnIdled()
    if not PatipanStudio.Options.AntiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(vector2New())
    end)
end

function PatipanStudio.World.OnJump()
    if not PatipanStudio.Options.InfiniteJump or PatipanStudio.Player.Body() then return end
    local hum = PatipanStudio.Player.Humanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end

function PatipanStudio.World.SetCrouch(down)
    local state = PatipanStudio.State
    if state.HopCrouched == down then return end
    state.HopCrouched = down
    local controller = PatipanStudio.GameLib.Character
    if not controller then return end
    if not down and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
    controller.crouch(down)
end

function PatipanStudio.World.OnSpace(input, down, processed)
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    if down and UserInputService:GetFocusedTextBox() then return end
    PatipanStudio.State.SpaceHeld = down
end

function PatipanStudio.World.Hop()
    local opts, state = PatipanStudio.Options, PatipanStudio.State
    local body = opts.BunnyHop and state.SpaceHeld and PatipanStudio.Player.Alive() and PatipanStudio.Player.Body()
    if not body or UserInputService:GetFocusedTextBox() then
        PatipanStudio.World.SetCrouch(false)
        return
    end
    local controller = PatipanStudio.GameLib.Character
    local grounded = body.OnGround == true
    PatipanStudio.World.SetCrouch(opts.BunnyCrouch and not grounded)
    controller.jump(false)
    if not grounded or osClock() - state.HopAt < PatipanStudio.Config.HopGap then return end
    state.HopAt = osClock()
    controller.jump()
end

function PatipanStudio.World.HopStep()
    local ok, err = pcall(PatipanStudio.World.Hop)
    if ok then
        PatipanStudio.Faults.Clear("Bunny Hop")
    else
        PatipanStudio.Faults.Report("Bunny Hop", err, { "BunnyHop" }, PatipanStudio.World.Hop)
    end
end

function PatipanStudio.World.Rejoin()
    pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
end

function PatipanStudio.World.ServerHop()
    pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
end

PatipanStudio.Skins = { Map = {}, Applied = setmetatable({}, { __mode = "k" }), Catalog = nil, Rarity = {}, Images = {}, Colors = {}, Originals = setmetatable({}, { __mode = "k" }) }

function PatipanStudio.Skins.Folder()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    return assets and assets:FindFirstChild("Skins")
end

---@return string?  category name, nil = not a weapon look
function PatipanStudio.Skins.CategoryOf(name, kind)
    local mapped = PatipanStudio.Config.SkinKinds[kind]
    if mapped then return mapped end
    if kind ~= "Weapon" then return nil end
    local gun = PatipanStudio.Weapons[name]
    return gun and gun.Type or "Other"
end

function PatipanStudio.Skins.Build()
    local skins = PatipanStudio.Skins
    local folder = skins.Folder()
    local listing = PatipanStudio.Util.Decode(ReplicatedStorage:GetAttribute("AvaiableSkins")) or {}
    local ranks = PatipanStudio.Config.SkinRanks
    local catalog = {}
    for name, entries in pairs(listing) do
        if type(entries) ~= "table" or not (folder and folder:FindFirstChild(name)) then continue end
        local _, first = next(entries)
        local category = skins.CategoryOf(name, type(first) == "table" and first.type)
        if not category then continue end
        catalog[category] = catalog[category] or {}
        table.insert(catalog[category], name)
        skins.Rarity[name], skins.Images[name], skins.Colors[name] = {}, {}, {}
        for skin, entry in pairs(entries) do
            if type(entry) ~= "table" then continue end
            skins.Rarity[name][skin] = ranks[entry.rarity] or 0
            local look = type(entry.wearImages) == "table" and entry.wearImages[1]
            skins.Images[name][skin] = look and look.assetId
            local rarity = PatipanStudio.GameLib.Rarities and PatipanStudio.GameLib.Rarities[entry.rarity]
            skins.Colors[name][skin] = type(rarity) == "table" and rarity.Color or nil
        end
    end
    for _, names in pairs(catalog) do table.sort(names) end
    skins.Catalog = catalog
end

---@return string[]  categories in display order
function PatipanStudio.Skins.Categories()
    if not PatipanStudio.Skins.Catalog then PatipanStudio.Skins.Build() end
    local list, seen = {}, {}
    for _, category in ipairs(PatipanStudio.Config.SkinOrder) do
        if PatipanStudio.Skins.Catalog[category] then list[#list + 1] = category seen[category] = true end
    end
    for category in pairs(PatipanStudio.Skins.Catalog) do
        if not seen[category] then list[#list + 1] = category end
    end
    if #list == 0 then list[1] = "-" end
    return list
end

function PatipanStudio.Skins.Items(category)
    if not PatipanStudio.Skins.Catalog then PatipanStudio.Skins.Build() end
    local names = PatipanStudio.Skins.Catalog[category or ""]
    return (names and #names > 0) and names or { "-" }
end

---@return string[]  rarest first
function PatipanStudio.Skins.List(weapon)
    local folder = PatipanStudio.Skins.Folder()
    local holder = folder and folder:FindFirstChild(weapon or "")
    if not holder then return { "-" } end
    local ranks = PatipanStudio.Skins.Rarity[weapon] or {}
    local names = {}
    for _, child in ipairs(holder:GetChildren()) do names[#names + 1] = child.Name end
    table.sort(names, function(a, b)
        local ra, rb = ranks[a] or 0, ranks[b] or 0
        if ra ~= rb then return ra > rb end
        return a < b
    end)
    return #names > 0 and names or { "-" }
end

---@param view string  "Camera" or "Character"
---@return Folder?     best wear available
function PatipanStudio.Skins.Source(weapon, skin, view)
    local folder = PatipanStudio.Skins.Folder()
    local paint = folder and folder:FindFirstChild(weapon) and folder[weapon]:FindFirstChild(skin)
    local side = paint and paint:FindFirstChild(view)
    if not side then return nil end
    for _, wear in ipairs(PatipanStudio.Config.SkinWears) do
        if side:FindFirstChild(wear) then return side[wear] end
    end
    return side:FindFirstChildOfClass("Folder")
end

function PatipanStudio.Skins.Paint(model, weapon, skin, view)
    local source = PatipanStudio.Skins.Source(weapon, skin, view)
    if not source then return false end
    local whole = source:FindFirstChild("SurfaceAppearance")
    local arms = PatipanStudio.Config.SkinArms
    for _, part in ipairs(model:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        local old = part:FindFirstChildOfClass("SurfaceAppearance")
        local look = source:FindFirstChild(part.Name)
        if not look and whole and old and not arms[part.Name] then look = whole end
        if not look then continue end
        local originals = PatipanStudio.Skins.Originals
        if originals[part] == nil then originals[part] = old and old:Clone() or false end
        if old then old:Destroy() end
        look:Clone().Parent = part
    end
    return true
end

---Puts back the look each part had before we painted it.
function PatipanStudio.Skins.Reset(model)
    local originals = PatipanStudio.Skins.Originals
    for _, part in ipairs(model:GetDescendants()) do
        local saved = part:IsA("BasePart") and originals[part]
        if saved == nil then continue end
        local current = part:FindFirstChildOfClass("SurfaceAppearance")
        if current then current:Destroy() end
        if saved then saved:Clone().Parent = part end
        originals[part] = nil
    end
end

function PatipanStudio.Skins.WeaponOf(model)
    local folder = PatipanStudio.Skins.Folder()
    if folder and folder:FindFirstChild(model.Name) then return model.Name end
    local equipped = PatipanStudio.Player.Equipped()
    return equipped and (equipped.Weapon or equipped.Name)
end

function PatipanStudio.Skins.Models()
    local list = {}
    for _, child in ipairs(Workspace.CurrentCamera:GetChildren()) do
        if child:IsA("Model") then list[#list + 1] = { child, "Camera" } end
    end
    local char = PatipanStudio.Player.Character()
    local folder = PatipanStudio.Skins.Folder()
    if char and folder then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Model") and folder:FindFirstChild(child.Name) then list[#list + 1] = { child, "Character" } end
        end
    end
    return list
end

function PatipanStudio.Skins.Step()
    local skins = PatipanStudio.Skins
    local on = PatipanStudio.Options.SkinChanger
    local glove = on and skins.Map[PatipanStudio.Config.GloveKey]
    local gloveSkin = glove and skins.Map[glove]
    for _, entry in ipairs(skins.Models()) do
        local model, view = entry[1], entry[2]
        local weapon = skins.WeaponOf(model)
        local skin = on and weapon and skins.Map[weapon] or nil
        local key = (skin or gloveSkin) and (tostring(weapon) .. "|" .. tostring(skin) .. "|" .. tostring(gloveSkin)) or nil
        if skins.Applied[model] == key then continue end
        if skins.Applied[model] then skins.Reset(model) end
        if skin then skins.Paint(model, weapon, skin, view) end
        if gloveSkin and view == "Camera" then skins.Paint(model, glove, gloveSkin, view) end
        skins.Applied[model] = key
    end
end

function PatipanStudio.Skins.Set(weapon, skin, quiet)
    if not weapon or weapon == "-" or not skin or skin == "-" then return false end
    local map, gloveKey = PatipanStudio.Skins.Map, PatipanStudio.Config.GloveKey
    local isGlove = PatipanStudio.Skins.Catalog and table.find(PatipanStudio.Skins.Catalog.Gloves or {}, weapon)
    if skin == "Default" then
        if map[weapon] == nil then return false end
        map[weapon] = nil
        if map[gloveKey] == weapon then map[gloveKey] = nil end
    else
        if map[weapon] == skin then return false end
        map[weapon] = skin
        if isGlove then map[gloveKey] = weapon end
    end
    if not quiet then PatipanStudio.Skins.Save() end
    return true
end

---@param pick fun(list: string[]): string  chooses one skin per item
---@return number  items changed
function PatipanStudio.Skins.SetAll(pick)
    local count = 0
    for _, category in ipairs(PatipanStudio.Skins.Categories()) do
        if category == "Gloves" then continue end
        for _, weapon in ipairs(PatipanStudio.Skins.Items(category)) do
            PatipanStudio.Skins.Set(weapon, pick(PatipanStudio.Skins.List(weapon)), true)
            count += 1
        end
    end
    PatipanStudio.Skins.Save()
    return count
end

function PatipanStudio.Skins.Save()
    if type(writefile) ~= "function" then return end
    local ok, err = pcall(function()
        if type(isfolder) == "function" and not isfolder(PatipanStudio.Config.SaveFolder) then makefolder(PatipanStudio.Config.SaveFolder) end
        writefile(PatipanStudio.Config.SkinFile, HttpService:JSONEncode(PatipanStudio.Skins.Map))
    end)
    if not ok then warn("[BloxStrike] skins save:", err) end
end

function PatipanStudio.Skins.Load()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, raw = pcall(function() return isfile(PatipanStudio.Config.SkinFile) and readfile(PatipanStudio.Config.SkinFile) end)
    local map = ok and PatipanStudio.Util.Decode(raw)
    if type(map) == "table" then PatipanStudio.Skins.Map = map end
end

PatipanStudio.Economy = {}

function PatipanStudio.Economy.RedeemAll()
    local net = PatipanStudio.GameLib.Net
    local packet = net and net.Dashboard and net.Dashboard.RedeemCode
    if not packet or PatipanStudio.State.Redeeming then return 0 end
    PatipanStudio.State.Redeeming = true
    local sent = 0
    for _, code in ipairs(PatipanStudio.Config.Codes) do
        if pcall(packet.Send, code) then sent += 1 end
        task.wait(PatipanStudio.Config.RedeemGap)
    end
    PatipanStudio.State.Redeeming = false
    return sent
end

function PatipanStudio.Economy.HookBuys()
    local net = PatipanStudio.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.BuyMenuPurchase
    if not packet then return end
    local original
    original = PatipanStudio.Util.Hook("Buy", packet.Send, function(payload, ...)
        if type(payload) == "table" and payload.Name and not PatipanStudio.State.Replaying then
            local list = PatipanStudio.State.Bought
            for index, entry in ipairs(list) do
                if entry.Name == payload.Name then table.remove(list, index) break end
            end
            list[#list + 1] = { Equipment = payload.Equipment, Path = payload.Path, Name = payload.Name }
        end
        return original(payload, ...)
    end)
end

function PatipanStudio.Economy.Rebuy()
    local net = PatipanStudio.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.BuyMenuPurchase
    if not packet or #PatipanStudio.State.Bought == 0 or PatipanStudio.State.Replaying then return 0 end
    PatipanStudio.State.Replaying = true
    local sent = 0
    for _, entry in ipairs(PatipanStudio.State.Bought) do
        if pcall(packet.Send, { Equipment = entry.Equipment, Path = entry.Path, Name = entry.Name }) then sent += 1 end
        task.wait(PatipanStudio.Config.RebuyGap)
    end
    PatipanStudio.State.Replaying = false
    return sent
end

---Buys once each time the game enters a buy phase, so warmup and round 1 each get their own rebuy.
function PatipanStudio.Economy.Step()
    local state = PatipanStudio.State
    local phase = Workspace:GetAttribute("GameState")
    local entered = PatipanStudio.Config.BuyStates[phase] and phase ~= state.LastPhase
    state.LastPhase = phase
    if not entered then state.RebuyPending = state.RebuyPending and PatipanStudio.Config.BuyStates[phase] return end
    state.RebuyPending = true
end

function PatipanStudio.Economy.Tick()
    local state = PatipanStudio.State
    PatipanStudio.Economy.Step()
    if not (PatipanStudio.Options.AutoRebuy and state.RebuyPending and PatipanStudio.Player.Alive()) then return end
    state.RebuyPending = false
    task.spawn(PatipanStudio.Economy.Rebuy)
end

function PatipanStudio.Economy.BoughtText()
    local names = {}
    for _, entry in ipairs(PatipanStudio.State.Bought) do names[#names + 1] = entry.Name end
    return #names > 0 and table.concat(names, ", ") or "-"
end

PatipanStudio.Spectators = {}

function PatipanStudio.Spectators.Text()
    local count = tonumber(LocalPlayer:GetAttribute("Spectators")) or 0
    if count == 0 then return "None" end
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player:GetAttribute("IsSpectating")) == "true" and tostring(player:GetAttribute("Dead")) == "true" then
            names[#names + 1] = player.DisplayName
        end
    end
    return count .. " watching" .. (#names > 0 and (" (dead: " .. table.concat(names, ", ") .. ")") or "")
end

PatipanStudio.Faults = { Streaks = {} }

function PatipanStudio.Faults.Clear(name)
    PatipanStudio.Faults.Streaks[name] = nil
end

function PatipanStudio.Faults.AnyOn(toggles)
    for _, key in ipairs(toggles) do
        if PatipanStudio.Options[key] then return true end
    end
    return false
end

---@param restore function?  the feature's own off path
function PatipanStudio.Faults.Halt(name, err, toggles, restore)
    warn("[BloxStrike] " .. name .. " stopped:", err)
    for _, key in ipairs(toggles) do
        PatipanStudio.Options[key] = false
    end
    if restore then PatipanStudio.Util.Try(name .. " restore", restore) end
    local halted = PatipanStudio.State.Halted
    halted[#halted + 1] = { name, tostring(err):match("^[^\n]*"), toggles }
end

---@param toggles string[]   turned off once the feature keeps failing; empty = keeps running, warns once per streak
---@param restore function?  run once when the feature is stopped
---@return boolean           true while the feature is stopped
function PatipanStudio.Faults.Report(name, err, toggles, restore)
    local now, streaks = osClock(), PatipanStudio.Faults.Streaks
    local streak = streaks[name]
    if not streak or (streak.Halted and PatipanStudio.Faults.AnyOn(toggles)) then
        streak = { Count = 0, First = now, Warned = false, Halted = false }
        streaks[name] = streak
    end
    streak.Count += 1
    if streak.Warned then return streak.Halted end
    if streak.Count < PatipanStudio.Config.MaxFails or now - streak.First < PatipanStudio.Config.FailWindow then return false end

    streak.Warned = true
    if #toggles == 0 then
        warn("[BloxStrike] " .. name .. " keeps failing:", err)
        return false
    end
    streak.Halted = true
    PatipanStudio.Faults.Halt(name, err, toggles, restore)
    return true
end

PatipanStudio.Scheduler = { Jobs = {} }

---@param toggles string[]   options the job serves; switched off if it keeps failing
---@param restore function?  the job's off path, run once if it gets stopped
function PatipanStudio.Scheduler.Every(name, interval, fn, toggles, restore)
    PatipanStudio.Scheduler.Jobs[name] = { Interval = interval, Fn = fn, Next = 0, Toggles = toggles, Restore = restore }
end

---@return boolean  a halted job runs again once one of its toggles is back on
function PatipanStudio.Scheduler.Resume(name, job)
    if not PatipanStudio.Faults.AnyOn(job.Toggles) then return false end
    job.Halted = false
    PatipanStudio.Faults.Clear(name)
    return true
end

function PatipanStudio.Scheduler.Boot()
    PatipanStudio:Connect(RunService.Heartbeat, function()
        local now = osClock()
        for name, job in pairs(PatipanStudio.Scheduler.Jobs) do
            if now < job.Next then continue end
            job.Next = now + job.Interval
            if job.Halted and not PatipanStudio.Scheduler.Resume(name, job) then continue end

            local ok, err = pcall(job.Fn)
            if ok then
                PatipanStudio.Faults.Clear(name)
            else
                job.Halted = PatipanStudio.Faults.Report(name, err, job.Toggles, job.Restore)
            end
        end
    end)
end

PatipanStudio.UI = { Labels = {} }

function PatipanStudio.UI.Detach(fn)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(fn, table.unpack(packed, 1, packed.n))
            if not ok then warn("[BloxStrike] ui:", err) end
        end)
    end
end

function PatipanStudio.UI.Bind(widget, key)
    local function Apply(value) PatipanStudio.Options[key] = value end
    Apply(widget.Value)
    widget:OnChanged(Apply)
end

function PatipanStudio.UI.AddKeyMode(group, toggleIdx, keyIdx, default)
    group:AddDropdown(toggleIdx .. "Mode", { Text = T("Key mode", "โหมดปุ่ม"), Values = { "Hold", "Toggle", "Always" }, Default = default, Callback = function(mode)
        local picker = Library.Options[keyIdx]
        if picker then picker:SetValue({ picker.Value, mode }) end
    end })
end

---Toggle that keeps its info, so the library's "not supported" / "not available" notices name the feature instead of the idx.
function PatipanStudio.UI.NamedToggle(group, idx, info)
    local toggle = group:AddToggle(idx, info)
    toggle.Info = toggle.Info or info
    return toggle
end

function PatipanStudio.UI.BuildMain(window)
    window:AddTabSection(T("Main", "หลัก"))
    local tab = window:AddTab(T("Main", "หลัก"), "mushroom", T("Status and links", "สถานะและลิงก์"))

    local status = tab:AddLeftGroupbox(T("Status", "สถานะ"), "star")
    PatipanStudio.UI.Labels.Match = status:AddParagraph({ Title = T("Match", "แมตช์"), Content = "-" })
    PatipanStudio.UI.Labels.Combat = status:AddParagraph({ Title = T("Combat", "การต่อสู้"), Content = "-" })
    PatipanStudio.UI.Labels.Spectators = status:AddParagraph({ Title = T("Spectators", "คนดูเรา"), Content = "-" })
    PatipanStudio.UI.Labels.Esp = status:AddParagraph({ Title = T("ESP", "ESP"), Content = "-" })

    local discord = tab:AddRightGroupbox(T("Discord", "ดิสคอร์ด"), "link")
    discord:AddLabel(PatipanStudio.Config.Discord)
    discord:AddButton({ Text = T("Copy Discord Link", "คัดลอกลิงก์ดิสคอร์ด"), Func = PatipanStudio.UI.Detach(function()
        if PatipanStudio.Util.Copy(PatipanStudio.Config.Discord) then
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

local priorities = { "Crosshair", "Distance", "Health" }

function PatipanStudio.UI.BuildAimbot(window)
    window:AddTabSection(T("Combat", "การต่อสู้"))
    local tab = window:AddTab(T("Aimbot", "เล็งอัตโนมัติ"), "crosshair", T("Locks your camera onto enemies", "ล็อคกล้องไปที่ศัตรู"))

    local main = tab:AddLeftGroupbox(T("Aimbot", "เล็งอัตโนมัติ"), "crosshair")
    main:AddToggle("Aimbot", { Text = T("Aimbot", "เล็งอัตโนมัติ"), Description = T("Locks your view onto the enemy in the FOV", "ล็อคกล้องไปที่ศัตรูในวง FOV") })
        :AddKeyPicker("AimbotKey", { Default = "E", Mode = "Toggle" })
    PatipanStudio.UI.AddKeyMode(main, "Aimbot", "AimbotKey", "Toggle")
    main:AddSlider("AimbotSmooth", { Text = T("Smoothness", "ความนุ่ม"), Description = T("1 = instant snap", "1 = หันทันที"), Min = 1, Max = 20, Default = 1, Rounding = 0 })
    main:AddCheckbox("AimbotSticky", { Text = T("Sticky target", "ล็อคเป้าเดิม"), Description = T("Keeps the same enemy until it is lost", "ไม่สลับเป้าจนกว่าเป้าเดิมจะหลุด"), Default = true })

    local target = tab:AddRightGroupbox(T("Aimbot Targeting", "การเลือกเป้า (เล็ง)"), "target")
    target:AddDropdown("AimbotBone", { Text = T("Aim part", "จุดที่เล็ง"), Values = { "Head", "Torso" }, Default = "Head" })
    target:AddDropdown("AimbotPriority", { Text = T("Priority", "เลือกเป้าตาม"), Values = priorities, Default = "Crosshair" })
    target:AddCheckbox("AimbotVisible", { Text = T("Visible only", "เฉพาะที่มองเห็น"), Default = true })
    target:AddSlider("AimbotFov", { Text = T("FOV", "ขนาดวง"), Min = 20, Max = 800, Default = 150, Suffix = "px" })
    target:AddToggle("AimbotShowFov", { Text = T("Show FOV circle", "แสดงวง FOV") })
    target:AddSlider("AimbotMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 3000, Default = 1500, Suffix = "m" })
end

function PatipanStudio.UI.BuildSilent(window)
    local tab = window:AddTab(T("Silent Aim", "ไซเลนต์เอม"), "bomb", T("Your shots find the enemy for you", "กระสุนวิ่งหาศัตรูเอง"))

    local main = tab:AddLeftGroupbox(T("Silent Aim", "ไซเลนต์เอม"), "bomb")
    PatipanStudio.UI.NamedToggle(main, "SilentAim", { Text = T("Silent aim", "ไซเลนต์เอม"), Description = T("Shots you fire go to the enemy in the FOV", "นัดที่ยิงพุ่งไปหาศัตรูในวง FOV") })
        :AddKeyPicker("SilentKey", { Default = "None", Mode = "Toggle" })
    main:AddSlider("SilentHitChance", { Text = T("Hit chance", "โอกาสโดน"), Description = T("Lower looks more legit", "ยิ่งต่ำยิ่งดูเนียน"), Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    main:AddSlider("SilentHeadChance", { Text = T("Headshot chance", "โอกาสเข้าหัว"), Description = T("The rest go to the body", "ที่เหลือเข้าลำตัว"), Min = 0, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    Library.Compat.NeedCap("SilentAim", { "HookFunction", "Gc" })

    local target = tab:AddRightGroupbox(T("Silent Targeting", "การเลือกเป้า (ไซเลนต์)"), "target")
    target:AddDropdown("SilentPriority", { Text = T("Priority", "เลือกเป้าตาม"), Values = priorities, Default = "Crosshair" })
    target:AddCheckbox("SilentVisible", { Text = T("Visible only", "เฉพาะที่มองเห็น"), Description = T("Off = also through walls", "ปิด = ยิงทะลุกำแพงด้วย"), Default = true })
    target:AddSlider("SilentFov", { Text = T("FOV", "ขนาดวง"), Min = 20, Max = 1000, Default = 220, Suffix = "px" })
    target:AddToggle("SilentShowFov", { Text = T("Show FOV circle", "แสดงวง FOV") })
    target:AddSlider("SilentMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 3000, Default = 2000, Suffix = "m" })
    target:AddCheckbox("SilentPredict", { Text = T("Lead moving targets", "ยิงดักคนที่วิ่ง"), Default = false })
end

function PatipanStudio.UI.BuildTrigger(window)
    local tab = window:AddTab(T("Trigger & Rage", "ยิงออโต้ & เรจ"), "zap", T("Shoots for you", "ยิงให้อัตโนมัติ"))

    local trigger = tab:AddLeftGroupbox(T("Triggerbot", "ยิงอัตโนมัติ"), "zap")
    trigger:AddToggle("Triggerbot", { Text = T("Triggerbot", "ยิงอัตโนมัติ"), Description = T("Fires the moment an enemy is under your crosshair", "ยิงทันทีที่ศัตรูอยู่ใต้เป้า") })
        :AddKeyPicker("TriggerKey", { Default = "T", Mode = "Toggle" })
    PatipanStudio.UI.AddKeyMode(trigger, "Triggerbot", "TriggerKey", "Toggle")
    trigger:AddSlider("TriggerDelay", { Text = T("Reaction delay", "ดีเลย์ก่อนยิง"), Min = 0, Max = 400, Default = 0, Rounding = 0, Suffix = "ms" })
    trigger:AddSlider("TriggerHitChance", { Text = T("Fire chance", "โอกาสยิง"), Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })

    local rage = tab:AddRightGroupbox(T("Ragebot", "เรจบอท"), "bomb")
    PatipanStudio.UI.NamedToggle(rage, "Ragebot", { Text = T("Ragebot", "เรจบอท"), Description = T("Snaps to and kills any enemy it can reach on its own", "หันไปยิงศัตรูที่ยิงถึงเองทันที") })
        :AddKeyPicker("RageKey", { Default = "None", Mode = "Toggle" })
    rage:AddCheckbox("RageVisible", { Text = T("Visible only", "เฉพาะที่มองเห็น"), Description = T("Off = also through walls", "ปิด = ยิงทะลุกำแพงด้วย"), Default = true })
    rage:AddSlider("RageMaxDistance", { Text = T("Max distance", "ระยะสูงสุด"), Min = 50, Max = 3000, Default = 2000, Suffix = "m" })
end

function PatipanStudio.UI.BuildGuns(window)
    local tab = window:AddTab(T("Gun Mods", "ม็อดปืน"), "swords", T("Recoil and spread", "แรงถีบและการกระจาย"))

    local mods = tab:AddLeftGroupbox(T("Gun Mods", "ม็อดปืน"), "swords")
    PatipanStudio.UI.NamedToggle(mods, "NoRecoil", { Text = T("No recoil", "ไม่มีแรงถีบ"), Description = T("Your view stays still while spraying", "จอนิ่งตอนกดยิงค้าง") })
    PatipanStudio.UI.NamedToggle(mods, "NoSpread", { Text = T("No spread", "ไม่มีการกระจาย"), Description = T("Every bullet lands on the crosshair", "ทุกนัดลงกลางเป้า") })
    Library.Compat.NeedCap("NoRecoil", "HookFunction")
    Library.Compat.NeedCap("NoSpread", { "HookFunction", "Gc" })
end

function PatipanStudio.UI.BuildVisuals(window)
    window:AddTabSection(T("Visuals", "การมองเห็น"))
    PatipanStudio.Util.Try("visuals tab", function()
        window:AddVisualsTab({ Provider = PatipanStudio.Esp.Targets, Preview = true })
    end)

    local tab = window:AddTab(T("World", "โลก"), "globe", T("Lighting, flash and smoke", "แสง แฟลช และควัน"))
    local world = tab:AddLeftGroupbox(T("World", "โลก"), "flower")
    world:AddToggle("Fullbright", { Text = T("Fullbright", "สว่างทั้งแมพ") })
    world:AddToggle("NoFlash", { Text = T("No flash", "กันแฟลช"), Description = T("Flashbangs do not blind you", "แฟลชไม่ทำให้ตาบอด") })
    world:AddToggle("NoSmoke", { Text = T("No smoke", "ไม่มีควัน"), Description = T("See through smoke grenades", "มองทะลุควัน") })

    local heard = tab:AddLeftGroupbox(T("Hidden Enemies", "ศัตรูหลังกำแพง"), "eye")
    PatipanStudio.UI.NamedToggle(heard, "SoundEsp", { Text = T("Sound ESP", "ESP จากเสียง"), Description = T("Shows where enemies walk and shoot, even behind walls", "โชว์จุดที่ศัตรูเดินและยิง แม้อยู่หลังกำแพง") })
    heard:AddSlider("SoundEspLife", { Text = T("Show for", "แสดงนาน"), Min = 1, Max = 8, Default = 3, Rounding = 0, Suffix = "s" })
    heard:AddSlider("EspMemory", { Text = T("Keep hidden enemies", "จำศัตรูที่หลบ"), Description = T("ESP keeps a box where an enemy was last seen or heard", "ESP ค้างกล่องไว้ที่ที่เห็นหรือได้ยินศัตรูล่าสุด"), Min = 0, Max = 15, Default = 5, Rounding = 0, Suffix = "s" })
    Library.Compat.NeedCap("SoundEsp", "Upvalues")

    local cam = tab:AddRightGroupbox(T("Camera", "กล้อง"), "eye")
    PatipanStudio.UI.NamedToggle(cam, "CameraFov", { Text = T("Custom FOV", "ปรับมุมมอง") })
    cam:AddSlider("CameraFovValue", { Text = T("FOV", "มุมมอง"), Min = 70, Max = 120, Default = 100, Rounding = 0 })
end

local skinTitles = {
    Pistol = { "Pistols", "ปืนพก", "coin" },
    SMG = { "SMGs", "ปืนกลมือ", "zap" },
    Rifle = { "Rifles", "ปืนไรเฟิล", "crosshair" },
    Sniper = { "Snipers", "สไนเปอร์", "target" },
    Heavy = { "Heavy", "ปืนหนัก", "bomb" },
    Shotgun = { "Shotguns", "ลูกซอง", "bomb" },
    ["Machine Gun"] = { "Machine Guns", "ปืนกล", "zap" },
    Knives = { "Knives", "มีด", "swords" },
    Gloves = { "Gloves", "ถุงมือ", "shield" },
    Grenades = { "Grenades", "ระเบิด", "bomb" },
    Gear = { "Gear", "อุปกรณ์", "gear" },
}

function PatipanStudio.UI.SkinGroup(tab, category, side)
    local title = skinTitles[category] or { category, category, "star" }
    local group = side == "Left" and tab:AddLeftGroupbox(T(title[1], title[2]), title[3]) or tab:AddRightGroupbox(T(title[1], title[2]), title[3])
    for _, weapon in ipairs(PatipanStudio.Skins.Items(category)) do
        if weapon == "-" then continue end
        local values = { "Default" }
        for _, skin in ipairs(PatipanStudio.Skins.List(weapon)) do values[#values + 1] = skin end
        group:AddDropdown("Skin_" .. weapon, { Text = weapon, Values = values, Default = PatipanStudio.Skins.Map[weapon] or "Default", Searchable = true, Images = PatipanStudio.Skins.Images[weapon], Colors = PatipanStudio.Skins.Colors[weapon], Callback = function(skin)
            PatipanStudio.Skins.Set(weapon, skin)
        end })
    end
end

---@param heights table  rows used per side so far, updated in place
function PatipanStudio.UI.PlaceSkinGroup(tab, category, heights)
    local side = heights.Left <= heights.Right and "Left" or "Right"
    local rows = 1
    for _, weapon in ipairs(PatipanStudio.Skins.Items(category)) do
        if weapon ~= "-" then rows += 1 end
    end
    if rows == 1 then return end
    heights[side] += rows
    PatipanStudio.Util.Try("skins " .. category, PatipanStudio.UI.SkinGroup, tab, category, side)
end

function PatipanStudio.UI.SyncSkins()
    for _, category in ipairs(PatipanStudio.Skins.Categories()) do
        for _, weapon in ipairs(PatipanStudio.Skins.Items(category)) do
            local picker = Library.Options["Skin_" .. weapon]
            if picker then picker:SetValue(PatipanStudio.Skins.Map[weapon] or "Default") end
        end
    end
end

function PatipanStudio.UI.BuildSkins(window)
    local tab = window:AddTab(T("Skins", "สกิน"), "star", T("Any skin, only on your screen", "ใส่สกินไหนก็ได้ เห็นแค่บนจอคุณ"))

    local main = tab:AddLeftGroupbox(T("Skin Changer", "เปลี่ยนสกิน"), "star")
    main:AddToggle("SkinChanger", { Text = T("Skin changer", "เปลี่ยนสกิน"), Description = T("Pick a skin below and it shows right away", "เลือกสกินด้านล่างแล้วขึ้นทันที") })
    main:AddButton({ Text = T("Rarest On Everything", "หายากสุดทุกอัน"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        local count = PatipanStudio.Skins.SetAll(function(list) return list[1] end)
        PatipanStudio.UI.SyncSkins()
        Library:Notify("Skins", "Set " .. count .. " items", 3, "Success")
    end) })
    main:AddButton({ Text = T("Random", "สุ่ม"), Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.Skins.SetAll(function(list) return list[math.random(#list)] end)
        PatipanStudio.UI.SyncSkins()
    end) }):AddButton({ Text = T("Reset All", "ล้างทั้งหมด"), Style = "Danger", Func = PatipanStudio.UI.Detach(function()
        table.clear(PatipanStudio.Skins.Map)
        PatipanStudio.Skins.Save()
        PatipanStudio.UI.SyncSkins()
    end) })

    local gear = { Knives = true, Gloves = true, Grenades = true, Gear = true }
    local heights = { Left = PatipanStudio.Config.SkinMainRows, Right = 0 }
    for _, category in ipairs({ "Knives", "Gloves", "Grenades", "Gear" }) do
        PatipanStudio.UI.PlaceSkinGroup(tab, category, heights)
    end

    local guns = window:AddTab(T("Gun Skins", "สกินปืน"), "crosshair", T("Skins for every gun", "สกินปืนทุกกระบอก"))
    heights = { Left = 0, Right = 0 }
    local ok, categories = pcall(PatipanStudio.Skins.Categories)
    for _, category in ipairs(ok and categories or {}) do
        if gear[category] then continue end
        PatipanStudio.UI.PlaceSkinGroup(guns, category, heights)
    end
end

function PatipanStudio.UI.BuildMisc(window)
    window:AddTabSection(T("Misc", "อื่นๆ"))
    local tab = window:AddTab(T("Misc", "อื่นๆ"), "gear", T("Buying, codes and utility", "ซื้อของ โค้ด และอื่นๆ"))

    local buy = tab:AddLeftGroupbox(T("Auto Buy", "ซื้ออัตโนมัติ"), "shop")
    PatipanStudio.UI.NamedToggle(buy, "AutoRebuy", { Text = T("Auto rebuy", "ซื้อซ้ำอัตโนมัติ"), Description = T("Buys your last loadout every round", "ซื้อชุดล่าสุดของคุณให้ทุกรอบ") })
    Library.Compat.NeedCap("AutoRebuy", "HookFunction")
    PatipanStudio.UI.Labels.Bought = buy:AddParagraph({ Title = T("Saved loadout", "ชุดที่จำไว้"), Content = "-" })
    buy:AddButton({ Text = T("Rebuy Now", "ซื้อซ้ำตอนนี้"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        PatipanStudio.Util.Try("hook buys", PatipanStudio.Economy.HookBuys)
        local sent = PatipanStudio.Economy.Rebuy()
        Library:Notify("Auto Buy", sent > 0 and ("Bought " .. sent .. " items") or "Buy something once first", 3, sent > 0 and "Success" or "Info")
    end) }):AddButton({ Text = T("Clear", "ล้าง"), Func = PatipanStudio.UI.Detach(function()
        table.clear(PatipanStudio.State.Bought)
    end) })

    local codes = tab:AddLeftGroupbox(T("Codes", "โค้ด"), "key")
    codes:AddButton({ Text = T("Redeem All Codes", "แลกโค้ดทั้งหมด"), Style = "Primary", Func = PatipanStudio.UI.Detach(function()
        local sent = PatipanStudio.Economy.RedeemAll()
        Library:Notify("Codes", "Sent " .. sent .. " codes (level 5+ needed)", 4, "Coin")
    end) })

    local util = tab:AddRightGroupbox(T("Utility", "อรรถประโยชน์"), "flower")
    util:AddToggle("InfiniteJump", { Text = T("Infinite jump", "กระโดดไม่จำกัด"), Description = T("Lobby only, use Bunny hop in rounds", "ใช้ได้เฉพาะล็อบบี้ ในรอบใช้บันนี่ฮอป") })
    util:AddToggle("BunnyHop", { Text = T("Bunny hop", "บันนี่ฮอป"), Description = T("Hold Space to keep hopping and carry your speed", "กด Space ค้างเพื่อกระโดดต่อเนื่องและรักษาความเร็ว") })
    util:AddCheckbox("BunnyCrouch", { Text = T("Crouch jump", "ย่อตอนลอย"), Description = T("Crouches in the air like a CS crouch jump", "ย่อตัวกลางอากาศแบบ crouch jump ใน CS"), Default = true })
    util:AddToggle("AntiAfk", { Text = T("Anti AFK", "กันหลุด AFK") })
    util:AddButton({ Text = T("Rejoin", "เข้าใหม่"), Func = PatipanStudio.UI.Detach(PatipanStudio.World.Rejoin) })
        :AddButton({ Text = T("Server Hop", "ย้ายเซิร์ฟ"), Func = PatipanStudio.UI.Detach(PatipanStudio.World.ServerHop) })
end

function PatipanStudio.UI.RefreshStatus()
    local labels, state = PatipanStudio.UI.Labels, PatipanStudio.State
    if labels.Match then
        labels.Match:SetText(("%s | %s | $%s"):format(tostring(Workspace:GetAttribute("Map") or "-"), tostring(Workspace:GetAttribute("GameState") or "-"), tostring(LocalPlayer:GetAttribute("Money") or 0)))
    end
    if labels.Combat then
        local target = state.RageTarget or state.AimTarget or state.SilentTarget
        target = target and target.Name or "none"
        labels.Combat:SetText(("Target: %s | Kills %s | Shots %d | Aimed %d"):format(target, tostring(LocalPlayer:GetAttribute("Kills") or 0), state.Shots, state.Redirected))
    end
    if labels.Spectators then labels.Spectators:SetText(PatipanStudio.Spectators.Text()) end
    if labels.Esp then
        local visuals = Library.Visuals
        labels.Esp:SetText((visuals and visuals:Get("Enabled")) and (PatipanStudio.Esp.Count .. " players") or "Off")
    end
    if labels.Bought then labels.Bought:SetText(PatipanStudio.Economy.BoughtText()) end
end

---Turns off what the scheduler halted and shows queued notices; runs on the UI pump, never on a game thread.
function PatipanStudio.UI.Drain()
    local state = PatipanStudio.State
    if not (state.Halted[1] or state.Notices[1]) then return end
    local stopped, notices = table.clone(state.Halted), table.clone(state.Notices)
    table.clear(state.Halted)
    table.clear(state.Notices)

    for _, halt in ipairs(stopped) do
        for _, key in ipairs(halt[3]) do
            local toggle = Library.Options[key]
            if toggle and toggle.Value == true then PatipanStudio.Util.Try("halt " .. key, toggle.SetValue, toggle, false) end
        end
        Library:Notify("PatipanStudio", halt[1] .. " stopped: " .. halt[2], 6, "Error")
    end
    for _, notice in ipairs(notices) do
        Library:Notify(notice[1], notice[2], 5, "Warning")
    end
end

---Hooks go in the first time a feature that needs them is switched on, never at load.
function PatipanStudio.UI.HookOnDemand()
    local installers = {
        SilentAim = PatipanStudio.Silent.InstallHook,
        Ragebot = PatipanStudio.Silent.InstallHook,
        Triggerbot = PatipanStudio.Silent.InstallHook,
        NoRecoil = PatipanStudio.Guns.HookKick,
        CameraFov = PatipanStudio.Guns.BindFov,
        NoSpread = PatipanStudio.Guns.HookSpread,
        NoSmoke = PatipanStudio.World.HookEffects,
        NoFlash = PatipanStudio.World.HookEffects,
        AutoRebuy = PatipanStudio.Economy.HookBuys,
        SoundEsp = PatipanStudio.Sound.Install,
    }
    for idx, install in pairs(installers) do
        local toggle = Library.Options[idx]
        if not toggle then continue end
        toggle:OnChanged(function(on)
            if on then task.defer(PatipanStudio.Util.Try, "hook " .. idx, install) end
        end)
    end

    local trigger = Library.Options.Triggerbot
    if trigger then
        trigger:OnChanged(function(on)
            if on then task.delay(PatipanStudio.Config.HookSettle, PatipanStudio.UI.WarnReducedTrigger) end
        end)
    end
end

---Triggerbot fires without the shoot hook; only shot pacing is less exact, so say so once.
function PatipanStudio.UI.WarnReducedTrigger()
    local state = PatipanStudio.State
    if state.Hooks.Shoot or state.TriggerWarned then return end
    state.TriggerWarned = true
    table.insert(state.Notices, { T("Triggerbot", "ยิงอัตโนมัติ"), T("Running in reduced mode on this executor; shot pacing is less exact", "ทำงานแบบจำกัดบน executor นี้ จังหวะยิงอาจไม่แม่นเท่าที่ควร") })
end

function PatipanStudio.UI.BlockMissing()
    local absent = PatipanStudio.GameLib.Missing
    local missing = {
        Net = PatipanStudio.GameLib.Net == nil and (absent.Remotes or true),
        Character = PatipanStudio.GameLib.Character == nil and (absent.CharacterController or true),
        Skins = PatipanStudio.Skins.Folder() == nil and "Absent",
    }
    if missing.Skins then warn("[BloxStrike] Assets.Skins not found, the skin changer is blocked") end

    local unsupported = T("Not available on this executor", "ใช้กับ executor นี้ไม่ได้")
    local outdated = T("Changed by a game update, wait for a script update", "เกมอัปเดตแล้ว รอสคริปต์อัปเดต")
    for source, features in pairs(PatipanStudio.Config.ModuleFeatures) do
        local why = missing[source]
        if not why then continue end
        for _, idx in ipairs(features) do
            Library.Compat.Block(idx, why == "Absent" and outdated or unsupported)
        end
    end
end

function PatipanStudio.UI.Build()
    local window = Library.Window
    for _, build in ipairs({ PatipanStudio.UI.BuildMain, PatipanStudio.UI.BuildAimbot, PatipanStudio.UI.BuildSilent, PatipanStudio.UI.BuildTrigger, PatipanStudio.UI.BuildGuns, PatipanStudio.UI.BuildVisuals, PatipanStudio.UI.BuildSkins, PatipanStudio.UI.BuildMisc }) do
        PatipanStudio.Util.Try("build", build, window)
    end
    PatipanStudio.Util.Try("settings tab", function() window:AddSettingsTab() end)

    for key in pairs(PatipanStudio.Options) do
        local widget = Library.Options[key]
        if widget then PatipanStudio.Util.Try("bind " .. key, PatipanStudio.UI.Bind, widget, key) end
    end
    PatipanStudio.Util.Try("hooks", PatipanStudio.UI.HookOnDemand)
    PatipanStudio.Util.Try("missing modules", PatipanStudio.UI.BlockMissing)

    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.RefreshStatus)
    Library:Every(PatipanStudio.Config.StatusInterval, PatipanStudio.UI.Drain)
end

function PatipanStudio.Boot()
    PatipanStudio.Util.Try("skins load", PatipanStudio.Skins.Load)
    PatipanStudio.Util.Try("combat", PatipanStudio.Combat.Start)
    PatipanStudio:Connect(LocalPlayer.Idled, PatipanStudio.World.OnIdled)
    PatipanStudio:Connect(UserInputService.JumpRequest, PatipanStudio.World.OnJump)
    PatipanStudio:Connect(RunService.Heartbeat, PatipanStudio.World.HopStep)
    PatipanStudio:Connect(UserInputService.InputBegan, function(input, processed) PatipanStudio.World.OnSpace(input, true, processed) end)
    PatipanStudio:Connect(UserInputService.InputEnded, function(input) PatipanStudio.World.OnSpace(input, false) end)

    PatipanStudio.Scheduler.Every("World", 0.2, PatipanStudio.World.Step, { "Fullbright" }, PatipanStudio.World.Step)
    PatipanStudio.Scheduler.Every("Auto Rebuy", 0.5, PatipanStudio.Economy.Tick, { "AutoRebuy" })
    PatipanStudio.Scheduler.Every("Sound ESP", 0.1, PatipanStudio.Sound.Step, { "SoundEsp" }, PatipanStudio.Sound.Step)
    PatipanStudio.Scheduler.Every("Skin Changer", 0.15, PatipanStudio.Skins.Step, { "SkinChanger" }, PatipanStudio.Skins.Step)
    PatipanStudio.Util.Try("scheduler", PatipanStudio.Scheduler.Boot)
end

function PatipanStudio:Unload()
    self.State.Alive = false
    pcall(PatipanStudio.Sound.Uninstall)
    if PatipanStudio.Esp.Folder then pcall(function() PatipanStudio.Esp.Folder:Destroy() end) end
    PatipanStudio.Combat.Unload()
    for _, key in ipairs({ "NoRecoil", "NoSpread", "Fullbright", "CameraFov", "BunnyHop", "SkinChanger" }) do
        PatipanStudio.Options[key] = false
    end
    pcall(PatipanStudio.World.Step)
    pcall(PatipanStudio.World.SetCrouch, false)
    PatipanStudio.Guns.UnbindFov()
    pcall(PatipanStudio.Skins.Step)
    for _, conn in ipairs(self.State.Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(self.State.Connections)
    if Library then PatipanStudio.Util.UnhookAll() end
    environment.BloxStrikeUnload = nil
end

---@return boolean  false when the menu could not be opened
local function BuildInterface()
    Library = PatipanStudio.Util.LoadLibrary(PatipanStudio.Config.UiSource)
    if not Library then return false end
    pcall(MarioBanner.Step, "UI library")
    PatipanStudio.Library = Library
    T = function(en, th) return Library:T(en, th) end
    local opened, err = pcall(Library.CreateWindow, Library, {
        Title = "PatipanStudio",
        SubTitle = "BloxStrike by PatipanStudio",
        MenuKey = Enum.KeyCode.RightControl,
        ConfigFolder = PatipanStudio.Config.SaveFolder,
        Language = "Auto",
        Theme = "Overworld",
        Intro = true,
        OnUnlocked = function()
            PatipanStudio.UI.Build()
            task.defer(PatipanStudio.Util.Try, "boot", PatipanStudio.Boot)
            task.defer(PatipanStudio.Util.Try, "autoload config", function() Library:LoadAutoloadConfig() end)
        end,
    })
    if not opened then
        PatipanStudio.Util.Alert("The menu failed to load on this executor: " .. tostring(err):match("^[^\n]*"), err)
        return false
    end
    Library:OnUnload(function() PatipanStudio:Unload() end)
    return true
end

environment.BloxStrikeUnload = function()
    if PatipanStudio.Library and not PatipanStudio.Library.Unloaded then
        PatipanStudio.Library:Unload()
    else
        PatipanStudio:Unload()
    end
end

pcall(MarioBanner.Step, "Systems")
if not BuildInterface() then return end
pcall(MarioBanner.Step, "Interface")
pcall(MarioBanner.Ready)