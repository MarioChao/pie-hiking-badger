--!strict
-- Game Gui Script


---------- Services ----------

local Players = game:GetService("Players")


---------- Instances ----------

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui


---------- Gui instances ----------

local Game_ScreenGui: ScreenGui = PlayerGui:WaitForChild("Game_ScreenGui")
local Menu_TextButton: TextButton = Game_ScreenGui.Menu_TextButton


local Menu_ScreenGui: ScreenGui = PlayerGui:WaitForChild("Menu_ScreenGui")

local GameInfo_ScreenGui: ScreenGui = PlayerGui:WaitForChild("GameInfo_ScreenGui")


---------- Event functions ----------

local function onMenuActivated()
	Menu_ScreenGui.Enabled = not Menu_ScreenGui.Enabled
	if not Menu_ScreenGui.Enabled then
		GameInfo_ScreenGui.Enabled = false
	end
end


---------- Set up functions ----------

local function setUpGameGui()
	Game_ScreenGui.Enabled = true
end


---------- Calling / connecting functions ----------

Menu_TextButton.Activated:Connect(onMenuActivated)

setUpGameGui()
