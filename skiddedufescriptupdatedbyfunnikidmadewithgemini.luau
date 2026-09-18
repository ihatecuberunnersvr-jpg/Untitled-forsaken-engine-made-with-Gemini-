--------------------------------------------------------------------------------
-- GAME ID CHECKER
--------------------------------------------------------------------------------
local ALLOWED_PLACE_IDS = {
	[100039707794702] = true,
	[99585784721880]  = true,
	[99055603649009]  = true,
	[70444122688316]  = true,
}

if not ALLOWED_PLACE_IDS[game.PlaceId] then
	game:GetService("Players").LocalPlayer:Kick("Incorrect Game! Current Place ID (" .. tostring(game.PlaceId) .. ") is not authorized.")
	return
end

--------------------------------------------------------------------------------
-- RAYFIELD GEN 2 SETUP
--------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2-preview"))()

local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera

--// RAYFIELD WINDOW SETUP (GEN 2)
local Window = Rayfield:CreateWindow({
   name = "FLUXUSSAKEN FREE FOR ALL",
   subtitle = "by PASTWAY",
   sidebarLayout = true,
})

--// TABS (GEN 2 SYNTAX)
local CombatTab = Window:CreateTab({ name = "Combat", icon = 4483362458 })
local AutoFarmTab = Window:CreateTab({ name = "Auto Farm", icon = 4483362458 })
local ESPTab = Window:CreateTab({ name = "ESP", icon = 4483362458 })
local UtilityTab = Window:CreateTab({ name = "Movement & Misc", icon = 4483362458 })

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

--------------------------------------------------------------------------------
-- CHARACTER STATE CHECKS
--------------------------------------------------------------------------------
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
-- UNBROKEN STICKY POSITIONING LOOP (STEPS EVERY FRAME)
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
-- AUTO FARM TAB ELEMENTS (GEN 2 PREVIEW SYNTAX)
--------------------------------------------------------------------------------
AutoFarmTab:CreateToggle({
   name = "Lock in Front of Person",
   currentValue = false,
   callback = function(value)
      lockInFrontOn = value
   end,
})

AutoFarmTab:CreateToggle({
   name = "Stick to Person?",
   currentValue = false,
   callback = function(value)
      stickToPersonOn = value
      if not value then currentLockedTarget = nil end
   end,
})

AutoFarmTab:CreateDropdown({
   name = "Position Offset (Hit Range)",
   options = {"Close (~3 studs)", "Slightly Far (~5.5 studs)", "Far (~8 studs)"},
   currentOption = "Close (~3 studs)",
   callback = function(option)
      local selected = typeof(option) == "table" and option[1] or option
      if selected:find("Slightly Far") then
         hitDistanceOffset = 5.5
      elseif selected:find("Far") then
         hitDistanceOffset = 8
      else
         hitDistanceOffset = 3
      end
   end,
})

LowHpToggle = AutoFarmTab:CreateToggle({
   name = "Auto Farm Low Health Players",
   currentValue = false,
   callback = function(value)
      autoFarmLowHpOn = value
      if value and AllPlayersToggle then AllPlayersToggle:Set(false) end
      if not value then currentLockedTarget = nil end
   end,
})

AllPlayersToggle = AutoFarmTab:CreateToggle({
   name = "Auto Farm All Players",
   currentValue = false,
   callback = function(value)
      autoFarmAllOn = value
      if value and LowHpToggle then LowHpToggle:Set(false) end
      if not value then currentLockedTarget = nil end
   end,
})

AutoFarmTab:CreateDropdown({
   name = "Low HP Target Threshold",
   options = {"10 HP", "20 HP", "30 HP", "50 HP"},
   currentOption = "20 HP",
   callback = function(option)
      local selected = typeof(option) == "table" and option[1] or option
      local val = tonumber(string.match(selected, "%d+"))
      if val then targetHealthThreshold = val end
   end,
})

