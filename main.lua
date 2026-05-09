local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local running = true
local ESPPlayerToggle = false
local ESPLootToggle = false
local OpenCloseButton = Enum.KeyCode.LeftControl

local SlapRoyaleID = 9431156611

if game.PlaceId ~= SlapRoyaleID then
	script:Destroy()
	return
end

local ZircellFrame = nil
local IsTwenningZircellFrame = false
local rebindConnections = {}

local GloveNames = {}
pcall(function()
	for _, glove in ipairs(ReplicatedStorage.Gloves:GetChildren()) do
		GloveNames[glove.Name] = true
	end
end)

local function round(n)
	return math.floor(n + 0.5)
end

local function FormatNumber(n: number, doRound: boolean)
	if doRound then n = round(n) end

	local str = tostring(n):gsub("%.", ",")
	local intPart, fracPart = str:match("^(%-?%d+)(,?%d*)")
	if not intPart then return str end

	local result = ""
	while #intPart > 3 do
		result = "." .. intPart:sub(-3) .. result
		intPart = intPart:sub(1, -4)
	end
	result = intPart .. result

	if fracPart and fracPart ~= "" and fracPart ~= "," then
		result = result .. fracPart
	end

	return result
end

local function GetCode()
	local map = workspace:FindFirstChild("Map")
	if not map then return "Error" end
	local codeBrick = map:FindFirstChild("CodeBrick")
	if not codeBrick then return "Error" end
	local surfaceGui = codeBrick:FindFirstChild("SurfaceGui")
	if not surfaceGui or not surfaceGui:FindFirstChild("IMGTemplate") then
		return "Error"
	end

	local templates = {}
	for _, v in ipairs(surfaceGui:GetChildren()) do
		if v.Name == "IMGTemplate" then
			table.insert(templates, v)
		end
	end
	table.sort(templates, function(a, b)
		return a.AbsolutePosition.y < b.AbsolutePosition.y
	end)

	local code = {}
	for _, v in ipairs(templates) do
		if v.Image == "http://www.roblox.com/asset/?id=9648769161" then
			table.insert(code, "4")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648765536" then
			table.insert(code, "2")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648762863" then
			table.insert(code, "3")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648759883" then
			table.insert(code, "9")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648755440" then
			table.insert(code, "8")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648752438" then
			table.insert(code, "2")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648749145" then
			table.insert(code, "8")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648745618" then
			table.insert(code, "3")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648742013" then
			table.insert(code, "7")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648738553" then
			table.insert(code, "8")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648734698" then
			table.insert(code, "2")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648730082" then
			table.insert(code, "6")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648723237" then
			table.insert(code, "3")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648718450" then
			table.insert(code, "6")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648715920" then
			table.insert(code, "6")
		elseif v.Image == "http://www.roblox.com/asset/?id=9648712563" then
			table.insert(code, "2")
		end
	end
	return table.concat(code)
end

