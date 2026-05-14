----------------------------------------------------------------------
--  AngelicXS Recycle Job — Config v2.0                            --
--  ox_target · ox_lib · ox_inventory                              --
--  No duty system — grab trash → sort → get items                 --
----------------------------------------------------------------------

Config = {}

-- ── Framework (set exactly ONE to true) ───────────────────────
Config.UseESX    = false   -- es_extended
Config.UseQBCore = false   -- qb-core
Config.UseQBX    = true    -- qbx_core

-- ── Map blip ──────────────────────────────────────────────────
Config.JobBlip       = true
Config.JobBlipSprite = 478
Config.JobBlipColour = 12
Config.JobBlipName   = "AngelicXS' Recycling Depot"

-- ── Locations ─────────────────────────────────────────────────
Config.EntryPoint   = vector4(850.36,  -1995.43, 29.98,  78.68)
Config.EntryPed     = 'u_m_y_smugmech_01'

Config.RecycleDepot = vector4(1087.34, -3099.42, -39.0, 270.00)
Config.ExitPed      = 's_m_y_garbage'

-- ── Anti-cheat ────────────────────────────────────────────────
Config.FurthestBin = 25

-- ── Trash bins — multi-spot, players grab from here ───────────
Config.TrashBins = {
    vector4(1095.69, -3102.79, -39.0, 180.00),
    vector4(1093.00, -3102.79, -39.0, 180.00),
    -- vector4(1091.00, -3102.79, -39.0, 180.00),
}

-- ── Recycle sorting bins ──────────────────────────────────────
-- Only change the vector4 values.
Config.RecycleBins = {
    { spot = vector4(1088.73, -3096.62, -39.0, 0.0), entity = nil, colour = nil },
    { spot = vector4(1091.25, -3096.56, -39.0, 0.0), entity = nil, colour = nil },
    { spot = vector4(1095.04, -3096.53, -39.0, 0.0), entity = nil, colour = nil },
    { spot = vector4(1097.59, -3096.51, -39.0, 0.0), entity = nil, colour = nil },
    { spot = vector4(1101.19, -3096.56, -39.0, 0.0), entity = nil, colour = nil },
    { spot = vector4(1103.81, -3096.68, -39.0, 0.0), entity = nil, colour = nil },
}

-- ── Item rewards ──────────────────────────────────────────────
Config.ItemRewardChance = 100   -- 0-100. Set 100 to always give items.

Config.RandomItemList = {
    ['yellow'] = {
        { item = 'metalscrap', min = 1, max = 4 },
        { item = 'plastic',    min = 1, max = 3 },
    },
    ['blue'] = {
        { item = 'plastic',    min = 1, max = 4 },
        { item = 'rubber',     min = 1, max = 3 },
    },
    ['green'] = {
        { item = 'metalscrap', min = 2, max = 5 },
        { item = 'aluminum',   min = 1, max = 3 },
    },
}

-- ── Visual guidance while holding an item ─────────────────────
-- true  = glowing arrow marker drawn above every matching bin
-- false = text-only guidance via lib.showTextUI
Config.ShowBinMarker = true

-- ── Language ──────────────────────────────────────────────────
Config.Lang = {
    ['request_entry']    = 'Enter Recycling Depot',
    ['request_exit']     = 'Exit Recycling Depot',
    ['grab_sort_item']   = 'Grab Item to Sort',
    ['place_item']       = 'Place Item in ',
    ['sort_item_2']      = ' Bin',
    ['wrong_bin']        = 'Wrong bin! You need: ',
    ['item_sorted']      = 'Item sorted correctly!',
    ['need_trash']       = 'Grab trash from the trash bin first!',
    ['not_finished']     = 'Finish sorting the current item first!',
    ['textui_holding']   = '🗑️  Take this to the ',
    ['textui_bin']       = ' BIN',
    ['inside_warehouse'] = 'You entered the recycling depot!',
    ['item_find_1']      = 'Found: ',
    ['item_find_2']      = ' — nice find!',
    ['grabbing']         = 'Grabbing item...',
    ['sorting']          = 'Sorting item...',
    ['yellow']           = 'YELLOW',
    ['blue']             = 'BLUE',
    ['green']            = 'GREEN',
}
