local Core = exports.SeaM_Core:GetCoreObject()

-- hold the loading screen ourselves, or it drops and you stare at the ground
-- for a second before the articles arrive
SetManualShutdownLoadingScreenNui(true)
local loadingHeld = true

local function reveal(fadeMs)
    if loadingHeld then
        loadingHeld = false
        ShutdownLoadingScreenNui()
    end
    DoScreenFadeIn(fadeMs or 0)
end

local state = {
    open = false,
    busy = false,
    characters = {},
    maxSlots = 1,
    selected = nil,
}

local function send(action, payload)
    payload = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

local function focus(on)
    SetNuiFocus(on, on)
    SetNuiFocusKeepInput(false)
end

local function uiConfig()
    return {
        serverName = Config.UI.serverName,
        tagline    = Config.UI.tagline,
        accent     = Config.UI.accent,
        roster     = Config.UI.roster,
        card       = Config.UI.card,
        store      = Config.UI.store,
        credits    = Config.UI.credits,
        nationalities = Config.Creation.nationalities,
        minAge = Config.Creation.minAge,
        maxAge = Config.Creation.maxAge,
    }
end

local function fetchCharacters()
    local characters, maxSlots = Core.Callbacks.await('multichar:list')
    return characters or {}, maxSlots or 1
end

local function findCharacter(citizenid)
    for i = 1, #state.characters do
        if state.characters[i].citizenid == citizenid then return state.characters[i] end
    end
end

function OpenSelection()
    if state.open then return end
    state.open = true

    -- the server round-trip and collision streaming don't depend on each other,
    -- so run them together instead of paying for both
    local fetched = false
    CreateThread(function()
        state.characters, state.maxSlots = fetchCharacters()
        fetched = true
    end)

    Scene.setup()
    while not fetched do Wait(0) end

    state.selected = state.characters[1] and state.characters[1].citizenid or nil
    Scene.setPreview(findCharacter(state.selected))

    focus(true)
    send('open', {
        characters = state.characters,
        maxSlots   = state.maxSlots,
        selected   = state.selected,
        config     = uiConfig(),
    })

    Wait(50) -- one paint before anything is uncovered
    reveal(400)
end

local function closeSelection()
    if not state.open then return end
    state.open = false
    focus(false)
    send('close')
end

local function refresh(selectId)
    state.characters, state.maxSlots = fetchCharacters()

    if selectId and findCharacter(selectId) then
        state.selected = selectId
    elseif not findCharacter(state.selected) then
        state.selected = state.characters[1] and state.characters[1].citizenid or nil
    end

    Scene.setPreview(findCharacter(state.selected))
    send('update', {
        characters = state.characters,
        maxSlots   = state.maxSlots,
        selected   = state.selected,
    })
end

local function spawnInto(character, isNew)
    closeSelection()

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    Scene.teardown()

    Appearance.applyToPlayer(character.appearance, character.gender)

    local position = Config.Spawn
    if Config.SpawnMode == 'last' then
        position = Core.Callbacks.await('player:spawnpoint') or Config.Spawn
    end

    Scene.spawnPlayer(position)

    DoScreenFadeIn(800)
    Scene.playEffect()

    TriggerEvent('SeaM_MultiChar:client:spawned', character, isNew == true)

    local function ready()
        TriggerEvent('SeaM_MultiChar:client:ready', character, isNew == true)
        TriggerServerEvent('SeaM_MultiChar:server:ready')
    end

    if isNew and Config.Appearance.customiseOnCreate and Appearance.available() then
        Wait(1200)
        Appearance.customise(function(appearance)
            if appearance then
                TriggerServerEvent('SeaM_MultiChar:server:saveAppearance', appearance)
            end

            ready()
        end)

        return
    end

    ready()
end

-- re-previewing the same hand respawns the ped for nothing, so ignore a repeat
RegisterNUICallback('preview', function(data, cb)
    if state.busy or data.citizenid == state.selected then return cb({ ok = true }) end

    local character = findCharacter(data.citizenid)
    if character then
        state.selected = data.citizenid
        Scene.setPreview(character)
    end
    cb({ ok = true })
end)

RegisterNUICallback('play', function(data, cb)
    if state.busy then return cb({ ok = false, error = 'Hold on.' }) end
    state.busy = true

    local ok = Core.Callbacks.await('characters:select', data.citizenid)
    state.busy = false

    if not ok then
        cb({ ok = false, error = 'That character could not be loaded.' })
        return
    end

    cb({ ok = true })
    spawnInto(findCharacter(data.citizenid) or { gender = 0 }, false)
end)

RegisterNUICallback('create', function(data, cb)
    if state.busy then return cb({ ok = false, error = 'Hold on.' }) end
    state.busy = true

    local ok, payload = Core.Callbacks.await('characters:create', data.slot, {
        firstname   = data.firstname,
        lastname    = data.lastname,
        dob         = data.dob,
        gender      = data.gender,
        nationality = data.nationality,
    })

    if not ok then
        state.busy = false
        local messages = {
            invalid_name    = 'Enter a given and a family name.',
            invalid_slot    = 'That berth does not exist.',
            slot_taken      = 'That berth is already taken.',
            limit_reached   = 'Every one of your berths is taken.',
            invalid_dob     = 'That date of birth is not a real one.',
            invalid_age     = ('Hands must be between %d and %d.')
                :format(Config.Creation.minAge, Config.Creation.maxAge),
            invalid_payload = 'Could not read that form.',
            invalid_nationality = 'Choose where you are sailing from.',
        }
        return cb({ ok = false, error = messages[payload] or 'Could not create that character.' })
    end

    local selected = Core.Callbacks.await('characters:select', payload.citizenid)
    state.busy = false

    if not selected then
        refresh(payload.citizenid)
        return cb({ ok = false, error = 'Character created, but it would not load. Try again.' })
    end

    cb({ ok = true })
    spawnInto({
        citizenid = payload.citizenid,
        gender = data.gender,
        appearance = nil,
    }, true)
end)

RegisterNUICallback('delete', function(data, cb)
    if state.busy then return cb({ ok = false, error = 'Hold on.' }) end
    state.busy = true

    local ok = Core.Callbacks.await('characters:delete', data.citizenid)
    state.busy = false

    if not ok then return cb({ ok = false, error = 'That character could not be deleted.' }) end

    refresh(nil)
    cb({ ok = true })
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(50) end

    DoScreenFadeOut(0)

    -- already loaded means a resource restart mid-session, not a fresh join. on a fresh
    -- join this can never pass, so it is a short check and not a two second stall.
    local deadline = GetGameTimer() + 500
    while GetGameTimer() < deadline do
        if exports.SeaM_Core:IsPlayerLoaded() then
            reveal(0)
            return
        end
        Wait(50)
    end

    OpenSelection()
end)

RegisterNetEvent('SeaM_Core:player:unloaded', function()
    if state.open then return end
    OpenSelection()
end)

exports('Open', OpenSelection)
exports('IsOpen', function() return state.open end)
