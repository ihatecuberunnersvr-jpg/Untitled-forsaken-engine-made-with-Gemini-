--------------------------------------------------------------------------------
-- SERVICES & LOCAL PLAYER SETUP
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
end)

--------------------------------------------------------------------------------
-- UI FRAMEWORK INITIALIZATION (RAYFIELD)
--------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal Script Hub",
   LoadingTitle = "Loading Hub...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "HubConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local CombatTab   = Window:CreateTab("Combat", 4483362458)
local ESPTab      = Window:CreateTab("ESP", 4483362458)
local UtilityTab  = Window:CreateTab("Utility", 4483362458)

--------------------------------------------------------------------------------
-- GLOBAL STATE & CONSTANTS
--------------------------------------------------------------------------------
local autoFarmLowHpOn = false
local autoFarmAllOn   = false
local lockInFrontOn   = false
local stickToPersonOn = false

local hitDistanceOffset = 3
local targetHealthThreshold = 20
local MAX_ABILITY_DISTANCE = 30
local currentLockedTarget = nil

local LowHpToggle, AllPlayersToggle

local SAFE_SPACE_CFRAME = CFrame.new(-1119.03076171875, 894.944580078125 + 6, -85.89985656738281)

--------------------------------------------------------------------------------
-- ABILITY TABLES & COOLDOWNS
--------------------------------------------------------------------------------
local JasonAbilities = {
	["Slash"]    = { LastUsed = 0, Cooldown = 1.2 },
	["Behead"]   = { LastUsed = 0, Cooldown = 8.0 },
	["Eviscerate"]= { LastUsed = 0, Cooldown = 12.0 },
}

local ShedletskyAbilities = {
	["Slash"]    = { LastUsed = 0, Cooldown = 1.0 },
	["SwordSlam"]= { LastUsed = 0, Cooldown = 6.0 },
}

local NoliAbilities = {
	["VoidStrike"]= { LastUsed = 0, Cooldown = 2.0 },
	["Teleport"]  = { LastUsed = 0, Cooldown = 10.0 },
}

local JASON_AUTO_ABILITIES      = {"Slash", "Behead", "Eviscerate"}
local SHEDLETSKY_AUTO_ABILITIES = {"Slash", "SwordSlam"}
local NOLI_AUTO_ABILITIES       = {"VoidStrike"}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------
local function getCurrentCharacterType()
	if not char then return "Unknown" end
	if char:FindFirstChild("Behead") or char:FindFirstChild("JasonMask") then
		return "Jason"
	elseif char:FindFirstChild("SwordSlam") or char:FindFirstChild("FriedChicken") then
		return "Shedletsky"
	elseif char:FindFirstChild("VoidStrike") or char:FindFirstChild("NoliHead") then
		return "Noli"
	end
	return "Unknown"
end

local function canUseCharacter()
	if not char or not hum or hum.Health <= 0 then return false end
	if char:GetAttribute("Stunned") == true or char:GetAttribute("Frozen") == true then
		return false
	end
	return true
end

local function castCharacterAction(abilityName, targetPosition)
	local cType = getCurrentCharacterType()
	local abilityTable = (cType == "Jason" and JasonAbilities) 
		or (cType == "Shedletsky" and ShedletskyAbilities) 
		or (cType == "Noli" and NoliAbilities) 

	if not abilityTable or not abilityTable[abilityName] then return end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
	if remotes then
		local remoteEvent = remotes:FindFirstChild(abilityName)
		if remoteEvent and remoteEvent:IsA("RemoteEvent") then
			remoteEvent:FireServer(targetPosition)
			abilityTable[abilityName].LastUsed = os.clock()
			return
		end
	end

	local tool = char:FindFirstChild(abilityName)
	if tool and tool:IsA("Tool") then
		tool:Activate()
		abilityTable[abilityName].LastUsed = os.clock()
	end
end

local function isTargetAliveAndValid(p)
	if not p or p == player then return false end
	local c = p.Character
	if not c then return false end
	local h = c:FindFirstChildOfClass("Humanoid")
	local r = c:FindFirstChild("HumanoidRootPart")
	return h and r and h.Health > 0
end

