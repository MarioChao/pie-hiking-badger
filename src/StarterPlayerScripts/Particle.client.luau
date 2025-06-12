--!strict
-- Particle Script


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local GuiParticles3D = require(ReplicatedStorage.GuiParticles3D)


---------- Instances ----------

local ParticleEvent = ReplicatedStorage:WaitForChild("ParticleEvents")
local ParticleRemote = ParticleEvent.ParticleRemote


---------- Local functions ----------

local function onShowTextParticles(text: string, particles: number, parent: Instance)
	-- Display particles on parent part
	if parent:IsA("BasePart") then
		task.defer(function()
			GuiParticles3D.displayGuiTextParticle(text, particles, parent)
		end)
	end

	-- Display particle on child objects
	for _, object in parent:GetDescendants() do
		if object:IsA("BasePart") then
			task.defer(function()
				GuiParticles3D.displayGuiTextParticle(text, particles, object)
			end)
		end
	end
end


---------- Event functions ----------

local function onParticleClientEvent(mode: string, ...)
	if mode == "ShowTextParticles" then
		onShowTextParticles(...)
	end
end


---------- Calling / connecting functions ----------

ParticleRemote.OnClientEvent:Connect(onParticleClientEvent)

