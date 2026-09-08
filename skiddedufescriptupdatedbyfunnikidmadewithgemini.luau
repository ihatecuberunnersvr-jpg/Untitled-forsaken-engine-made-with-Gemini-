--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera

--// RAYFIELD WINDOW SETUP
local Window = Rayfield:CreateWindow({
   Name = "UFE Hub",
   LoadingTitle = "UFE Hub Interface",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false
})

--// TABS
local CombatTab = Window:CreateTab("Combat", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local UtilityTab = Window:CreateTab("Movement & Misc", 4483362458)

--------------------------------------------------------------------------------
-- CHARACTER TRACKING
--------------------------------------------------------------------------------
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
end)

--------------------------------------------------------------------------------
-- RELIABLE BLUE HIGHLIGHT + TEXT ESP
--------------------------------------------------------------------------------
local espOn = false
local activeESP = {}

local function removeESP(plr)
    if activeESP[plr] then
        if activeESP[plr].Highlight then activeESP[plr].Highlight:Destroy() end
        if activeESP[plr].Billboard then activeESP[plr].Billboard:Destroy() end
        if activeESP[plr].Connection then activeESP[plr].Connection:Disconnect() end
        activeESP[plr] = nil
    end
end

local function applyESP(plr)
    if plr == player then return end
    removeESP(plr)

    local function setupChar(targetChar)
        if not targetChar then return end
        
        local root = targetChar:WaitForChild("HumanoidRootPart", 5)
        local targetHum = targetChar:WaitForChild("Humanoid", 5)
        local head = targetChar:WaitForChild("Head", 5) or root
        
        if not root or not targetHum then return end

        -- Create Box Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(0, 150, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Adornee = targetChar
        highlight.Parent = targetChar

        -- Create Name/HP Overlay
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = head
        billboard.Parent = targetChar

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14

        local conn = RS.RenderStepped:Connect(function()
            if not espOn or not targetChar:IsDescendantOf(workspace) or targetHum.Health <= 0 then
                highlight.Enabled = false
                billboard.Enabled = false
            else
                highlight.Enabled = true
                billboard.Enabled = true
                label.Text = plr.Name .. " | " .. math.floor(targetHum.Health) .. " HP"
            end
        end)

        activeESP[plr] = {
            Highlight = highlight,
            Billboard = billboard,
            Connection = conn
        }
    end

    if plr.Character then setupChar(plr.Character) end
    plr.CharacterAdded:Connect(setupChar)
end

ESPTab:CreateToggle({
   Name = "Blue Highlight & Box ESP",
   CurrentValue = false,
   Flag = "ESP_Toggle",
   Callback = function(Value)
      espOn = Value
      if espOn then
         for _, p in ipairs(Players:GetPlayers()) do
            applyESP(p)
         end
      else
         for p, _ in pairs(activeESP) do
            removeESP(p)
         end
      end
   end,
})

Players.PlayerAdded:Connect(function(p)
    if espOn then applyESP(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
end)

--------------------------------------------------------------------------------
-- CAMLOCK FUNCTIONALITY
--------------------------------------------------------------------------------
local ACTIVATION_DISTANCE = 80 
local DROP_DISTANCE = 200      
local CAMERA_OFFSET = Vector3.new(0, 4.5, 10) 

local currentTarget = nil
local isLocked = false

local function getPlayerInCameraView()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myRoot = myChar.HumanoidRootPart
    local bestTarget = nil
    local highestFacingScore = 0.4 
    local cameraLookDirection = camera.CFrame.LookVector

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local targetChar = p.Character
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                if distance <= ACTIVATION_DISTANCE then
                    local vectorToTarget = (targetRoot.Position - camera.CFrame.Position).Unit
                    local dotProduct = cameraLookDirection:Dot(vectorToTarget) 
                    
                    if dotProduct > highestFacingScore then
                        highestFacingScore = dotProduct
                        bestTarget = targetChar
                    end
                end
            end
        end
    end
    return bestTarget
end

local function disableLock()
    isLocked = false
    currentTarget = nil
    RS:UnbindFromRenderStep("CamlockLoop")
end

local function enableLock(targetPlayerChar)
    currentTarget = targetPlayerChar
    isLocked = true

    RS:BindToRenderStep("CamlockLoop", Enum.RenderPriority.Camera.Value + 1, function()
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") or not currentTarget or not currentTarget:FindFirstChild("HumanoidRootPart") then
            disableLock()
            return
        end

        local myRoot = myChar.HumanoidRootPart
        local targetRoot = currentTarget.HumanoidRootPart
        local targetHumanoid = currentTarget:FindFirstChildOfClass("Humanoid")

        if not targetHumanoid or targetHumanoid.Health <= 0 or (myRoot.Position - targetRoot.Position).Magnitude > DROP_DISTANCE then
            disableLock()
            return
        end

        local myPos = myRoot.Position
        local targetPos = targetRoot.Position
        local targetAimPos = targetPos + Vector3.new(0, 1.5, 0)
        
        local flatDirection = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
        if flatDirection.Magnitude == 0 then flatDirection = Vector3.new(0, 0, 1) end

        local finalCamPos = myPos - (flatDirection * CAMERA_OFFSET.Z) + Vector3.new(0, CAMERA_OFFSET.Y, 0)
        camera.CFrame = CFrame.lookAt(finalCamPos, targetAimPos)
    end)
end

CombatTab:CreateToggle({
   Name = "CamLock Target",
   CurrentValue = false,
   Flag = "CamLock_Toggle",
   Callback = function(Value)
      if Value then
         local target = getPlayerInCameraView()
         if target then
            enableLock(target)
         else
            Rayfield:Notify({
               Title = "CamLock",
               Content = "No Target in Camera View",
               Duration = 2,
               Image = 4483362458,
            })
            disableLock()
         end
      else
         disableLock()
      end
   end,
})

--------------------------------------------------------------------------------
-- AUTO ABILITIES (JASON)
--------------------------------------------------------------------------------
local autoAbilitiesOn = false
local MAX_AUTO_DISTANCE = 15

local jasonFolder = ReplicatedStorage:WaitForChild("CharacterAbilities", 5) and ReplicatedStorage.CharacterAbilities:FindFirstChild("Jason")
local jasonAbilities = {
	["MainAbility"] = {
		["Cooldown"] = 1.9,
		["LastUsed"] = 0,
		["Remote"] = jasonFolder and jasonFolder:FindFirstChild("JasonAttackRemote")
	},
	["AltAbility1"] = {
		["Cooldown"] = 15,
		["LastUsed"] = 0,
		["Remote"] = jasonFolder and jasonFolder:FindFirstChild("Behead")
	},
	["AltAbility2"] = {
		["Cooldown"] = 25,
		["LastUsed"] = 0,
		["Remote"] = jasonFolder and jasonFolder:FindFirstChild("GashingWound")
	}
}

local jasonBusy = false

local function canUseJason()
	if char and char:GetAttribute("Character") == "Jason" and (char:GetAttribute("CanAttack") ~= false and (char:GetAttribute("Emoting") ~= true and char:GetAttribute("AbilitiesDisabled") ~= true)) then
		return hum and hum.Health > 0
	end
	return false
end

local function getClosestPlayerForAbility()
	local closestChar = nil
	local shortestDistance = math.huge
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")

	if not myRoot then return nil, math.huge end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local targetChar = p.Character
			local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
			local targetHum = targetChar:FindFirstChild("Humanoid")

			if targetRoot and targetHum and targetHum.Health > 0 then
				local distance = (targetRoot.Position - myRoot.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestChar = targetChar
				end
			end
		end
	end
	return closestChar, shortestDistance
end

local function aimAtTarget(targetCharacter)
	if not targetCharacter then return end
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

	if myRoot and targetRoot then
		local targetPos = Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetPos)
	end
end

local function castJasonAbility(abilityName)
	if jasonBusy or not canUseJason() then return end
	local abilityData = jasonAbilities[abilityName]
	if abilityData and abilityData.Remote then
		local now = os.clock()
		if now - abilityData.LastUsed >= abilityData.Cooldown then
			jasonBusy = true
			abilityData.LastUsed = now
			abilityData.Remote:FireServer()
			task.delay(0.05, function()
				jasonBusy = false
			end)
		end
	end
end

RS.Heartbeat:Connect(function()
	if autoAbilitiesOn and canUseJason() then
		local closestChar, distance = getClosestPlayerForAbility()
		if closestChar and distance <= MAX_AUTO_DISTANCE then
			aimAtTarget(closestChar)
			for abilityName, _ in pairs(jasonAbilities) do
				local data = jasonAbilities[abilityName]
				if data and (os.clock() - data.LastUsed >= data.Cooldown) then
					castJasonAbility(abilityName)
				end
			end
		end
	end
end)

CombatTab:CreateToggle({
   Name = "auto abilitys (WORKING IN PROCESS)",
   CurrentValue = false,
   Flag = "AutoJason_Toggle",
   Callback = function(Value)
      autoAbilitiesOn = Value
   end,
})

--------------------------------------------------------------------------------
-- AUTO SLASH SHEDLETSKY
--------------------------------------------------------------------------------
local autoShedletskyOn = false
local MAX_SLASH_DISTANCE = 15
local shedFolder = ReplicatedStorage:WaitForChild("CharacterAbilities", 5) and ReplicatedStorage.CharacterAbilities:FindFirstChild("Shedletsky")

local shedAbilities = {
	["Slash"] = {
		["Cooldown"] = 15,
		["LastUsed"] = 0,
		["Remote"] = shedFolder and shedFolder:FindFirstChild("ShedletskyAttackRemote")
	}
}

local shedBusy = false

local function canUseShedletsky()
	if char and char:GetAttribute("Character") == "Shedletsky" and (char:GetAttribute("CanRun") ~= false and (char:GetAttribute("CanAttack") ~= false and (char:GetAttribute("Emoting") ~= true and char:GetAttribute("AbilitiesDisabled") ~= true))) then
		return hum and hum.Health > 0
	end
	return false
end

local function playShedletskyAnim()
	local anim = Instance.new("Animation")
	local skin = char:GetAttribute("Skin")
	local actualSkin = char:GetAttribute("ActualSkin")

	if skin == "RetroShed" then
		anim.AnimationId = "rbxassetid://84906874339359"
	elseif skin == "M100Shed" or skin == "M75Shed" then
		anim.AnimationId = "rbxassetid://72661064392418"
	elseif skin == "BusterShedletsky" then
		anim.AnimationId = "rbxassetid://102735588255002"
	elseif skin == "ButcherShedletsky" then
		anim.AnimationId = "rbxassetid://83703568665249"
	elseif skin == "NessShedletsky" or skin == "Scout" then
		anim.AnimationId = "rbxassetid://117635960799966"
	elseif skin == "Targetman" then
		anim.AnimationId = "rbxassetid://117814766896269"
	elseif skin == "SCP" then
		anim.AnimationId = "rbxassetid://113516249240896"
	elseif skin == "Snyfort" or skin == "Pastelbeat" or skin == "Upbeat" or skin == "SoapyDX" or skin == "SoapyDXLegacy" or skin == "DownTunes" then
		anim.AnimationId = "rbxassetid://115680124099922"
	elseif skin == "Pastello" and (actualSkin ~= "Pastello3" and actualSkin ~= "Pastello4") then
		anim.AnimationId = "rbxassetid://79130710510782"
	elseif skin == "Pastello" and actualSkin == "Pastello3" then
		anim.AnimationId = "rbxassetid://99539026106525"
	elseif skin == "Pastello" and actualSkin == "Pastello4" then
		anim.AnimationId = "rbxassetid://115470481199645"
	elseif skin == "GoldenShedletsky" then
		anim.AnimationId = "rbxassetid://94865308722467"
	elseif skin == "TillDawnShedletsky" then
		anim.AnimationId = "rbxassetid://112474546068323"
	elseif skin == "Blega" then
		anim.AnimationId = "rbxassetid://74816403474613"
	elseif skin == "SoapyDX4" then
		anim.AnimationId = "rbxassetid://122628818808958"
	elseif skin == "VIPShed" then
		anim.AnimationId = "rbxassetid://80100528383027"
	else
		anim.AnimationId = "rbxassetid://107302018639039"
	end

	local track = hum:LoadAnimation(anim)
	track:Play()

	local hitConn
	hitConn = char:GetAttributeChangedSignal("HitSlash"):Connect(function()
		if char:GetAttribute("HitSlash") and skin ~= "Blega" then
			track:Stop()
			local hitAnim = Instance.new("Animation")
			hitAnim.AnimationId = "rbxassetid://104029412142861"
			hum:LoadAnimation(hitAnim):Play()
			if hitConn then hitConn:Disconnect() end
		end
	end)
end

local function performShedletskyAction(actionName)
	if shedBusy or not canUseShedletsky() then return end
	local data = shedAbilities[actionName]
	if data and data.Remote then
		local now = os.clock()
		if now - data.LastUsed >= data.Cooldown then
			shedBusy = true
			data.LastUsed = now
			if actionName == "Slash" then
				playShedletskyAnim()
			end
			data.Remote:FireServer()
			task.delay(0.35, function()
				shedBusy = false
			end)
		end
	end
end

RS.Heartbeat:Connect(function()
	if autoShedletskyOn and canUseShedletsky() then
		local closestChar, distance = getClosestPlayerForAbility()
		if closestChar and distance <= MAX_SLASH_DISTANCE then
			aimAtTarget(closestChar)
			local slashData = shedAbilities["Slash"]
			if os.clock() - slashData.LastUsed >= slashData.Cooldown then
				performShedletskyAction("Slash")
			end
		end
	end
end)

CombatTab:CreateToggle({
   Name = "auto slash shedletsky",
   CurrentValue = false,
   Flag = "AutoShed_Toggle",
   Callback = function(Value)
      autoShedletskyOn = Value
   end,
})

--------------------------------------------------------------------------------
-- TPWALK & MOVEMENT UTILITIES
--------------------------------------------------------------------------------
local tpwalkOn = false
local speed = 1

UtilityTab:CreateToggle({
   Name = "TpWalk",
   CurrentValue = false,
   Flag = "TpWalk_Toggle",
   Callback = function(Value)
      tpwalkOn = Value
   end,
})

UtilityTab:CreateSlider({
   Name = "TpWalk Speed",
   Range = {1, 10},
   Increment = 1,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "Speed_Slider",
   Callback = function(Value)
      speed = Value
   end,
})

RS.RenderStepped:Connect(function()
    if tpwalkOn and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        local hrp = char.HumanoidRootPart
        local move = char.Humanoid.MoveDirection
        hrp.CFrame = hrp.CFrame + (move * speed)
    end
end)

--------------------------------------------------------------------------------
-- SAVE PLACE / PLATFORM
--------------------------------------------------------------------------------
local savedPos = Vector3.new(-1119.03076171875, 894.944580078125, -85.89985656738281)
local platform

UtilityTab:CreateButton({
   Name = "Save Place (Platform TP)",
   Callback = function()
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if not hrp then return end

      if not platform then
          platform = Instance.new("Part")
          platform.Size = Vector3.new(60, 5, 60)
          platform.Position = savedPos
          platform.Anchored = true
          platform.Color = Color3.fromRGB(120, 120, 120)
          platform.Material = Enum.Material.SmoothPlastic
          platform.Name = "SafePlatform"
          platform.Parent = workspace
      end

      hrp.CFrame = CFrame.new(savedPos + Vector3.new(0, 6, 0))
   end,
})
