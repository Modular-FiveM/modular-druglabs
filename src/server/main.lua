local ESX = exports['es_extended']:getSharedObject()
local Druglabs = {}
local InDruglab = {}
local OngoingMissions = {}
local DruglabRaids = {}

CreateThread(function()
    exports['oxmysql']:query([[
        CREATE TABLE IF NOT EXISTS `modular_druglabs` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(46) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `drugtype` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `coords` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `pincode` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `stashData` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `xp` INT(11) NULL DEFAULT '0',
            `activated` INT(11) NULL DEFAULT '1',
            PRIMARY KEY (`id`) USING BTREE
        )
    ]])
end)

ESX.RegisterCommand(Config.AdminCommand, 'admin', function(xPlayer, args, showError)
    exports['oxmysql']:query([[
        SELECT users.firstname, users.lastname, modular_druglabs.*
        FROM modular_druglabs
        INNER JOIN users
        ON modular_druglabs.owner = users.identifier
        ORDER BY modular_druglabs.id ASC
    ]], {}, function(data)
        TriggerClientEvent('modular-druglabs:openAdminMenu', xPlayer.source, data)
    end)
end, false)

RegisterNetEvent('modular-druglabs:createDruglab', function(owner, shell, pincode, slots, weight, coords, price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getGroup() ~= Config.AdminRank then
        return print('Lua Executor maybe?')
    end

    if not shell or not owner then
        return print('No shell or owner')
    end

    local ownerPlayer = ESX.GetPlayerFromId(owner)

    if not ownerPlayer then
        return print('No owner player')
    end

    if price and price > 0 then
        if ownerPlayer.getAccount('bank').money < price then
            return lib.notify(src, {
                description = 'Player doesn\'t have enough money in bank',
                type = 'error'
            })
        end

        ownerPlayer.removeAccountMoney('bank', price)
    end

    local ConfigData = Config.Druglabs[shell]

    if not ConfigData then
        return print('No shell data')
    end

    exports['oxmysql']:query([[
        INSERT INTO modular_druglabs
        (owner, drugtype, coords, pincode, stashData)
        VALUES 
        (@owner, @drugtype, @coords, @pincode, @stash)
    ]], {
        ['@owner'] = ownerPlayer.getIdentifier(),
        ['@drugtype'] = shell,
        ['@coords'] = json.encode(coords),
        ['@pincode'] = pincode,
        ['@stash'] = json.encode({ slots = slots, weight = weight }),
    }, function()
        loadDruglabs()

        sendDiscordLog({
            hook = 'createDruglab',
            title = 'Druglab Created',
            description = '**Player:** ' .. xPlayer.getName() .. '\n**Druglab:** ' .. shell
        })
    end)
end)


---- Lib Callbacks ----

lib.callback.register('modular-druglabs:getPincode', function(src, druglab_id)
    if Druglabs[druglab_id] then
        return Druglabs[druglab_id].pincode
    else
        local data = exports['oxmysql']:single_async('SELECT pincode FROM modular_druglabs WHERE id = ?', { druglab_id })

        return data.pincode or ''
    end
end)

lib.callback.register('modular-druglabs:getDruglabData', function(src, druglab_id)
    if Druglabs[druglab_id] then
        return Druglabs[druglab_id]
    else
        local data = exports['oxmysql']:single_async('SELECT * FROM modular_druglabs WHERE id = ?', { druglab_id })

        return data
    end
end)

lib.callback.register('modular-druglabs:updateDruglabs', function(src)
    loadDruglabs()
    return
end)

lib.callback.register('modular-druglabs:processDrugs', function(src, druglab_id, drugtype, drug)
    local xPlayer = ESX.GetPlayerFromId(src)
    local level = Druglabs[druglab_id].level
    local drugData = Config.Druglabs[drugtype].processItems[drug]

    if not drugData then
        return lib.notify(src, { 
            description = 'This drug does not exist', 
            type = 'error' 
        })
    end

    if level < drugData.neededLevel then
        return lib.notify(src, { 
            description = 'You need to be level ' .. drugData.level .. ' to process this drug', 
            type = 'error' 
        })
    end

    local canProcess = true
    local neededItem = nil

    for item, amount in pairs(drugData.neededItems) do
        local itemData = xPlayer.getInventoryItem(item)

        if itemData and itemData.count < amount then
            canProcess = false
            neededItem = item
            neededAmount = amount
            break
        elseif itemData == nil then
            canProcess = false
            neededItem = item
            neededAmount = amount
            break
        end
    end

    if canProcess then
        for item, amount in pairs(drugData.neededItems) do
            xPlayer.removeInventoryItem(item, amount)
        end

        for item, amount in pairs(drugData.givingItems) do
            xPlayer.addInventoryItem(item, amount)
        end

        return true
    else
        lib.notify(src, {
            description = 'You need ' .. neededAmount .. ' ' .. neededItem .. ' to process the ' .. drug,
            type = 'error'
        })

        return false
    end
end)

lib.callback.register('modular-druglabs:getRaidStatus', function(src, druglab_id)
    local raidStatus = DruglabRaids[druglab_id] or 'notOnCooldown'

    if raidStatus == 'onCooldown' then
        return false, false
    elseif raidStatus == 'notOnCooldown' then
        return true, false
    elseif raidStatus == 'policeRaided' then
        return true, true
    else
        return false, false
    end
end)

lib.callback.register('modular-druglabs:raidSuccess', function(src, druglab_id)
    DruglabRaids[druglab_id] = 'policeRaided'

    sendDiscordLog({
        hook = 'raidSuccess',
        title = 'Druglab Raided Successfully',
        description = '**Player:** ' .. ESX.GetPlayerFromId(src).getName() .. '\n**Druglab:** ' .. druglab_id
    })
end)


---- Net Events ----
RegisterNetEvent('modular-druglabs:setRoutingBucket', function(index, bool)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if bool then
        xPlayer.setMeta('modular_druglab', { inDruglab = true, index = index })

        index = index + 250
        SetPlayerRoutingBucket(src, index)
        InDruglab[src] = index
    else
        SetPlayerRoutingBucket(src, 0)
        InDruglab[src] = nil
        xPlayer.setMeta('modular_druglab', { inDruglab = false })
    end
end)

RegisterNetEvent('modular-druglabs:changePincode', function(druglabId, pincode)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if Druglabs[druglabId] and Druglabs[druglabId].owner ~= xPlayer.getIdentifier() then
        return print('Not owner')
    end

    Druglabs[druglabId].pincode = pincode
    exports['oxmysql']:query('UPDATE modular_druglabs SET pincode = ? WHERE id = ?', { pincode, druglabId })
end)

RegisterNetEvent('modular-druglabs:deleteDruglab', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getGroup() ~= Config.AdminRank then
        return print('Lua Executor maybe?')
    end

    exports['oxmysql']:query('DELETE FROM modular_druglabs WHERE id = ?', { id }, function()
        loadDruglabs()

        sendDiscordLog({
            hook = 'deleteDruglab',
            title = 'Druglab Deleted',
            description = '**Player:** ' .. xPlayer.getName() .. '\n**Druglab:** ' .. id
        })
    end)
end)

RegisterNetEvent('modular-druglabs:startMission', function(druglab_id, missionId)
    local src = source
    local alreadyStarted = false

    for i = 1, #OngoingMissions do
        if OngoingMissions[i] and OngoingMissions[i].druglab_id == druglab_id then
            alreadyStarted = true
            break
        end
    end

    if OngoingMissions[src] then
        return print('Already on a mission, modding?')
    end

    if alreadyStarted then
        return lib.notify(src, {
            description = 'Someone is already on a mission for this druglab',
            type = 'error'
        })
    end

    OngoingMissions[src] = { druglab_id = druglab_id, missionId = missionId }
end)

RegisterNetEvent('modular-druglabs:giveMissionReward', function(missionId, druglab_id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not OngoingMissions[src] then
        return print('No mission, modding?')
    elseif OngoingMissions[src].druglab_id ~= druglab_id then
        return print('Not the same druglab, modding?')
    elseif OngoingMissions[src].missionId ~= missionId then
        return print('Not the same mission, modding?')
    end

    if missionId == 1 then
        local randomInt = math.random(#Config.Missions[missionId].rewards[Druglabs[druglab_id].drugtype])
        local reward = Config.Missions[missionId].rewards[Druglabs[druglab_id].drugtype][randomInt]

        if reward.item == 'black_money' then
            xPlayer.addAccountMoney('black_money', reward.amount)
        else
            xPlayer.addInventoryItem(reward.item, reward.amount)
        end
    elseif missionId == 2 then
        local rewards = Config.Missions[missionId].rewards[Druglabs[druglab_id].drugtype]

        for _, reward in pairs(rewards) do
            if reward.item == 'black_money' then
                xPlayer.addAccountMoney('black_money', reward.amount)
            else
                xPlayer.addInventoryItem(reward.item, reward.amount)
            end
        end
    elseif missionId then
        if Config.Missions[missionId].reward then
            Config.Missions[missionId].reward(xPlayer, Druglabs[druglab_id].drugtype)
        else
            print('MissionID: ' .. missionId .. ' has no reward function')
        end
    else
        print('Mission rewards not found.')
    end

    if Druglabs[druglab_id] then
        Druglabs[druglab_id].xp = Druglabs[druglab_id].xp + (Config.Missions[missionId].rewardXP / (Config.HarderForNextLevel and Druglabs[druglab_id].level or 1))
        Druglabs[druglab_id].level = math.floor(Druglabs[druglab_id].xp / Config.XPForLevel) + 1

        exports['oxmysql']:query('UPDATE modular_druglabs SET xp = ? WHERE id = ?', { Druglabs[druglab_id].xp, druglab_id })
    end

    lib.notify(src, {
        description = 'You have completed the mission and received your rewards',
        type = 'success'
    })

    sendDiscordLog({
        hook = 'finishMission',
        title = 'Druglab Mission Completed',
        description = '**Player:** ' .. xPlayer.getName() .. '\n**Druglab:** ' .. druglab_id .. '\n**Mission:** ' .. missionId
    })

    OngoingMissions[src] = nil
end)

RegisterNetEvent('modular-druglabs:changeOwner', function(druglab_id, newOwner)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local yPlayer = ESX.GetPlayerFromId(newOwner)

    if xPlayer and yPlayer then
        if Druglabs[druglab_id] and (Druglabs[druglab_id].owner == xPlayer.getIdentifier() or xPlayer.getGroup() == Config.AdminRank) then
            Druglabs[druglab_id].owner = yPlayer.getIdentifier()
            exports['oxmysql']:query('UPDATE modular_druglabs SET owner = ? WHERE id = ?', { yPlayer.getIdentifier(), druglab_id })
            loadDruglabs()
        end
    end
end)

RegisterNetEvent('modular-druglabs:raidFailed', function(druglab_id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    DruglabRaids[druglab_id] = 'onCooldown'
    SetTimeout(Config.RaidCooldown * (60 * 1000), function()
        DruglabRaids[druglab_id] = 'notOnCooldown'
    end)
end)

RegisterNetEvent('esx:playerLoaded', function(src, xPlayer, isNew)
    local druglabData = xPlayer.getMeta('modular_druglab')

    if druglabData?.inDruglab then
        local index = druglabData.index + 250
        SetPlayerRoutingBucket(src, index)
        InDruglab[src] = index
        local druglab = loadSpecificDruglab(src, druglabData.index)
        TriggerClientEvent('modular-druglabs:enterDruglab', src, druglab.id, druglab)
    end
end)

RegisterNetEvent('modular-druglabs:toggleDruglab', function(druglab_id, activated)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getGroup() ~= Config.AdminRank then
        return print('Lua Executor maybe?')
    end

    local status = 1
    if activated == 1 then
        status = 0
    end

    if Druglabs[druglab_id] then
        Druglabs[druglab_id].activated = status
    end

    exports['oxmysql']:query('UPDATE modular_druglabs SET activated = ? WHERE id = ?', { status, druglab_id }, function()
        if status == 0 then
            deactivateDruglab(druglab_id, false)
        else
            loadDruglabs()
        end
    end)
end)

RegisterNetEvent('modular-druglabs:shutdownDruglab', function(druglab_id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getJob().name ~= Config.PoliceJob then
        return print('Lua Executor maybe?')
    end

    deactivateDruglab(druglab_id, true)
end)

function deactivateDruglab(druglab_id, updateDB)
    for src, index in pairs(InDruglab) do
        index -= 250

        if index == druglab_id then
            TriggerClientEvent('modular-druglabs:exitDruglab', src, druglab_id)
            InDruglab[src] = nil
        end
    end

    if updateDB then
        exports['oxmysql']:query('UPDATE modular_druglabs SET activated = ? WHERE id = ?', { 0, druglab_id }, function()
            loadDruglabs()
        end)
    else
        loadDruglabs()
    end
end

function loadDruglabs()
    Druglabs = {}

    exports['oxmysql']:query('SELECT * FROM modular_druglabs WHERE activated = "1"', {}, function(data)
        for _, druglab in pairs(data) do
            local id = druglab.id
            local stashData = json.decode(druglab.stashData)
            data[_].coords = json.decode(druglab.coords)
            data[_].stashData = json.decode(druglab.stashData)

            -- XP and Level
            data[_].level = math.floor(data[_].xp / Config.XPForLevel) + 1

            if Config.UseOXInventory then
                exports.ox_inventory:RegisterStash('modular-druglabs-' .. id, '[Druglab Stash]', stashData.slots, stashData.weight * 1000, false)
            else
                Config.LoadStash('modular-druglabs-' .. id, '[Druglab Stash]', stashData.slots, stashData.weight * 1000)
            end

            Druglabs[id] = data[_]
        end

        TriggerClientEvent('modular-druglabs:updateDruglabs', -1, Druglabs)
    end)
end

function loadSpecificDruglab(src, index)
    local druglab = exports['oxmysql']:single_async('SELECT * FROM modular_druglabs WHERE id = ? AND activated = "1"', { index })

    druglab.coords = json.decode(druglab.coords)
    druglab.stashData = json.decode(druglab.stashData)

    -- XP and Level
    druglab.level = math.floor(druglab.xp / Config.XPForLevel) + 1

    if Config.UseOXInventory then
        exports.ox_inventory:RegisterStash('modular-druglabs-' .. druglab.id, '[Druglab Stash]', druglab.stashData.slots, druglab.stashData.weight * 1000, false)
    else
        Config.LoadStash('modular-druglabs-' .. druglab.id, '[Druglab Stash]', druglab.stashData.slots, druglab.stashData.weight * 1000)
    end
    
    return druglab
end

function sendDiscordLog(data)
    local webhook = Config.Discord.webhooks[data.hook]

    if not webhook then
        return print('No webhook found = ' .. data.hook)
    end

    Config.Log(data.title, data.description)

    PerformHttpRequest(webhook,
        function(err, text, headers) end,
        'POST',
        json.encode({
            username    = Config.Discord.name, 
            avatar_url  = Config.Discord.avatar,
            embeds      = {
                {
                    color = Config.Discord.color or 16711680,
                    title = data.title or 'No Title',
                    description = data.description or 'No Description',
                }
            }
        }), 
        { 
            ['Content-Type']= 'application/json'
        }
    )
end


if Config.EnableDebug then
    CreateThread(function()
        Wait(1500)
        loadDruglabs()
    end)
end