local function CreateHL(char: Model)
	local plr: Player = game.Players:GetPlayerFromCharacter(char)
	if not plr or plr == player then return end
	if not char or char == player.Character then return end

	local humanoid: Humanoid = char:FindFirstChild("Humanoid")
	local hrp: BasePart = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	if char:FindFirstChild("Zircell_Highlight") then
		char.Zircell_Highlight:Destroy()
	end
	if hrp:FindFirstChild("Zircell_Billboard") then
		hrp.Zircell_Billboard:Destroy()
	end

	local hl = Instance.new("Highlight")
	hl.Name = "Zircell_Highlight"
	hl.FillColor = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(150, 0, 0)
	hl.FillTransparency = 0.5
	hl.Parent = char

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Zircell_Billboard"
	billboard.Size = UDim2.new(7, 0, 7, 0)
	billboard.Active = true
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 300
	billboard.ResetOnSpawn = false
	billboard.StudsOffset = Vector3.new(7, 0, 0)
	billboard.Parent = hrp

	local uilist = Instance.new("UIListLayout")
	uilist.Padding = UDim.new(0.05, 0)
	uilist.FillDirection = Enum.FillDirection.Vertical
	uilist.SortOrder = Enum.SortOrder.LayoutOrder
	uilist.Parent = billboard

	local function CreateFrame(name, lo, size)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.LayoutOrder = lo
		frame.BackgroundTransparency = 1
		frame.Active = false
		frame.BorderSizePixel = 0
		frame.Size = size
		frame.Parent = billboard
		return frame
	end

	local function CreateUIStroke(thickness, color, parent)
		local uistroke = Instance.new("UIStroke")
		uistroke.Color = color
		uistroke.Thickness = thickness or 2
		uistroke.Parent = parent
		return uistroke
	end

	local function CreateTextLabel(name, text, size, pos, color, parent, lo)
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = name
		textLabel.LayoutOrder = lo or 0
		textLabel.BackgroundTransparency = 1
		textLabel.Active = false
		textLabel.BorderSizePixel = 0
		textLabel.Size = size
		textLabel.Position = pos
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.Text = text
		textLabel.TextColor3 = color
		textLabel.TextScaled = true
		textLabel.TextWrapped = true
		textLabel.Parent = parent
		return textLabel
	end

	local function CreateUIGrid(cellPadding, cellSize, parent)
		local uigrid = Instance.new("UIGridLayout")
		uigrid.CellPadding = cellPadding
		uigrid.CellSize = cellSize
		uigrid.FillDirection = Enum.FillDirection.Horizontal
		uigrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uigrid.VerticalAlignment = Enum.VerticalAlignment.Center
		uigrid.SortOrder = Enum.SortOrder.LayoutOrder
		uigrid.StartCorner = Enum.StartCorner.TopLeft
		uigrid.Parent = parent
		return uigrid
	end

	local statsFrame = CreateFrame("Stats", 2, UDim2.new(1, 0, 0.3, 0))
	local equippedFrame = CreateFrame("Equipped", 1, UDim2.new(1, 0, 0.2, 0))
	local inventoryFrame = CreateFrame("Inventory", 3, UDim2.new(1, 0, 0.3, 0))

	CreateUIStroke(2, Color3.fromRGB(255, 255, 255), statsFrame)
	CreateUIStroke(2, Color3.fromRGB(255, 255, 255), equippedFrame)
	CreateUIStroke(2, Color3.fromRGB(255, 255, 255), inventoryFrame)
	CreateUIGrid(UDim2.new(0.025, 0, 0.025, 0), UDim2.new(0.4, 0, 0.4, 0), statsFrame)

	local equippedText = CreateTextLabel("Equipped", "Equipped: Glove Name", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 255, 255), equippedFrame)
	local inventoryText = CreateTextLabel("Inventory", "Backpack: ...", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 255, 255), inventoryFrame)
	local jumpText = CreateTextLabel("Jump", "Jump: 0", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), Color3.fromRGB(255, 255, 255), statsFrame, 1)
	local speedText = CreateTextLabel("Speed", "Speed: 0", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 0, 0), Color3.fromRGB(255, 255, 255), statsFrame, 2)
	local healthText = CreateTextLabel("Health", "Health: 0", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 255, 255), statsFrame, 4)
	local distanceText = CreateTextLabel("Distance", "Distance: 0", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(255, 255, 255), statsFrame, 5)
	local slapsText = CreateTextLabel("Slaps", "Slaps: 0", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 255, 255), statsFrame, 3)

	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), equippedText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), inventoryText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), jumpText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), speedText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), healthText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), distanceText)
	CreateUIStroke(2, Color3.fromRGB(0, 0, 0), slapsText)
end

local function RemoveHL(char)
	if char and char:FindFirstChild("Zircell_Highlight") then
		char.Zircell_Highlight:Destroy()
	end
	if char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("Zircell_Billboard") then
		char.HumanoidRootPart.Zircell_Billboard:Destroy()
	end
end

