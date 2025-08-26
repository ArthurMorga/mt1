--[[
    CIA MILITARY TYCOON OPTIMIZED SCRIPT
    - Fixed vehicle spawning with correct UUID
    - Enhanced stealth measures
    - Optimized performance
    - Official Rayfield implementation
]]

-- Enable secure mode to reduce detection 
getgenv().SecureMode = true

--========================================================================--
--                       ROBUST RAYFIELD UI LOADER                        --
--========================================================================--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--========================================================================--
--                        CONFIGURATION & SERVICES                        --
--========================================================================--

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- State variables
local seaGreenColor = Color3.fromRGB(57, 166, 40)
local autoBuying = false
local collectTeleporting = false

-- Cooldown & Speed variables
local buySweepCooldown = 1
local collectCooldown = 30
local rebirthCooldown = 5
local teleportDuration = 1

-- Auto-Rebirth & Auto-Spawn variables
local isAutoRebirthActive, lastRebirthAttempt, rebirthFunction = false, 0, nil
local isAutoSpawnPlaneActive, isAutoSpawnTruckActive = false, false

-- Universal Head Resizer variables
local isHeadResizerActive, headSize, originalProperties = false, 5, {}

-- Capture Sequence variables
local isCapturing = false
local smallOutpostPositions = {
    Vector3.new(733.92, 132.43, 2458.11), Vector3.new(-1019.96, 132.54, 2648.47),
    Vector3.new(-2071.40, 132.08, 1838.18), Vector3.new(-2662.56, 132.83, 988.05),
    Vector3.new(-3083.99, 131.79, -64.24), Vector3.new(-3195.84, 132.39, -1328.31),
    Vector3.new(-2896.62, 131.86, -2429.60), Vector3.new(-2560.93, 131.88, -3056.00),
    Vector3.new(-805.23, 132.32, -3610.12), Vector3.new(528.86, 132.28, -3761.17),
    Vector3.new(1983.74, 132.45, -3231.40), Vector3.new(2836.28, 132.38, -2146.90)
}

local armedFortressPositions = {
    Vector3.new(-1385.68, 137.00, 1554.99)
}

-- Vehicle UUIDs (CORRECTED)
local VEHICLE_UUIDS = {
    PLANE = "ad989579-9f33-443d-b3ad-8b968f270a3f", -- Corrected UUID for plane
    TRUCK = "b08a5285-61e9-4583-8a17-09f6b7560438"
}

-- Active connections table for proper garbage collection
local activeConnections = {}

--========================================================================--
--                       CORE FEATURE LOGIC BLOCKS                        --
--========================================================================--

-- UNIVERSAL HEAD RESIZER
local function revertAllHeadProperties()
    for part, props in pairs(originalProperties) do
        if part and part.Parent then
            part.Size = props.Size
            if props.Mesh and props.Mesh.Parent then
                props.Mesh.Scale = props.OriginalScale
            end
        end
    end
    originalProperties = {}
end

local function headResizerLoop()
    while isHeadResizerActive and task.wait(0.5) do
        local myCharacter = player.Character
        for _, model in ipairs(workspace:GetChildren()) do
            if model:IsA("Model") and model ~= myCharacter then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local head = model:FindFirstChild("Head")
                    if head then
                        if not originalProperties[head] then
                            local mesh = head:FindFirstChildOfClass("SpecialMesh") or head:FindFirstChildOfClass("BlockMesh")
                            originalProperties[head] = {
                                Size = head.Size,
                                Mesh = mesh,
                                OriginalScale = mesh and mesh.Scale or nil
                            }
                        end
                        local newSize = Vector3.new(headSize, headSize, headSize)
                        head.Size = newSize
                        local meshRef = originalProperties[head].Mesh
                        if meshRef then
                            meshRef.Scale = newSize
                        end
                    end
                end
            end
        end
    end
end

-- INFINITE JUMP
local function toggleInfiniteJump(value)
    getgenv().infiniteJump = value
end

UserInputService.JumpRequest:Connect(function()
    if getgenv().infiniteJump and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid:ChangeState('Jumping')
        end
    end
end)

-- ANTI-AFK & HELPERS
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function getPlayerTycoon()
    local tycoon = workspace.PlayerTycoons:FindFirstChild(player.Name)
    if not tycoon then
        tycoon = workspace.PlayerTycoons:WaitForChild(player.Name, 5)
    end
    return tycoon
