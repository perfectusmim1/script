-- afk_fluent.lua
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Fluent UI ve Gerekli Kütüphaneler
local Fluent = loadstring(game:HttpGet("https://github.com/1dontgiveaf/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/1dontgiveaf/Fluent/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/1dontgiveaf/Fluent/main/Addons/InterfaceManager.lua"))()

-- Fluent Pencere Oluşturma
local Window = Fluent:CreateWindow({
    Title = "AFK World",
    SubTitle = "By",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 400),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Sekmeler
local Tabs = {
    Main = Window:AddTab({ Title = "Webhook", Icon = "bell" })
}

-- Webhook ile ilgili değişkenler
local webhookFilePath = "FluentScripts/" .. game.PlaceId .. "/webhook_url.txt"
local webhookUrl = ""
local webhookEnabled = false

-- Webhook URL'sini kaydetme fonksiyonu
local function saveWebhookUrl(url)
    if url and url ~= "" then
        writefile(webhookFilePath, url)
        print("[DEBUG] Webhook URL saved to:", webhookFilePath)
    else
        print("[WARNING] Webhook URL is empty, not saving.")
    end
end

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
        print("[DEBUG] Auto-enabled Webhook in AFK World with URL:", webhookUrl)
    else
        print("[WARNING] No saved Webhook URL found, Webhook not auto-enabled.")
    end
end

-- Webhook fonksiyonları
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
                    ['1000 GEMS'] = '1000',
                    ['5000 GEMS'] = '5000',
                    ['2 TICKETS'] = '2',
                    ['5 TICKETS'] = '5',
                    ['8 TICKETS'] = '8'
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
                        ['Horse Mount'] = 'Horse Mount',
                        ['HOLY WAR AXE'] = 'HOLY WAR EXE',
                        ['Random Potion'] = 'Random Potion',
                        ['35 COMMON POWDER'] = '35 COMMON POWDER',
                        ['30 RARE POWDER'] = '30 RARE POWDER',
                        ['22 LEGENDARY POWDER'] = '25 LEGENDARY POWDER'
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
        username = "AFK",
        avatar_url = "https://media.discordapp.net/attachments/1142448438529765389/1355464540002975774/ZAPPPP.png",
        embeds = {embedData}
    }
    
    local jsonPayload = game:GetService("HttpService"):JSONEncode(payload)
    
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

-- Webhook döngüsü
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild('CountDown')

    print("AFK Notify Loaded [Arise]")

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
end)

-- Fluent UI Elemanları
Tabs.Main:AddParagraph({
    Title = "Webhook Information",
    Content = "Enter your Discord Webhook URL below to receive AFK rewards notifications. This script auto-enables Webhook notifications in AFK World if a URL was previously saved."
})

local WebhookSection = Tabs.Main:AddSection("AFK Rewards Webhook")

Tabs.Main:AddInput("WebhookURL", {
    Title = "Webhook URL",
    Default = loadWebhookUrl(),
    Placeholder = "Enter your Discord Webhook URL here...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        webhookUrl = Value
        saveWebhookUrl(webhookUrl)
        print("[DEBUG] Webhook URL set to:", webhookUrl)
    end
})

Tabs.Main:AddToggle("WebhookEnabled", {
    Title = "Enable Webhook Notifications",
    Default = webhookEnabled,
    Callback = function(state)
        webhookEnabled = state
        print("[DEBUG] Webhook notifications toggled:", state)
        if state and webhookUrl == "" then
            Fluent:Notify({
                Title = "Error",
                Content = "Please enter a valid Webhook URL first!",
                Duration = 5
            })
            webhookEnabled = false
        end
    end
})

-- SaveManager ve InterfaceManager Ayarları
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:SetFolder("FluentScripts/" .. game.PlaceId)
InterfaceManager:SetFolder("FluentScripts/" .. game.PlaceId)

SaveManager:BuildConfigSection(Tabs.Main)
InterfaceManager:BuildInterfaceSection(Tabs.Main)

Fluent:Notify({
    Title = "AFK World Script Loaded",
    Content = "Webhook features loaded successfully for AFK World!",
    Duration = 5
})

print("AFK World Fluent UI with Webhook loaded!")
