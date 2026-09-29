local Core = exports.SeaM_Core:GetCoreObject()

local SeaM = exports.SeaM_Core

-- one bulk lookup for the whole crew; older builds without the export fall back per row
local function appearancesFor(citizenids)
    if GetResourceState('SeaM_Appearance') ~= 'started' then return nil end

    local ok, bulk = pcall(function() return exports.SeaM_Appearance:GetAppearances(citizenids) end)
    if ok and type(bulk) == 'table' then return bulk end

    local out = {}
    for i = 1, #citizenids do
        out[citizenids[i]] = exports.SeaM_Appearance:GetAppearance(citizenids[i])
    end
    return out
end

-- core only length-truncates dob, so without this a crafted packet signs on a 5-year-old
local function ageFrom(dob)
    local y, m, d = tostring(dob or ''):match('^(%d%d%d%d)-(%d%d)-(%d%d)$')
    if not y then return nil end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if m < 1 or m > 12 or d < 1 or d > 31 then return nil end

    local now = os.date('*t')
    local age = now.year - y
    if now.month < m or (now.month == m and now.day < d) then age = age - 1 end
    return age
end

local allowedNationality = {}
for i = 1, #Config.Creation.nationalities do
    allowedNationality[Config.Creation.nationalities[i]] = true
end

-- appearance is a client table that lands in the database, so cap what one post can carry
local APPEARANCE_MAX_KEYS = 64
local APPEARANCE_MAX_DEPTH = 4

local function appearanceSane(value, depth)
    depth = depth or 1
    if depth > APPEARANCE_MAX_DEPTH then return false end

    local keys = 0
    for k, v in pairs(value) do
        keys = keys + 1
        if keys > APPEARANCE_MAX_KEYS then return false end

        local kt = type(k)
        if kt ~= 'string' and kt ~= 'number' then return false end
        if kt == 'string' and #k > 48 then return false end

        local vt = type(v)
        if vt == 'table' then
            if not appearanceSane(v, depth + 1) then return false end
        elseif vt == 'string' then
            if #v > 128 then return false end
        elseif vt ~= 'number' and vt ~= 'boolean' then
            return false
        end
    end
    return true
end

local function validateCreate(ctx)
    local info = ctx and ctx.charinfo
    if type(info) ~= 'table' then return false, 'invalid_payload' end

    local age = ageFrom(info.dob)
    if not age then return false, 'invalid_dob' end
    if age < Config.Creation.minAge or age > Config.Creation.maxAge then
        return false, 'invalid_age'
    end

    -- The form only offers the configured list, so anything else is a crafted packet.
    -- This hook runs in SeaM_Core with a copy of ctx: editing ctx.charinfo here would
    -- never reach the saved character, so reject it instead of trying to fix it up.
    if not allowedNationality[info.nationality] then
        return false, 'invalid_nationality'
    end

    return true
end

-- registering before Core has provided Hooks silently no-ops, and the gate would
-- be gone with no error to show for it
CreateThread(function()
    while not Core.Hooks do Wait(50) end
    Core.Hooks.register('character:create', validateCreate)
end)

Core.Callbacks.register('multichar:list', function(source)
    local license = GetPlayerIdentifierByType(source, Core.Config.Server.RequiredIdent)
    if not license then return {}, 0 end

    local rows = Core.DB.query([[
        SELECT citizenid, slot, name, charinfo, job, gang, metadata, playtime, last_seen
        FROM seam_players WHERE license = ? ORDER BY slot ASC
    ]], { license })

    local ids = {}
    for i = 1, #rows do ids[i] = rows[i].citizenid end
    local looks = appearancesFor(ids)

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local charinfo = json.decode(row.charinfo or '{}') or {}
        local job      = json.decode(row.job or '{}') or {}
        local gang     = json.decode(row.gang or '{}') or {}
        local metadata = json.decode(row.metadata or '{}') or {}

        local jobDef   = Core.Jobs[job.name or ''] or {}
        local jobGrade = jobDef.grades and jobDef.grades[job.grade or 0] or nil
        local gangDef  = Core.Gangs[gang.name or ''] or {}

        out[i] = {
            citizenid   = row.citizenid,
            slot        = row.slot,
            name        = row.name,
            firstname   = charinfo.firstname,
            lastname    = charinfo.lastname,
            dob         = charinfo.dob,
            gender      = charinfo.gender or 0,
            nationality = charinfo.nationality,
            phone       = charinfo.phone,
            job         = jobDef.label or 'Civilian',
            jobGrade    = jobGrade and jobGrade.name or nil,
            gang        = (gang.name and gang.name ~= 'none') and gangDef.label or nil,
            playtime    = row.playtime or 0,
            lastSeen    = row.last_seen,
            appearance  = looks and looks[row.citizenid] or metadata.appearance,
        }
    end

    return out, Core.Config.Server.MaxCharacters
end)

local announced = {}

--- Fired once the player is standing in the world with their appearance
--- settled, rather than merely loaded. SeaM_Tutorial hangs its first run off
--- this so the narrator does not start behind the clothing editor.
RegisterNetEvent('SeaM_MultiChar:server:ready', function()
    local source = source

    if announced[source] then return end
    announced[source] = true

    TriggerEvent('SeaM_MultiChar:playerReady', source)
end)

AddEventHandler('playerDropped', function() announced[source] = nil end)
AddEventHandler('SeaM_Core:player:unloaded', function(source) announced[source] = nil end)

RegisterNetEvent('SeaM_MultiChar:server:saveAppearance', function(appearance)
    local src = source
    if type(appearance) ~= 'table' or not SeaM:GetCitizenId(src) then return end
    if not appearanceSane(appearance) then
        Core.Log.warn('multichar', ('%s sent an oversized appearance payload'):format(src))
        return
    end

    if GetResourceState('SeaM_Appearance') == 'started' then
        exports.SeaM_Appearance:SetAppearance(src, appearance)
        return
    end

    SeaM:SetMetadata(src, 'appearance', appearance)
    SeaM:SavePlayer(src, false)
end)

exports('SaveAppearance', function(source, appearance)
    if type(appearance) ~= 'table' or not SeaM:GetCitizenId(source) then return false end
    if not appearanceSane(appearance) then return false end

    if GetResourceState('SeaM_Appearance') == 'started' then
        return exports.SeaM_Appearance:SetAppearance(source, appearance)
    end

    SeaM:SetMetadata(source, 'appearance', appearance)
    SeaM:SavePlayer(source, false)
    return true
end)
