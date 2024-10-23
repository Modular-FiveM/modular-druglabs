local m_abs, m_rad, m_sin, m_cos = math.abs, math.rad, math.sin, math.cos

RegisterNetEvent('modular-druglabs:openAdminMenu', function(druglabs)
    local options = {}

    for i = 1, #druglabs do
        local druglab = druglabs[i]

        druglab.coords = json.decode(druglab.coords)
        druglab.stashData = json.decode(druglab.stashData)
        druglab.level = math.floor(druglab.xp / Config.XPForLevel) + 1
        
        local owner = druglab.firstname .. ' ' .. druglab.lastname
        local status = druglab.activated == 1 and 'On' or 'Off'
        
        options[i] = {
            title = 'Druglab - ' .. druglab.id,
            description = 'Click this to view options for the druglab',
            metadata = {
                ['ID'] = druglab.id,
                ['Owner'] = owner,
                ['Pincode'] = druglab.pincode,
                ['Stash Slots'] = druglab.stashData.slots,
                ['Stash Weight'] = druglab.stashData.weight * 100,
                ['LVL'] = druglab.level,
                ['XP'] = druglab.xp
            },

            onSelect = function()
                lib.registerContext({
                    id = 'druglab_' .. druglab.id,
                    title = 'Druglab ' .. druglab.id,
                    options = {
                        {
                            title = 'Toggle druglab',
                            description = 'Toggle the druglab on or off',
                            metadata = {
                                ['ID'] = druglab.id,
                                ['Status'] = status
                            },

                            onSelect = function()
                                TriggerServerEvent('modular-druglabs:toggleDruglab', druglab.id, druglab.activated)
                            end
                        },

                        {
                            title = 'Change Pincode',
                            description = 'Change the pincode for the druglab',
                            icon = 'hashtag',
                            onSelect = function()
                                local pincode = lib.inputDialog('Change Pincode', {
                                    {
                                        type = 'input',
                                        label = 'Pincode',
                                        description = 'Enter a new pincode for the druglab',
                                        icon = 'hashtag',
                                        min = 1,
                                        max = 60,
                                        required = true
                                    }
                                })

                                if not pincode then return end
                                TriggerServerEvent('modular-druglabs:changePincode', druglab.id, pincode[1])
                            end
                        },

                        {
                            title = 'Change Owner',
                            description = 'Change the owner of the druglab',
                            icon = 'fa-solid fa-user',
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
                                TriggerServerEvent('modular-druglabs:changeOwner', druglab.id, input[1])
                            end
                        },

                        {
                            title = 'TP to entrance',
                            description = 'Teleport to the entrance of the druglab',
                            icon = 'fa-solid fa-sign-in',
                            onSelect = function()
                                RequestCollisionAtCoord(druglab.coords.enterCoords.x, druglab.coords.enterCoords.y, druglab.coords.enterCoords.z)
                                SetEntityCoords(PlayerPedId(), druglab.coords.enterCoords.x, druglab.coords.enterCoords.y, druglab.coords.enterCoords.z)
                            end
                        },

                        {
                            title = 'Delete Druglab',
                            description = 'Delete the druglab',
                            icon = 'trash',
                            onSelect = function()
                                TriggerServerEvent('modular-druglabs:deleteDruglab', druglab.id)
                            end
                        }
                    }
                })

                lib.showContext('druglab_' .. druglab.id)
            end
        }

    end

    lib.registerContext({ id = 'all_druglabs_admin', title = 'All Druglabs', options = options })

    lib.registerContext({
        id = 'admin_menu_druglab',
        title = 'Modular Druglabs',
        options = {
            {
                title = 'Check Druglabs',
                description = 'View all druglabs',
                icon = 'bars',
                menu = 'all_druglabs_admin'
            },

            {
                title = 'Create Druglab',
                description = 'Create a new druglab',
                icon = 'bars',
                onSelect = function()
                    createDruglab()
                end
            }
        }
    })

    lib.showContext('admin_menu_druglab')
end)