local function CreateLootHL(loot)
	if not loot or not (loot:IsA("Tool") or loot:IsA("Model")) then return end
	local handle = loot:FindFirstChild("Handle")
	if not handle then return end

	if loot:FindFirstChild("Zircell_Highlight_Loot") then
		loot.Zircell_Highlight_Loot:Destroy()
	end
	if handle:FindFirstChild("Zircell_Billboard_Loot") then
		handle.Zircell_Billboard_Loot:Destroy()
	end

	local hl = Instance.new("Highlight")
	hl.Name = "Zircell_Highlight_Loot"
	hl.FillColor = Color3.fromRGB(0, 0, 255)
	hl.OutlineColor = Color3.fromRGB(0, 0, 150)
	hl.FillTransparency = 0.5
	hl.Parent = loot

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Zircell_Billboard_Loot"
	billboard.Size = UDim2.new(5, 0, 3, 0)
	billboard.Active = true
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 500
	billboard.ResetOnSpawn = false
	billboard.Parent = handle

	local textLabelName = Instance.new("TextLabel", billboard)
	textLabelName.Name = "NameLabel"
	textLabelName.Size = UDim2.new(1, 0, 0.5, 0)
	textLabelName.Text = loot.Name
	textLabelName.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabelName.TextScaled = true
	textLabelName.Font = Enum.Font.FredokaOne
	textLabelName.TextXAlignment = Enum.TextXAlignment.Center
	textLabelName.TextYAlignment = Enum.TextYAlignment.Center
	textLabelName.FontFace.Weight = Enum.FontWeight.Bold

	local stroke1 = Instance.new("UIStroke", textLabelName)
	stroke1.Color = Color3.fromRGB(0, 0, 0)
	stroke1.Thickness = 2

	local textLabelD = Instance.new("TextLabel", billboard)
	textLabelD.Name = "DistanceLabel"
	textLabelD.Size = UDim2.new(1, 0, 0.5, 0)
	textLabelD.Position = UDim2.new(0, 0, 0.5, 0)
	textLabelD.Text = FormatNumber((handle.Position - workspace.Camera.CFrame.Position).Magnitude, true)
	textLabelD.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabelD.TextScaled = true
	textLabelD.Font = Enum.Font.FredokaOne
	textLabelD.TextXAlignment = Enum.TextXAlignment.Center
	textLabelD.TextYAlignment = Enum.TextYAlignment.Center
	textLabelD.FontFace.Weight = Enum.FontWeight.Bold

	local stroke2 = Instance.new("UIStroke", textLabelD)
	stroke2.Color = Color3.fromRGB(0, 0, 0)
	stroke2.Thickness = 2
end

local function RemoveLootHL(loot)
	if not loot then return end
	if loot:FindFirstChild("Zircell_Highlight_Loot") then
		loot.Zircell_Highlight_Loot:Destroy()
	end
	local handle = loot:FindFirstChild("Handle")
	if handle and handle:FindFirstChild("Zircell_Billboard_Loot") then
		handle.Zircell_Billboard_Loot:Destroy()
	end
end

