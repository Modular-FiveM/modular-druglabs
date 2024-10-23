Config = {}

Config.UseUIText = false -- if false it will use the ox_lib radial menu
Config.UseOXInventory = GetResourceState('ox_inventory') == 'started' -- if true it will use the ox_inventory
Config.AdminRank = 'admin' -- admin rank to create druglabs
Config.AdminCommand = 'druglab' -- admin command to create druglabs / view existing druglabs
Config.EnableDebug = true -- debug mode (if true, will display blip at all druglabs)
Config.XPForLevel = 500 -- 500 xp per level (gets harder for each level - If changed when druglabs already have levels, it will affect druglab levels)
Config.HarderForNextLevel = false -- if true, it will be harder for each level to level up

Config.PoliceJob = 'police'
Config.RaidCooldown = 60 -- 1 hour cooldown for police raids
Config.PoliceRaid = {
    Skillchecks = {'easy', 'easy', 'medium', 'hard'},
    SkillcheckButtons = {'e'},
    DeleteDruglabOnRaid = true
}

Config.LoadStash = function(id, name, slots, weight)
    print('load stash', id, name, slots, weight)
end

Config.OpenStash = function()

end

-- More information about the druglabs can be found in the README.md

Config.Druglabs = {
    ['weed'] = {
        shell = 'bob74_ipl', -- shell to use, can be 'bob74_ipl' or 'custom_shell'

        coords = {
            door = vector4(1066.31, -3183.40, -39.164, 270.6447),
            pc = vector3(1045.31, -3194.90, -38.20),
            stash = vector3(1059.54, -3181.84, -38.83),
            process = vector3(1035.71, -3205.46, -38.18)
        },

        drugProcessTime = 10, -- time in seconds to process drugs
        processItems = {
            ['Packed Weed'] = {
                neededLevel = 1,
                neededItems = {
                    ['plastic_bag'] = 5,
                    ['weed_powder'] = 5
                },

                givingItems = {
                    ['packed_weed'] = 5
                },
            }
        },

        loadShell = function(cfg) -- returns this meth table, example: cfg.coords.door
            if cfg.shell == 'bob74_ipl' then
                local resourceStarted = GetResourceState('bob74_ipl') == 'started'

                if not resourceStarted then
                    for i = 1, 10 do
                        print('Start bob74_ipl resource')
                    end
                end
            elseif shell == 'custom_shell' then
                print('Load custom shell here')
                -- load shell here
            end
        end,

        despawnShell = function(cfg)
            -- Despawn the spawned shell
        end
    },

    ['meth'] = {
        shell = 'bob74_ipl', -- shell to use, can be 'bob74_ipl' or 'custom_shell'

        coords = {
            door = vector4(997.1663, -3200.713, -36.39367, 270.6447),
            pc = vector3(1001.943, -3194.163, -39.03827),
            stash = vector3(997.0823, -3200.375, -38.99311),
            process = vector3(1006.916, -3195.57, -38.99318)
        },

        drugProcessTime = 10, -- time in seconds to process drugs
        processItems = {
            ['Packed Meth'] = {
                neededLevel = 1,
                neededItems = {
                    ['plastic_bag'] = 5,
                    ['meth_powder'] = 5
                },

                givingItems = {
                    ['packed_meth'] = 5
                },
            }
        },

        loadShell = function(cfg) -- returns this meth table, example: cfg.coords.door
            if cfg.shell == 'bob74_ipl' then
                local resourceStarted = GetResourceState('bob74_ipl') == 'started'

                if not resourceStarted then
                    for i = 1, 10 do
                        print('Start bob74_ipl resource')
                    end
                end
            elseif shell == 'custom_shell' then
                print('Load custom shell here')
                -- load shell here
            end
        end,

        despawnShell = function(cfg)
            -- Despawn the spawned shell
        end
    },

    ['cocaine'] = {
        shell = 'bob74_ipl', -- shell to use, can be 'bob74_ipl' or 'custom_shell'

        coords = {
            door = vector4(997.1663, -3200.713, -36.39367, 270.6447),
            pc = vector3(1086.524, -3194.238, -38.99668),
            stash = vector3(1098.987, -3193.205, -38.99341),
            process = vector3(1092.892, -3194.853, -38.99341)
        },

        drugProcessTime = 10, -- time in seconds to process drugs
        processItems = {
            ['Packed Coke'] = {
                neededLevel = 1,
                neededItems = {
                    ['plastic_bag'] = 5,
                    ['meth_powder'] = 5
                },

                givingItems = {
                    ['packed_meth'] = 5
                },
            }
        },

        loadShell = function(cfg) -- returns this meth table, example: cfg.coords.door
            if cfg.shell == 'bob74_ipl' then
                local resourceStarted = GetResourceState('bob74_ipl') == 'started'

                if not resourceStarted then
                    for i = 1, 10 do
                        print('Start bob74_ipl resource')
                    end
                end
            elseif shell == 'custom_shell' then
                print('Load custom shell here')
                -- load shell here
            end
        end,

        despawnShell = function(cfg)
            -- Despawn the spawned shell
        end
    },
}

