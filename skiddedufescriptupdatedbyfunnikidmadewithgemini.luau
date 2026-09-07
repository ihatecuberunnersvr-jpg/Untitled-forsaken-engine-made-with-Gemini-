--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera

--// GUI SETUP
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "UtilityGui"
gui.ResetOnSpawn = false

--// MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 400)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

--// MINI BUTTON
local mini = Instance.new("TextButton", gui)
mini.Size = UDim2.new(0, 40, 0, 40)
mini.Position = frame.Position
mini.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mini.Text = "GUI"
mini.TextColor3 = Color3.new(1, 1, 1)
mini.Visible = false
mini.Active = true
mini.Draggable = true

local minicorner = Instance.new("UICorner", mini)
minicorner.CornerRadius = UDim.new(1, 0)

--// TOP BAR
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1, 0, 0, 30)
top.BackgroundTransparency = 1

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.Text = "UFE hub ezzzzz"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local minimize = Instance.new("TextButton", top)
minimize.Size = UDim2.new(0, 30, 1, 0)
minimize.Position = UDim2.new(1, -30, 0, 0)
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

minimize.MouseButton1Click:Connect(function()
    frame.Visible = false
    mini.Visible = true
    mini.Position = frame.Position
end)

mini.MouseButton1Click:Connect(function()
    frame.Visible = true
    mini.Visible = false
end)

--// HOLDER (CONTAINER FOR BUTTONS)
local holder = Instance.new("Frame", frame)
holder.Position = UDim2.new(0, 0, 0, 30)
holder.Size = UDim2.new(1, 0, 1, -30)
holder.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", holder)
layout.Padding = UDim.new(0, 6)

local function makeButton(text)
    local b = Instance.new("TextButton", holder)
    b.Size = UDim2.new(1, -10, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = text
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    local c = Instance.new("UICorner", b)
    c.CornerRadius = UDim.new(0, 8)
    return b
end

--------------------------------------------------------------------------------
-- 2D BLUE BOX ESP
--------------------------------------------------------------------------------
local espOn = false
local espButton = makeButton("ESP: OFF")
local espFolder = Instance.new("Folder", gui)
espFolder.Name = "ESP2DFolder"

local function create2DESP(plr)
    if plr == player then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = plr.Name .. "_2DESP"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(3.5, 0, 5, 0)
    bill.ClipsDescendants = false

    local box = Instance.new("Frame", bill)
    box.Size = UDim2.new(1, 0, 1, 0)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = Color3.fromRGB(0, 150, 255)

    local label = Instance.new("TextLabel", bill)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, -0.25, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14

    local connection
    local function attachToChar(char)
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not root or not hum then return end

        bill.Adornee = root
        bill.Parent = espFolder

        if connection then connection:Disconnect() end
        connection = RS.RenderStepped:Connect(function()
            if not espOn or not char:IsDescendantOf(workspace) or hum.Health <= 0 then
                bill.Enabled = false
            else
                bill.Enabled = true
                label.Text = plr.Name .. " | " .. math.floor(hum.Health) .. " HP"
            end
        end)
    end

    if plr.Character then attachToChar(plr.Character) end
    plr.CharacterAdded:Connect(attachToChar)
end

espButton.MouseButton1Click:Connect(function()
    espOn = not espOn
    espButton.Text = espOn and "ESP: ON" or "ESP: OFF"
    espFolder:ClearAllChildren()

    if espOn then
        for _, p in ipairs(Players:GetPlayers()) do
            create2DESP(p)
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if espOn then create2DESP(p) end
end)

--------------------------------------------------------------------------------
-- CAMLOCK FUNCTIONALITY
--------------------------------------------------------------------------------
local ACTIVATION_DISTANCE = 80 
local DROP_DISTANCE = 200      
local CAMERA_OFFSET = Vector3.new(0, 4.5, 10) 

local currentTarget = nil
local isLocked = false
local camlockBtn = makeButton("CamLock: OFF")

local function getPlayerInCameraView()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myRoot = character.HumanoidRootPart
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
    camlockBtn.Text = "CamLock: OFF"
    camlockBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
end

local function enableLock(targetPlayerChar)
    currentTarget = targetPlayerChar
    isLocked = true

    camlockBtn.Text = "CamLock: ON"
    camlockBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)

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

camlockBtn.MouseButton1Click:Connect(function()
    if isLocked then
        disableLock()
    else
        local target = getPlayerInCameraView()
        if target then
            enableLock(target)
        else
            camlockBtn.Text = "NO TARGET IN VIEW"
            camlockBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            task.wait(1)
            if not isLocked then
                camlockBtn.Text = "CamLock: OFF"
                camlockBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- AUTO ABILITIES (JASON ABILITIES AUTO-CAST)
--------------------------------------------------------------------------------
local autoAbilitiesOn = false
local autoAbilitiesBtn = makeButton("auto abilitys (WORKING IN PROCESS)")

local v_u_6 = player.Character or player.CharacterAdded:Wait()
local v_u_7 = v_u_6:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(char)
	v_u_6 = char
	v_u_7 = char:WaitForChild("Humanoid")
end)

local MAX_AUTO_DISTANCE = 15