local function SetupGui()
	if player.PlayerGui:FindFirstChild("ZircellGui") then
		player.PlayerGui.ZircellGui:Destroy()
	end

	local gui = Instance.new("ScreenGui", player.PlayerGui)
	gui.Name = "ZircellGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.new(0.2, 0, 0.5, 0)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.2, 0, 0.5, 0)
	ZircellFrame = frame

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0.1, 0)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Text = "Alpha Zircell"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.FontFace.Weight = Enum.FontWeight.Bold

	local utilities = Instance.new("ScrollingFrame", frame)
	utilities.Size = UDim2.new(1, 0, 0.9, 0)
	utilities.Position = UDim2.new(0, 0, 0.1, 0)
	utilities.CanvasSize = UDim2.new(0, 0, 0, 0)
	utilities.ScrollBarThickness = 10
	utilities.BackgroundTransparency = 1
	utilities.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	utilities.ScrollBarImageTransparency = 0.5
	utilities.Active = true
	utilities.Selectable = true
	utilities.ScrollingDirection = Enum.ScrollingDirection.Y
	utilities.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local uiListLayout = Instance.new("UIListLayout", utilities)
	uiListLayout.Padding = UDim.new(0, 5)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	uiListLayout.FillDirection = Enum.FillDirection.Vertical

	Instance.new("UIPadding", utilities).PaddingTop = UDim.new(0, 0)

	local closeFrame = Instance.new("Frame", utilities)
	closeFrame.Size = UDim2.new(0.95, 0, 0.1, 0)
	closeFrame.BackgroundTransparency = 1
	closeFrame.LayoutOrder = 0

	local closeText = Instance.new("TextLabel", closeFrame)
	closeText.Size = UDim2.new(0.7, 0, 1, 0)
	closeText.Text = "Open/Close Button"
	closeText.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeText.TextScaled = true
	closeText.BackgroundTransparency = 1
	closeText.Font = Enum.Font.FredokaOne
	closeText.FontFace.Weight = Enum.FontWeight.Bold

	local closeButton = Instance.new("TextButton", closeFrame)
	closeButton.Size = UDim2.new(0.3, 0, 1, 0)
	closeButton.Position = UDim2.new(0.7, 0, 0, 0)
	closeButton.Text = "LeftControl"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.BackgroundTransparency = 1
	closeButton.Font = Enum.Font.FredokaOne
	closeButton.FontFace.Weight = Enum.FontWeight.Bold

	local function startRebind()
		if rebindConnections["OCB"] then
			rebindConnections["OCB"]:Disconnect()
			rebindConnections["OCB"] = nil
		end
		closeButton.Text = "Press a key..."
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 0)
		rebindConnections["OCB"] = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				OpenCloseButton = input.KeyCode
				closeButton.Text = input.KeyCode.Name
				closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				if rebindConnections["OCB"] then
					rebindConnections["OCB"]:Disconnect()
					rebindConnections["OCB"] = nil
				end
			end
		end)
	end
	closeButton.Activated:Connect(startRebind)

	local espFrame = Instance.new("Frame", utilities)
	espFrame.Size = UDim2.new(0.95, 0, 0.1, 0)
	espFrame.BackgroundTransparency = 1
	espFrame.LayoutOrder = 6

	local espText = Instance.new("TextLabel", espFrame)
	espText.Size = UDim2.new(0.7, 0, 1, 0)
	espText.Text = "Player ESP"
	espText.TextColor3 = Color3.fromRGB(255, 255, 255)
	espText.TextScaled = true
	espText.BackgroundTransparency = 1
	espText.Font = Enum.Font.FredokaOne
	espText.FontFace.Weight = Enum.FontWeight.Bold

	local espButton = Instance.new("TextButton", espFrame)
	espButton.Size = UDim2.new(0.3, 0, 1, 0)
	espButton.Position = UDim2.new(0.7, 0, 0, 0)
	espButton.Text = "False"
	espButton.TextColor3 = Color3.fromRGB(255, 0, 0)
	espButton.TextScaled = true
	espButton.BackgroundTransparency = 1
	espButton.Font = Enum.Font.FredokaOne
	espButton.FontFace.Weight = Enum.FontWeight.Bold

	espButton.Activated:Connect(function()
		ESPPlayerToggle = not ESPPlayerToggle
		if ESPPlayerToggle then
			espButton.Text = "True"
			espButton.TextColor3 = Color3.fromRGB(0, 255, 0)
			for _, plr in pairs(Players:GetPlayers()) do
				if plr.Character then
					CreateHL(plr.Character)
				end
			end
		else
			espButton.Text = "False"
			espButton.TextColor3 = Color3.fromRGB(255, 0, 0)
			for _, plr in pairs(Players:GetPlayers()) do
				if plr.Character then
					RemoveHL(plr.Character)
				end
			end
		end
	end)

	local espLootFrame = Instance.new("Frame", utilities)
	espLootFrame.Size = UDim2.new(0.95, 0, 0.1, 0)
	espLootFrame.BackgroundTransparency = 1
	espLootFrame.LayoutOrder = 7

	local espLootText = Instance.new("TextLabel", espLootFrame)
	espLootText.Size = UDim2.new(0.7, 0, 1, 0)
	espLootText.Text = "Loot ESP"
	espLootText.TextColor3 = Color3.fromRGB(255, 255, 255)
	espLootText.TextScaled = true
	espLootText.BackgroundTransparency = 1
	espLootText.Font = Enum.Font.FredokaOne
	espLootText.FontFace.Weight = Enum.FontWeight.Bold

	local espLootButton = Instance.new("TextButton", espLootFrame)
	espLootButton.Size = UDim2.new(0.3, 0, 1, 0)
	espLootButton.Position = UDim2.new(0.7, 0, 0, 0)
	espLootButton.Text = "False"
	espLootButton.TextColor3 = Color3.fromRGB(255, 0, 0)
	espLootButton.TextScaled = true
	espLootButton.BackgroundTransparency = 1
	espLootButton.Font = Enum.Font.FredokaOne
	espLootButton.FontFace.Weight = Enum.FontWeight.Bold

	espLootButton.Activated:Connect(function()
		ESPLootToggle = not ESPLootToggle
		local itemsFolder = workspace:FindFirstChild("Items")
		if not itemsFolder then return end

		if ESPLootToggle then
			espLootButton.Text = "True"
			espLootButton.TextColor3 = Color3.fromRGB(0, 255, 0)
			for _, loot in ipairs(itemsFolder:GetChildren()) do
				CreateLootHL(loot)
			end
		else
			espLootButton.Text = "False"
			espLootButton.TextColor3 = Color3.fromRGB(255, 0, 0)
			for _, loot in ipairs(itemsFolder:GetChildren()) do
				RemoveLootHL(loot)
			end
		end
	end)

	local getCodeFrame = Instance.new("Frame", utilities)
	getCodeFrame.Size = UDim2.new(0.95, 0, 0.1, 0)
	getCodeFrame.BackgroundTransparency = 1
	getCodeFrame.LayoutOrder = 8

	local getCodeText = Instance.new("TextLabel", getCodeFrame)
	getCodeText.Size = UDim2.new(0.7, 0, 1, 0)
	getCodeText.Text = "Bunker Code"
	getCodeText.TextColor3 = Color3.fromRGB(255, 255, 255)
	getCodeText.TextScaled = true
	getCodeText.BackgroundTransparency = 1
	getCodeText.Font = Enum.Font.FredokaOne
	getCodeText.FontFace.Weight = Enum.FontWeight.Bold

	local getCodeButton = Instance.new("TextButton", getCodeFrame)
	getCodeButton.Size = UDim2.new(0.3, 0, 1, 0)
	getCodeButton.Position = UDim2.new(0.7, 0, 0, 0)
	getCodeButton.Text = "Get"
	getCodeButton.TextColor3 = Color3.fromRGB(0, 255, 0)
	getCodeButton.TextScaled = true
	getCodeButton.BackgroundTransparency = 1
	getCodeButton.Font = Enum.Font.FredokaOne
	getCodeButton.FontFace.Weight = Enum.FontWeight.Bold

	getCodeButton.Activated:Connect(function()
		local code = GetCode()
		if code then
			getCodeButton.Text = code
			getCodeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			getCodeButton.Text = "Error"
			getCodeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
		end
	end)

	local destroyFrame = Instance.new("Frame", utilities)
	destroyFrame.Size = UDim2.new(0.95, 0, 0.1, 0)
	destroyFrame.BackgroundTransparency = 1
	destroyFrame.LayoutOrder = 9

	local destroyText = Instance.new("TextLabel", destroyFrame)
	destroyText.Size = UDim2.new(0.7, 0, 1, 0)
	destroyText.Text = "Destroy Script"
	destroyText.TextColor3 = Color3.fromRGB(255, 255, 255)
	destroyText.TextScaled = true
	destroyText.BackgroundTransparency = 1
	destroyText.Font = Enum.Font.FredokaOne
	destroyText.FontFace.Weight = Enum.FontWeight.Bold

	local destroyButton = Instance.new("TextButton", destroyFrame)
	destroyButton.Size = UDim2.new(0.3, 0, 1, 0)
	destroyButton.Position = UDim2.new(0.7, 0, 0, 0)
	destroyButton.Text = "Destroy"
	destroyButton.TextColor3 = Color3.fromRGB(0, 255, 0)
	destroyButton.TextScaled = true
	destroyButton.BackgroundTransparency = 1
	destroyButton.Font = Enum.Font.FredokaOne
	destroyButton.FontFace.Weight = Enum.FontWeight.Bold

	destroyButton.Activated:Connect(function()
		running = false
		ESPPlayerToggle = false
		ESPLootToggle = false
		local itemsFolder = workspace:FindFirstChild("Items")
		if not itemsFolder then return end
		for _, loot in ipairs(itemsFolder:GetChildren()) do
			RemoveLootHL(loot)
		end
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character then
				RemoveHL(plr.Character)
			end
		end
		if player.PlayerGui:FindFirstChild("ZircellGui") then
			player.PlayerGui.ZircellGui:Destroy()
		end
		script:Destroy()
	end)
