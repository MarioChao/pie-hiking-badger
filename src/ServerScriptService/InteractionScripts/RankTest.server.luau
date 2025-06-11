--!strict
-- Rank Test Script


---------- Service ----------

local DebrisService = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local LeaderstatsModule = require(ServerStorage.LeaderstatsModule)


---------- Instances ----------

local RankTestFolder: Folder = workspace._Workspace.RankTest
local RankTestInteraction: Folder = RankTestFolder.Interaction
local RankTestInteractivePart: Part = RankTestInteraction.InteractivePart
local RankTestProximityPrompt: ProximityPrompt = RankTestInteractivePart.ProximityPrompt
local PoofAudioPlayer: AudioPlayer = RankTestInteractivePart.PoofAudioPlayer
local PulsingAudioPlayer: AudioPlayer = RankTestInteractivePart.PulsingAudioPlayer

local RankTestBillboardGui = Instance.new("BillboardGui")

local RankEvents = ServerStorage.RankEvents
local RankBindableFunction = RankEvents.RankBindableFunction

local CameraEvents = ReplicatedStorage.CameraEvents
local CameraRemote = CameraEvents.CameraRemote

local MenuEvents = ReplicatedStorage.MenuEvents
local MenuRemote = MenuEvents.MenuRemote


---------- Variables ----------

local interactThrottle = false

local rng = Random.new()


---------- Helper functions ----------

local function lerp(a: number, b: number, alpha: number)
	return a + (b - a) * alpha
end


---------- Local functions ----------

local function displayBillboardGuiText(text: string, particles: number, parent: Instance)
	local count = 0
	for i = 1, particles do
		task.defer(function()
			-- Create billboard gui
			local billboardGui = RankTestBillboardGui:Clone()

			-- Create text label
			local textLabel = Instance.new("TextLabel")

			-- Gui properties
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			textLabel.BackgroundTransparency = 1

			-- Text properties
			textLabel.Text = text
			textLabel.FontFace = Font.fromEnum(Enum.Font.Merriweather)
			textLabel.TextColor3 = Color3.new(0.686274, 0.211764, 0.552941)
			textLabel.TextScaled = true
			textLabel.RichText = true

			-- Size
			local billboardSize = rng:NextNumber(0.5, 1)
			RankTestBillboardGui.Size = UDim2.new(0, 2000, billboardSize, 0)

			-- Parent instances
			textLabel.Parent = billboardGui
			billboardGui.Parent = parent

			-- Move gui configurations
			local startTime = time()
			local transitionTime = 3
			local dPosition_dt = rng:NextUnitVector() * rng:NextNumber(0.5, 4)
			local dRotation_dt = rng:NextNumber(-180, 180)

			-- Move gui
			while time() - startTime < transitionTime do
				-- Wait
				local deltaTime = RunService.Heartbeat:Wait()

				-- Get alpha
				local alpha = (time() - startTime) / transitionTime

				-- Move billboard
				billboardGui.StudsOffsetWorldSpace += dPosition_dt * deltaTime

				-- Rotate text
				textLabel.Rotation += dRotation_dt * deltaTime

				-- Text transparency
				textLabel.TextTransparency = lerp(0, 1, alpha)
			end

			-- Clean up
			count += 1
			DebrisService:AddItem(textLabel, 0)
			DebrisService:AddItem(billboardGui, 0)
		end)
	end

	while count < 10 do
		RunService.Heartbeat:Wait()
	end
end

local function displayRank(player: Player)
	-- Get rank
	local rank = "no data"
	task.defer(function()
		rank = RankBindableFunction:Invoke("TestAndGetPlayerRank", player)
	end)

	---------- Wait for rank ----------

	local transitionTime = 2
	local startTime = time()
	local initialColor = RankTestInteractivePart.Color

	-- Start change
	CameraRemote:FireClient(player, "SetFieldOfView", 120, transitionTime + 1)
	for _, object in RankTestInteraction:GetChildren() do
		if object:IsA("BasePart") then
			object.Color = Color3.new(0.8, 0, 0)
		end
	end

	-- Set leaderstats
	LeaderstatsModule.setData(player, "Rank", "???")

	-- Wait
	while rank == "no data" or time() - startTime < transitionTime do
		RunService.Heartbeat:Wait()
	end

	-- End change
	CameraRemote:FireClient(player, "SetFieldOfView", 70, 0.3)
	for _, object in RankTestInteraction:GetChildren() do
		if object:IsA("BasePart") then
			object.Color = initialColor
		end
	end


	-- Update menu
	MenuRemote:FireClient(player, "UpdateRank", rank)

	-- Set leaderstats
	LeaderstatsModule.setData(player, "Rank", rank)

	-- Play audio
	PoofAudioPlayer:Play()

	-- Display rank on gui
	task.defer(function()
		displayBillboardGuiText(rank, 32, RankTestInteractivePart)
	end)
	for _, object in RankTestInteraction.ParticleParts:GetChildren() do
		if object:IsA("BasePart") then
			task.defer(function()
				displayBillboardGuiText(rank, 2, object)
			end)
		end
	end
end


---------- Event functions ----------

local function onProximityPromptTriggered(player: Player)
	if interactThrottle then
		return
	end
	interactThrottle = true

	-- Disable interaction
	RankTestProximityPrompt.Enabled = false

	-- Display rank
	displayRank(player)

	-- Enable interaction
	RankTestProximityPrompt.Enabled = true

	interactThrottle = false
end


---------- Calling / connecting functions ----------

RankTestProximityPrompt.Triggered:Connect(onProximityPromptTriggered)
PulsingAudioPlayer:Play()