AutoFarmTab:CreateButton({
   name = "Teleport to Safe Space",
   callback = function()
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
   name = "Blue Highlight & Box ESP",
   currentValue = false,
   callback = function(value)
      espOn = value
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
-- COMBAT TAB (ATTACK REMOTES, SHEDLETSKY CHICKEN & CAMLOCK)
--------------------------------------------------------------------------------
local autoAttackOn = false

local function findRemote()
    local remote = ReplicatedStorage:FindFirstChild("JasonAttackRemote", true)
    if remote then return remote end

    local charAbilities = ReplicatedStorage:FindFirstChild("CharacterAbilities", true)
    if charAbilities then
        local jasonFolder = charAbilities:FindFirstChild("Jason", true)
        if jasonFolder then
            return jasonFolder:FindFirstChild("JasonAttackRemote", true)
        end
    end
    return nil
end

local attackRemote = findRemote()

task.spawn(function()
    while true do
        if autoAttackOn then
            if not attackRemote then
                attackRemote = findRemote()
            end
            
            if attackRemote then
                attackRemote:FireServer()
            end
        end
        task.wait(0)
    end
end)

CombatTab:CreateToggle({
   name = "Auto Attack (No Delay Loop)",
   currentValue = false,
   callback = function(value)
      autoAttackOn = value
      if value and not attackRemote then
         attackRemote = findRemote()
         if not attackRemote then
            warn("[Script Error]: Could not locate 'JasonAttackRemote' in ReplicatedStorage!")
         end
      end
   end,
})

--------------------------------------------------------------------------------
-- SHEDLETSKY AUTO CHICKEN
--------------------------------------------------------------------------------
local shedChickenAutoOn = false

local function findChickenRemote()
    local remote = ReplicatedStorage:FindFirstChild("ShedletskyChickenRemote", true)
    if remote then return remote end

    local charAbilities = ReplicatedStorage:FindFirstChild("CharacterAbilities", true)
    if charAbilities then
        local shedFolder = charAbilities:FindFirstChild("Shedletsky", true)
        if shedFolder then
            return shedFolder:FindFirstChild("ShedletskyChickenRemote", true)
        end
    end
    return nil
end

local chickenRemote = findChickenRemote()

task.spawn(function()
    while true do
        if shedChickenAutoOn then
            if not chickenRemote then
                chickenRemote = findChickenRemote()
            end
            
            if chickenRemote then
                task.spawn(function()
                    chickenRemote:InvokeServer()
                end)
            end
        end
        task.wait()
    end
end)

CombatTab:CreateToggle({
   name = "Shedletsky Auto Chicken",
   currentValue = false,
   callback = function(value)
      shedChickenAutoOn = value
      if value and not chickenRemote then
         chickenRemote = findChickenRemote()
         if not chickenRemote then
            warn("[Script Error]: Could not locate 'ShedletskyChickenRemote' in ReplicatedStorage!")
         end
      end
   end,
})

--------------------------------------------------------------------------------
-- NEW CAMLOCK FUNCTIONALITY
--------------------------------------------------------------------------------
local ACTIVATION_DISTANCE = 80 
local DROP_DISTANCE = 200      
local CAMERA_OFFSET = Vector3.new(0, 4.5, 10) 
local TURN_SMOOTHNESS = 0.25

local currentTarget = nil
local isLocked = false

local function getBestTarget()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
	
	local myRoot = character.HumanoidRootPart
	local bestTarget = nil
	local highestFacingScore = 0.3 
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

local function isTargetValid(targetChar)
	if not targetChar or not targetChar.Parent or not targetChar:FindFirstChild("HumanoidRootPart") then
		return false
	end
	
	local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local myChar = player.Character
	if myChar and myChar:FindFirstChild("HumanoidRootPart") then
		local distance = (myChar.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
		if distance > DROP_DISTANCE then
			return false
		end
	end

	return true
end

local function disableLock()
	isLocked = false
	currentTarget = nil
	RS:UnbindFromRenderStep("CamAndCharLockLoop")
end

local function enableLock()
	isLocked = true

	RS:BindToRenderStep("CamAndCharLockLoop", Enum.RenderPriority.Camera.Value + 1, function()
		if not isLocked then return end

		local myChar = player.Character
		if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

		if not isTargetValid(currentTarget) then
			currentTarget = getBestTarget()
		end

		if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
			local myRoot = myChar.HumanoidRootPart
			local myPos = myRoot.Position
			local targetPos = currentTarget.HumanoidRootPart.Position
			local targetAimPos = targetPos + Vector3.new(0, 1.5, 0)

			local charLookTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
			local charTargetCFrame = CFrame.lookAt(myPos, charLookTarget)
			myRoot.CFrame = myRoot.CFrame:Lerp(charTargetCFrame, TURN_SMOOTHNESS)

			local flatDirection = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
			if flatDirection.Magnitude == 0 then flatDirection = Vector3.new(0, 0, 1) end

			local finalCamPos = myPos - (flatDirection * CAMERA_OFFSET.Z) + Vector3.new(0, CAMERA_OFFSET.Y, 0)
			camera.CFrame = CFrame.lookAt(finalCamPos, targetAimPos)
		end
	end)
end

CombatTab:CreateToggle({
   name = "NEW Camlock",
   currentValue = false,
   callback = function(value)
      if value then
         enableLock()
      else
         disableLock()
      end
   end,
})

--------------------------------------------------------------------------------
-- EXTRA COMBAT ATTACKS (COOLKID, 1x4, LISTRO)
--------------------------------------------------------------------------------
local coolkidAutoOn = false
local auto1x4On = false
local listroAutoOn = false

local function findCoolkidRemote()
    local remote = ReplicatedStorage:FindFirstChild("CoolkidAttackRemote", true)
    if remote then return remote end

    local charAbilities = ReplicatedStorage:FindFirstChild("CharacterAbilities", true)
    if charAbilities then
        local coolkidFolder = charAbilities:FindFirstChild("Coolkid", true)
        if coolkidFolder then
            return coolkidFolder:FindFirstChild("CoolkidAttackRemote", true)
        end
    end
    return nil
end

local function find1x4Remote()
    local remote = ReplicatedStorage:FindFirstChild("1x4AttackRemote", true)
    if remote then return remote end

    local charAbilities = ReplicatedStorage:FindFirstChild("CharacterAbilities", true)
    if charAbilities then
        local folder1x4 = charAbilities:FindFirstChild("1x4", true)
        if folder1x4 then
            return folder1x4:FindFirstChild("1x4AttackRemote", true)
        end
    end
    return nil
end

local function findListroRemote()
    local remote = ReplicatedStorage:FindFirstChild("ListroPunch", true)
    if remote then return remote end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes", true)
    if remotesFolder then
        return remotesFolder:FindFirstChild("ListroPunch", true)
    end
    return nil
end

local coolkidRemote = findCoolkidRemote()
local remote1x4 = find1x4Remote()
local listroRemote = findListroRemote()

task.spawn(function()
    while true do
        if coolkidAutoOn then
            if not coolkidRemote then coolkidRemote = findCoolkidRemote() end
            if coolkidRemote then coolkidRemote:FireServer() end
        end
        task.wait()
    end
end)

task.spawn(function()
    while true do
        if auto1x4On then
            if not remote1x4 then remote1x4 = find1x4Remote() end
            if remote1x4 then remote1x4:FireServer() end
        end
        task.wait()
    end
end)

task.spawn(function()
    while true do
        if listroAutoOn then
            if not listroRemote then listroRemote = findListroRemote() end
            if listroRemote then listroRemote:FireServer() end
        end
        task.wait()
    end
end)

CombatTab:CreateSection("Additional Attack Loops")

CombatTab:CreateToggle({
   name = "Auto Coolkid Attack (0 Delay)",
   currentValue = false,
   callback = function(value)
      coolkidAutoOn = value
      if value and not coolkidRemote then
         coolkidRemote = findCoolkidRemote()
         if not coolkidRemote then
            warn("[Script Error]: Could not locate 'CoolkidAttackRemote' in ReplicatedStorage!")
         end
      end
   end,
})

CombatTab:CreateToggle({
   name = "Auto 1x4 Attack (0 Delay)",
   currentValue = false,
   callback = function(value)
      auto1x4On = value
      if value and not remote1x4 then
         remote1x4 = find1x4Remote()
         if not remote1x4 then
            warn("[Script Error]: Could not locate '1x4AttackRemote' in ReplicatedStorage!")
         end
      end
   end,
})

CombatTab:CreateToggle({
   name = "Auto Listro Punch (0 Delay)",
   currentValue = false,
   callback = function(value)
      listroAutoOn = value
      if value and not listroRemote then
         listroRemote = findListroRemote()
         if not listroRemote then
            warn("[Script Error]: Could not locate 'ListroPunch' in ReplicatedStorage!")
         end
      end
   end,
})

--------------------------------------------------------------------------------
-- TPWALK & MOVEMENT UTILITIES
--------------------------------------------------------------------------------
local tpwalkOn = false
local speed = 1

UtilityTab:CreateToggle({
   name = "TpWalk",
   currentValue = false,
   callback = function(value)
      tpwalkOn = value
   end,
})

UtilityTab:CreateSlider({
   name = "TpWalk Speed",
   range = {1, 10},
   increment = 1,
   suffix = "x",
   currentValue = 1,
   callback = function(value)
      speed = value
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
-- INVISIBILITY SYSTEMS (LEGACY & NEW DISAPPEAR)
--------------------------------------------------------------------------------
local invisOn = false
local invisTrack = nil
local originalIds = {}
local legacyNoclipConn = nil
local INVIS_ID = "rbxassetid://99789196955252"

local function stopInvisAnim()
	invisOn = false
	if legacyNoclipConn then
		legacyNoclipConn:Disconnect()
		legacyNoclipConn = nil
	end
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

	for _, v in ipairs(animateScript:GetDescendants()) do
		if v:IsA("Animation") then
			originalIds[v] = v.AnimationId
			v.AnimationId = INVIS_ID
		end
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local customAnim = Instance.new("Animation")
	customAnim.AnimationId = INVIS_ID

	invisTrack = animator:LoadAnimation(customAnim)
	invisTrack.Priority = Enum.AnimationPriority.Action4
	invisTrack.Looped = true
	invisTrack:Play()

	legacyNoclipConn = RS.Stepped:Connect(function()
		if not invisOn or not player.Character then return end
		for _, v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") and v.CanCollide and v.Name ~= "HumanoidRootPart" then
				v.CanCollide = false
			end
		end
	end)
end

player.CharacterAdded:Connect(function()
	if invisOn then
		task.wait(0.5)
		startInvisAnim()
	end
end)

UtilityTab:CreateToggle({
   name = "Legacy Invisibility",
   currentValue = false,
   callback = function(value)
      if value then
         startInvisAnim()
      else
         stopInvisAnim()
      end
   end,
})

--------------------------------------------------------------------------------
-- NEW INVISIBILITY (DISAPPEAR CORE) SYSTEM
--------------------------------------------------------------------------------
local noclip_connection = nil
local camera_connection = nil
local loadedanim = nil

local function ApplyInvisibility(bool)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")

	if bool == false then
		task.spawn(function()
			if hum then
				for _, v in next, hum:GetPlayingAnimationTracks() do
					v.Priority = Enum.AnimationPriority.Core
					v:AdjustSpeed(0)
					v:Stop(0)
				end
			end
		end)

		if noclip_connection then
			noclip_connection:Disconnect()
			noclip_connection = nil
		end

		if camera_connection then
			camera_connection:Disconnect()
			camera_connection = nil
			pcall(function()
				if hum then
					workspace.CurrentCamera.CameraSubject = hum
				end
			end)
		end
	else
		local function nocollision()
			local currentchar = player.Character
			if not currentchar then return end

			for _, v in pairs(currentchar:GetDescendants()) do
				if v:IsA("BasePart") and v.CanCollide and v.Name ~= "HumanoidRootPart" then
					v.CanCollide = false
				end
			end

			local root = currentchar:FindFirstChild("HumanoidRootPart")
			if root then
				root.CanCollide = true
			end
		end

		if noclip_connection then
			noclip_connection:Disconnect()
			noclip_connection = nil
		end
		noclip_connection = RS.Stepped:Connect(nocollision)

		if hrp then
			workspace.CurrentCamera.CameraSubject = hrp
			if camera_connection then
				camera_connection:Disconnect()
				camera_connection = nil
			end
			camera_connection = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
				if hrp then
					workspace.CurrentCamera.CameraSubject = hrp
				end
			end)
		end

		local Anim = Instance.new("Animation")
		Anim.AnimationId = "rbxassetid://105781160624925"

		if hum then
			loadedanim = hum:LoadAnimation(Anim)
			loadedanim.Priority = Enum.AnimationPriority.Action4

			repeat task.wait() until loadedanim.Length > 0
			loadedanim:Play()

			repeat task.wait() until loadedanim.IsPlaying
			loadedanim:AdjustSpeed(0)
			loadedanim.TimePosition = 0
		end
	end
end

UtilityTab:CreateToggle({
   name = "New Invisibility",
   currentValue = false,
   callback = function(value)
      ApplyInvisibility(value)
   end,
})

--------------------------------------------------------------------------------
-- SAVE PLACE / PLATFORM
--------------------------------------------------------------------------------
local savedPos = Vector3.new(-1119.03076171875, 894.944580078125, -85.89985656738281)
local platform

UtilityTab:CreateButton({
   name = "Save Place (Platform TP)",
   callback = function()
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