end

local function UpdateHL(char)
	local plr: Player = game.Players:GetPlayerFromCharacter(char)
	if not plr or plr == player then return end
	if not char or char == player.Character then return end

	local humanoid: Humanoid = char:FindFirstChild("Humanoid")
	local hrp: BasePart = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	if not char:FindFirstChild("Zircell_Highlight") or not hrp:FindFirstChild("Zircell_Billboard") then
		CreateHL(char)
		return
	end

	local billboard = hrp:FindFirstChild("Zircell_Billboard")
	local statsFrame = billboard:FindFirstChild("Stats")
	local equippedFrame = billboard:FindFirstChild("Equipped")
	local inventoryFrame = billboard:FindFirstChild("Inventory")
	if not statsFrame or not equippedFrame or not inventoryFrame then return end

	local equippedText = equippedFrame:FindFirstChild("Equipped")
	local inventoryText = inventoryFrame:FindFirstChild("Inventory")
	local jumpText = statsFrame:FindFirstChild("Jump")
	local speedText = statsFrame:FindFirstChild("Speed")
	local slapsText = statsFrame:FindFirstChild("Slaps")
	local distanceText = statsFrame:FindFirstChild("Distance")
	local healthText = statsFrame:FindFirstChild("Health")

	local gloveObj = plr:FindFirstChild("Glove")
	local gloveValue = gloveObj and gloveObj.Value or "None"
	if equippedText and equippedText.Text ~= "Equipped: " .. gloveValue then
		equippedText.Text = "Equipped: " .. gloveValue
	end

	local slapsObj = plr:FindFirstChild("Slaps")
	local slapsValue = slapsObj and FormatNumber(slapsObj.Value, true) or "0"
	if slapsText and slapsText.Text ~= "Slaps: " .. slapsValue then
		slapsText.Text = "Slaps: " .. slapsValue
	end

	local dist = (workspace.Camera.CFrame.Position - hrp.Position).Magnitude
	local dStr = FormatNumber(dist, true)
	if distanceText and distanceText.Text ~= "Distance: " .. dStr then
		distanceText.Text = "Distance: " .. dStr
	end

	local hStr = FormatNumber(humanoid.Health, true)
	local mStr = FormatNumber(humanoid.MaxHealth, true)
	if healthText and healthText.Text ~= "Health: " .. hStr .. "/" .. mStr then
		healthText.Text = "Health: " .. hStr .. "/" .. mStr
	end

	local spdStr = FormatNumber(humanoid.WalkSpeed, true)
	if speedText and speedText.Text ~= "Speed: " .. spdStr then
		speedText.Text = "Speed: " .. spdStr
	end

	local jmpStr = FormatNumber(humanoid.JumpPower, true)
	if jumpText and jumpText.Text ~= "Jump: " .. jmpStr then
		jumpText.Text = "Jump: " .. jmpStr
	end

	if inventoryText then
		local itemCounts = {}
		for _, tool in ipairs(plr.Backpack:GetChildren()) do
			if tool:IsA("Tool") and not GloveNames[tool.Name] then
				itemCounts[tool.Name] = (itemCounts[tool.Name] or 0) + 1
			end
		end
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and not GloveNames[tool.Name] then
				itemCounts[tool.Name] = (itemCounts[tool.Name] or 0) + 1
			end
		end

		local parts = {}
		for name, count in pairs(itemCounts) do
			table.insert(parts, count > 1 and name .. " (x" .. count .. ")" or name)
		end
		table.sort(parts)

		local text = #parts > 0 and table.concat(parts, ", ") or "Empty"
		if inventoryText.Text ~= "Backpack: " .. text then
			inventoryText.Text = "Backpack: " .. text
		end
	end
