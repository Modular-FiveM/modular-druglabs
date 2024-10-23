ESX = exports['es_extended']:getSharedObject()
Druglabs = {}
InsideDruglab = {}
OutsideDruglab = {}
Blips = {}
IsPlayerInDruglab = false
MissionStarted = false
CreatingDrugs = false
PoliceRaidTries = 0

RegisterNetEvent('modular-druglabs:updateDruglabs', function(Druglabs_)
    RefreshDruglabs(Druglabs_)
end)

RegisterNetEvent('modular-druglabs:enterDruglab', function(druglab_id, data)
    EnterDruglab(data, vector3(data.coords.enterCoords.x, data.coords.enterCoords.y, data.coords.enterCoords.z + 1.0), true)
end)

RegisterNetEvent('esx:playerLoaded', function()
    lib.callback.await('modular-druglabs:updateDruglabs', false)
end)

function getDruglab(id)
    for k,v in pairs(Druglabs) do
        if v.id == id then
            return v
        end
    end

    return nil
end

RegisterNetEvent('modular-druglabs:exitDruglab', function(druglab_id, forced)
    local druglab =  getDruglab(druglab_id)
    local druglabCfg = Config.Druglabs[druglab.drugtype]
    local EnterCoords = vector3(druglab.coords.enterCoords.x, druglab.coords.enterCoords.y, druglab.coords.enterCoords.z + .5)

    RequestCollisionAtCoord(EnterCoords)

    DoScreenFadeOut(150)
    Wait(250)
    SetEntityCoords(PlayerPedId(), EnterCoords)
    Wait(350)
    DoScreenFadeIn(250)

    for k,v in pairs(InsideDruglab) do
        if type(v) == 'number' then
            exports.ox_target:removeZone(v)
        else
            v:remove()
        end
    end

    lib.removeRadialItem('druglab_leave')
    lib.hideTextUI()
    InsideDruglab = {}
    TriggerServerEvent('modular-druglabs:setRoutingBucket', druglab_id, false)
    druglabCfg.despawnShell(druglabCfg)
    IsPlayerInDruglab = false
    removeAllRadial()

    for k,v in pairs(Druglabs) do
        if v.DoorPoint then
            v.DoorPoint:remove()
        end
    end

    for k,v in pairs(InsideDruglab) do
        if type(v) == 'number' then
            exports.ox_target:removeZone(v)
        else
            v:remove() 
        end
    end

    if forced then
        lib.notify({ description = 'You have been forced out of the druglab', type = 'error' })
    else
        lib.notify({ description = 'You have left the druglab', type = 'success' })
    end
end)

function removeAllRadial()
    lib.removeRadialItem('druglab_access_police')
    lib.removeRadialItem('druglab_access')
    lib.removeRadialItem('druglab_leave')
end