end

local function isAvailableToBuy(button)
    return button:IsA("BasePart") and button.Color == seaGreenColor
end

-- TELEPORT & AUTOMATION
local function smoothTeleport(targetCFrame, duration)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local hrp = player.Character.HumanoidRootPart
    
    -- Disable collision during teleport
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    
    tween:Play()
    tween.Completed:Wait()
    
    -- Re-enable collision and reset physics
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)
end

local function buyAllAvailableButtons()
    local myTycoon = getPlayerTycoon()
    if not myTycoon then return end
    
    local remoteFunction = myTycoon:FindFirstChild("RemoteFunction")
    local buttonFolder = myTycoon:FindFirstChild("ButtonFolder")
    
    if not remoteFunction or not buttonFolder then return end
    
    local buttonsToBuy = {}
    for _, buttonModel in ipairs(buttonFolder:GetChildren()) do
        local mainButtonPart = buttonModel:FindFirstChild("Button")
        if mainButtonPart and isAvailableToBuy(mainButtonPart) then
            table.insert(buttonsToBuy, buttonModel.Name)
        end
    end
    
    if #buttonsToBuy > 0 then
        for _, buttonName in ipairs(buttonsToBuy) do
            pcall(function()
                remoteFunction:InvokeServer("BuyButton", buttonName)
            end)
            task.wait(0.1)
        end
    end
end

local function executeRebirth()
    if os.clock() - lastRebirthAttempt < rebirthCooldown then return end
    
    if not rebirthFunction then
        local playerTycoon = workspace.PlayerTycoons:FindFirstChild(player.Name)
        if playerTycoon then
            rebirthFunction = playerTycoon:FindFirstChild("Rebirth")
        end
    end
    
    if rebirthFunction then
        local success, result = pcall(function()
            return rebirthFunction:InvokeServer()
        end)
        
        lastRebirthAttempt = os.clock()
        
        if success and result == true then
            Rayfield:Notify("Rebirth Successful", "The server processed the rebirth request.", 5)
        end
    end
end

local function toggleAutoRebirth(value)
    isAutoRebirthActive = value
    if isAutoRebirthActive then
        activeConnections.autoRebirth = RunService.Heartbeat:Connect(executeRebirth)
    elseif activeConnections.autoRebirth then
        activeConnections.autoRebirth:Disconnect()
        activeConnections.autoRebirth = nil
    end
end

local function teleportToCollectButton()
    local myTycoon = getPlayerTycoon()
    if not myTycoon then return end
    
    local modelsFolder = myTycoon:WaitForChild("Models", 2)
    if not modelsFolder then return end
    
    local collectButton
    local starterGiver = modelsFolder:FindFirstChild("StarterGiver")
    if starterGiver then
        collectButton = starterGiver:FindFirstChild("CollectButton")
    end
    
    if not collectButton then
        local giver = modelsFolder:FindFirstChild("Giver")
        collectButton = giver and giver:FindFirstChild("CollectButton")
    end
    
    if collectButton and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = collectButton.CFrame + Vector3.new(0, 5, 0)
    end
end

-- VEHICLE SPAWNING LOGIC (CORRECTED)
local function getVehicleSpawnRemote()
    return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.5.1")
           :WaitForChild("knit"):WaitForChild("Services"):WaitForChild("VehicleService")
           :WaitForChild("RF"):WaitForChild("Spawn")
end

local function spawnVehicle(uuid, vehicleName)
    local spawnRemote = getVehicleSpawnRemote()
    if not spawnRemote then
        Rayfield:Notify("Vehicle Spawn Error", "Could not find spawn remote.", 7)
        return
    end
    
    local success, errorMsg = pcall(function()
        local args = {uuid}
        spawnRemote:InvokeServer(unpack(args))
    end)
    
    if success then
        Rayfield:Notify("Vehicle Spawn", vehicleName .. " spawn request sent.", 5)
    else
        Rayfield:Notify("Vehicle Spawn", vehicleName .. " spawn failed: " .. tostring(errorMsg), 7)
    end
end

local function setupDeathTrigger(character)
    if not character then return end
    
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if isAutoSpawnPlaneActive or isAutoSpawnTruckActive then
            task.wait(11)
            if isAutoSpawnPlaneActive then
                spawnVehicle(VEHICLE_UUIDS.PLANE, "Plane")
            end
            if isAutoSpawnTruckActive then
                spawnVehicle(VEHICLE_UUIDS.TRUCK, "Truck")
            end
        end
    end)
