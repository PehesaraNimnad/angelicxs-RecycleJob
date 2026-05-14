-- ============================================================
--  angelicxs-RecycleJob | client.lua  v2.0
--  No duty system. Grab → Sort → Get items.
--  ox_target · ox_lib · markers for bin guidance
-- ============================================================

-- ── State ────────────────────────────────────────────────────
local CurrentSort  = false   -- 'yellow' | 'blue' | 'green' | false
local prop         = nil     -- held bag object

local EntryPed = nil
local ExitPed  = nil

local ActiveColour = { yellow = false, blue = false, green = false }
local Containers   = {}      -- synced from server; each has .spot .entity .colour

-- ── Bin colour styles ────────────────────────────────────────
-- Used for lib.showTextUI style and DrawMarker colour
local BinStyle = {
    yellow = { r = 255, g = 215, b = 0,   hex = '#FFD700' },
    blue   = { r = 65,  g = 105, b = 225, hex = '#4169E1' },
    green  = { r = 34,  g = 139, b = 34,  hex = '#228B22' },
}

-- ── Utility ───────────────────────────────────────────────────
local function LoadModel(hash)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
    end
    return hash
end

local function Randomizer(list)
    return list[math.random(#list)]
end

-- ── Notify ───────────────────────────────────────────────────
local function Notify(msg, ntype)
    local t = ({ error='error', success='success', warning='warning' })[ntype] or 'inform'
    lib.notify({ description = msg, type = t })
end

-- ── Spawn static NPC ─────────────────────────────────────────
local function SpawnPed(model, pos, scenario)
    local hash = LoadModel(GetHashKey(model))
    local ped  = CreatePed(3, hash, pos.x, pos.y, pos.z - 1, pos.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, scenario, 0, false)
    SetModelAsNoLongerNeeded(model)
    return ped
end

local function SafeRemoveTarget(ped, name)
    if ped and DoesEntityExist(ped) then
        exports.ox_target:removeLocalEntity(ped, name)
    end
end

-- ── TextUI: show which bin the player needs ───────────────────
local function ShowBinHint(colour)
    local style = BinStyle[colour]
    lib.showTextUI(
        Config.Lang['textui_holding'] .. Config.Lang[colour] .. Config.Lang['textui_bin'],
        {
            position = 'right-center',
            icon     = 'fas fa-recycle',
            style    = {
                borderRadius = 6,
                backgroundColor = style.hex,
                color           = '#ffffff',
                fontSize        = '16px',
                fontWeight      = 'bold',
            },
        }
    )
end

-- ── Marker thread: arrow above matching bins while holding ────
local function StartMarkerThread(colour)
    if not Config.ShowBinMarker then return end
    CreateThread(function()
        while CurrentSort == colour do
            for _, v in ipairs(Containers) do
                if v.colour == colour and v.entity and DoesEntityExist(v.entity) then
                    local p  = GetEntityCoords(v.entity)
                    local st = BinStyle[colour]
                    -- Downward arrow (type 1) floating 1.5m above bin
                    DrawMarker(1,
                        p.x, p.y, p.z + 1.8,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.6, 0.6, 0.6,
                        st.r, st.g, st.b, 180,
                        false, true, 2, false, nil, nil, false)
                end
            end
            Wait(0)
        end
    end)
end

-- ── Anim helpers ─────────────────────────────────────────────
local function PlayProgress(label, dict, clip, flag, duration)
    return lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = false,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = dict, clip = clip, flag = flag },
    })
end

local function AttachBag(ped)
    local hash = LoadModel(GetHashKey('prop_cs_rub_binbag_01'))
    prop = CreateObject(hash, 0, 0, 0, true, true, true)
    RequestAnimDict('missfbi4prepp1')
    while not HasAnimDictLoaded('missfbi4prepp1') do Wait(10) end
    TaskPlayAnim(ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 6.0, -6.0, -1, 49, 0, 0, 0, 0)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005),
        0.12, 0.0, -0.05, 220.0, 120.0, 0.0, true, true, false, true, 1, true)
end

