local function missionBlip(coords, oldLocation)
    if oldLocation and DoesBlipExist(oldLocation) then
        RemoveBlip(oldLocation)
    end

    local blip = AddBlipForCoord(coords)
    SetBlipRoute(blip, true)
    SetBlipColour(blip, 5)

    return blip
end

local function carryBox(ply)
    local ad = "anim@heists@box_carry@"
    local prop_name = 'hei_prop_heist_box'

    lib.requestAnimDict(ad)
    local x,y,z in GetEntityCoords(ply)
    boxProp = CreateObject(GetHashKey(prop_name), x, y, z+0.2,  true,  true, true)
    AttachEntityToEntity(boxProp, ply, GetPedBoneIndex(ply, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(ply, ad, "idle", 3.0, -8, -1, 63, 0, 0, 0, 0 )
end

local function detachBox(ply)
    local ad = "anim@heists@box_carry@"
    lib.requestAnimDict(ad)
    TaskPlayAnim(ply, ad, "exit", 3.0, 1.0, -1, 49, 0, 0, 0, 0 )
    DetachEntity(boxProp, 1, 1)
    DeleteObject(boxProp)
    Wait(1000)
    ClearPedSecondaryTask(ply)
end

missionTable[1] = function(data)
    local missionConfig = Config.Missions[1]
    local vehicleHash, locationsNeeded = missionConfig.vehicle, missionConfig.locationsShuffle-1
    local sphereZone, locationBlip, myVehicle
    local carryingBox = false

    local availableLocations = {table.unpack(missionConfig.pickupLocations)}

    local randomLocationNum = math.random(#availableLocations)
    local randomLocation = availableLocations[randomLocationNum]
    availableLocations[randomLocationNum] = nil


    while true do
        Wait(500)

        if not IsPlayerInDruglab then
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(data.coords.garageCoords.x, data.coords.garageCoords.y, data.coords.garageCoords.z))

            if dist < 15.0 then
                lib.requestModel(missionConfig.vehicle)
                myVehicle = CreateVehicle(missionConfig.vehicle, data.coords.garageCoords.x, data.coords.garageCoords.y, data.coords.garageCoords.z, true, true)
                SetVehicleOnGroundProperly(myVehicle)
                SetEntityAsMissionEntity(myVehicle, true, true)
                lib.setVehicleProperties(myVehicle, vehicleProperties)
                break
            end
        end
    end

    local function finishMission()
        lib.notify({
            type = 'success',
            description = 'You have finished the mission, head back to the lab'
        })

        local garageVector = vector3(data.coords.garageCoords.x, data.coords.garageCoords.y, data.coords.garageCoords.z)
        locationBlip = missionBlip(garageVector, locationBlip)

        local deliverPoint = lib.points.new({ coords = garageVector, distance = 15 })
        local deliverMarker = lib.marker.new({ 
            type = 25, 
            coords = garageVector, 
            color = { r = 255, g = 0, b = 0, a = 50 }, 
            width = 2.8, 
            height = 0.8 
        })

        local function deliverVehicle()
            lib.notify({ 
                type = 'success', 
                description = 'You have delivered the vehicle'
            })

            RemoveBlip(locationBlip)
            deliverPoint:remove()
            lib.removeRadialItem('deliver_vehicle')
            TaskLeaveAnyVehicle(PlayerPedId(), 0, 0)
            Wait(1750)
            DeleteVehicle(myVehicle)

            TriggerServerEvent('modular-druglabs:giveMissionReward', 1, data.id)
            MissionStarted = false
        end

        function deliverPoint:onEnter()
            if Config.UseUIText then
                lib.showTextUI('Press [E] to deliver vehicle')
            else
                lib.addRadialItem({
                    id = 'deliver_vehicle',
                    icon = 'fa-solid fa-warehouse',
                    label = 'Deliver Vehicle & Drugs',
                    onSelect = function()
                        deliverVehicle()
                    end
                })
            end
        end

        function deliverPoint:onExit()
            if Config.UseUIText then
                lib.hideTextUI()
            else
                lib.removeRadialItem('deliver_vehicle')
            end
        end

        function deliverPoint:nearby()
            deliverMarker:draw()

            if Config.UseUIText and self.currentDistance < 4.0 then
                if IsControlJustPressed(0, 38) then
                    deliverVehicle()
                end
            end
        end
    end

    local usedPlaces = {}

    local function loadNewLocation(newLocation)
        local boxesToPickup = math.random(newLocation.boxesToPickup.min, newLocation.boxesToPickup.max)
        locationBlip = missionBlip(newLocation.coords, locationBlip)

        sphereZone = exports.ox_target:addSphereZone({
            coords = newLocation.coords,
            radius = newLocation.radius,
            options = {
                {
                    name = 'steal_drugs_mission',
                    label = 'Take the drugs',
                    icon = 'fa-solid fa-boxes-stacked',
                    distance = 3.5,
                    canInteract = function()
                        return carryingBox == false
                    end,
    
                    onSelect = function()
                        carryingBox = true
                        carryBox(PlayerPedId())
                    end
                }
            }
        })

        exports.ox_target:addLocalEntity(myVehicle, {
            {
                name = 'store_drugs_mission',
                label = 'Store the drugs',
                icon = 'fa-solid fa-boxes-stacked',
                distance = 3.5,
                bones = { 'door_pside_r', 'door_dside_r' },
                canInteract = function()
                    return carryingBox == true
                end,

                onSelect = function()
                    boxesToPickup -= 1

                    if boxesToPickup > 0 then
                        lib.notify({ type = 'success', description = 'You have stored the drugs in the vehicle (' .. boxesToPickup .. ' box(es) left)' })
                    elseif locationsNeeded <= 0 then
                        exports.ox_target:removeZone('store_drugs_mission')
                        exports.ox_target:removeZone(sphereZone)

                        finishMission()
                    else
                        locationsNeeded -= 1
                        lib.notify({ type = 'success', description = 'You have stored the drugs in the vehicle, head to the next location (' .. locationsNeeded+1 .. ' location(s) left)' })
                        
                        exports.ox_target:removeZone('store_drugs_mission')
                        exports.ox_target:removeZone(sphereZone)

                        availableLocations[randomLocationNum] = nil
                        randomLocNum = math.random(#availableLocations)
                        loadNewLocation(availableLocations[randomLocNum])
                    end

                    carryingBox = false
                    detachBox(PlayerPedId())
                end
            }
        })
    end

    loadNewLocation(randomLocation)
end

missionTable[2] = function(data)
    local vehicle = nil
    local missionConfig = Config.Missions[2]
    local vehicleSpawn = missionConfig.vehicleSpawns[math.random(#missionConfig.vehicleSpawns)]
    local vehicleBlip = missionBlip(vehicleSpawn.vehicleCoords)
    
    -- Load PEDS & Vehicle --
    local peds = {}

    while true do
        Wait(150)

        local dist = #(GetEntityCoords(PlayerPedId()) - vector3(vehicleSpawn.vehicleCoords.x, vehicleSpawn.vehicleCoords.y, vehicleSpawn.vehicleCoords.z))

        if dist < 30.0 then
            lib.requestModel(vehicleSpawn.vehicleHash)
            vehicle = CreateVehicle(vehicleSpawn.vehicleHash, vehicleSpawn.vehicleCoords, true, false)
            SetVehicleDoorsLocked(vehicle, 2)
            SetVehicleOnGroundProperly(vehicle)
            SetEntityAsMissionEntity(vehicle, true, true)

            lib.notify({
                type = 'success',
                description = 'You have found the vehicle, go to the driver seat to start lockpicking the vehicle'
            })
            
            exports.ox_target:addLocalEntity(vehicle, {
                {
                    name = 'lockpick_vehicle_door',
                    label = 'Lockpick Vehicle Door (Mission)',
                    icon = 'fa-solid fa-boxes-stacked',
                    distance = 3.5,
                    bones = { 'door_pside_f' },
    
                    onSelect = function()
                        local success = lib.skillCheck({'easy', 'medium', 'medium'})

                        if success then
                            lib.notify({ type = 'success', description = 'You have successfully lockpicked the vehicle' })
                            exports.ox_target:removeZone('lockpick_vehicle_door')
                            SetVehicleDoorsLocked(vehicle, 0)
                        else
                            lib.notify({ type = 'error', description = 'You have failed to lockpick the vehicle' })
                        end
                    end
                }
            })

            for i = 1, #vehicleSpawn.NPC do
                local ped = vehicleSpawn.NPC[i]

                lib.requestModel(ped.pedHash)
                peds[i] = CreatePed(4, ped.pedHash, ped.pedCoords, true, false)
                GiveWeaponToPed(peds[i], ped.weapon, ped.weapon_ammo, false, true)
                TaskSetBlockingOfNonTemporaryEvents(peds[i], true)
                SetPedDropsWeaponsWhenDead(peds[i], false) 
                SetPedCombatAttributes(peds[i], 46, true)
                SetPedCombatAttributes(peds[i], 1424, true)
                SetPedCombatMovement(peds[i], 1)
                SetPedCombatRange(peds[i], 0)
                SetPedAlertness(peds[i], 3)
                TaskCombatPed(peds[i], PlayerPedId(), 0, 16)
            end

            RemoveBlip(vehicleBlip)

            break
        end
    end

    -- Point --
    local deliverPointCoords = vector3(data.coords.garageCoords.x, data.coords.garageCoords.y, data.coords.garageCoords.z)
    local deliverPoint = lib.points.new({ coords = deliverPointCoords, distance = 15 })
    local deliverMarker = lib.marker.new({ type = 25, coords = deliverPointCoords, color = { r = 255, g = 0, b = 0, a = 50 }, width = 1.2, height = 0.5 })
    local deliverBlip = missionBlip(deliverPointCoords)

    -- Local Function Deliver --
    local function deliverVehicle()
        lib.notify({ 
            type = 'success', 
            description = 'You have delivered the vehicle' 
        })

        RemoveBlip(deliverBlip)
        for i = 1, #peds do 
            if DoesEntityExist(peds[i]) then 
                DeleteEntity(peds[i]) 
            end
        end

        deliverPoint:remove()
        lib.removeRadialItem('deliver_vehicle')
        TaskLeaveAnyVehicle(PlayerPedId(), 0, 0)
        Wait(1750)
        DeleteVehicle(vehicle)
        TriggerServerEvent('modular-druglabs:giveMissionReward', 2, data.id)
        MissionStarted = false
    end

    function deliverPoint:onEnter()
        if Config.UseUIText then
            lib.showTextUI('Press [E] to deliver the vehicle')
        else
            lib.addRadialItem({
                id = 'deliver_vehicle',
                icon = 'fa-solid fa-warehouse',
                label = 'Deliver Vehicle',
                onSelect = function()
                    deliverVehicle()
                end
            })
        end
    end

    function deliverPoint:onExit()
        if Config.UseUIText then
            lib.hideTextUI()
        else
            lib.removeRadialItem('deliver_vehicle')
        end
    end

    function deliverPoint:nearby()
        deliverMarker:draw()

        if Config.UseUIText and self.currentDistance < 4.0 then
            if IsControlJustPressed(0, 38) then
                deliverVehicle()
            end
        end
    end
end

missionTable[3] = function(data)
    print('This mission has not been setup by the developer yet')
end