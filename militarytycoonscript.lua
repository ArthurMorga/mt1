                                                                                 getgenv().SecureMode= 
                                                                        true;local Rayfield=loadstring(game:HttpGet(    
                                                                    "https://sirius.menu/rayfield"))();local player=game.Players. 
                                                                LocalPlayer;local ReplicatedStorage=game:GetService("ReplicatedStorage" 
                                                            );local TweenService=game:GetService("TweenService");local RunService=game:   
                                                          GetService("RunService");local UserInputService=game:GetService(                  
                                                        "UserInputService");local VirtualUser=game:GetService("VirtualUser");local            
                                                      TeleportService=game:GetService("TeleportService");local HttpService=game:GetService(     
                                                    "HttpService");local seaGreenColor=Color3.fromRGB(57,166,40);local crimsonColor=Color3.       
                                                  fromRGB(166,13,13);local autoBuying=false;local prioritizeWorkers=false;local collectTeleporting= 
                                                  false;local buySweepCooldown=1;local collectCooldown=30;local rebirthCooldown=5;local               
                                                teleportDuration=1;local isAutoRebirthActive,lastRebirthAttempt,rebirthFunction=false,0,nil;local       
                                                isAutoSpawnPlaneActive,isAutoSpawnTruckActive=false,false;local isHeadResizerActive,headSize,             
                                              originalProperties=false,5,{};local isNoHoldEnabled=false;local originalHoldDurations={};local VEHICLE_UUIDS= 
                                              {PLANE="ad989579-9f33-443d-b3ad-8b968f270a3f",TRUCK="b08a5285-61e9-4583-8a17-09f6b7560438"};local             
                                            activeConnections={};local function revertAllHoldDurations() for prompt,originalDuration in pairs(                
                                            originalHoldDurations) do pcall(function() if (prompt and prompt.Parent) then prompt.HoldDuration=originalDuration; 
                                          end end);end originalHoldDurations={};end local function noHoldLoop() while isNoHoldEnabled do for _,descendant in      
                                          ipairs(workspace:GetDescendants()) do if descendant:IsA("ProximityPrompt") then if (originalHoldDurations[descendant]==   
                                          nil) then originalHoldDurations[descendant]=descendant.HoldDuration;end descendant.HoldDuration=0;end end task.wait(1);end  
                                          end local function toggleNoHold(value) isNoHoldEnabled=value;if isNoHoldEnabled then Rayfield:Notify({Title=                
                                        "World Utilities",Content="Fast Hold Prompts has been enabled.",Duration=5});task.spawn(noHoldLoop);else Rayfield:Notify({Title 
                                        ="World Utilities",Content="Fast Hold Prompts has been disabled.",    --[[==============================]]Duration=5});           
                                        revertAllHoldDurations();end end local function             --[[============================================]]                    
                                        revertAllHeadProperties() for part,props in pairs(      --[[======================================================]]                
                                      originalProperties) do if (part and part.Parent) then --[[==========================================================]] part.Size=props. 
                                      Size;if (props.Mesh and props.Mesh.Parent) then     --[[==============================================================]]props.Mesh.     
                                      Scale=props.OriginalScale;end end end               --[[================================================================]]                
                                      originalProperties={};end local function            --[[==================================================================]]              
                                      headResizerLoop() while isHeadResizerActive and     --[[==================================================================]]task.wait(0.5)    
                                      do local myCharacter=player.Character;for _,model   --[[====================================================================]]in ipairs(    
                    workspace:GetChildren()) do if (model:IsA("Model") and (model~=       --[[====================================================================]]myCharacter))   
              then local humanoid=model:FindFirstChildOfClass("Humanoid");if (humanoid    --[[======================================================================]]and (humanoid 
            .Health>0)) then local head=model:FindFirstChild("Head");if head then if  not --[[======================================================================]]              
          originalProperties[head] then local mesh=head:FindFirstChildOfClass(            --[[======================================================================]]"SpecialMesh" 
        ) or head:FindFirstChildOfClass("BlockMesh") ;originalProperties[head]={Size=head --[[======================================================================]].Size,Mesh=   
        mesh,OriginalScale=(mesh and mesh.Scale) or nil };end local newSize=Vector3.new(  --[[======================================================================]]headSize,     
      headSize,headSize);head.Size=newSize;if originalProperties[head].Mesh then          --[[======================================================================]]              
      originalProperties[head].Mesh.Scale=newSize;end end end end end end end local         --[[==================================================================]]function        
      toggleInfiniteJump(value) getgenv().infiniteJump=value;if value then Rayfield:Notify( --[[================================================================]]{Title=           
    "Player Utilities",Content="Infinite Jump has been enabled.",Duration=5});else Rayfield --[[==============================================================]]:Notify({Title=   
    "Player Utilities",Content="Infinite Jump has been disabled.",Duration=5});end end        --[[==========================================================]]UserInputService.   
    JumpRequest:Connect(function() if (getgenv().infiniteJump and player.Character) then local  --[[====================================================]]humanoid=player.        
    Character:FindFirstChildOfClass("Humanoid");if humanoid then humanoid:ChangeState("Jumping"); --[[==============================================]]end end end);player.Idled 
    :Connect(function() VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new());end); --[[====================================]]local function                
    getPlayerTycoon() local tycoon=workspace.PlayerTycoons:FindFirstChild(player.Name);if  not tycoon     --[[========================]]then tycoon=workspace.PlayerTycoons:  
    WaitForChild(player.Name,5);end return tycoon;end local function isAvailableToBuy(button) return button:IsA("BasePart") and (button.Color==seaGreenColor) ;end local    
  function smoothTeleport(targetCFrame,duration) if ( not player.Character or  not player.Character:FindFirstChild("HumanoidRootPart")) then return;end local hrp=player. 
  Character.HumanoidRootPart;for _,part in ipairs(player.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false;end end local tween=         
  TweenService:Create(hrp,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=targetCFrame});tween:Play();tween.Completed:Wait();for _,part in ipairs(player.         
  Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=true;end end hrp.Velocity,hrp.RotVelocity=Vector3.new(0,0,0),Vector3.new(0,0,0);end local   
  function executePurchaseLogic() local myTycoon=getPlayerTycoon();if  not myTycoon then return;end local remoteFunction=myTycoon:FindFirstChild("RemoteFunction");local  
  buttonFolder=myTycoon:FindFirstChild("ButtonFolder");if ( not remoteFunction or  not buttonFolder) then return;end if prioritizeWorkers then for _,buttonModel in       
  ipairs(buttonFolder:GetChildren()) do local modelName=buttonModel.Name:lower();if (string.find(modelName,"worker") or string.find(modelName,"upgrade")) then local      
  mainButtonPart=buttonModel:FindFirstChild("Button");if mainButtonPart then local btnColor=mainButtonPart.Color;if ((btnColor==seaGreenColor) or (btnColor==crimsonColor 
  )) then pcall(function() remoteFunction:InvokeServer("BuyButton",buttonModel.Name);end);return;end end end end end local otherButtonsToBuy={};for _,buttonModel in      
  ipairs(buttonFolder:GetChildren()) do local mainButtonPart=buttonModel:FindFirstChild("Button");if (mainButtonPart and isAvailableToBuy(mainButtonPart)) then table.    
  insert(otherButtonsToBuy,buttonModel.Name);end end for _,buttonName in ipairs(otherButtonsToBuy) do pcall(function() remoteFunction:InvokeServer("BuyButton",buttonName 
  );end);task.wait(0.1);end end local function executeRebirth() if ((os.clock() -lastRebirthAttempt)<rebirthCooldown) then return;end if  not rebirthFunction then local    
  playerTycoon=workspace.PlayerTycoons:FindFirstChild(player.Name);if playerTycoon then rebirthFunction=playerTycoon:FindFirstChild("Rebirth");end end if rebirthFunction   
  then local success,result=pcall(function() return rebirthFunction:InvokeServer();end);lastRebirthAttempt=os.clock();if (success and (result==true)) then Rayfield:Notify( 
  {Title="Rebirth Successful",Content="The server processed the rebirth request.",Duration=5});end end end local function toggleAutoRebirth(value) isAutoRebirthActive=     
  value;if isAutoRebirthActive then Rayfield:Notify({Title="Automation",Content="Auto-Rebirth has been enabled.",Duration=5});activeConnections.autoRebirth=RunService.     
  Heartbeat:Connect(executeRebirth);else Rayfield:Notify({Title="Automation",Content="Auto-Rebirth has been disabled.",Duration=5});if activeConnections.autoRebirth then   
  activeConnections.autoRebirth:Disconnect();activeConnections.autoRebirth=nil;end end end local function teleportToCollectButton() local myTycoon=getPlayerTycoon();if     
  not myTycoon then return;end local modelsFolder=myTycoon:WaitForChild("Models",2);if  not modelsFolder then return;end local collectButton;local starterGiver=            
  modelsFolder:FindFirstChild("StarterGiver");if starterGiver then collectButton=starterGiver:FindFirstChild("CollectButton");end if  not collectButton then local giver=   
  modelsFolder:FindFirstChild("Giver");collectButton=giver and giver:FindFirstChild("CollectButton") ;end if (collectButton and player.Character and player.Character:      
  FindFirstChild("HumanoidRootPart")) then player.Character.HumanoidRootPart.CFrame=collectButton.CFrame + Vector3.new(0,5,0) ;end end local function getVehicleSpawnRemote 
  () return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.5.1"):WaitForChild("knit"):WaitForChild("Services"):           
  WaitForChild("VehicleService"):WaitForChild("RF"):WaitForChild("Spawn");end local function spawnVehicle(uuid,vehicleName) local spawnRemote=getVehicleSpawnRemote();if    
  not spawnRemote then Rayfield:Notify({Title="Vehicle Spawn Error",Content="Could not find spawn remote.",Duration=7});return;end pcall(function() spawnRemote:          
  InvokeServer(uuid);Rayfield:Notify({Title="Vehicle Spawn",Content=vehicleName   .. " spawn request sent." ,Duration=5});end);end local function setupDeathTrigger(      
  character) if  not character then return;end local humanoid=character:WaitForChild("Humanoid");humanoid.Died:Connect(function() if (isAutoSpawnPlaneActive or           
    isAutoSpawnTruckActive) then task.wait(11);if isAutoSpawnPlaneActive then spawnVehicle(VEHICLE_UUIDS.PLANE,"Plane");end if isAutoSpawnTruckActive then spawnVehicle(  
    VEHICLE_UUIDS.TRUCK,"Truck");end end end);end player.CharacterAdded:Connect(setupDeathTrigger);if player.Character then setupDeathTrigger(player.Character);end local 
     function joinLowPlayerServer() Rayfield:Notify({Title="Server Hop",Content="Searching for optimal server...",Duration=10});local placeId=game.PlaceId;local          
    avoidedServers={};pcall(function() avoidedServers=HttpService:JSONDecode(readfile("CIA_AvoidedServers.json"));end);local success,serverList=pcall(function() return   
      TeleportService:GetGameInstancesAsync(placeId);end);if ( not success or  not serverList) then Rayfield:Notify({Title="Server Hop Error",Content=                  
      "Failed to retrieve server list.",Duration=7});return;end for _,server in ipairs(serverList) do if (server.Playing<server.MaxPlayers) then local serverId=        
      tostring(server.Id);local shouldAvoid=false;for _,avoidedId in pairs(avoidedServers) do if (serverId==tostring(avoidedId)) then shouldAvoid=true;break;end end if 
          not shouldAvoid then table.insert(avoidedServers,serverId);pcall(function() writefile("CIA_AvoidedServers.json",HttpService:JSONEncode(avoidedServers));end); 
        TeleportService:TeleportToPlaceInstance(placeId,serverId,player);return;end end end Rayfield:Notify({Title="Server Hop",Content="No suitable servers found.",   
        Duration=7});end local Window=Rayfield:CreateWindow({Name="Military Tycoon Script",LoadingTitle="Asset Controller",LoadingSubtitle="Loading script...",Theme=   
          "Amethyst",ConfigurationSaving={Enabled=true,FolderName="CIA_MilitaryTycoon",FileName="Configuration"},Discord={Enabled=true,Invite="sirius",RememberJoins= 
            true}});local AutomationTab=Window:CreateTab("Automation","settings");AutomationTab:CreateToggle({Name="Auto Buy",CurrentValue=false,Flag="AutoBuyToggle" 
              ,Callback=function(Value) autoBuying=Value;if autoBuying then Rayfield:Notify({Title="Automation",Content="Auto Buy has been enabled.",Duration=5});    
                activeConnections.autoBuy=RunService.Heartbeat:Connect(function() if autoBuying then executePurchaseLogic();task.wait(buySweepCooldown);end end);else 
                   Rayfield:Notify({Title="Automation",Content="Auto-Buy has been disabled.",Duration=5});if activeConnections.autoBuy then activeConnections.      
                      autoBuy:Disconnect();activeConnections.autoBuy=nil;end end end});AutomationTab:CreateToggle({Name="Prioritize Workers",Description=           
                                  "Forces purchase of worker/upgrade buttons, ignoring all others.",CurrentValue=false,Flag="PrioritizeWorkersToggle",Callback=     
                                      function(Value) prioritizeWorkers=Value;if Value then Rayfield:Notify({Title="Automation",Content=                            
                                      "Worker prioritization is now active.",Duration=5});else              Rayfield:Notify({Title="Automation",Content=            
                                      "Worker prioritization has been disabled.",Duration=5});end           end});AutomationTab:CreateToggle({Name="Auto Collect" 
                                      ,CurrentValue=false,Flag="AutoCollectToggle",Callback=                function(Value) collectTeleporting=Value;if           
                                      collectTeleporting then Rayfield:Notify({Title="Automation",          Content="Auto-Collect has been enabled.",Duration=5}) 
                                      ;activeConnections.autoCollect=RunService.Heartbeat:Connect(            function() if collectTeleporting then               
                                      teleportToCollectButton();task.wait(collectCooldown);end end)           ;else Rayfield:Notify({Title="Automation",Content=  
                                      "Auto-Collect has been disabled.",Duration=5});if                       activeConnections.autoCollect then                
                                        activeConnections.autoCollect:Disconnect();                           activeConnections.autoCollect=nil;end end end});  
                                        AutomationTab:CreateToggle({Name="Auto Rebirth",                        CurrentValue=false,Flag="AutoRebirthToggle",    
                                        Callback=toggleAutoRebirth});AutomationTab:CreateSection(               "Delays & Cooldowns");AutomationTab:          
                                        CreateSlider({Name="Auto-Buy Sweep Delay",Description=                  "Delay between each full sweep.",Range={0.5,  
                                        10},Increment=0.1,Suffix="s",CurrentValue=1,Flag=                         "BuyCooldownSlider",Callback=function(    
                                        Value) buySweepCooldown=Value;end});AutomationTab:                        CreateSlider({Name="Auto-Collect Delay",  
                                          Range={5,60},Increment=1,Suffix="s",CurrentValue=30,                      Flag="CollectCooldownSlider",Callback 
                                          =function(Value) collectCooldown=Value;end});                               AutomationTab:CreateSlider({    
                                            Name="Rebirth Attempt Delay",Range={1,60},Increment                         =1,Suffix="s",            
                                            CurrentValue=5,Flag="RebirthCooldownSlider",                                      Callback=   
                                              function(Value) rebirthCooldown=Value;end});  
                                                local TeleportTab=Window:CreateTab(       
                                                    "Teleports","map-pin");TeleportTab: 
                                                          CreateSection(          


"Quick Locations");local quickTeleports={["Infinity Tower"]=CFrame.new( -11.74,801.47, -436.31),["Nuclear Power Plant"]=CFrame.new(2172.38,131.21,849.91),AirField=CFrame.new( -1552.16,125.47, -2712.45),["Oil Rig"]=CFrame.new(205.37,197.22,4340.92)};for name,cframe in pairs(quickTeleports) do TeleportTab:CreateButton({Name=name,Callback=function() Rayfield:Notify({Title="Teleport",Content="Teleporting to "   .. name   .. "..." ,Duration=teleportDuration});smoothTeleport(cframe,teleportDuration);end});end TeleportTab:CreateButton({Name="Teleport to Crate",Callback=function() local crate=workspace:FindFirstChild("Crate");if  not crate then Rayfield:Notify({Title="Crate Not Found",Content="There is no crate on the map.",Duration=7});return;end local hitbox=crate:FindFirstChild("Hitbox");if hitbox then Rayfield:Notify({Title="Teleport",Content="Teleporting to Crate...",Duration=teleportDuration});smoothTeleport(hitbox.CFrame + Vector3.new(0,5,0) ,teleportDuration);else Rayfield:Notify({Title="Crate Error",Content="Crate was found, but its Hitbox was not.",Duration=7});end end});TeleportTab:CreateButton({Name="Diamond Refinery",Callback=function() local success,hitboxPart=pcall(function() return workspace.ControlPoints["Diamond Refinery"].ControlPointCore.HitboxOrigin;end);if (success and hitboxPart) then Rayfield:Notify({Title="Teleport",Content="Teleporting to Diamond Refinery...",Duration=teleportDuration});smoothTeleport(hitboxPart.CFrame + Vector3.new(0,5,0) ,teleportDuration);else Rayfield:Notify({Title="Teleport Failed",Content="Cannot find Diamond Refinery. Try getting closer.",Duration=7});end end});TeleportTab:CreateSection("Teleport Settings");TeleportTab:CreateSlider({Name="Teleport Speed",Description="Controls the duration of all teleports.",Range={0.1,60},Increment=0.1,Suffix="s",CurrentValue=1,Flag="TeleportSpeedSlider",Callback=function(Value) teleportDuration=Value;end});local MiscTab=Window:CreateTab("Misc & Player","user");MiscTab:CreateSection("Player Utilities");MiscTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Flag="InfiniteJumpToggle",Callback=toggleInfiniteJump});MiscTab:CreateButton({Name="Give BTools",Callback=function() local backpack=player.Backpack;local tools={{Name="Hammer",BinType=4},{Name="Clone",BinType=3},{Name="Grab",BinType=2}};local granted=false;for _,tool in ipairs(tools) do if  not backpack:FindFirstChild(tool.Name) then local newTool=Instance.new("HopperBin",backpack);newTool.Name=tool.Name;newTool.BinType=tool.BinType;granted=true;end end if granted then Rayfield:Notify({Title="Utilities",Content="BTools granted.",Duration=5});else Rayfield:Notify({Title="Utilities",Content="BTools already present.",Duration=5});end end});MiscTab:CreateToggle({Name="Adjust Players Heads",Description="Makes all other player heads bigger.",CurrentValue=false,Flag="BigHeadsToggle",Callback=function(Value) isHeadResizerActive=Value;if Value then Rayfield:Notify({Title="Player Utilities",Content="Big Heads has been enabled.",Duration=5});task.spawn(headResizerLoop);else Rayfield:Notify({Title="Player Utilities",Content="Big Heads has been disabled.",Duration=5});revertAllHeadProperties();end end});MiscTab:CreateSlider({Name="Head Size",Description="Controls the size for 'Big Heads'.",Range={1,20},Increment=0.5,Suffix=" studs",CurrentValue=5,Flag="HeadSizeSlider",Callback=function(Value) headSize=Value;end});MiscTab:CreateSection("World Utilities");MiscTab:CreateToggle({Name="Fast Hold Prompts",Description="Makes all proximity prompts (like entering vehicles) instant.",CurrentValue=false,Flag="NoHoldPromptsToggle",Callback=toggleNoHold});MiscTab:CreateSection("Server");MiscTab:CreateButton({Name="Join Low Player Server",Callback=joinLowPlayerServer});Rayfield:LoadConfiguration();