function RefreshDruglabs(druglabs_)
    print('Refreshing druglabs')

    if not IsPlayerInDruglab then
        for k,v in pairs(OutsideDruglab) do
            if type(v) == 'number' then
                exports.ox_target:removeZone(v)
            else
                v:remove() 
            end
        end
    end

    for _, blip in pairs(Blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    removeAllRadial()

    Blips = {}

    for k,v in pairs(druglabs_) do
        local data = Config.Druglabs[v.drugtype]

        -- Enter Point (Outside) --
        local EnterCoords = vector3(v.coords.enterCoords.x, v.coords.enterCoords.y, v.coords.enterCoords.z + 1.0)
        local EnterPoint = lib.points.new({ coords = EnterCoords, distance = 8 })
        local EnterMarker = lib.marker.new({ type = 2, coords = EnterCoords, color = { r = 255, g = 0, b = 0, a = 50 }, width = 0.8, height = 0.5 })

        function EnterPoint:onEnter()
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                return
            end

            if Config.UseUIText then
                lib.showTextUI('Press [E] to enter the druglab')
            else
                lib.addRadialItem({
                    id = 'druglab_access',
                    icon = 'fa-solid fa-warehouse',
                    label = 'Access Druglab',
                    onSelect = function()
                        EnterDruglab(v, EnterCoords, false, false)
                    end
                })
            end

            if ESX.PlayerData.job.name == Config.PoliceJob then
                lib.addRadialItem({
                    id = 'druglab_access_police',
                    icon = 'fa-solid fa-warehouse',
                    label = 'Raid Druglab',
                    onSelect = function()
                        local canRaid, isRaided = lib.callback.await('modular-druglabs:getRaidStatus', false, v.id)

                        if not canRaid then
                            return lib.notify({
                                description = 'You have failed to enter the druglab 3 times (Raid Cooldown)',
                                type = 'error'
                            })
                        end

                        local success = isRaided or lib.skillCheck(Config.PoliceRaid.Skillchecks, Config.PoliceRaid.SkillcheckButtons)

                        if success then
                            lib.callback.await('modular-druglabs:raidSuccess', false, v.id)
                            PoliceRaidTries = 0
                            EnterDruglab(v, EnterCoords, true, true)
                        else
                            PoliceRaidTries += 1
                            lib.notify({
                                description = 'You failed to enter the druglab',
                                type = 'error'
                            })

                            if PoliceRaidTries == 3 then
                                TriggerServerEvent('modular-druglabs:raidFailed', v.id)
                            end
                        end
                    end
                })
            end
        end

        function EnterPoint:nearby()
            EnterMarker:draw()

            if Config.UseUIText then
                if IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(PlayerPedId(), false) then
                    EnterDruglab(v, EnterCoords)
                end
            end
        end

        function EnterPoint:onExit()
            if Config.UseUIText then
                lib.hideTextUI()
            else
                lib.removeRadialItem('druglab_access_police')
                lib.removeRadialItem('druglab_access')
            end
        end

        druglabs_[k].DoorPoint = EnterPoint
        table.insert(OutsideDruglab, EnterPoint)

        if Config.EnableDebug then
            local blip = AddBlipForCoord(EnterCoords)
            SetBlipSprite(blip, 770)
            SetBlipColour(blip, 16)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Druglab')
            EndTextCommandSetBlipName(blip)

            Blips[#Blips + 1] = blip
        end
    end

    Druglabs = druglabs_
end

function EnterDruglab(data, EnterCoords, access, isPolice)
    if access ~= nil and access == false then
        local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

        if inVehicle then
            return lib.notify({ 
                type = 'error', 
                description = 'You cannot enter the druglab while in a vehicle' 
            })
        end

        local input = lib.inputDialog('Enter Druglab', {
            {
                type = 'input',
                label = 'Pincode',
                description = 'Enter the pincode for the druglab',
                icon = 'hashtag',
                password = true,
                min = 1
            }
        })

        if not input then return end

        local realPincode = lib.callback.await('modular-druglabs:getPincode', false, data.id)
        if input[1] ~= realPincode then
            return lib.notify({ type = 'error', description = 'Invalid pincode' })
        end
    end


    IsPlayerInDruglab = true
    local cfg = Config.Druglabs[data.drugtype]
    TriggerServerEvent('modular-druglabs:setRoutingBucket', data.id, true)
    cfg.loadShell(cfg)

    lib.notify({ description = 'You have entered the druglab', type = 'success' })

    RequestCollisionAtCoord(cfg.coords.door)
    DoScreenFadeOut(150)
    Wait(250)
    SetEntityCoords(PlayerPedId(), cfg.coords.door)
    Wait(350)
    DoScreenFadeIn(250)

    local function leaveDruglab()
        RequestCollisionAtCoord(EnterCoords)

        DoScreenFadeOut(150)
        Wait(250)
        SetEntityCoords(PlayerPedId(), EnterCoords)
        Wait(350)
        DoScreenFadeIn(250)

        for k,v in pairs(InsideDruglab) do
            if type(v) == 'number' then
                exports.ox_target:removeZone(v)
            else
                v:remove() 
            end
        end

        lib.removeRadialItem('druglab_leave')
        lib.hideTextUI()
        TriggerServerEvent('modular-druglabs:setRoutingBucket', data.id, false)
        InsideDruglab = {}
        cfg.despawnShell(cfg)
        IsPlayerInDruglab = false
    end

    -- Inside Points --
    local DoorPoint = lib.points.new({ coords = cfg.coords.door, distance = 3 })
    
    function DoorPoint:onEnter()
        if Config.UseUIText then
            lib.showTextUI('Press [E] to leave the druglab')
        else
            lib.addRadialItem({
                id = 'druglab_leave',
                icon = 'fa-solid fa-warehouse',
                label = 'Leave Druglab',
                onSelect = function()
                    leaveDruglab()
                end
            })

            lib.showTextUI('Leave Druglab')
        end
    end
     
    if Config.UseUIText then
        function DoorPoint:nearby()
            if IsControlJustPressed(0, 38) then
                leaveDruglab()
            end
        end
    end

    function DoorPoint:onExit()
        lib.hideTextUI()
        lib.removeRadialItem('druglab_leave')
    end


    -- Inside PC Target --
    local pc = exports.ox_target:addBoxZone({
        coords = cfg.coords.pc,
        size = { x = 0.5, y = 0.5, z = 0.5 },
        options = {
            {
                label = 'Open PC',
                icon = 'fa-solid fa-laptop',
                distance = 3,

                onSelect = function()
                    loadPCMenu(index, data, isPolice)
                end
            }
        }
    })
    
    -- Inside Stash Target --
    local stash = exports.ox_target:addSphereZone({
        coords = cfg.coords.stash,
        radius = 1.5,
        options = {
            {
                label = 'Open Stash',
                icon = 'fa-solid fa-boxes-stacked',
                distance = 3,

                onSelect = function()
                    local id = 'modular-druglabs-' .. data.id
                    
                    if Config.UseOXInventory then
                        exports.ox_inventory:openInventory('stash', { id = id })
                    else
                        Config.OpenStash(id)
                    end
                end
            }
        }
    })

    -- Processing Zone --
    local processZone = lib.points.new({ coords = cfg.coords.process, distance = 3 })
    local processMarker = lib.marker.new({ type = 25, coords = cfg.coords.process - vector3(0,0,0.97), color = { r = 255, g = 0, b = 0, a = 50 }, width = 2.5, height = 1.0 })

    local function processDrugs(drug)
        if not CreatingDrugs then return end

        if lib.progressBar({
            duration = cfg.drugProcessTime * 1000,
            label = 'Processing...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                sprint = true
            },
            anim = {
                scenario = 'PROP_HUMAN_PARKING_METER'
            }
        }) then
            local success = lib.callback.await('modular-druglabs:processDrugs', false, data.id, data.drugtype, drug)

            if success then
                processDrugs(drug)
            else
                CreatingDrugs = false
                ClearPedTasks(PlayerPedId())
                lib.hideTextUI()
                lib.removeRadialItem('druglab_process_stop')
                addRadialWhenEnter()
            end
        else 
            CreatingDrugs = false
            ClearPedTasks(PlayerPedId())
            lib.hideTextUI()
            lib.removeRadialItem('druglab_process_stop')
            addRadialWhenEnter()
        end
    end

    function addRadialWhenEnter()
        lib.addRadialItem({
            id = 'druglab_process',
            icon = 'fa-solid fa-warehouse',
            label = 'Start Processing',
            onSelect = function()
                if not CreatingDrugs then
                    local options = {}

                    for k,v in pairs(Config.Druglabs[data.drugtype].processItems) do
                        table.insert(options, { label = k, value = k })
                    end

                    local input = lib.inputDialog('Process Drugs', {
                        {
                            type = 'select',
                            label = 'Choose the drug you want to process',
                            icon = 'fa-solid fa-cubes',
                            options = options
                        }
                    })

                    if not input or not input?[1] then
                        return lib.notify({ type = 'error', description = 'You did not select a drug' })
                    end

                    CreatingDrugs = true
                    
                    lib.notify({ description = 'You have started processing drugs', type = 'info' })
                    lib.showTextUI('Press [X] to stop')
                    lib.removeRadialItem('druglab_process')
                    lib.addRadialItem({
                        id = 'druglab_process_stop',
                        icon = 'fa-solid fa-warehouse',
                        label = 'Stop Processing',
                        onSelect = function()
                            CreatingDrugs = false
                            ClearPedTasks(PlayerPedId())
                            lib.removeRadialItem('druglab_process_stop')
                            addRadialWhenEnter()
                        end
                    })
                    
                    processDrugs(input[1])
                end
            end
        })
    end

    function processZone:onEnter()
        if not isPolice then
            addRadialWhenEnter()
        end
    end

    function processZone:nearby()
        processMarker:draw()
    end

    function processZone:onExit()
        if not isPolice then
            lib.removeRadialItem('druglab_process')
            lib.removeRadialItem('druglab_process_stop')
            CreatingDrugs = false
            ClearPedTasks(PlayerPedId())
        end
    end

    table.insert(InsideDruglab, processZone)
    table.insert(InsideDruglab, DoorPoint)
    table.insert(InsideDruglab, pc)
    table.insert(InsideDruglab, stash)
end

function loadPCMenu(index, data, isPolice)
    local isOwner = data.owner == ESX.GetPlayerData().identifier
    local druglabData = lib.callback.await('modular-druglabs:getDruglabData', false, data.id)

    if isPolice then
        lib.registerContext({ 
            id = 'inside_pc_menu', 
            title = 'PC (Police)', 
            options = {
                {
                    title = 'Shutdown Druglab',
                    description = 'Shutdown the druglab (Police)',
                    icon = 'fa-solid fa-info',
                    onSelect = function()
                        TriggerServerEvent('modular-druglabs:shutdownDruglab', data.id)
                    end
                }
            }
        })

        lib.showContext('inside_pc_menu')

        return
    end

    lib.registerContext({
        id = 'inside_pc_menu_settings',
        title = 'PC Settings',
        options = {
            {
                title = 'Change Pincode',
                description = 'Change the pincode of the druglab',
                icon = 'fa-solid fa-key',
                disabled = not isOwner,
                onSelect = function()
                    local input = lib.inputDialog('Change Pincode', {
                        {
                            type = 'input',
                            label = 'Pincode',
                            description = 'Enter the new pincode for the druglab',
                            icon = 'hashtag',
                            password = true,
                            min = 1,
                            max = 60,
                        }
                    })

                    if not input then return end
                    TriggerServerEvent('modular-druglabs:changePincode', data.id, input[1])
                end
            },

            {
                title = 'Change Owner',
                description = 'Change the owner of the druglab',
                icon = 'fa-solid fa-user',
                disabled = not isOwner,
                onSelect = function()
                    local players = {}

                    for k,v in pairs(ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 15.0)) do
                        table.insert(players, { label = GetPlayerName(v), value = GetPlayerServerId(v) })
                    end

                    if #players == 0 then
                        return lib.notify({ type = 'error', description = 'No players nearby' })
                    end

                    local input = lib.inputDialog('Change Owner', {
                        {
                            type = 'select',
                            label = 'Select Owner',
                            description = 'Select a new owner for the druglab',
                            icon = 'fa-solid fa-user',
                            options = players,
                            required = true
                        }
                    })

                    if not input then return end
                    TriggerServerEvent('modular-druglabs:changeOwner', data.id, input[1])
                end
            }
        }
    })

    local missions = {}

    for i = 1, #Config.Missions do
        local mission = Config.Missions[i]
        local levelNeeded = mission.levelNeeded
        local level = tonumber(druglabData.level) or 1

        if level >= levelNeeded then
            table.insert(missions, {
                title = mission.title,
                description = mission.description,
                icon = 'fa-solid fa-tasks',
                onSelect = function()
                    startMission(i, data)
                end
            })
        else
            table.insert(missions, {
                title = mission.title,
                description = mission.description,
                icon = 'fa-solid fa-tasks',
                disabled = true
            })
        end
    end

    lib.registerContext({
        id = 'druglab_missions',
        title = 'Druglab Missions',
        menu = 'inside_pc_menu',
        options = missions
    })
    
    local level = druglabData.level
    local xp = druglabData.xp
    local xpPert = ((xp % Config.XPForLevel) / Config.XPForLevel) * 100

    lib.registerContext({ 
        id = 'inside_pc_menu', 
        title = 'PC', 
        options = {
            {
                title = 'Druglab Level System',
                description = 'Level: ' .. level,
                progress = xpPert,
            },

            {
                title = 'Druglab Missions',
                description = 'View the missions you can do in the druglab',
                icon = 'bars',
                menu = 'druglab_missions'
            },

            {
                title = 'Druglab Settings',
                description = 'View the settings of the druglab',
                icon = 'fa-solid fa-gear',
                iconAnimation = 'spin',
                menu = 'inside_pc_menu_settings'
            }
        } 
    })

    lib.showContext('inside_pc_menu')
