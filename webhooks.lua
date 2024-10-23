Config = Config or {}

Config.Discord = {
    name = 'Modular Druglab Logs',
    avatar = 'image_link',
    color = 16711680, -- red

    webhooks = {
        ['addDruglab'] = '',
        ['deleteDruglab'] = '',
        ['finishMission'] = '',
        ['raidSuccess'] = '',
        ['createDruglab'] = ''
    }
}

Config.Log = function(title, description)
    -- Custom log function
    print(title .. ' : ' .. description)
end