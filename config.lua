-- character select. core owns the data, this owns the screen and where you land.

Config = {}

Config.SpawnMode = 'fixed' -- 'fixed' | 'last'
Config.Spawn = vector4(4981.0439, -5871.1797, 19.9187, 35.2861) -- cayo, the starting point

-- where the preview ped stands. flat, empty, always streamed in.
-- sway is the slow camera drift, off because the camera should hold still.
Config.Preview = {
    ped       = vector4(4981.0439, -5871.1797, 19.9187, 35.2861),
    distance  = 2.4,
    height    = 0.25,
    fov       = 38.0,
    sway      = false,
    swayArc   = 0.18, -- metres either side
    swaySpeed = 0.00022,
}

-- select screen only, cleared on spawn
Config.Scene = {
    overrideTime    = true,
    hour            = 19,
    minute          = 20,
    overrideWeather = true,
    weather         = 'EXTRASUNNY',
}

Config.Animation = {
    enabled = true,
    mode    = 'random', -- 'random' | 'fixed'
    fixed   = 'WORLD_HUMAN_STAND_IMPATIENT',
    scenarios = {
        'WORLD_HUMAN_STAND_IMPATIENT',
        'WORLD_HUMAN_SMOKING',
        'WORLD_HUMAN_STAND_MOBILE',
        'WORLD_HUMAN_LEANING',
        'WORLD_HUMAN_MUSCLE_FLEX',
    },
}

-- played as the character switches in
Config.Effect = {
    enabled    = true,
    mode       = 'random', -- 'random' | 'fixed' | 'off'
    fixed      = 'HeistCelebPass',
    list       = { 'HeistCelebPass', 'SuccessNeutral', 'RaceTurbo', 'MP_Celeb_Win' },
    durationMs = 900,
}

Config.UI = {
    serverName = 'SeaM Roleplay',
    tagline    = 'Sign the articles, take a berth, and the tide does the rest.',
    accent     = '#c9974a', -- the one colour that means "you can act on this"
    roster     = 'articles', -- 'articles' | 'plates' | 'manifest' | 'logbook'
    card       = 'parch',    -- 'parch' | 'brass' | 'plain'

    store = { label = "Ship's store", url = '' }, -- empty url hides it, http(s) only

    credits = { -- empty list hides the button
        { role = 'Founder',   name = 'SeaM' },
        { role = 'Framework', name = 'SeaM_Core' },
        { role = 'Crew',      name = 'Everyone who logs in' },
    },
}

Config.Creation = {
    nationalities = {
        'American', 'British', 'Canadian', 'Mexican', 'Irish', 'Italian',
        'German', 'French', 'Polish', 'Nigerian', 'Japanese', 'Korean',
        'Brazilian', 'Australian', 'Other',
    },
    minAge = 18, -- re-checked server-side, the form is a client
    maxAge = 90,
}

-- 'none' skips clothing and gives everyone a default freemode ped.
-- to bridge something else, adapt client/appearance.lua.
Config.Appearance = {
    resource = 'auto', -- 'auto' | 'SeaM_Appearance' | 'none'
    customiseOnCreate = true,
}

Config.Models = {
    male   = `mp_m_freemode_01`,
    female = `mp_f_freemode_01`,
}