end

boxProp = nil
vehicleProperties = json.decode('{"modArchCover":-1,"modSpeakers":-1,"wheelWidth":0.0,"modStruts":-1,"modSubwoofer":-1,"modSuspension":-1,"modDoorR":-1,"driftTyres":false,"color1":5,"tyres":[],"pearlescentColor":111,"paintType2":0,"modHood":-1,"bodyHealth":1000,"modRoof":-1,"modSpoilers":-1,"modVanityPlate":-1,"modTrimB":-1,"modRoofLivery":-1,"tyreSmokeColor":[255,255,255],"tankHealth":1000,"modSeats":-1,"modWindows":-1,"windows":[4,5,7],"modDial":-1,"modSteeringWheel":-1,"dirtLevel":3,"modEngineBlock":-1,"neonColor":[255,0,255],"engineHealth":1000,"modExhaust":-1,"bulletProofTyres":true,"modGrille":-1,"dashboardColor":0,"modHorns":-1,"modAPlate":-1,"modCustomTiresF":false,"modShifterLeavers":-1,"modHydrolic":-1,"modOrnaments":-1,"modDashboard":-1,"modLightbar":-1,"modFrame":-1,"modRightFender":-1,"modTransmission":-1,"modArmor":-1,"modNitrous":-1,"modTrimA":-1,"modFender":-1,"model":1162065741,"modTank":-1,"modPlateHolder":-1,"oilLevel":5,"modSmokeEnabled":false,"modTrunk":-1,"modXenon":false,"neonEnabled":[false,false,false,false],"modCustomTiresR":false,"modTurbo":false,"paintType1":0,"modDoorSpeaker":-1,"modRearBumper":-1,"modFrontBumper":-1,"modAirFilter":-1,"modSideSkirt":-1,"windowTint":-1,"wheelSize":0.0,"modFrontWheels":-1,"doors":[],"modBrakes":-1,"wheels":1,"plate":"Y13DN9I0","interiorColor":0,"xenonColor":255,"color2":0,"extras":[],"plateIndex":3,"wheelColor":156,"modLivery":1,"modHydraulics":false,"modBackWheels":-1,"modAerials":-1,"fuelLevel":65,"modEngine":-1}')
missionTable = {}

function startMission(index, data)
    local neededLevel = Config.Missions[index].levelNeeded

    if tonumber(data.level) < neededLevel then
        return lib.notify({
            type = 'error',
            description = 'You need to be level ' .. neededLevel .. ' to start this mission'
        })
    elseif MissionStarted then
        return lib.notify({
            type = 'error',
            description = 'You already have a mission in progress'
        })
    else
        lib.notify({
            type = 'info',
            description = 'You have started mission #' .. index
        })
    end

    MissionStarted = true
    TriggerServerEvent('modular-druglabs:startMission', data.id, index)

    missionTable[index](data)
end

if Config.EnableDebug then
    RegisterCommand('sigma', function(src, args)
        local index = tonumber(args[1] or 1)
        local data = lib.callback.await('modular-druglabs:getDruglabData', false, 2)

        startMission(index, data)
    end)
    
    RegisterCommand('sigma2', function()
        TriggerServerEvent('modular-druglabs:startMission', 2, 1)
        TriggerServerEvent('modular-druglabs:giveMissionReward', 1, 2)
    end)
end