local jasonFolder = ReplicatedStorage:WaitForChild("CharacterAbilities", 5) and ReplicatedStorage.CharacterAbilities:FindFirstChild("Jason")
local v_u_10 = {
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

local AUTO_CAST_ABILITIES = { "MainAbility", "AltAbility1", "AltAbility2" }
local v_u_13 = false

local function canUseAbility()
	if v_u_6 and v_u_6:GetAttribute("Character") == "Jason" and (v_u_6:GetAttribute("CanAttack") ~= false and (v_u_6:GetAttribute("Emoting") ~= true and v_u_6:GetAttribute("AbilitiesDisabled") ~= true)) then
		return v_u_7.Health > 0
	end
	return false
end

local function getClosestPlayerForAbility()
	local closestChar = nil
	local shortestDistance = math.huge
	local myRoot = v_u_6 and v_u_6:FindFirstChild("HumanoidRootPart")

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
	local myRoot = v_u_6:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

	if myRoot and targetRoot then
		local targetPos = Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetPos)
	end
end

local function castAbility(abilityName)
	if v_u_13 or not canUseAbility() then return end
	local abilityData = v_u_10[abilityName]
	if abilityData and abilityData.Remote then
		local now = os.clock()
		if now - abilityData.LastUsed >= abilityData.Cooldown then
			v_u_13 = true
			abilityData.LastUsed = now
			abilityData.Remote:FireServer()
			task.delay(0.05, function()
				v_u_13 = false
			end)
		end
	end
end

RS.Heartbeat:Connect(function()
	if autoAbilitiesOn and canUseAbility() then
		local closestChar, distance = getClosestPlayerForAbility()
		if closestChar and distance <= MAX_AUTO_DISTANCE then
			aimAtTarget(closestChar)
			for _, abilityName in ipairs(AUTO_CAST_ABILITIES) do
				local data = v_u_10[abilityName]
				if data and (os.clock() - data.LastUsed >= data.Cooldown) then
					castAbility(abilityName)
				end
			end
		end
	end
end)

autoAbilitiesBtn.MouseButton1Click:Connect(function()
	autoAbilitiesOn = not autoAbilitiesOn
	if autoAbilitiesOn then
		autoAbilitiesBtn.Text = "Auto Abilities: ON"
		autoAbilitiesBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	else
		autoAbilitiesBtn.Text = "auto abilitys (WORKING IN PROCESS)"
		autoAbilitiesBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end
end)

--------------------------------------------------------------------------------
-- AUTO SLASH SHEDLETSKY
--------------------------------------------------------------------------------
local autoShedletskyOn = false
local autoShedletskyBtn = makeButton("auto slash shedletsky")

local MAX_SLASH_DISTANCE = 15
local shedFolder = ReplicatedStorage:WaitForChild("CharacterAbilities", 5) and ReplicatedStorage.CharacterAbilities:FindFirstChild("Shedletsky")

local shedAbilities = {
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

local shedBusy = false

local function canUseShedletsky()
	if v_u_6 and v_u_6:GetAttribute("Character") == "Shedletsky" and (v_u_6:GetAttribute("CanRun") ~= false and (v_u_6:GetAttribute("CanAttack") ~= false and (v_u_6:GetAttribute("Emoting") ~= true and v_u_6:GetAttribute("AbilitiesDisabled") ~= true))) then
		return v_u_7.Health > 0
	end
	return false
end

local function playShedletskyAnim()
	local anim = Instance.new("Animation")
	local skin = v_u_6:GetAttribute("Skin")
	local actualSkin = v_u_6:GetAttribute("ActualSkin")

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

	local track = v_u_7:LoadAnimation(anim)
	track:Play()

	local hitConn
	hitConn = v_u_6:GetAttributeChangedSignal("HitSlash"):Connect(function()
		if v_u_6:GetAttribute("HitSlash") and skin ~= "Blega" then
			track:Stop()
			local hitAnim = Instance.new("Animation")
			hitAnim.AnimationId = "rbxassetid://104029412142861"
			v_u_7:LoadAnimation(hitAnim):Play()
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

autoShedletskyBtn.MouseButton1Click:Connect(function()
	autoShedletskyOn = not autoShedletskyOn
	if autoShedletskyOn then
		autoShedletskyBtn.Text = "Auto Slash Shedletsky: ON"
		autoShedletskyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	else
		autoShedletskyBtn.Text = "auto slash shedletsky"
		autoShedletskyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end
end)

--------------------------------------------------------------------------------
-- TPWALK & SPEED
--------------------------------------------------------------------------------
local tpwalkOn = false
local speed = 1
local tpwalkButton = makeButton("TpWalk: OFF")

tpwalkButton.MouseButton1Click:Connect(function()
    tpwalkOn = not tpwalkOn
    tpwalkButton.Text = tpwalkOn and "TpWalk: ON" or "TpWalk: OFF"
end)

local slider = makeButton("Speed: 1")
slider.MouseButton1Click:Connect(function()
    speed += 1
    if speed > 10 then speed = 1 end
    slider.Text = "Speed: "..speed
end)

RS.RenderStepped:Connect(function()
    if tpwalkOn then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local hrp = char.HumanoidRootPart
            local move = char.Humanoid.MoveDirection
            hrp.CFrame = hrp.CFrame + (move * speed)
        end
    end
end)

--------------------------------------------------------------------------------
-- TELEPORT TO SAVED POSITION + PLATFORM
--------------------------------------------------------------------------------
local savedPos = Vector3.new(-1119.03076171875, 894.944580078125, -85.89985656738281)
local platform
local posButton = makeButton("Save Place")

posButton.MouseButton1Click:Connect(function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not platform then
        platform = Instance.new("Part")
        platform.Size = Vector3.new(60,5,60)
        platform.Position = savedPos
        platform.Anchored = true
        platform.Color = Color3.fromRGB(120,120,120)
        platform.Material = Enum.Material.SmoothPlastic
        platform.Name = "SafePlatform"
        platform.Parent = workspace
    end

    hrp.CFrame = CFrame.new(savedPos + Vector3.new(0,6,0))
end)

