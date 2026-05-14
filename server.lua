-- ============================================================
--  angelicxs-RecycleJob | server.lua  v2.0
--  No duty/payment. Items only via ox_inventory.
-- ============================================================

-- ── Data ─────────────────────────────────────────────────────
local PlayersInZone = {}   -- [src] = true | nil

local Containers   = Config.RecycleBins
local ConModels    = { -14708062, -96647174, 811169045 }
local ActiveColour = { yellow = false, blue = false, green = false }
local TrashObjs    = {}    -- [index] = entity  (one per Config.TrashBins entry)

-- ── Helpers ──────────────────────────────────────────────────
local function Randomizer(list)
    return list[math.random(#list)]
end

local function AnyoneActive()
    for _, v in pairs(PlayersInZone) do
        if v then return true end
    end
    return false
end

-- Returns true if loc is within Config.FurthestBin of ANY trash bin
local function NearAnyBin(loc)
    for _, pos in ipairs(Config.TrashBins) do
        if #(loc - vector3(pos.x, pos.y, pos.z)) <= Config.FurthestBin then
            return true
        end
    end
    return false
end

-- ── Give item via ox_inventory ────────────────────────────────
local function GiveItem(src, item, qty)
    exports.ox_inventory:AddItem(src, item, qty)
end

-- ── Entity management ─────────────────────────────────────────
local function SpawnContainer(v)
    local hash = Randomizer(ConModels)
    if     hash == -14708062 then v.colour = 'yellow' ; ActiveColour.yellow = true
    elseif hash == -96647174 then v.colour = 'blue'   ; ActiveColour.blue   = true
    elseif hash == 811169045 then v.colour = 'green'  ; ActiveColour.green  = true
    end
    v.entity = CreateObject(hash, v.spot.x, v.spot.y, v.spot.z - 1, true, true, true)
    SetEntityHeading(v.entity, v.spot.w)
end

local function SpawnTrashBins()
    for i, pos in ipairs(Config.TrashBins) do
        if not (TrashObjs[i] and DoesEntityExist(TrashObjs[i])) then
            TrashObjs[i] = CreateObject(
                1748268526, pos.x, pos.y, pos.z - 1, true, true, true)
            SetEntityHeading(TrashObjs[i], pos.w)
        end
    end
end

local function DeleteTrashBins()
    for i, ent in pairs(TrashObjs) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
        TrashObjs[i] = nil
    end
end

local function DeleteContainers()
    for _, v in ipairs(Containers) do
        if v.entity and DoesEntityExist(v.entity) then DeleteEntity(v.entity) end
        v.entity = nil
        v.colour = nil
    end
    ActiveColour.yellow = false
    ActiveColour.blue   = false
    ActiveColour.green  = false
end

-- ── Activity updater (player enter / exit depot) ──────────────
RegisterNetEvent('angelicxs-RecycleJob:Server:ActivityUpdater', function(active)
    local src = source
    PlayersInZone[src] = active or nil

    if active then
        for _, v in ipairs(Containers) do
            if not (v.entity and DoesEntityExist(v.entity)) then
                SpawnContainer(v)
            end
        end
        SpawnTrashBins()
    else
        if not AnyoneActive() then
            DeleteContainers()
            DeleteTrashBins()
        end
    end

    TriggerClientEvent('angelicxs-RecycleJob:Client:ActivityUpdater', -1, ActiveColour, Containers)
end)

-- ── Reward: give items on correct sort ───────────────────────
RegisterNetEvent('angelicxs-RecycleJob:GiveReward', function(colour, loc)
    local src = source

    -- Anti-cheat: must be near a trash bin
    if not NearAnyBin(loc) then
        TriggerEvent('angelicxs-RecycleJob:Cheat', src,
            'reward triggered too far from any trash bin')
        return
    end

    -- Chance check
    if math.random(100) > Config.ItemRewardChance then return end

    local pool = Config.RandomItemList[colour]
    if not pool or #pool == 0 then return end

    local pick = Randomizer(pool)
    local qty  = math.random(pick.min, pick.max)

    GiveItem(src, pick.item, qty)

    TriggerClientEvent('angelicxs-RecycleJob:Notify', src,
        Config.Lang['item_find_1'] .. pick.item ..
        ' x' .. qty .. ' — ' .. Config.Lang['item_find_2'],
        'success')
end)

-- ── Anti-cheat ────────────────────────────────────────────────
AddEventHandler('angelicxs-RecycleJob:Cheat', function(src, reason)
    print(('[RecycleJob] EXPLOIT | Player %d | %s'):format(src, reason))
    DropPlayer(src, 'Exploit detected.')
end)

RegisterNetEvent('angelicxs-RecycleJob:ThatIsAThing', function(reason)
    TriggerEvent('angelicxs-RecycleJob:Cheat', source, reason)
end)

-- ── Resource stop cleanup ─────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    PlayersInZone = {}
    DeleteContainers()
    DeleteTrashBins()
end)
