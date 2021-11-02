--[[ CONTROLLER via AeroFramework

CameraController
Integern
27/10/2021


METHODS

    CameraController:Init()
    CameraController:Start()
    CameraController:GrabCamera() Camera camera
    CameraController:GetRotation() Table rotations
    CameraController:UpdateFOV(Number fov)
    CameraController:BroomstickSpeedUpdated(Number speed)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run synchronously

        Start()
            Called upon refernece of module after Init(); run asynchronously

        GrabCamera()
            returns our local camera object  
            
        GetRotation()
            Returns the rotation values of our camera

        UpdateFOV(Number fov)
            Changes our FOV to the given value.

        BroomstickSpeedUpdated(Number speed)
            Call with the given speed, and it will pretty up the camera based on the speed e.g. increase FOV the faster we go


CONSTANTS

    Table CameraController.CameraSettings
        Settings (some read, some write) that relate to our camera
    Table CameraController.SensitivitySettings
        Settings for the sensitivity of our camera
    Table CameraController.Maids
        Contains maid objects for cleaning up (garbage collection)
    Service UserInputService
        "
    Service RunService
        "


EVENTS

    AnglesChanged(Number xAngle, Number yAngle)


--]]


local CameraController = {

    CameraSettings = {
        Offset = Vector3.new(0.5,2,7); --camera offset
        FOV = 80; --fov
        HeightAbove = 0; --how high above character camera should be
        HeadOffset = Vector3.new(0, 1.5, 0); --offset to account for size/position of the head

        _xAngle = 0; --actual camera rotation values in degrees
        _yAngle = 0;
    };

    SensitivitySettings = {
        Scalar = 1;

        Mouse = {
            X = 0.6;
            Y = 0.7;
        };
    };

    SpeedContribution = {
        MaxFOV = 60;
    };
    
    Maids = {
        _NewCharacter = false;
    };

};

local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')






function CameraController:Start() 
    
    --track mouse movement
    UserInputService.InputChanged:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end;
        if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
            CameraController:_MouseMoved(inputObject.Delta)
        end
    end)
    
    --load maids
    self.Maids._NewCharacter = self.Shared.Maid.new();

    --track new character spawned
    self.Player.CharacterAdded:Connect(function(character)
        self:_NewCharacter(character)
    end)
    if self.Player.Character then
        self:_NewCharacter(self.Player.Character)
    end

    --track broomstick speed
    self.Controllers.BroomstickController:ConnectEvent('SpeedUpdated', function(speed)
        self:BroomstickSpeedUpdated(speed)
    end)


end

function CameraController:Init() 
    self:RegisterEvent('AnglesChanged')
end




function CameraController:GrabCamera()
    return game.Workspace.CurrentCamera;
end




function CameraController:_MouseMoved(delta)
    local settings = self.CameraSettings;
    local sensitivity = self.SensitivitySettings

    settings._xAngle = settings._xAngle - delta.x*(sensitivity.Scalar * sensitivity.Mouse.X)
    settings._yAngle = math.clamp(settings._yAngle - delta.y*(sensitivity.Scalar * sensitivity.Mouse.Y),-80,80)

    self:FireEvent('AnglesChanged', Vector2.new(settings._xAngle, settings._yAngle))
end




function CameraController:_NewCharacter(character)
    local maid = self.Maids._NewCharacter
    maid:DoCleaning() --cleanup stuff from previous character

    local player = self.Player;
    local camera = self:GrabCamera()



    --///////////////////////////////////////////
    -- setup environment for our custom camera
    --///////////////////////////////////////////
    wait()

    --change camera type so we can code custom behaviour. default camera scripts may try override
    maid:GiveTask(camera:GetPropertyChangedSignal('CameraType'):Connect(function()
        camera.CameraType = Enum.CameraType.Scriptable
    end))
    camera.CameraType = Enum.CameraType.Scriptable

    --disable camera zooming
    player.CameraMaxZoomDistance = 5
    player.CameraMinZoomDistance = 5

    camera.FieldOfView = self.CameraSettings.FOV

    --lock mouse in center of screen. default camera scripts may try override, so put in a fail safe.
    maid:GiveTask(UserInputService:GetPropertyChangedSignal('MouseBehavior'):Connect(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end))
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter



    --/////////////////////////////////////////
    -- load behaviour
    --/////////////////////////////////////////

    local settings = self.CameraSettings;

    maid:GiveTask(RunService.Heartbeat:Connect(function() -- update camera each frame; use heartbeat instead of render stepped so we can cam shake.

        --check if our character is valid
        if not character then return end

        local root = character:FindFirstChild('HumanoidRootPart')
        if not root then return end


        --//calculate new camera cframe
        local startCFrame = CFrame.new((root.CFrame.p + Vector3.new(0,settings.HeightAbove,0)))*CFrame.Angles(0, math.rad(settings._xAngle), 0)*CFrame.Angles(math.rad(settings._yAngle), 0, 0)
        
        local cameraCFrame = startCFrame + startCFrame:VectorToWorldSpace(Vector3.new(settings.Offset.X,settings.Offset.Y,settings.Offset.Z))
        local cameraFocus = startCFrame + startCFrame:VectorToWorldSpace(Vector3.new(settings.Offset.X,settings.Offset.Y,-50000))

        local newCFrame = CFrame.new(cameraCFrame.p,cameraFocus.p)
        local finalCFrame = newCFrame;

        --check we are not clipping anything!
        local clipPoint = root.Position + Vector3.new(0, settings.HeightAbove, 0) + settings.HeadOffset

        local RaycastResult = self.Shared.Modules.Raycasting:Raycast(
            clipPoint,
            (cameraCFrame.p - clipPoint),
            (cameraCFrame.p - clipPoint).magnitude,
            {self.Shared.Modules.World:GetWorldDirectory()}
        )

        if RaycastResult then
            finalCFrame = CFrame.new(
                RaycastResult.Position + newCFrame.LookVector.Unit, --offset it a bit from whatever we're clipping
                cameraFocus.p
            )
        end
        
        --update camera with calculated cframe
            camera.CFrame = finalCFrame

        --//rotate character
        --root.CFrame = CFrame.new(root.CFrame.p, root.CFrame.p + Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z))

    end))

end




function CameraController:GetRotation()
    return Vector2.new(self.CameraSettings._xAngle, self.CameraSettings._yAngle)
end




function CameraController:UpdateFOV(fov)
    self:GrabCamera().FieldOfView = fov;
end

function CameraController:BroomstickSpeedUpdated(speed)

    if not speed then
        self:UpdateFOV(self.CameraSettings.FOV)
    else
        self:UpdateFOV(self.CameraSettings.FOV + math.clamp(speed^0.7, 0, self.SpeedContribution.MaxFOV))
    end

end





return CameraController