end

player.CharacterAdded:Connect(setupDeathTrigger)
if player.Character then
    setupDeathTrigger(player.Character)
end

-- AUTO FIRE LOGIC
local function autoFireWithArguments()
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not (humanoid and humanoid.SeatPart) then return end
    
    local vehicle = humanoid.SeatPart
    while vehicle and vehicle.Parent ~= workspace.Vehicles do
        vehicle = vehicle.Parent
    end
    if not vehicle then return end
    
    local fireRemote = vehicle:FindFirstChild("Fire")
    if not (fireRemote and fireRemote:IsA("RemoteEvent")) then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 2000
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character, vehicle}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local targetPosition = raycastResult and raycastResult.Position or (rayOrigin + rayDirection)
    
    local originPart = vehicle:FindFirstChild("Barrel", true) or humanoid.SeatPart
    local originPosition = originPart.CFrame.Position
    
    local argsPrimary = {[1]=2, [2]=targetPosition, [3]=originPosition, [7]={}}
    local argsSecondary = {[1]="Secondary", [2]=targetPosition, [3]={}}
    
    pcall(function() fireRemote:FireServer(unpack(argsPrimary)) end)
    pcall(function() fireRemote:FireServer(unpack(argsSecondary)) end)
end

-- CAPTURE SEQUENCE LOGIC
local function startCaptureSequence(positions, waitTime, locationType)
    if isCapturing then
        Rayfield:Notify("Capture Sequence", "A sequence is already in progress.", 7)
        return
    end
    
    isCapturing = true
    local locationsToVisit = {}
    
    for _, pos in ipairs(positions) do
        table.insert(locationsToVisit, pos)
    end
    
    task.spawn(function()
        while #locationsToVisit > 0 and isCapturing do
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                Rayfield:Notify("Capture Sequence", "Character not found. Aborting.", 7)
                break
            end
            
            local currentPlayerPos = player.Character.HumanoidRootPart.Position
            local closestPos, closestIndex, shortestDist = nil, nil, math.huge
            
            for i, pos in ipairs(locationsToVisit) do
                local dist = (currentPlayerPos - pos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestPos = pos
                    closestIndex = i
                end
            end
            
            if closestPos then
                Rayfield:Notify("Capture Sequence", "Teleporting to next " .. locationType .. ". " .. #locationsToVisit .. " remaining.", 5)
                smoothTeleport(CFrame.new(closestPos) + Vector3.new(0, 5, 0), teleportDuration)
                Rayfield:Notify("Capture Sequence", "Waiting for capture... (" .. waitTime .. "s)", waitTime)
                task.wait(waitTime)
                table.remove(locationsToVisit, closestIndex)
            else
                break
            end
        end
        
        Rayfield:Notify("Capture Sequence", "All " .. locationType .. "s have been visited.", 7)
        isCapturing = false
    end)
end

-- FIXED SERVER HOP FUNCTION (No HTTP requests)
local function joinLowPlayerServer()
    Rayfield:Notify("Server Hop", "Searching for optimal server...", 10)
    
    local placeId = game.PlaceId
    local avoidedServers = {}
    local teleportService = game:GetService("TeleportService")
    
    -- Load avoided servers list
    pcall(function()
        avoidedServers = HttpService:JSONDecode(readfile("CIA_AvoidedServers.json"))
    end)
    
    local function tryTeleport()
        -- Use Roblox's official API instead of HTTP requests
        local success, serverList = pcall(function()
            return TeleportService:GetGameInstancesAsync(placeId)
        end)
        
        if not success or not serverList then
            Rayfield:Notify("Server Hop Error", "Failed to retrieve server list.", 7)
            return false
        end
        
        for _, server in ipairs(serverList) do
            if server.Playing < server.MaxPlayers then
                local serverId = tostring(server.Id)
                local shouldAvoid = false
                
                for _, avoidedId in pairs(avoidedServers) do
                    if serverId == tostring(avoidedId) then
                        shouldAvoid = true
                        break
                    end
                end
                
                if not shouldAvoid then
                    table.insert(avoidedServers, serverId)
                    pcall(function()
                        writefile("CIA_AvoidedServers.json", HttpService:JSONEncode(avoidedServers))
                    end)
                    
                    TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
                    return true
                end
            end
        end
        
        return false
    end
    
    -- Try to teleport
    local teleportResult = tryTeleport()
    
    if not teleportResult then
        Rayfield:Notify("Server Hop", "No suitable servers found.", 7)
    end
end

--========================================================================--
--                            UI CONSTRUCTION                             --
--========================================================================--

local Window = Rayfield:CreateWindow({
    Name = "Military Asset Controller",
    LoadingTitle = "Asset Controller",
    LoadingSubtitle = "Initializing strategic overlay",
    Theme = "Amethyst",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CIA_MilitaryTycoon",
        FileName = "Configuration"
    },
    Discord = {
        Enabled = false,
        Invite = "sirius",
        RememberJoins = true
    }
})

local AutomationTab = Window:CreateTab("Automation", "settings")
AutomationTab:CreateToggle({
    Name = "Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuying = Value
        if autoBuying then
            activeConnections.autoBuy = RunService.Heartbeat:Connect(function()
                if autoBuying then
                    buyAllAvailableButtons()
                    task.wait(buySweepCooldown)
                end
            end)
        elseif activeConnections.autoBuy then
            activeConnections.autoBuy:Disconnect()
            activeConnections.autoBuy = nil
        end
    end
})

AutomationTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "AutoCollectToggle",
    Callback = function(Value)
        collectTeleporting = Value
        if collectTeleporting then
            activeConnections.autoCollect = RunService.Heartbeat:Connect(function()
                if collectTeleporting then
                    teleportToCollectButton()
                    task.wait(collectCooldown)
                end
            end)
        elseif activeConnections.autoCollect then
            activeConnections.autoCollect:Disconnect()
            activeConnections.autoCollect = nil
        end
    end
})

AutomationTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirthToggle",
    Callback = toggleAutoRebirth
})

local TeleportTab = Window:CreateTab("Teleports", "map-pin")
TeleportTab:CreateSection("Quick Locations")

local quickTeleports = {
    ["Infinity Tower"] = CFrame.new(-11.74, 801.47, -436.31),
    ["Nuclear Power Plant"] = CFrame.new(2172.38, 131.21, 849.91),
    ["AirField"] = CFrame.new(-1552.16, 125.47, -2712.45),
    ["Oil Rig"] = CFrame.new(205.37, 197.22, 4340.92)
}

for name, cframe in pairs(quickTeleports) do
    TeleportTab:CreateButton({
        Name = name,
        Callback = function()
            smoothTeleport(cframe, teleportDuration)
        end
    })
end

TeleportTab:CreateButton({
    Name = "Teleport to Crate",
    Callback = function()
        local crate = workspace:FindFirstChild("Crate")
        if not crate then
            Rayfield:Notify("Crate Not Found", "There is no crate currently on the map.", 7)
            return
        end
        
        local hitbox = crate:FindFirstChild("Hitbox")
        if hitbox then
            smoothTeleport(hitbox.CFrame + Vector3.new(0, 5, 0), teleportDuration)
        else
            Rayfield:Notify("Crate Error", "Crate was found, but its Hitbox was not.", 7)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Diamond Refinery",
    Callback = function()
        local success, hitboxPart = pcall(function()
            return workspace.ControlPoints["Diamond Refinery"].ControlPointCore.HitboxOrigin
        end)
        
        if success and hitboxPart then
            smoothTeleport(hitboxPart.CFrame + Vector3.new(0, 5, 0), teleportDuration)
        else
            Rayfield:Notify("Teleport Error", "Could not find Diamond Refinery part.", 7)
        end
    end
})

TeleportTab:CreateSection("Capture Sequences")
TeleportTab:CreateButton({
    Name = "Capture Small Outposts",
    Callback = function()
        startCaptureSequence(smallOutpostPositions, 35, "Small Outpost")
    end
})

TeleportTab:CreateButton({
    Name = "Capture Armed Fortresses",
    Callback = function()
        startCaptureSequence(armedFortressPositions, 50, "Armed Fortress")
    end
})

local MiscTab = Window:CreateTab("Misc & Player", "user")
MiscTab:CreateSection("Player Utilities")
MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = toggleInfiniteJump
})

