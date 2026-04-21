local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--====================--
-- FLAGS
--====================--
local uiVisible = true
local menuOpen = false

local espPlayerOn = false
local espDoorOn = false
local espPCOn = false

local highlights = {}

--====================--
-- UTIL
--====================--
local function clearByTag(tag)
	for h, data in pairs(highlights) do
		if data.tag == tag then
			-- Ngắt kết nối các sự kiện để chống lag
			if data.conns then
				for _, conn in pairs(data.conns) do
					conn:Disconnect()
				end
			end
			if h and h.Parent then h:Destroy() end
			highlights[h] = nil
		end
	end
end

local function makeHighlight(parent, color, tag)
	if not parent then return nil end
	if parent:FindFirstChildOfClass("Highlight") then return nil end

	local h = Instance.new("Highlight")
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.35
	h.OutlineTransparency = 0
	h.Parent = parent

	highlights[h] = { tag = tag, conns = {} }
	return h
end

--====================--
-- BEAST CHECK
--====================--
local function isBeast(player)
	if not player.Character then return false end
	if player.Character:FindFirstChild("Beast") then return true end
	if player.Character:FindFirstChild("Hammer") then return true end
	if player.Backpack:FindFirstChild("Hammer") then return true end
	return false
end

--====================--
-- ESP FUNCTIONS
--====================--
local function togglePlayers()
	espPlayerOn = not espPlayerOn
	clearByTag("players")

	if not espPlayerOn then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			if isBeast(plr) then
				makeHighlight(plr.Character, Color3.fromRGB(255,0,0), "players")
			else
				makeHighlight(plr.Character, Color3.fromRGB(0,255,0), "players")
			end
		end
	end
end

local function toggleDoors()
	espDoorOn = not espDoorOn
	clearByTag("doors")

	if not espDoorOn then return end

	local count = 0
	for _, obj in pairs(Workspace:GetDescendants()) do
		count = count + 1
		if count % 500 == 0 then task.wait() end
		
		if obj:IsA("Model") then
			local name = obj.Name:lower()
			if name:find("door") and not name:find("exit") then
				makeHighlight(obj, Color3.fromRGB(255, 221, 0), "doors")
			end
		end
	end
end

local function togglePCs()
	espPCOn = not espPCOn
	clearByTag("pcs")

	if not espPCOn then return end

	local count = 0
	for _, obj in pairs(Workspace:GetDescendants()) do
		count = count + 1
		if count % 500 == 0 then task.wait() end
		
		if obj:IsA("Model") and obj.Name == "ComputerTable" then
			local screen = obj:FindFirstChild("Screen")
			if screen then
				local h = makeHighlight(obj, Color3.fromRGB(0,170,255), "pcs")
				if h then
					local function updatePCColor()
						if not h or not h.Parent then return end
						if screen.BrickColor.Name:lower():find("green") or (screen.Color.G > 0.5 and screen.Color.R < 0.4) then
							h.FillColor = Color3.fromRGB(0, 255, 0)
							h.OutlineColor = Color3.fromRGB(0, 255, 0)
						else
							h.FillColor = Color3.fromRGB(0, 170, 255)
							h.OutlineColor = Color3.fromRGB(0, 170, 255)
						end
					end
					
					updatePCColor()
					
					local conn1 = screen:GetPropertyChangedSignal("Color"):Connect(updatePCColor)
					local conn2 = screen:GetPropertyChangedSignal("BrickColor"):Connect(updatePCColor)
					
					table.insert(highlights[h].conns, conn1)
					table.insert(highlights[h].conns, conn2)
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		task.wait(1)
		if espPlayerOn and plr ~= LocalPlayer then
			if isBeast(plr) then
				makeHighlight(char, Color3.fromRGB(255,0,0), "players")
			else
				makeHighlight(char, Color3.fromRGB(0,255,0), "players")
			end
		end
	end)
end)

--====================--
-- UI SETUP (CoreGui)
--====================--
local guiParent
pcall(function()
	guiParent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
end)
if not guiParent then
	guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui", guiParent)
