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
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local UtilityTab = Window:CreateTab("Movement & Misc", 4483362458)

--------------------------------------------------------------------------------
-- CHARACTER & STATE TRACKING
--------------------------------------------------------------------------------
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
end)

--------------------------------------------------------------------------------
-- SAFE SPACE SETUP
--------------------------------------------------------------------------------
local SAFE_SPACE_CFRAME = CFrame.new(0, 5000, 0)
local safeSpacePart = workspace:FindFirstChild("SafeSpaceBaseplate")

if not safeSpacePart then
	safeSpacePart = Instance.new("Part")
	safeSpacePart.Name = "SafeSpaceBaseplate"
	safeSpacePart.Size = Vector3.new(200, 5, 200)
	safeSpacePart.CFrame = SAFE_SPACE_CFRAME
	safeSpacePart.Anchored = true
	safeSpacePart.Material = Enum.Material.SmoothPlastic
	safeSpacePart.Color = Color3.fromRGB(40, 40, 45)
	safeSpacePart.Parent = workspace
end

local function teleportToSafeSpace()
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if myRoot then
		myRoot.CFrame = SAFE_SPACE_CFRAME * CFrame.new(0, 5, 0)
	end
end

--------------------------------------------------------------------------------
-- ANTI-VOID SYSTEM
--------------------------------------------------------------------------------
local ANTI_VOID_HEIGHT = -150
local antiVoidPart = workspace:FindFirstChild("AntiVoidPlate")

if not antiVoidPart then
	antiVoidPart = Instance.new("Part")
	antiVoidPart.Name = "AntiVoidPlate"
	antiVoidPart.Size = Vector3.new(10000, 10, 10000)
	antiVoidPart.CFrame = CFrame.new(0, ANTI_VOID_HEIGHT, 0)
	antiVoidPart.Anchored = true
	antiVoidPart.CanCollide = true
	antiVoidPart.Transparency = 0.6
	antiVoidPart.Material = Enum.Material.ForceField
	antiVoidPart.Color = Color3.fromRGB(255, 0, 80)
	antiVoidPart.Parent = workspace
end

antiVoidPart.Touched:Connect(function(hit)
	if char and hit:IsDescendantOf(char) then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(0, 50, 0)
		end
	end
end)

--------------------------------------------------------------------------------
-- CHARACTER ABILITY CONFIGURATIONS (JASON, SHEDLETSKY & NOLI)
--------------------------------------------------------------------------------
local charAbilitiesFolder = ReplicatedStorage:WaitForChild("CharacterAbilities", 5)
local jasonFolder = charAbilitiesFolder and charAbilitiesFolder:FindFirstChild("Jason")
local shedFolder = charAbilitiesFolder and charAbilitiesFolder:FindFirstChild("Shedletsky")
local noliFolder = charAbilitiesFolder and charAbilitiesFolder:FindFirstChild("Noli")

local JasonAbilities = {
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
	},
	["AltAbility3"] = {
		["Cooldown"] = 20,
		["LastUsed"] = 0,
		["Remote"] = jasonFolder and jasonFolder:FindFirstChild("Enraged")
	}
}

local ShedletskyAbilities = {
	["Slash"] = {
		["Cooldown"] = 15,
		["LastUsed"] = 0,
		["Remote"] = shedFolder and shedFolder:FindFirstChild("ShedletskyAttackRemote")
	},
	["Fried Chicken"] = {
		["Cooldown"] = 15,
		["LastUsed"] = 0,
		["Remote"] = shedFolder and shedFolder:FindFirstChild("ShedletskyChickenRemote")
	}
}

local NoliAbilities = {
	["MainAbility"] = { -- Slash
		["Cooldown"] = 1.8,
		["LastUsed"] = 0,
		["Remote"] = noliFolder and noliFolder:FindFirstChild("NoliAttackRemote")
	},
	["AltAbility2"] = { -- Nova
		["Cooldown"] = 0,
		["LastUsed"] = 0,
		["Remote"] = noliFolder and noliFolder:FindFirstChild("NoliNova")
	}
}

local JASON_AUTO_ABILITIES = { "MainAbility", "AltAbility1", "AltAbility2" }
local SHEDLETSKY_AUTO_ABILITIES = { "Slash", "Fried Chicken" }
local NOLI_AUTO_ABILITIES = { "MainAbility", "AltAbility2" }

local autoFarmLowHpOn = false
local autoFarmAllOn = false
local lockInFrontOn = false
local stickToPersonOn = false
local targetHealthThreshold = 20
local hitDistanceOffset = 3
local MAX_ABILITY_DISTANCE = 15

local currentLockedTarget = nil

