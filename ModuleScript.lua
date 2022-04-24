local CoreGui = game:GetService("CoreGui")

do
	if game.PlaceId ~= 5846387555 then game:GetService('Players').LocalPlayer:Kick('\n\nUnsupported place!\n\nThis script only works in studio mode!') end
end

do
	local OldUI = CoreGui:FindFirstChild("AutoBuildGui")
	if OldUI then
		OldUI:Destroy()
	end
end

warn('\n\n\n\n\nThanks for using RetroStudio Auto Build by Att#7148! \n\n\nPress the insert key to toggle the ui.')

local UIS = game:GetService('UserInputService')
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local RemoteEvents = ReplicatedStorage.RemoteEvents

local CreateObjectEvent = RemoteFunctions.CreateObject
local ObjectPropertyChangeRequestEvent = RemoteEvents.ObjectPropertyChangeRequested
local CheckpointEvent = RemoteEvents.ChangeHistoryInteractionRequested

local AutoBuildGui, MainFrame, TitleLabel, ModelBox, NameBox, StartButton = loadstring(game:HttpGet("https://raw.githubusercontent.com/FloofyPlasma/RetroStudio-Auto-Build/main/UI.lua"))()()
local Properties = loadstring(game:HttpGet("https://raw.githubusercontent.com/FloofyPlasma/RetroStudio-Auto-Build/main/Properties.lua"))()

local CreatedInstances = 0

local function CreateNewInstance(ClassName: string, Parent: Instance)
	local Success, Result = pcall(CreateObjectEvent.InvokeServer, CreateObjectEvent, ClassName, Parent)
	CreatedInstances += 1

	if not Success then
		warn(Result)
	end

	return Result
end

local function SetInstanceProperty(Object: Instance, PropertyName: string, NewValue: any)
	ObjectPropertyChangeRequestEvent:FireServer(Object, PropertyName, NewValue)
end

local function SetCheckpoint()
	CheckpointEvent:FireServer("AddCheckpoint")
end

local function ScanModel(Model: Instance, ServerParent: Instance?)
	if not ServerParent then
		ServerParent = CreateNewInstance(Model.ClassName, workspace)
		task.spawn(SetInstanceProperty, ServerParent, "Name", Model.Name)
	end

	for _,Child in ipairs(Model:GetChildren()) do
		--task.spawn(function()
			local Properties = Properties[Child.ClassName]
			
			if not Properties then
				continue
			end

			local NewObject = CreateNewInstance(Child.ClassName, ServerParent)
			local IsAnchored = Child:GetAttribute("Anchored")

			if IsAnchored ~= nil then
				Child.Anchored = IsAnchored
			end

			if Child:IsA("BasePart") then
				SetInstanceProperty(NewObject, "FormFactor", "Custom")
			end

			for _,Property in ipairs(Properties) do
				SetInstanceProperty(NewObject, Property, Child[Property])
			end

			if IsAnchored ~= nil then
				Child.Anchored = true
			end

			ScanModel(Child, NewObject)
		--end)
	end
end

local function GetAssets(AssetId: string | number)
	local Model = game:GetObjects("rbxassetid://"..AssetId)

	if not Model then return end

	Model = Model[1]

	for _,Object in ipairs(Model:GetDescendants()) do
		pcall(function()
			Object:SetAttribute("Anchored", Object.Anchored)
			Object.Anchored = true
		end)
	end

	return Model
end

local function Start(AssetId: string | number, ModelName: string)
	local Model = GetAssets(AssetId)

	if not Model then return end

	Model.Name = ModelName
	local StartTime = tick()
	CreatedInstances = 0
	warn('\n\n\nStarting! This may take a while depending on the size of your model.\n\n\nPlease be patient thanks :3\n\n\n')
	--SetCheckpoint()
	ScanModel(Model)
	--SetCheckpoint()
	warn('\n\n\nFinished! Took ' .. tick() - StartTime .. ' seconds to create '.. tostring(CreatedInstances) .. ' instances.\n\n\n')
	Model:Destroy()
end

local function Init()
	local AssetId = tonumber(ModelBox.Text) or 0
	local ModelName = tostring(NameBox.Text) or 'Model'
	Start(AssetId, ModelName)
end

StartButton.Activated:Connect(Init)

UIS.InputBegan:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Insert then
		AutoBuildGui.Enabled = not AutoBuildGui.Enabled
	end
end)

--Start(9441839065, "PermaLobby")

return {}