end

local function CloseZircellFrame()
	if IsTwenningZircellFrame then return end
	local tween1 = TweenService:Create(ZircellFrame, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0)})
	local tween2 = TweenService:Create(ZircellFrame, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0.2,0,0.5,0)})
	if ZircellFrame.Visible then
		IsTwenningZircellFrame = true
		tween1:Play()
		tween1.Completed:Connect(function()
			ZircellFrame.Visible = false
			IsTwenningZircellFrame = false
		end)
	else
		IsTwenningZircellFrame = true
		ZircellFrame.Visible = true
		tween2:Play()
		tween2.Completed:Connect(function()
			IsTwenningZircellFrame = false
		end)
	end
end

SetupGui()
task.spawn(function()
	while true do
		if not running then break end
		if ESPPlayerToggle then
			for _, plr in ipairs(Players:GetPlayers()) do
				UpdateHL(plr.Character)
			end
		end
	
		if ESPLootToggle then
			local itemsFolder = workspace:FindFirstChild("Items")
			if itemsFolder then
				for _, loot in ipairs(itemsFolder:GetChildren()) do
					local handle = loot:FindFirstChild("Handle")
					local billboard = handle and handle:FindFirstChild("Zircell_Billboard_Loot")
					if billboard then
						local distLabel = billboard:FindFirstChild("DistanceLabel")
						if distLabel and handle then
							local dist = (handle.Position - workspace.Camera.CFrame.Position).Magnitude
							distLabel.Text = FormatNumber(dist, true)
						end
					end
				end
			end
		end
		task.wait(0.1)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == OpenCloseButton then
		CloseZircellFrame()
	end
end)