local LowHpToggle
local AllPlayersToggle

local function getCurrentCharacterType()
	if not char then return nil end
	return char:GetAttribute("Character")
end

local function canUseCharacter()
	if not char or not hum or hum.Health <= 0 then return false end
	local cType = getCurrentCharacterType()

	if cType == "Jason" or cType == "Slasher" or cType == "Noli" then
		return char:GetAttribute("CanAttack") ~= false and char:GetAttribute("Emoting") ~= true and char:GetAttribute("AbilitiesDisabled") ~= true
	elseif cType == "Shedletsky" then
		return char:GetAttribute("CanRun") ~= false and char:GetAttribute("CanAttack") ~= false and char:GetAttribute("Emoting") ~= true and char:GetAttribute("AbilitiesDisabled") ~= true
	end
	return true
end

--------------------------------------------------------------------------------
-- ANIMATION & ACTION HANDLER
--------------------------------------------------------------------------------
local function playShedletskyAnim()
	if not char or not hum then return end
	local anim = Instance.new("Animation")
	local skin = char:GetAttribute("Skin")
	local actualSkin = char:GetAttribute("ActualSkin")

	if skin == "RetroShed" then anim.AnimationId = "rbxassetid://84906874339359"
	elseif skin == "M100Shed" or skin == "M75Shed" then anim.AnimationId = "rbxassetid://72661064392418"
	elseif skin == "BusterShedletsky" then anim.AnimationId = "rbxassetid://102735588255002"
	elseif skin == "ButcherShedletsky" then anim.AnimationId = "rbxassetid://83703568665249"
	elseif skin == "NessShedletsky" or skin == "Scout" then anim.AnimationId = "rbxassetid://117635960799966"
	elseif skin == "Targetman" then anim.AnimationId = "rbxassetid://117814766896269"
	elseif skin == "SCP" then anim.AnimationId = "rbxassetid://113516249240896"
	elseif skin == "Snyfort" or skin == "Pastelbeat" or skin == "Upbeat" or skin == "SoapyDX" or skin == "SoapyDXLegacy" or skin == "DownTunes" then anim.AnimationId = "rbxassetid://115680124099922"
	elseif skin == "Pastello" and (actualSkin ~= "Pastello3" and actualSkin ~= "Pastello4") then anim.AnimationId = "rbxassetid://79130710510782"
	elseif skin == "Pastello" and actualSkin == "Pastello3" then anim.AnimationId = "rbxassetid://99539026106525"
	elseif skin == "Pastello" and actualSkin == "Pastello4" then anim.AnimationId = "rbxassetid://115470481199645"
	elseif skin == "GoldenShedletsky" then anim.AnimationId = "rbxassetid://94865308722467"
	elseif skin == "TillDawnShedletsky" then anim.AnimationId = "rbxassetid://112474546068323"
	elseif skin == "Blega" then anim.AnimationId = "rbxassetid://74816403474613"
	elseif skin == "SoapyDX4" then anim.AnimationId = "rbxassetid://122628818808958"
	elseif skin == "VIPShed" then anim.AnimationId = "rbxassetid://80100528383027"
	else anim.AnimationId = "rbxassetid://107302018639039" end

	local track = hum:LoadAnimation(anim)
	track:Play()

	local conn
	conn = char:GetAttributeChangedSignal("HitSlash"):Connect(function()
		if char:GetAttribute("HitSlash") and skin ~= "Blega" then
			track:Stop()
			local hitAnim = Instance.new("Animation")
			hitAnim.AnimationId = "rbxassetid://104029412142861"
			hum:LoadAnimation(hitAnim):Play()
			if conn then conn:Disconnect() end
		end
	end)
end

local function playNoliAnim()
	if not char or not hum then return end
	local anim = Instance.new("Animation")
	local skin = char:GetAttribute("Skin")

	if skin == "RetroNoli" then anim.AnimationId = "rbxassetid://120515916154475"
	elseif skin == "Clockwork" then anim.AnimationId = "rbxassetid://108021827965381"
	elseif skin == "NarratorNoli" then anim.AnimationId = "rbxassetid://128744951510910"
	elseif skin == "Noli4" then anim.AnimationId = "rbxassetid://98438228576241"
	elseif skin == "EvilTeh" then anim.AnimationId = "rbxassetid://97930480559280"
	elseif skin == "AdminNoli" then anim.AnimationId = "rbxassetid://126706312443717"
	elseif skin == "Pastway" or skin == "Fleatway" then anim.AnimationId = "rbxassetid://105540391527912"
	else anim.AnimationId = "rbxassetid://133721031387826" end

	local track = hum:LoadAnimation(anim)
	track:Play()
	track:AdjustSpeed(1.5)