Config.Missions = {
    [1] = {
        title = 'Mission #1, Pickup boxes', -- title of the mission
        description = 'Go to different locations to pickup boxes for loot', -- description of the mission
        levelNeeded = 1, -- level needed to start this mission

        locationsShuffle = 3, -- amount of locations to pickup boxes from on 1 trip (if there is only 1 location, it will always be the same location)
        vehicle = `rumpo`,
        pickupLocations = {
            {
                coords = vector3(542.162, 2663.839, 42.36736),
                radius = 2.0,
                boxesToPickup = { -- min & max of boxes to pickup at this location
                    min = 2,
                    max = 5
                }
            },

            {
                coords = vector3(914.8535, 3567.395, 33.79387),
                radius = 2.0,
                boxesToPickup = {
                    min = 2,
                    max = 5
                }
            },

            {
                coords = vector3(379.4124, 3583.642, 33.29222),
                radius = 2.0,
                boxesToPickup = {
                    min = 2,
                    max = 5
                }
            },

            {
                coords = vector3(265.79, 2598.19, 44.83),
                radius = 2.0,
                boxesToPickup = {
                    min = 2,
                    max = 3
                }
            },

            {
                coords = vector3(186.13, 2786.51, 46.01),
                radius = 2.0,
                boxesToPickup = {
                    min = 2,
                    max = 5
                }
            },

            {
                coords = vector3(46.36, 2789.47, 57.87),
                radius = 2.0,
                boxesToPickup = {
                    min = 2,
                    max = 5
                }
            }
        },

        rewardXP = 100, -- xp to give when mission is completed
        rewards = {
            ['meth'] = { -- Chooses random reward from this table, could be 50 joints or 250k black money
                {
                    item = 'packed_meth',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            },

            ['cocaine'] = {
                {
                    item = 'packed_cocaine',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            },

            ['weed'] = {
                {
                    item = 'joint',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            }
        }
    },

    [2] = {
        title = 'Mission #2, Steal Vehicle', -- title of the mission
        description = 'Go to a random location and steal a vehicle filled with drugs', -- description of the mission

        levelNeeded = 2, -- level needed to start this mission
        rewardXP = 100, -- xp to give when mission is completed
        rewards = {
            ['meth'] = { -- Gives all rewards in this table
                {
                    item = 'packed_meth',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            },

            ['cocaine'] = {
                {
                    item = 'packed_cocaine',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            },

            ['weed'] = {
                {
                    item = 'joint',
                    amount = 50 -- 50 joints
                },
                {
                    item = 'black_money',
                    amount = 250000 -- 250k
                }
            }
        },

        vehicleSpawns = {
            {
                vehicleHash = `rumpo`,
                vehicleCoords = vector4(373.5276, -1836.189, 28.49216, 138.7282),
                NPC = {
                    {
                        pedHash = `g_m_m_chigoon_02`,
                        pedCoords = vector4(367.6844, -1838.158, 28.363, 201.2067),
                        weapon = `weapon_bat`,
                        weapon_ammo = 1
                    },

                    {
                        pedHash = `g_m_m_chigoon_02`,
                        pedCoords = vector4(375.6083, -1839.485, 28.17925, 137.9904),
                        weapon = `weapon_bat`,
                        weapon_ammo = 1
                    },

                    {
                        pedHash = `g_m_m_chigoon_02`,
                        pedCoords = vector4(375.1418, -1831.696, 28.75077, 349.0784),
                        weapon = `weapon_bat`,
                        weapon_ammo = 1
                    }
                }
            }
        }
    },

    [3] = {
        title = 'Mission #3, idk yet', -- title of the mission
        description = 'Do something idk', -- description of the mission
        levelNeeded = 3, -- level needed to start this mission
        rewardXP = 100, -- xp to give when mission is completed

        reward = function(xPlayer, drugType) -- Custom reward for this mission that you can create yourself
            print('SRC: ' .. xPlayer.source) -- source of the player
            print('Identifier: ' .. xPlayer.identifier) -- steam:11000010f7b3b3e
            print('Drug Type: ' .. drugType) -- drug type (weed, meth, cocaine)
        end
    },
}