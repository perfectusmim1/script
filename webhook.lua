-- webhook.lua
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local webhookFilePath = "FluentScripts/" .. game.PlaceId .. "/webhook_url.txt"
local webhookUrl = ""
local webhookEnabled = false

-- Webhook URL'sini okuma fonksiyonu
local function loadWebhookUrl()
    if isfile(webhookFilePath) then
        local url = readfile(webhookFilePath)
        print("[DEBUG] Loaded Webhook URL:", url)
        return url
    else
        print("[DEBUG] Webhook URL file not found at:", webhookFilePath)
        return ""
    end
end

-- Webhook otomatik başlatma kontrolü
if game.PlaceId == 116614712661486 then
    webhookUrl = loadWebhookUrl()
    if webhookUrl and webhookUrl ~= "" then
        webhookEnabled = true
        print("[DEBUG] Auto-enabled Webhook in PlaceID 116614712661486 with URL:", webhookUrl)
    else
        print("[WARNING] No saved Webhook URL found, Webhook not auto-enabled.")
    end
end

local function item_received()
    local item_list = {}
    local gem_total = 0
    local ticket_total = 0 

    local rewardinfo = require(game:GetService("ReplicatedStorage"):WaitForChild("Indexer"):WaitForChild("RewardInfo"))
    local afkreward = player:WaitForChild("leaderstats"):WaitForChild("AfkRewards")

    for i, v in pairs(afkreward:GetAttributes()) do
        if v then
            local item = rewardinfo[i]
            if item then
                local value = v
                local rarity = item.Chance / 100 

                local is_gem_or_ticket = false
                local list_result = {
                    ['100 GEMS'] = '100',
                    ['500 GEMS'] = '500',
                    ['2000 GEMS'] = '2000',
                    ['2 TICKETS'] = '2',
                    ['5 TICKETS'] = '5',
                    ['8 TICKETS'] = '8',
                }

                for name_list, amount in pairs(list_result) do
                    if string.find(item.Name, name_list, 1, true) then
                        local item_value = tonumber(amount) * value
                        if string.find(name_list, "GEMS") then
                            gem_total = gem_total + item_value
                        elseif string.find(name_list, "TICKET") then
                            ticket_total = ticket_total + item_value
                        end
                        is_gem_or_ticket = true
                        break
                    end
                end

                if not is_gem_or_ticket then
                    local list_description = {
                        ['Ziru G'] = 'Ziru G',
                        ['Tiger'] = 'Tiger',
                        ['Twin Prism Blades'] = 'Twin Prism Blades',
                        ['20 COMMON POWDER'] = '20 COMMON POWDER',
                        ['20 RARE POWDER'] = '20 RARE POWDER',
                        ['20 LEGENDARY POWDER'] = '20 LEGENDARY POWDER'
                    }
                    local display_name = list_description[item.Name] or item.Name
                    table.insert(item_list, {
                        name = display_name, 
                        value = value,
                        rarity = rarity
                    })
                end
            end
        end
    end

    if gem_total > 0 then
        table.insert(item_list, {
            name = "Gems",
            value = gem_total,
            rarity = 10 
        })
    end
    if ticket_total > 0 then
        table.insert(item_list, {
            name = "Tickets",
            value = ticket_total,
            rarity = 11
        })
    end

    table.sort(item_list, function(a, b)
        return a.rarity < b.rarity
    end)

    return item_list
end

local function discord_notify(rewards)
    if not webhookEnabled or webhookUrl == "" then
        print("[DEBUG] Webhook not enabled or URL not set")
        return
    end

    local rewardsText = ""
    for _, reward in ipairs(rewards) do
        rewardsText = rewardsText .. "➟ " .. reward.name .. " x" .. reward.value .. "\n"
    end
    
    local embedData = {
        color = 16755219,
        author = {
            name = "# Arise Crossover"
        },
        fields = {
            {
                name = "**__Account - Information__**",
                value = "➟ Roblox Username: || " .. player.Name .. "||"
            },
            {
                name = "**__Rewards - Received__**",
                value = rewardsText
            }
        },
        image = {
            url = "https://media.discordapp.net/attachments/1142448438529765389/1355464540376141914/face.png"
        }
    }
    
    local payload = {
        username = "ZapZone - AFK",
        avatar_url = "https://media.discordapp.net/attachments/1142448438529765389/1355464540002975774/ZAPPPP.png",
        embeds = {embedData}
    }
    
    local jsonPayload = HttpService:JSONEncode(payload)
    
    local _request_ = http_request or request or HttpPost or (syn and syn.request)
    local response = _request_({
        Url = webhookUrl,
        Body = jsonPayload,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    
    print("[DEBUG] Webhook response:", response and response.Body or "No response")
end

repeat task.wait() until game:IsLoaded()
repeat task.wait() until player.PlayerGui:FindFirstChild('CountDown')

print("ZapZone - AFK Notify Loaded [Arise]")

while true do
    task.wait(10)
    if webhookEnabled then
        local success, err = pcall(function()
            local rewards = item_received()
            if #rewards > 0 then
                discord_notify(rewards)
                print("[DEBUG] Notification sent with " .. #rewards .. " rewards")
            else
                print("[DEBUG] No rewards found to report")
            end
        end)
        if not success then
            warn("[ERROR] Webhook error: " .. tostring(err))
        end
    end
end