local function getLowHpTarget(threshold)
	if stickToPersonOn and isTargetAliveAndValid(currentLockedTarget) then
		local h = currentLockedTarget.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= threshold then
			return currentLockedTarget
		end
	end

	local lowestHp = math.huge
	local bestPlr = nil

	for _, p in ipairs(Players:GetPlayers()) do
		if isTargetAliveAndValid(p) then
			local h = p.Character.Humanoid
			if h.Health <= threshold and h.Health < lowestHp then
				lowestHp = h.Health
				bestPlr = p
			end
		end
	end

	if bestPlr then currentLockedTarget = bestPlr end
	return bestPlr
end

local function getAnyTarget()
	if stickToPersonOn and isTargetAliveAndValid(currentLockedTarget) then
		return currentLockedTarget
	end

	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closestDist = math.huge
	local bestPlr = nil

	for _, p in ipairs(Players:GetPlayers()) do
		if isTargetAliveAndValid(p) then
			local tRoot = p.Character.HumanoidRootPart
			local dist = (tRoot.Position - myRoot.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				bestPlr = p
			end
		end
	end

	if bestPlr then currentLockedTarget = bestPlr end
	return bestPlr
end

local function positionAtTarget(targetPlayer)
	if not char or not targetPlayer or not targetPlayer.Character then return end
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

	if myRoot and tRoot then
		if lockInFrontOn then
			myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, -hitDistanceOffset) * CFrame.Angles(0, math.pi, 0)
		else
			myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, hitDistanceOffset)
		end
	end
end

local function teleportToSafeSpace()
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if myRoot then
		myRoot.CFrame = SAFE_SPACE_CFRAME
	end
end
--------------------------------------------------------------------------------
-- HEARTBEAT LOOPS & UI TABS
--------------------------------------------------------------------------------
RS.Stepped:Connect(function()
	if not autoFarmLowHpOn and not autoFarmAllOn then return end
	if not char or not hum or hum.Health <= 0 then return end

	local activeTarget = nil

	if autoFarmLowHpOn then
		activeTarget = getLowHpTarget(targetHealthThreshold)
	elseif autoFarmAllOn then
		activeTarget = getAnyTarget()
	end

	if activeTarget and isTargetAliveAndValid(activeTarget) then
		positionAtTarget(activeTarget)
	end
end)

RS.Heartbeat:Connect(function()
	if char and getCurrentCharacterType() == "Shedletsky" then
		char:SetAttribute("CanRun", true)
		char:SetAttribute("Slowed", false)
		if hum and hum.WalkSpeed < 16 then
			hum.WalkSpeed = 16
		end
	end

	if not autoFarmLowHpOn and not autoFarmAllOn then return end

	if hum and hum.Health <= 30 then
		if autoFarmLowHpOn and LowHpToggle then LowHpToggle:Set(false) end
		if autoFarmAllOn and AllPlayersToggle then AllPlayersToggle:Set(false) end
		autoFarmLowHpOn = false
		autoFarmAllOn = false
		currentLockedTarget = nil
		teleportToSafeSpace()
		return
	end

	local cType = getCurrentCharacterType()
	local autoList = ((cType == "Jason" or cType == "Slasher") and JASON_AUTO_ABILITIES) 
		or (cType == "Shedletsky" and SHEDLETSKY_AUTO_ABILITIES) 
		or (cType == "Noli" and NOLI_AUTO_ABILITIES) 
		or {}

	local abilityTable = ((cType == "Jason" or cType == "Slasher") and JasonAbilities) 
		or (cType == "Shedletsky" and ShedletskyAbilities) 
		or (cType == "Noli" and NoliAbilities) 
		or {}

	local targetP = currentLockedTarget
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")

	if targetP and isTargetAliveAndValid(targetP) and myRoot then
		local tRoot = targetP.Character:FindFirstChild("HumanoidRootPart")
		if tRoot then
			local distance = (tRoot.Position - myRoot.Position).Magnitude

			if distance <= MAX_ABILITY_DISTANCE and canUseCharacter() then
				for _, abilityName in ipairs(autoList) do
					local data = abilityTable[abilityName]
					if data and (os.clock() - data.LastUsed >= data.Cooldown) then
						castCharacterAction(abilityName, tRoot.Position)
					end
				end
			end
		end
	else
		currentLockedTarget = nil
		teleportToSafeSpace()
	end
end)

--------------------------------------------------------------------------------
-- AUTO FARM TAB ELEMENTS
--------------------------------------------------------------------------------
AutoFarmTab:CreateToggle({
   Name = "Lock in Front of Person",
   CurrentValue = false,
   Flag = "LockInFront_Toggle",
   Callback = function(Value)
      lockInFrontOn = Value
   end,
})

