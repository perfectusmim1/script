if game.PlaceId == 116614712661486 then
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    local request = http_request or request or HttpPost or syn.request

    local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    local TeleportCheck = false

    _G.AriseSettings = {
        Toggles = {
            AutoReinject = false
        }
    }

    local Window = Fluent:CreateWindow({
        Title = "AFK",
        SubTitle = "by Perfectus",
        TabWidth = 100,
        Size = UDim2.fromOffset(480, 360),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Main", Icon = "home" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    local Options = Fluent.Options

    local webhook = ""
    local accountIdentifier = "" 

    local function censorName(name)
        if #name <= 3 then
            return name:sub(1, 1) .. string.rep("*", #name - 1)
        else
            return name:sub(1, 3) .. string.rep("*", #name - 3)
        end
    end

    local function sendWebhook()
        local scrollingFrame = player:WaitForChild("PlayerGui"):WaitForChild("CountDown"):WaitForChild("Frame"):WaitForChild("Recieved"):WaitForChild("ScrollingFrame", 5)
        if not scrollingFrame then
            warn("ScrollingFrame not found in GUI!")
            Fluent:Notify({
                Title = "Error",
                Content = "ScrollingFrame not found in PlayerGui.CountDown.Frame.Recieved!",
                Duration = 3
            })
            return
        end

        local rewards = {}
        for _, rewardFrame in pairs(scrollingFrame:GetChildren()) do
            if rewardFrame:IsA("GuiObject") then
                local rewardText = rewardFrame:FindFirstChild("RewardName") and rewardFrame.RewardName.Text or "None"
                if rewardFrame.Name ~= "Template" and not rewardText:lower():match("template") then
                    local rewardName, amount = rewardText:match("([^%(]+)%((%d+)%)")
                    if rewardName and amount then
                        rewardName = rewardName:match("^%s*(.-)%s*$")
                        amount = tonumber(amount)
                        if rewards[rewardName] then
                            rewards[rewardName].total = rewards[rewardName].total + amount
                            rewards[rewardName].count = rewards[rewardName].count + 1
                        else
                            rewards[rewardName] = { total = amount, count = 1 }
                        end
                    end
                end
            end
        end

        local description = ""
        local hasRewards = false
        for rewardName, data in pairs(rewards) do
            description = description .. "- " .. rewardName .. ": " .. data.total .. "\n"
            hasRewards = true
        end

        if not hasRewards then
            description = "No AFK rewards found in GUI."
        end

        local identifier = accountIdentifier ~= "" and accountIdentifier or censorName(player.Name)

        local data = {
            ["content"] = "",
            ["embeds"] = {
                {
                    ["title"] = "AFK REWARDS MONITOR - ARISE",
                    ["type"] = "rich",
                    ["color"] = 0x000000,
                    ["description"] = description,
                    ["author"] = {
                        ["name"] = identifier
                    },
                    ["footer"] = {["text"] = "Perfectus | " .. os.date("%Y-%m-%d %H:%M:%S")}
                }
            }
        }

        local headers = {["content-type"] = "application/json"}
        local requestData = {
            Url = webhook,
            Body = HttpService:JSONEncode(data),
            Method = "POST",
            Headers = headers
        }

        if request then
            local success, response = pcall(request, requestData)
            if not success then
                warn("Webhook send failed: " .. tostring(response))
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to send webhook: " .. tostring(response),
                    Duration = 5
                })
            else
                print("Webhook sent successfully!")
            end
        else
            warn("No HTTP request function available!")
            Fluent:Notify({
                Title = "Error",
                Content = "HTTP request function not supported by your executor!",
                Duration = 5
            })
        end
    end

    do
        Tabs.Main:AddSection("Webhook Settings")

        Tabs.Main:AddInput("Webhook", {
            Title = "Webhook URL",
            Default = "",
            Numeric = false,
            Finished = false,
            Text = "Enter your Discord Webhook URL",
            Placeholder = "https://discord.com/api/webhooks/..."
        })

        Options.Webhook:OnChanged(function(value)
            webhook = value
        end)

        Tabs.Main:AddInput("Identifier", {
            Title = "Account Identifier",
            Default = "",
            Numeric = false,
            Finished = false,
            Text = "Optional custom ID (leave blank to use censored name)",
            Placeholder = "e.g., Account1"
        })

        Options.Identifier:OnChanged(function(value)
            accountIdentifier = value
        end)

        getgenv().WebhookWait = 30
        Tabs.Main:AddSlider("WebhookWait", {
            Title = "Send Interval (seconds)",
            Default = 30,
            Min = 10,
            Max = 600,
            Rounding = 0,
            Compact = false
        })

        Options.WebhookWait:OnChanged(function(value)
            getgenv().WebhookWait = value
        end)

        Tabs.Main:AddToggle("EnableWebhook", {
            Title = "Enable Webhook",
            Default = false,
        })

        Options.EnableWebhook:OnChanged(function(value)
            if value then
                task.spawn(function()
                    while Options.EnableWebhook.Value do
                        if webhook ~= "" and webhook:match("^https://discord%.com/api/webhooks/") then
                            sendWebhook()
                        else
                            Fluent:Notify({
                                Title = "Error",
                                Content = "Please enter a valid Discord webhook URL!",
                                Duration = 3
                            })
                            Options.EnableWebhook:SetValue(false)
                            break
                        end
                        task.wait(getgenv().WebhookWait)
                    end
                end)
            end
        end)

        Tabs.Main:AddButton({
            Title = "Test Webhook",
            Callback = function()
                if webhook ~= "" and webhook:match("^https://discord%.com/api/webhooks/") then
                    sendWebhook()
                    Fluent:Notify({
                        Title = "Success",
                        Content = "Webhook test sent!",
                        Duration = 3
                    })
                else
                    Fluent:Notify({
                        Title = "Error",
                        Content = "Please enter a valid Discord webhook URL!",
                        Duration = 3
                    })
                end
            end
        })

        Tabs.Settings:AddSection("Script Settings")
        Tabs.Settings:AddToggle("AutoReinjectToggle", {
            Title = "Auto Execute on Teleport",
            Description = "Executes the script automatically after teleporting.",
            Default = false,
            Callback = function(Value)
                _G.AriseSettings.Toggles.AutoReinject = Value
                if Value then
                    if not queueteleport then
                        Fluent:Notify({
                            Title = "Error",
                            Content = "Your exploit does not support this feature.",
                            Duration = 5
                        })
                        Options.AutoReinjectToggle:SetValue(false)
                        return
                    end
                    Fluent:Notify({
                        Title = "Auto Execute Enabled",
                        Content = "Script will execute on teleport.",
                        Duration = 3
                    })
                else
                    Fluent:Notify({
                        Title = "Auto Execute Disabled",
                        Content = "Script will not execute on teleport.",
                        Duration = 3
                    })
                end
            end
        })
    end

    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("Perfectus")
    SaveManager:SetFolder("Perfectus/afkarise")

    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)

    Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()

    player.OnTeleport:Connect(function(State)
        if _G.AriseSettings.Toggles.AutoReinject and not TeleportCheck and queueteleport then
            TeleportCheck = true
            queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/perfectusmim1/script/refs/heads/main/arisewebhook.lua'))()")
            Fluent:Notify({
                Title = "Execute Queued",
                Content = "Script will execute in the new server.",
                Duration = 3
            })
        end
    end)
end