function createDruglab()
    local shells = {}
    local players = {
        {
            label = GetPlayerName(PlayerId()),
            value = GetPlayerServerId(PlayerId())
        }
    }

    for k,v in pairs(Config.Druglabs) do
        table.insert(shells, { label = k, value = k })
    end

    for k,v in pairs(ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 10.0)) do
        table.insert(players, {
            label = GetPlayerName(v),
            value = GetPlayerServerId(v)
        })
    end

    local input = lib.inputDialog('Druglab Creation', {
        {
            type = 'select',
            label = 'Select Owner',
            description = 'Select a owner for the druglab',
            icon = 'fa-solid fa-user',
            options = players,
            required = true
        },

        {
            type = 'select',
            label = 'Select Shell',
            description = 'Select a shell',
            icon = 'fa-solid fa-house-chimney-user',
            options = shells,
            required = true
        },

        {
            type = 'input', 
            label = 'Pincode', 
            description = 'Enter a pincode for the druglab', 
            icon = 'hashtag',
            min = 1,
            max = 60,
            placeholder = 'secret password',
            required = true
        },

        {
            type = 'number',
            label = 'Stash Slots',
            description = 'Enter the amount of slots for the stash',
            icon = 'boxes',
            min = 1,
            max = 60,
            default = 15,
            required = true
        },

        {
            type = 'number',
            label = 'Stash Weight',
            description = 'Enter the weight for the stash',
            icon = 'weight',
            min = 1,
            default = 100,
            required = true
        },

        {
            type = 'checkbox',
            label = 'Same coords as you',
            checked = true
        },

        {
            type = 'number',
            label = 'Price',
            description = 'Enter the amount the druglab will cost',
            icon = 'dollar-sign',
            min = 0,
            required = false
        },
    })

    if not input then
        return
    end

    local useMyCoords = input[6]
    local myCoordsRN = GetEntityCoords(PlayerPedId())
    local enterCoords = useMyCoords and vector3(myCoordsRN.x, myCoordsRN.y, myCoordsRN.z - 1.0) or nil
    local garageCoords = nil
    local raycastCoords = nil
    local raycastHandle = nil
    local PlayerPed = PlayerPedId()

    if enterCoords == nil then
        lib.showTextUI('Look at the entrance of the druglab and press [ENTER] to set the coords')
    elseif enterCoords ~= nil and garageCoords == nil then
        lib.showTextUI('Look at the garage of the druglab and press [ENTER] to set the coords')
    end

    while enterCoords == nil or garageCoords == nil do
        Wait(0)

        local myCoords = GetEntityCoords(PlayerPed)
        if not raycastHandle then
            local camCoords, camRot = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2)
            local radX, radZ = m_rad(camRot.x), m_rad(camRot.z)
            local absX = m_abs(m_cos(radX))
            local forwardVec = vector3(-m_sin(radZ) * absX, m_cos(radZ) * absX, m_sin(radX))
            local destCoords = camCoords + (forwardVec * 15.0)
            raycastHandle = StartShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destCoords.x, destCoords.y, destCoords.z, 1|16, PlayerPed, 4)
        end

        local retval, _, tempCoords = GetShapeTestResult(raycastHandle)
        if retval == 0 then
            raycastHandle = nil
        elseif retval == 2 then
            raycastCoords = tempCoords
            raycastHandle = nil
        end

        if raycastCoords and raycastCoords.x ~= 0 then
            DrawLine(myCoords.x, myCoords.y, myCoords.z, raycastCoords.x, raycastCoords.y, raycastCoords.z, 255, 255, 255, 255)
            DrawSphere(raycastCoords.x, raycastCoords.y, raycastCoords.z, 0.1, 0, 0, 255, 0.7)
        end

        if IsControlJustPressed(0, 191) then
            if raycastCoords == nil or (raycastCoords.x == 0.0 or raycastCoords.y == 0.0 or raycastCoords.z == 0.0) then
                lib.notify({ type = 'error', description = 'Invalid Coords' })
            else
                if enterCoords ~= nil and garageCoords == nil then
                    garageCoords = vector4(raycastCoords.x, raycastCoords.y, raycastCoords.z, GetEntityHeading(PlayerPedId()))
                    lib.notify({ type = 'success', description = 'Garage Coords Set' })

                    break
                end
                
                if enterCoords == nil and not useMyCoords then
                    enterCoords = vector4(raycastCoords.x, raycastCoords.y, raycastCoords.z, GetEntityHeading(PlayerPedId()))
                    lib.notify({ type = 'success', description = 'Enter Coords Set' })
                
                    lib.showTextUI('Look at the garage of the druglab and press [ENTER] to set the coords')
                end
            end
        end
    end


    TriggerServerEvent('modular-druglabs:createDruglab', 
        input[1],
        input[2],
        input[3],
        input[4],
        input[5],
        { 
            enterCoords = enterCoords, 
            garageCoords = garageCoords 
        },
        input[7]
    )
end