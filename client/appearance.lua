Appearance = {}

local adapters = {}

adapters['SeaM_Appearance'] = function()
    return {

        applyToPlayer = function(data)
            if not data then return false end
            exports.SeaM_Appearance:setPlayerAppearance(data)
            return true
        end,

        applyToPed = function(ped, data)
            if not data then return false end
            return exports.SeaM_Appearance:setPedAppearance(ped, data) or ped
        end,

        customise = function(cb)
            exports.SeaM_Appearance:startPlayerCustomization(function(appearance)
                cb(appearance)
            end, nil)
        end,
    }
end

local active, activeName

local function resolve()
    if active ~= nil then return active end

    local wanted = Config.Appearance.resource

    if wanted == 'none' then
        active, activeName = false, 'none'
        return active
    end

    local name = wanted ~= 'auto' and wanted or 'SeaM_Appearance'

    if adapters[name] and GetResourceState(name) == 'started' then
        active, activeName = adapters[name](), name
        return active
    end

    if wanted ~= 'auto' then
        print(('[SeaM_MultiChar] appearance resource "%s" is not started; using default peds')
            :format(wanted))
    end

    active, activeName = false, 'none'
    return active
end

function Appearance.name()
    resolve()
    return activeName
end

function Appearance.available() return resolve() ~= false end

function Appearance.applyToPlayer(data, gender)
    local adapter = resolve()
    if adapter and adapter.applyToPlayer(data) then return end

    local model = gender == 1 and Config.Models.female or Config.Models.male
    RequestModel(model)

    local deadline = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(10) end

    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)
end

function Appearance.applyToPed(ped, data)
    local adapter = resolve()

    if adapter then
        local result = adapter.applyToPed(ped, data)
        if result then return type(result) == 'number' and result or ped end
    end

    SetPedDefaultComponentVariation(ped)
    return ped
end

function Appearance.customise(cb)
    local adapter = resolve()
    if not adapter then return cb(nil) end

    adapter.customise(cb)
end