gui.Name = "FTF_HAX_V2"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local haxBox = Instance.new("TextButton", gui)
haxBox.Size = UDim2.fromOffset(65, 65)
haxBox.Position = UDim2.fromScale(0.9, 0.7)
haxBox.Text = "12zz"
haxBox.Font = Enum.Font.SourceSansBold
haxBox.TextSize = 22
haxBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
haxBox.TextColor3 = Color3.fromRGB(255, 0, 0)
haxBox.BorderSizePixel = 2
haxBox.BorderColor3 = Color3.fromRGB(0, 0, 0)

local dragging, dragInput, dragStart, startPos
haxBox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = haxBox.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
haxBox.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		haxBox.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local menu = Instance.new("Frame", gui)
menu.Size = UDim2.fromOffset(400, 250)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
menu.Visible = false
menu.BorderSizePixel = 2
menu.BorderColor3 = Color3.fromRGB(0, 0, 0)

local topBar = Instance.new("Frame", menu)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Main Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", topBar)
close.Size = UDim2.new(0, 40, 1, 0)
close.Position = UDim2.new(1, -40, 0, 0)
close.Text = "X"
close.TextSize = 24
close.Font = Enum.Font.SourceSansBold
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
close.BorderSizePixel = 0

local container = Instance.new("Frame", menu)
container.Size = UDim2.new(1, -20, 1, -55)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1

local grid = Instance.new("UIGridLayout", container)
grid.CellSize = UDim2.new(0.31, 0, 0.45, 0)
grid.CellPadding = UDim2.new(0.035, 0, 0.1, 0)

local function makeBtn(text)
	local b = Instance.new("TextButton", container)
	b.Text = text
	b.TextSize = 20
	b.Font = Enum.Font.SourceSansBold
	b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BorderSizePixel = 0
	return b
end

local espBtn = makeBtn("ESP Player")
local doorBtn = makeBtn("ESP Door")
local pcBtn = makeBtn("ESP PC")
local ghostBtn = makeBtn("Hide 12zz")

--====================--
-- CONTROL LOGIC
--====================--
local function updateBtnColor(btn, state)
	btn.BackgroundColor3 = state and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 60)
end

haxBox.MouseButton1Click:Connect(function()
	if not dragging then
		menuOpen = not menuOpen
		menu.Visible = menuOpen
	end
end)

close.MouseButton1Click:Connect(function()
	menuOpen = false
	menu.Visible = false
end)

espBtn.MouseButton1Click:Connect(function()
	togglePlayers()
	updateBtnColor(espBtn, espPlayerOn)
end)

doorBtn.MouseButton1Click:Connect(function()
	toggleDoors()
	updateBtnColor(doorBtn, espDoorOn)
end)

pcBtn.MouseButton1Click:Connect(function()
	togglePCs()
	updateBtnColor(pcBtn, espPCOn)
end)

local isGhostMode = false
ghostBtn.MouseButton1Click:Connect(function()
	isGhostMode = not isGhostMode
	updateBtnColor(ghostBtn, isGhostMode)
	
	if isGhostMode then
		haxBox.BackgroundTransparency = 1
		haxBox.TextTransparency = 1
		haxBox.BorderSizePixel = 0
	else
		haxBox.BackgroundTransparency = 0
		haxBox.TextTransparency = 0
		haxBox.BorderSizePixel = 2
	end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	-- Bật tắt UI bằng phím M
	if input.KeyCode == Enum.KeyCode.M then
		uiVisible = not uiVisible
		gui.Enabled = uiVisible
	end
	
	-- Ctrl + Z để tắt toàn bộ ESP
	if input.KeyCode == Enum.KeyCode.Z and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
		espPlayerOn = false
		espDoorOn = false
		espPCOn = false
		
		clearByTag("players")
		clearByTag("doors")
		clearByTag("pcs")
		
		updateBtnColor(espBtn, espPlayerOn)
		updateBtnColor(doorBtn, espDoorOn)
		updateBtnColor(pcBtn, espPCOn)
	end
end)