MiscTab:CreateButton({
    Name = "Give BTools",
    Callback = function()
        local backpack = player.Backpack
        local tools = {
            {Name = "Hammer", BinType = 4},
            {Name = "Clone", BinType = 3},
            {Name = "Grab", BinType = 2}
        }
        
        local granted = false
        for _, tool in ipairs(tools) do
            if not backpack:FindFirstChild(tool.Name) then
                local newTool = Instance.new("HopperBin", backpack)
                newTool.Name = tool.Name
                newTool.BinType = tool.BinType
                granted = true
            end
        end
        
        if granted then
            Rayfield:Notify("Utilities", "BTools granted.", 5)
        else
            Rayfield:Notify("Utilities", "BTools already present.", 5)
        end
    end
})

MiscTab:CreateToggle({
    Name = "Enable Big Heads",
    Description = "Makes all other player and bot heads bigger (hitbox and visual).",
    CurrentValue = false,
    Flag = "BigHeadsToggle",
    Callback = function(Value)
        isHeadResizerActive = Value
        if Value then
            task.spawn(headResizerLoop)
        else
            revertAllHeadProperties()
        end
    end
})

MiscTab:CreateSlider({
    Name = "Adjustable Head Size",
    Description = "Controls the size for the 'Big Heads' feature.",
    Range = {1, 20},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "HeadSizeSlider",
    Callback = function(Value)
        headSize = Value
    end
})

MiscTab:CreateSection("Vehicle Spawners")
MiscTab:CreateToggle({
    Name = "Auto Spawn Plane on Respawn",
    Description = "Automatically spawns a plane 11 seconds after you die.",
    CurrentValue = false,
    Flag = "AutoSpawnPlaneToggle",
    Callback = function(Value)
        isAutoSpawnPlaneActive = Value
    end
})

MiscTab:CreateToggle({
    Name = "Auto Spawn Truck on Respawn",
    Description = "Automatically spawns a truck 11 seconds after you die.",
    CurrentValue = false,
    Flag = "AutoSpawnTruckToggle",
    Callback = function(Value)
        isAutoSpawnTruckActive = Value
    end
})

MiscTab:CreateSection("Combat")
MiscTab:CreateToggle({
    Name = "Auto Fire Vehicles",
    Description = "Continuously fires both primary and secondary weapons of the vehicle you are in.",
    CurrentValue = false,
    Flag = "AutoFireToggle",
    Callback = function(Value)
        if Value then
            activeConnections.autoFire = RunService.Heartbeat:Connect(autoFireWithArguments)
        elseif activeConnections.autoFire then
            activeConnections.autoFire:Disconnect()
            activeConnections.autoFire = nil
        end
    end
})

MiscTab:CreateSection("Server")
MiscTab:CreateButton({
    Name = "Join Low Player Server",
    Callback = joinLowPlayerServer
})

local SettingsTab = Window:CreateTab("Settings", "settings")
SettingsTab:CreateSection("Cooldowns & Delays")
SettingsTab:CreateSlider({
    Name = "Auto-Buy Sweep Delay",
    Description = "Delay between each full sweep of all available buttons.",
    Range = {0.5, 10},
    Increment = 0.1,
    Suffix = "seconds",
    CurrentValue = 1,
    Flag = "BuyCooldownSlider",
    Callback = function(Value)
        buySweepCooldown = Value
    end
})

SettingsTab:CreateSlider({
    Name = "Auto-Collect Delay",
    Range = {5, 60},
    Increment = 1,
    Suffix = "seconds",
    CurrentValue = 30,
    Flag = "CollectCooldownSlider",
    Callback = function(Value)
        collectCooldown = Value
    end
})

SettingsTab:CreateSlider({
    Name = "Rebirth Attempt Delay",
    Range = {1, 60},
    Increment = 1,
    Suffix = "seconds",
    CurrentValue = 5,
    Flag = "RebirthCooldownSlider",
    Callback = function(Value)
        rebirthCooldown = Value
    end
})

SettingsTab:CreateSlider({
    Name = "Teleport Speed",
    Description = "Controls the duration of all teleports.",
    Range = {0.1, 60},
    Increment = 0.1,
    Suffix = "seconds",
    CurrentValue = 1,
    Flag = "TeleportSpeedSlider",
    Callback = function(Value)
        teleportDuration = Value
    end
})

-- Initialize the UI
Rayfield:LoadConfiguration()
