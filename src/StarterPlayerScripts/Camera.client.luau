--!strict
-- Rank Test Script


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")


---------- Instances ----------

local CurrentCamera = workspace.CurrentCamera

local CameraEvents = ReplicatedStorage:WaitForChild("CameraEvents")
local CameraRemote = CameraEvents.CameraRemote


---------- Variables ----------


---------- Helper functions ----------

local function lerp(a: number, b: number, alpha: number)
	return a + (b - a) * alpha
end


---------- Local functions ----------

local function onSetFieldOfView(fieldOfView: number, transitionTime: number)
	local tweenInfo = TweenInfo.new(transitionTime)
	local tween = TweenService:Create(CurrentCamera, tweenInfo, {["FieldOfView"] = fieldOfView})
	tween:Play()
end


---------- Event functions ----------

local function onCameraClientEvent(mode: string, ...)
	if mode == "SetFieldOfView" then
		onSetFieldOfView(...)
	end
end


---------- Calling / connecting functions ----------

CameraRemote.OnClientEvent:Connect(onCameraClientEvent)