AutoFarmTab:CreateToggle({
   Name = "Stick to Person?",
   CurrentValue = false,
   Flag = "StickToPerson_Toggle",
   Callback = function(Value)
      stickToPersonOn = Value
      if not Value then currentLockedTarget = nil end
   end,
})

AutoFarmTab:CreateDropdown({
   Name = "Position Offset (Hit Range)",
   Options = {"Close (~3 studs)", "Slightly Far (~5.5 studs)", "Far (~8 studs)"},
   CurrentOption = {"Close (~3 studs)"},
   Flag = "HitDistance_Dropdown",
   Callback = function(Option)
      if Option[1]:find("Slightly Far") then
         hitDistanceOffset = 5.5
      elseif Option[1]:find("Far") then
         hitDistanceOffset = 8
      else
         hitDistanceOffset = 3
      end
   end,
})

LowHpToggle = AutoFarmTab:CreateToggle({
   Name = "Auto Farm Low Health Players",
   CurrentValue = false,
   Flag = "AutoFarmLowHp_Toggle",
   Callback = function(Value)
      autoFarmLowHpOn = Value
      if Value and AllPlayersToggle then AllPlayersToggle:Set(false) end
      if not Value then currentLockedTarget = nil end
   end,
})

AllPlayersToggle = AutoFarmTab:CreateToggle({
   Name = "Auto Farm All Players",
   CurrentValue = false,
   Flag = "AutoFarmAll_Toggle",
   Callback = function(Value)
      autoFarmAllOn = Value
      if Value and LowHpToggle then LowHpToggle:Set(false) end
      if not Value then currentLockedTarget = nil end
   end,
})

AutoFarmTab:CreateDropdown({
   Name = "Low HP Target Threshold",
   Options = {"10 HP", "20 HP", "30 HP", "50 HP"},
   CurrentOption = {"20 HP"},
   Flag = "HpThreshold_Dropdown",
   Callback = function(Option)
      local val = tonumber(string.match(Option[1], "%d+"))
      if val then targetHealthThreshold = val end
   end,
})

AutoFarmTab:CreateButton({
   Name = "Teleport to Safe Space",
   Callback = function()
      teleportToSafeSpace()
   end,
})

--------------------------------------------------------------------------------
-- ESP SYSTEM
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

        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(0, 150, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Adornee = targetChar
        highlight.Parent = targetChar

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
-- ANIMATION INVISIBILITY SYSTEM
--------------------------------------------------------------------------------
local invisOn = false
local invisTrack = nil
local originalIds = {}

local INVIS_ID = "rbxassetid://99789196955252"

local function stopInvisAnim()
	invisOn = false
	if invisTrack then
		invisTrack:Stop()
		invisTrack:Destroy()
		invisTrack = nil
	end

	local character = player.Character
	if character then
		local animateScript = character:FindFirstChild("Animate")
		if animateScript then
			for animValue, originalId in pairs(originalIds) do
				if animValue and animValue.Parent then
					animValue.AnimationId = originalId
				end
			end
		end
	end
	table.clear(originalIds)
end

local function startInvisAnim()
	stopInvisAnim()
	invisOn = true

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	local animator = humanoid and humanoid:WaitForChild("Animator", 5)
	local animateScript = character:WaitForChild("Animate", 5)

	if not animator or not animateScript then return end

	-- Replace all default IDs inside the default Animate script
	for _, v in ipairs(animateScript:GetDescendants()) do
		if v:IsA("Animation") then
			originalIds[v] = v.AnimationId
			v.AnimationId = INVIS_ID
		end
	end

	-- Stop all playing tracks currently active
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	-- Play custom looping invisible animation track
	local customAnim = Instance.new("Animation")
	customAnim.AnimationId = INVIS_ID

	invisTrack = animator:LoadAnimation(customAnim)
	invisTrack.Priority = Enum.AnimationPriority.Action4
	invisTrack.Looped = true
	invisTrack:Play()
end

player.CharacterAdded:Connect(function()
	if invisOn then
		task.wait(0.5)
		startInvisAnim()
	end
end)

UtilityTab:CreateToggle({
   Name = "Animation Invisibility",
   CurrentValue = false,
   Flag = "Invis_Toggle",
   Callback = function(Value)
      if Value then
         startInvisAnim()
      else
         stopInvisAnim()
      end
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