local function ThrowBag(ped)
    RequestAnimDict('missfbi4prepp1')
    while not HasAnimDictLoaded('missfbi4prepp1') do Wait(10) end
    TaskPlayAnim(ped, 'missfbi4prepp1', '_bag_throw_garbage_man', 8.0, 8.0, 1100, 48, 0, 0, 0, 0)
    Wait(1100)
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, 1, false)
        DeleteObject(prop)
        prop = nil
    end
    TaskPlayAnim(ped, 'missfbi4prepp1', 'exit', 8.0, 8.0, 800, 48, 0, 0, 0, 0)
    Wait(500)
    RemoveAnimDict('missfbi4prepp1')
end

local function CleanupProp()
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, 1, false)
        DeleteObject(prop)
        prop = nil
    end
end

-- ── Register ox_target on recycle bin models ─────────────────
local function RegisterBinTargets()
    exports.ox_target:addModel(-14708062, {{
        name     = 'RecycleYellow',
        label    = Config.Lang['place_item'] .. Config.Lang['yellow'] .. Config.Lang['sort_item_2'],
        icon     = 'fas fa-recycle',
        distance = 2.0,
        onSelect = function() TriggerEvent('RecycleJob:SortItem', 'yellow') end,
    }})
    exports.ox_target:addModel(-96647174, {{
        name     = 'RecycleBlue',
        label    = Config.Lang['place_item'] .. Config.Lang['blue'] .. Config.Lang['sort_item_2'],
        icon     = 'fas fa-recycle',
        distance = 2.0,
        onSelect = function() TriggerEvent('RecycleJob:SortItem', 'blue') end,
    }})
    exports.ox_target:addModel(811169045, {{
        name     = 'RecycleGreen',
        label    = Config.Lang['place_item'] .. Config.Lang['green'] .. Config.Lang['sort_item_2'],
        icon     = 'fas fa-recycle',
        distance = 2.0,
        onSelect = function() TriggerEvent('RecycleJob:SortItem', 'green') end,
    }})
    exports.ox_target:addModel(1748268526, {{
        name     = 'RecycleGrabTrash',
        label    = Config.Lang['grab_sort_item'],
        icon     = 'fas fa-trash',
        distance = 2.0,
        onSelect = function()
            if CurrentSort then
                Notify(Config.Lang['not_finished'], 'error')
                return
            end
            TriggerEvent('RecycleJob:BeginSorting')
        end,
    }})
end

local function UnregisterBinTargets()
    exports.ox_target:removeModel(-14708062,  'RecycleYellow')
    exports.ox_target:removeModel(-96647174,  'RecycleBlue')
    exports.ox_target:removeModel(811169045,  'RecycleGreen')
    exports.ox_target:removeModel(1748268526, 'RecycleGrabTrash')
end