end

local function castCharacterAction(actionName, targetPosition)
	if not canUseCharacter() then return end
	local cType = getCurrentCharacterType()
	local abilityTable = ((cType == "Jason" or cType == "Slasher") and JasonAbilities) or (cType == "Shedletsky" and ShedletskyAbilities) or (cType == "Noli" and NoliAbilities)

	if not abilityTable then return end
	local data = abilityTable[actionName]

	if data and data.Remote then
		local now = os.clock()
		if now - data.LastUsed >= data.Cooldown then
			data.LastUsed = now

			if cType == "Shedletsky" and actionName == "Slash" then
				playShedletskyAnim()
			elseif cType == "Noli" and actionName == "MainAbility" then
				playNoliAnim()
			end

			if cType == "Noli" and actionName == "AltAbility2" then
				local aimPos = targetPosition or (workspace.Camera.CFrame * CFrame.new(0, 0, -500)).Position
				data.Remote:FireServer(aimPos, true)
			else
				data.Remote:FireServer()
			end
		end
	end
end

--------------------------------------------------------------------------------
-- TARGET DETECTION & POSITIONING
--------------------------------------------------------------------------------
local function isTargetAliveAndValid(p)
	if not p or not p.Parent or not p.Character or p == player then return false end
	local tHum = p.Character:FindFirstChild("Humanoid")
	local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
	return tHum and tRoot and tHum.Health > 0 and p.Character:IsDescendantOf(workspace)
end

local function getLowHpTarget(maxHp)
	if stickToPersonOn and isTargetAliveAndValid(currentLockedTarget) then
		return currentLockedTarget
	end

	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local lowestHp = maxHp or targetHealthThreshold
	local targetPlayer = nil

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and isTargetAliveAndValid(p) then
			local tHum = p.Character.Humanoid
			if tHum.Health <= lowestHp then
				lowestHp = tHum.Health
				targetPlayer = p
			end
		end
	end

	currentLockedTarget = targetPlayer
	return targetPlayer
end

local function getAnyTarget()
	if stickToPersonOn and isTargetAliveAndValid(currentLockedTarget) then
		return currentLockedTarget
	end

	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closestDist = math.huge
	local targetPlayer = nil

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and isTargetAliveAndValid(p) then
			local tRoot = p.Character.HumanoidRootPart
			local dist = (tRoot.Position - myRoot.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				targetPlayer = p
			end
		end
	end

	currentLockedTarget = targetPlayer
	return targetPlayer
end

local function positionAtTarget(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not myRoot or not targetRoot then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local offset = hitDistanceOffset

	if lockInFrontOn then
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -offset) * CFrame.Angles(0, math.pi, 0)
	else
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, offset)
	end
end
--------------------------------------------------------------------------------
-- UNBROKEN STICKY POSITIONING LOOP
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

--------------------------------------------------------------------------------
-- AUTO FARM HEARTBEAT LOOP (FIRE ABILITIES ONLY WHEN NEARBY)
--------------------------------------------------------------------------------
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
-- FLY SYSTEM (FIXED)
--------------------------------------------------------------------------------
local flying = false
local flySpeed = 50
local flyBV = nil
local flyBG = nil
local flyConnection = nil

local function stopFly()
	flying = false
	
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	if flyBV then
		flyBV:Destroy()
		flyBV = nil
	end

	if flyBG then
		flyBG:Destroy()
		flyBG = nil
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local function startFly()
	stopFly()

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)

	if not root or not humanoid then return end

	flyBV = Instance.new("BodyVelocity")
	flyBV.Name = "FlyVelocity"
	flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = root

	flyBG = Instance.new("BodyGyro")
	flyBG.Name = "FlyGyro"
	flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyBG.CFrame = camera.CFrame
	flyBG.Parent = root

	flying = true
	humanoid.PlatformStand = true

	flyConnection = RS.RenderStepped:Connect(function()
		if not flying or not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
			stopFly()
			return
		end

		local moveDir = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

		flyBG.CFrame = camera.CFrame

		if moveDir.Magnitude > 0 then
			flyBV.Velocity = moveDir.Unit * flySpeed
		else
			flyBV.Velocity = Vector3.zero
		end
	end)
end

player.CharacterAdded:Connect(function()
	stopFly()
end)

UtilityTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "Fly_Toggle",
   Callback = function(Value)
      if Value then
         startFly()
      else
         stopFly()
      end
   end,
})

UtilityTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 5,
   Suffix = " Speed",
   CurrentValue = 50,
   Flag = "FlySpeed_Slider",
   Callback = function(Value)
      flySpeed = Value
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
