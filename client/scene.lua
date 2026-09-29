Scene = {}

local cam, previewPed, swayThread
local sceneActive = false

local function loadModel(model)
    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(10) end
    return HasModelLoaded(model)
end

local function positionCamera(offsetX)
    if not cam or not DoesCamExist(cam) then return end

    local anchor = previewPed and DoesEntityExist(previewPed) and previewPed or PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(anchor,
        offsetX or 0.0, Config.Preview.distance, Config.Preview.height)
    local target = GetOffsetFromEntityInWorldCoords(anchor, 0.0, 0.0, 0.1)

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

-- the drift is a 4.5s cycle over 18cm, so 30hz looks identical to 60 and costs half
local SWAY_TICK = 33

local function startSway()
    if not Config.Preview.sway then return end

    swayThread = true
    CreateThread(function()
        local speed, arc = Config.Preview.swaySpeed * 6.283, Config.Preview.swayArc
        local t = 0
        while swayThread do
            t = t + SWAY_TICK
            positionCamera(math.sin(t * speed) * arc)
            Wait(SWAY_TICK)
        end
    end)
end

local function pickScenario()
    local anim = Config.Animation
    if not anim.enabled then return nil end
    if anim.mode == 'fixed' then return anim.fixed end
    return anim.scenarios[math.random(#anim.scenarios)]
end

function Scene.setPreview(character)
    if previewPed and DoesEntityExist(previewPed) then
        DeletePed(previewPed)
        previewPed = nil
    end

    if not character then return end

    local gender = character.gender == 1 and 1 or 0
    local model = gender == 1 and Config.Models.female or Config.Models.male
    if not loadModel(model) then return end

    local spot = Config.Preview.ped
    previewPed = CreatePed(4, model, spot.x, spot.y, spot.z - 1.0, spot.w, false, false)
    SetModelAsNoLongerNeeded(model)

    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    SetEntityAlpha(previewPed, 255, false)

    previewPed = Appearance.applyToPed(previewPed, character.appearance) or previewPed

    local scenario = pickScenario()
    if scenario then TaskStartScenarioInPlace(previewPed, scenario, 0, true) end

    positionCamera(0.0)
end

function Scene.isActive() return sceneActive end

function Scene.setup()
    if sceneActive then return end
    sceneActive = true

    DoScreenFadeOut(0)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()
    local spot = Config.Preview.ped

    SetEntityCoordsNoOffset(ped, spot.x, spot.y, spot.z - 1.0, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetPlayerControl(PlayerId(), false, 0)

    RequestCollisionAtCoord(spot.x, spot.y, spot.z)
    local deadline = GetGameTimer() + 8000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do Wait(50) end

    if Config.Scene.overrideTime then
        NetworkOverrideClockTime(Config.Scene.hour, Config.Scene.minute, 0)
    end
    if Config.Scene.overrideWeather then
        SetWeatherTypeNowPersist(Config.Scene.weather)
        SetOverrideWeather(Config.Scene.weather)
    end

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        Config.Preview.fov, false, 0)
    positionCamera(0.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    startSway()
    ShutdownLoadingScreen()
    -- the reveal is main.lua's, once the ped is up and the ui has its data. fading in
    -- here is what showed you an empty beach a second before the articles arrived.
end

function Scene.teardown()
    if not sceneActive then return end
    sceneActive = false
    swayThread = nil

    if previewPed and DoesEntityExist(previewPed) then
        DeletePed(previewPed)
        previewPed = nil
    end

    RenderScriptCams(false, false, 0, true, true)
    if cam and DoesCamExist(cam) then
        DestroyCam(cam, false)
        cam = nil
    end

    if Config.Scene.overrideTime then NetworkClearClockTimeOverride() end
    if Config.Scene.overrideWeather then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    SetPlayerControl(PlayerId(), true, 0)
end

function Scene.playEffect()
    local effect = Config.Effect
    if not effect.enabled or effect.mode == 'off' then return end

    local name = effect.mode == 'fixed' and effect.fixed or effect.list[math.random(#effect.list)]
    StartScreenEffect(name, 0, false)
    SetTimeout(effect.durationMs, function() StopScreenEffect(name) end)
end

function Scene.spawnPlayer(position)
    local ped = PlayerPedId()

    RequestCollisionAtCoord(position.x, position.y, position.z)
    SetEntityCoordsNoOffset(ped, position.x + 0.0, position.y + 0.0, position.z + 0.0, false, false, false)
    SetEntityHeading(ped, (position.w or 0.0) + 0.0)

    local deadline = GetGameTimer() + 10000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do Wait(50) end

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    SetGameplayCamRelativeHeading(0.0)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    Scene.teardown()
    -- we hold the loading screen manually, so stopping mid-select must let it go
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(0)
end)
