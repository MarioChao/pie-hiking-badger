--!strict
-- Gui Particles 3D Module Script


---------- Module ----------

local GuiParticles3D = {}


---------- Services ----------

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")


---------- Variables ----------

local rng = Random.new()


---------- Helper functions ----------

local function lerp(a: number, b: number, alpha: number)
	return a + (b - a) * alpha
end


---------- Local functions ----------

local function displayGuiTextParticle(text: string, particles: number, parent: Instance)
	local count = 0
	for i = 1, particles do
		task.defer(function()
			-- Create billboard gui
			local billboardGui = Instance.new("BillboardGui")

			-- Create text label
			local textLabel = Instance.new("TextLabel")

			-- Gui properties
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			textLabel.BackgroundTransparency = 1

			-- Text properties
			textLabel.Text = text
			textLabel.FontFace = Font.fromName(Enum.Font.Merriweather.Name, Enum.FontWeight.Bold)
			textLabel.TextColor3 = Color3.new(1, 0.258823, 0.788235)
			textLabel.TextScaled = true
			textLabel.RichText = true

			-- Size
			local billboardSize = rng:NextNumber(0.5, 1.2)
			billboardGui.Size = UDim2.new(0, 2000, billboardSize, 0)

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
			Debris:AddItem(textLabel, 0)
			Debris:AddItem(billboardGui, 0)
		end)
	end

	while count < 10 do
		RunService.Heartbeat:Wait()
	end
end


---------- Module functions ----------

GuiParticles3D.displayGuiTextParticle = displayGuiTextParticle


---------- Return module ----------

return GuiParticles3D