-- ── Core: begin a sorting round ───────────────────────────────
AddEventHandler('RecycleJob:BeginSorting', function()
    -- Collect available colours from active containers
    local available = {}
    for colour, active in pairs(ActiveColour) do
        if active then available[#available + 1] = colour end
    end
    if #available == 0 then
        Notify('No recycle bins are active right now!', 'error')
        return
    end

    local colour = Randomizer(available)
    CurrentSort  = colour

    local ped = PlayerPedId()
    local ok  = PlayProgress(Config.Lang['grabbing'],
        'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        'machinic_loop_mechandplayer', 49, 2500)

    if not ok then
        CurrentSort = false
        return
    end

    AttachBag(ped)

    -- Show persistent HUD hint + coloured markers above bins
    ShowBinHint(colour)
    StartMarkerThread(colour)

    Notify(Config.Lang['textui_holding'] .. Config.Lang[colour] .. Config.Lang['textui_bin'], 'inform')
end)

-- ── Core: sort item into a bin ────────────────────────────────
AddEventHandler('RecycleJob:SortItem', function(bincolour)
    if not CurrentSort then
        Notify(Config.Lang['need_trash'], 'error')
        return
    end
    if CurrentSort ~= bincolour then
        local st = BinStyle[CurrentSort]
        -- Flash a wrong-bin notify with the colour name
        lib.notify({
            description = Config.Lang['wrong_bin'] .. Config.Lang[CurrentSort] .. Config.Lang['sort_item_2'],
            type        = 'error',
        })
        return
    end

    local ped = PlayerPedId()
    ThrowBag(ped)

    local ok = PlayProgress(Config.Lang['sorting'],
        'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        'machinic_loop_mechandplayer', 49, 3000)

    if ok then
        lib.hideTextUI()
        Notify(Config.Lang['item_sorted'], 'success')
        TriggerServerEvent('angelicxs-RecycleJob:GiveReward', CurrentSort, GetEntityCoords(ped))
        CurrentSort = false
    end
end)

-- ── Enter depot ───────────────────────────────────────────────
RegisterNetEvent('angelicxs-RecycleJob:Entry', function()
    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do Wait(10) end

    SetEntityCoords(PlayerPedId(),
        Config.RecycleDepot.x + 0.5, Config.RecycleDepot.y + 0.5, Config.RecycleDepot.z)
    SetEntityHeading(PlayerPedId(), Config.RecycleDepot.w)
    TriggerServerEvent('angelicxs-RecycleJob:Server:ActivityUpdater', true)

    DoScreenFadeIn(1000)
    while not IsScreenFadedIn() do Wait(10) end
    Notify(Config.Lang['inside_warehouse'], 'inform')

    Wait(500)

    -- Exit NPC
    ExitPed = SpawnPed(Config.ExitPed, Config.RecycleDepot, 'WORLD_HUMAN_STAND_IMPATIENT')
    exports.ox_target:addLocalEntity(ExitPed, {{
        name     = 'RecycleExit',
        label    = Config.Lang['request_exit'],
        icon     = 'fas fa-door-open',
        distance = 2.0,
        onSelect = function() TriggerEvent('angelicxs-RecycleJob:Exit') end,
    }})

    RegisterBinTargets()
end)

-- ── Exit depot ────────────────────────────────────────────────
RegisterNetEvent('angelicxs-RecycleJob:Exit', function()
    -- Drop whatever is being carried
    CurrentSort = false
    lib.hideTextUI()
    CleanupProp()

    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do Wait(10) end

    TriggerServerEvent('angelicxs-RecycleJob:Server:ActivityUpdater', false)
    SetEntityCoords(PlayerPedId(), Config.EntryPoint.x, Config.EntryPoint.y, Config.EntryPoint.z)

    if ExitPed then
        SafeRemoveTarget(ExitPed, 'RecycleExit')
        DeleteEntity(ExitPed)
        ExitPed = nil
    end
    UnregisterBinTargets()

    DoScreenFadeIn(1000)
    while not IsScreenFadedIn() do Wait(10) end
end)

-- ── Server → client state sync ────────────────────────────────
RegisterNetEvent('angelicxs-RecycleJob:Client:ActivityUpdater', function(colours, cons)
    ActiveColour = colours
    Containers   = cons
end)

-- ── Server → client notify ────────────────────────────────────
RegisterNetEvent('angelicxs-RecycleJob:Notify', function(msg, ntype)
    Notify(msg, ntype)
end)

-- ── Entry ped spawner (single low-cost thread) ────────────────
CreateThread(function()
    if Config.JobBlip then
        local blip = AddBlipForCoord(
            vector3(Config.EntryPoint.x, Config.EntryPoint.y, Config.EntryPoint.z))
        SetBlipSprite(blip, Config.JobBlipSprite)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, Config.JobBlipColour)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.JobBlipName)
        EndTextCommandSetBlipName(blip)
    end

    while true do
        local dist = #(GetEntityCoords(PlayerPedId()) -
            vector3(Config.EntryPoint.x, Config.EntryPoint.y, Config.EntryPoint.z))

        if dist <= 60 and not DoesEntityExist(EntryPed) then
            EntryPed = SpawnPed(Config.EntryPed, Config.EntryPoint, 'WORLD_HUMAN_STAND_IMPATIENT')
            exports.ox_target:addLocalEntity(EntryPed, {{
                name     = 'RecycleEntry',
                label    = Config.Lang['request_entry'],
                icon     = 'fas fa-recycle',
                distance = 2.0,
                onSelect = function() TriggerEvent('angelicxs-RecycleJob:Entry') end,
            }})
        elseif dist > 60 and DoesEntityExist(EntryPed) then
            SafeRemoveTarget(EntryPed, 'RecycleEntry')
            DeleteEntity(EntryPed)
            EntryPed = nil
        end

        Wait(2000)
    end
end)

-- ── Resource cleanup ──────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    CurrentSort = false
    lib.hideTextUI()
    CleanupProp()
    for _, ped in ipairs({ EntryPed, ExitPed }) do
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    UnregisterBinTargets()
end)
