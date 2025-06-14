local Lens = {}
Lens.__index = Lens

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Essentials = require(ReplicatedStorage.shared.vendor.essentials)
local Cleaner = Essentials.Cleaner

export type Lens = typeof(setmetatable({
    Screen = (nil :: any) :: Part,
    Distance = (nil :: any) :: number,
    Size = (nil :: any) :: UDim2,
    Rotation = (nil :: any) :: number,
    Position = (nil :: any) :: UDim2,
    AnchorPoint = (nil :: any) :: Vector2,
    AspectRatio = (nil :: any) :: number,
    AspectType = (nil :: any) :: Enum.AspectType,
    DominantAxis = (nil :: any) :: Enum.DominantAxis,
}, Lens))

local ActiveUI = {}

function Lens.new()
    local self = setmetatable({}, Lens)
    
    local LensFolder = workspace:FindFirstChild("Lens_UI")
    if not LensFolder then
        LensFolder = Instance.new("Folder")
        LensFolder.Name = "Lens_UI"
        LensFolder.Parent = workspace
    end
    
    local Screen = Instance.new("Part")
    Screen.Name = "Screen"
    Screen.Anchored = true
    Screen.CanCollide = false
    Screen.CanQuery = false
    Screen.CanTouch = false
    Screen.Transparency = 1
    Screen.Size = Vector3.new(1, 1, 0.001)
    Screen.Parent = LensFolder
    
    local SurfaceGui = Instance.new("SurfaceGui")
    SurfaceGui.Name = "Render"
    SurfaceGui.AlwaysOnTop = true
    SurfaceGui.Parent = Screen
    SurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    
    self.Cleaner = Cleaner.new()
    self.Screen = Screen
    self.SurfaceGui = SurfaceGui
    self.isRendering = false
    
    -- properties
    self.Distance = 5
    self.Size = UDim2.new(0, 100, 0, 100)
    self.Rotation = 0
    self.Position = UDim2.new(0, 0, 0, 0)
    self.AnchorPoint = Vector2.new(0, 0)
    
    self.AspectRatio = nil -- when nil, no constraint is applied
    self.AspectType = Enum.AspectType.FitWithinMaxSize
    self.DominantAxis = Enum.DominantAxis.Width
    
    -- default static update logic
    self.updateCallback = function()
        local camera = workspace.CurrentCamera
        local viewportSize = camera.ViewportSize
        local cameraPosition = camera.CFrame.Position
        local cameraLookVector = camera.CFrame.LookVector
        local cameraRightVector = camera.CFrame.RightVector
        local cameraUpVector = camera.CFrame.UpVector
        
        local aspectRatio = viewportSize.X / viewportSize.Y
        local fov = math.rad(camera.FieldOfView)
        local screenHeight = 2 * self.Distance * math.tan(fov / 2)
        local screenWidth = screenHeight * aspectRatio
        
        local pixelsPerUnitX = viewportSize.X / screenWidth
        local pixelsPerUnitY = viewportSize.Y / screenHeight
        
        local sizeX = (self.Size.X.Scale * viewportSize.X + self.Size.X.Offset) / pixelsPerUnitX
        local sizeY = (self.Size.Y.Scale * viewportSize.Y + self.Size.Y.Offset) / pixelsPerUnitY
        
        if self.AspectRatio then
            local currentAspectRatio = sizeX / sizeY
            
            if self.AspectType == Enum.AspectType.FitWithinMaxSize then
                if currentAspectRatio > self.AspectRatio then
                    sizeX = sizeY * self.AspectRatio
                else
                    sizeY = sizeX / self.AspectRatio
                end
            elseif self.AspectType == Enum.AspectType.ScaleWithParentSize then
                if self.DominantAxis == Enum.DominantAxis.Width then
                    sizeY = sizeX / self.AspectRatio
                    sizeX = sizeY * self.AspectRatio
                end
            end
        end
        
        local positionX = self.Position.X.Scale * viewportSize.X + self.Position.X.Offset
        local positionY = self.Position.Y.Scale * viewportSize.Y + self.Position.Y.Offset
        
        local normalizedPosX = (positionX / viewportSize.X) - 0.5
        local normalizedPosY = 0.5 - (positionY / viewportSize.Y)
        
        local worldPosX = normalizedPosX * screenWidth
        local worldPosY = normalizedPosY * screenHeight
        
        local anchorOffsetX = (self.AnchorPoint.X - 0.5) * sizeX
        local anchorOffsetY = (0.5 - self.AnchorPoint.Y) * sizeY
        
        local basePosition = cameraPosition + cameraLookVector * self.Distance
        local finalPosition = basePosition
            + cameraRightVector * (worldPosX - anchorOffsetX)
            + cameraUpVector * (worldPosY - anchorOffsetY)
        
        local baseCFrame = CFrame.new(finalPosition, finalPosition - cameraLookVector)
        local rotatedCFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(self.Rotation))
        
        self.Screen.CFrame = rotatedCFrame
        self.Screen.Size = Vector3.new(sizeX, sizeY, 0.001)
    end
    
    return self
end

function Lens:ChangeUpdateLogic(callback: () -> ())
    self.updateCallback = callback
end


function Lens:StartRender()
    if self.isRendering then return end
    
    self.Cleaner:Add(RunService.PreRender:Connect(self.updateCallback))
    self.isRendering = true
    table.insert(ActiveUI, self)
end

function Lens:StopRender()
    if not self.isRendering then return end
    
    self.Cleaner:Clean()
    self.isRendering = false
    
    for i = 1, #ActiveUI do
        if ActiveUI[i] == self then
            table.remove(ActiveUI, i)
            break
        end
    end
end

function Lens:Destroy()
    self:StopRender()
    
    if self.Screen and self.Screen.Parent then
        local folder = self.Screen.Parent
        self.Screen:Destroy()
        if folder and folder:IsA("Folder") and #folder:GetChildren() == 0 then
            folder:Destroy()
        end
    end
end

function Lens.DisposeAll()
    local activeUICopy = table.clone(ActiveUI)
    for i = 1, #activeUICopy do
        activeUICopy[i]:Destroy()
    end
    table.clear(ActiveUI)
end

return table.freeze({
    new = Lens.new,
    DisposeAll = Lens.DisposeAll,
})