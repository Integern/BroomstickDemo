--[[ CLASS via AeroFramework

BroomstickMover
Integern
29/10/2021

METHODS

    BroomstickMover:Init()
    BroomstickMover:Start()
    BroomstickMover.new()

    BroomstickMover:UpdateMoveInput(Vector3 moveInputVector)
    BroomstickMover:UpdateLookAngles(Vector2 anglesVector)
    BroomstickMover:Eject()

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        new()
            Constructor for BroomstickMover class

        UpdateMoveInput(Vector3 moveInputVector)
            Informs the class of the clients input direction vector, from the core character scripts. Updates the class
            in the direction the player wishes to move the broomstick

        UpdateLookAngles(Vector2 anglesVector)
            Informs the class of where the client is looking; for rotating the broomstick

        Eject()
            Ejects us off of the broomstick


CLASS VALUES

    ClientBroomstick Broomstick
        The broomstick this class is controlling/moving

    Table MovementInput
        Contains the input values (from the client e.g. where they are facing, or if they're moving forward) which informs
        our movement.

        MovementInput.Forward == 1, we are moving straight forward. " == -1 we are moving straight back. " == 0.5 Would be 
        moving forward but at half speed.

        For MovementInput.Right, " == -1 would mean that we are wanting to move left.

        MovementInput.Angles Is a Vector2.new(), where .X is the angle of movement calculated for the camera when the mouse
        moves across the X axis of the screen. .Y for the Y axis.

    Number Gravity
        Gravity to use in our calculations; e.g. informs how quickly we can reach our top speed when diving.

    Table Movement
        All the values for calculating our speed.

        Movement.Vertical values are used if we are tilted down or up when less/more than the .Angle value.

        Movement.DragCoefficient is used to calculate our drag (deacceleration) where drag = v^2 * Cd, where Cd is the DragCoefficient

        Movement.Vertical.DegreesPerSecondStall; if we move the camera in the vertical direction by this amount of degrees in a second, it will set
        our vertical speed to zero. Same methodology for horizontal.

    Table Roll
        Values pertaining to the roll of our broomstick; we will naturally gravitate to a roll of 0, but can give a left/right movement input
        to roll it.


EVENTS

    SpeedUpdated(Number speed)
    Ejected()


MODULE VALUES

    UserInputService UserInputService

    BroomstickMover.Debug
        When true, will show debug messages
    BroomstickMover.TopSpeed
        Top speed for our broomstick; used in calculation of our drag coefficient

    BroomstickMover.EjectAtSpeed
        If we detect a collision when exceeding this speed, will eject.
    BroomstickMover.TrackCollisionsAfter
        Will start tracking collisions this long after the client has been given control

    BroomstickMover.DragExponent
        If this is 1, there will be a linear relationship between increased speed and increased drag. The higher this value,
        the drag lessens at lower values and increases at higher values.

    BroomstickMover.LockCamera
        If we hold a held keybind, we can move the camera without it affecting the direction of our broomstick


--]]


local BroomstickMover = {
    Debug = false;

    TopSpeed = 300;

    TrackCollisionsAfter = 2;
    EjectAtSpeed = 30;

    DragExponent = 3;

    LockCamera = {
        HeldKeybinds = {
            Enum.KeyCode.C;
        };
    };
}
BroomstickMover.__index = BroomstickMover

local UserInputService = game:GetService('UserInputService')




local function debug(...)
    if not BroomstickMover.Debug then return end
    print('BROOMSTICKMOVER:',...)
end





function BroomstickMover:Start()
end

function BroomstickMover:Init()

end





function BroomstickMover.new(broomstick)

--///////////////////////////////////////////////////////
    local Parent = BroomstickMover.Shared.Classes.BaseInstance
    local self = Parent.new();
    setmetatable(BroomstickMover, Parent)
    setmetatable(self, BroomstickMover);

    self:_SetClassName('BroomstickMover')
--///////////////////////////////////////////////////////

    self.Broomstick = broomstick; --a ClientBroomstick

    --clients input
    self.MovementInput = {
        Direction = {
            Forward = 0;
            Right = 0;
        };
        Angles = Vector2.new();
    };

    --//////////////////
    --movement values
    --/////////////////
    self.Gravity = 200;

    self.Movement = {
        Speed = 0;
        DragCoefficient = false;

        Vertical = {
            DegreesPerSecondStall = 2880;

            Diving = {
                Angle = -5;
                Acceleration = self.Gravity;
            };
            Climbing = {
                Angle = 5;
                Acceleration = -self.Gravity/1.5;
            };
        };

        Horizontal = {
            DegreesPerSecondStall = 1440;

            Forward = {
                Acceleration = 150;
            };
            Backward = {
                Acceleration = 250;
            };
        };

    };

    self.Movement.DragCoefficient = self.Movement.Vertical.Diving.Acceleration / (BroomstickMover.TopSpeed)^BroomstickMover.DragExponent

    self.Roll = {
        AnglePerSecond = 200;
        NaturalAnglePerSecond = 60;
    };



    self._UpdateMemory = {
        MovementInput = {
            Angles = Vector2.new();
        };
    }




    --collision stuff
    self._Ejected = false;

    self._Collisions = {
        OverlapParams = false;
    }

    self._Collisions.OverlapParams = OverlapParams.new();
    self._Collisions.OverlapParams.FilterType = Enum.RaycastFilterType.Blacklist
    self._Collisions.OverlapParams.MaxParts = 1; --only need to detect one part to confirm collision

    self._Collisions.OverlapParams.FilterDescendantsInstances = {self.Broomstick.Model, BroomstickMover.Player.Character}

    BroomstickMover.Shared.Promise.new(function(resolve, reject, onCancel)
        wait(BroomstickMover.TrackCollisionsAfter)
        self:_TrackCollisions()
        resolve()
    end)






    --frame update
    self.Maid:GiveTask(game:GetService('RunService').RenderStepped:Connect(function(dt)
        self:_Update(dt)
    end))



    --events
    self:AddEvent('SpeedUpdated')
    self:AddEvent('Ejected')


    return self

end




function BroomstickMover:UpdateMoveInput(moveInputVector)
    --moveInputVector is the characters move direction vector, so going to pretty it up for our use.

    self.MovementInput.Direction.Forward = -moveInputVector.Z;
    self.MovementInput.Direction.Right = moveInputVector.X;

    debug('CONSTANT Update Move Input', moveInputVector, self.MovementInput.Direction.Forward, self.MovementInput.Direction.Right)

end

function BroomstickMover:UpdateLookAngles(anglesVector)
    self.MovementInput.Angles = anglesVector;
    debug('CONSTANT Update look angles', anglesVector)
end




function BroomstickMover:_Update(dt)
    
    --/////////////////////
    --rotate broomstick
    --///////////////////
    local angleChange = self.MovementInput.Angles - self._UpdateMemory.MovementInput.Angles; --used in sharp angle reduction and natural rolling

    --should we lock our camera?
    local cameraLocked = false;
    for _,keybind in pairs(self.LockCamera.HeldKeybinds) do 
        cameraLocked = UserInputService:IsKeyDown(keybind) or cameraLocked;
    end

    if not cameraLocked then --then have broomstick handle point to in our camera direction
        --facing direction
        self.Broomstick:SetYRotation( (self.MovementInput.Angles.X) % 360 ) -- -270 helps line up the orientations
        --tilt up/down
        self.Broomstick:SetTiltRotation( self.MovementInput.Angles.Y );
        --roll from tilting left/right (in camera X direction)
        self.Broomstick:AddRollRotation( math.sign(angleChange.X) * (math.abs(angleChange.X))^0.8 )
    end

    -- //// ROLLING

    --roll from moving left/right
    if self.MovementInput.Direction.Right ~= 0 then
        self.Broomstick:AddRollRotation(-1 * self.Roll.AnglePerSecond * self.MovementInput.Direction.Right * dt)
    end


    --try to naturally reset to 0
    local currentRoll = self.Broomstick:GetRotation().Roll;
    if currentRoll ~= 0 then
        --calculate which way to spin to get to 0 deg fastest
        local sign = ((currentRoll + 180) % 360) > 180 and 1 or -1

        local addRoll = self.Roll.NaturalAnglePerSecond * dt
        self.Broomstick:AddRollRotation(-sign * math.clamp(addRoll, 0, math.abs(currentRoll)))
    end


    debug('ANGLES', ' X:', self.MovementInput.Angles.X, ' Y:', self.MovementInput.Angles.Y)

    --////////////////////
    --speed calculations
    --////////////////////

    local globalAcceleration = 0;

    --tilting; will apply the (de)acceleration in the given direction, linearly proportional to the angle.
    if self.MovementInput.Angles.Y < self.Movement.Vertical.Diving.Angle then
        local acceleration = (self.Movement.Vertical.Diving.Acceleration) * ((math.abs(self.MovementInput.Angles.Y))/90);
        globalAcceleration += acceleration
        debug('Diving at angle', self.MovementInput.Angles.Y,'  Acceleration Add:', acceleration)
    elseif self.MovementInput.Angles.Y > self.Movement.Vertical.Climbing.Angle then
        local acceleration = (self.Movement.Vertical.Climbing.Acceleration) * ((math.abs(self.MovementInput.Angles.Y))/90);
        globalAcceleration += acceleration
        debug('Climbing at angle', self.MovementInput.Angles.Y,'  Acceleration Add:', acceleration)
    end

    --moving forward
    if self.MovementInput.Direction.Forward > 0 then
        globalAcceleration += self.Movement.Horizontal.Forward.Acceleration * self.MovementInput.Direction.Forward;
        debug('Moving forward. Acceleration add:', self.Movement.Horizontal.Forward.Acceleration)
    elseif self.MovementInput.Direction.Forward < 0 then
        globalAcceleration += self.Movement.Horizontal.Backward.Acceleration * self.MovementInput.Direction.Forward
    end

    self.Movement.Speed = math.clamp(self.Movement.Speed + globalAcceleration * dt, 0, math.huge)
    debug('New Speed:', self.Movement.Speed)

    
    --sharp angle reductions
    self._UpdateMemory.MovementInput.Angles = self.MovementInput.Angles;
    
    local angleRedHorizontal = 1 - math.clamp((angleChange.magnitude/(self.Movement.Horizontal.DegreesPerSecondStall*dt))^3, 0, 1) * (1 - math.abs(self.MovementInput.Angles.Y)/90)^0.5
    local angleRedVertical = 1 - math.clamp((angleChange.magnitude/(self.Movement.Vertical.DegreesPerSecondStall*dt))^3, 0, 1) * (math.abs(self.MovementInput.Angles.Y)/90)^0.5
    
    self.Movement.Speed *= angleRedHorizontal * angleRedVertical
    debug('ANGLE REDUCTION   ', 'angleChange:', angleChange, ' Horizontal*', angleRedHorizontal, ' Vertical*', angleRedVertical, '  Total*',angleRedHorizontal * angleRedVertical)
    debug('ANGLE REDUCTION    ', ' speed:', self.Movement.Speed)
    

    --drag
    local drag = ((self.Movement.Speed)^BroomstickMover.DragExponent) * self.Movement.DragCoefficient * dt;
    debug('Drag :',drag, drag/dt)

    self.Movement.Speed -= drag
    debug('DRAG', ' speed:', self.Movement.Speed)


    --///////////////////////
    -- apply movement to position
    --////////////////////////
    local movementVector = self.Broomstick.OrientationCFrame.LookVector.Unit;
    debug('MOVEMENT DIRECTION     ',movementVector)
    debug('FINAL SPEED     ', ':', self.Movement.Speed)

    self:FireEvent('SpeedUpdated', self.Movement.Speed)

    local addHorizontal = Vector3.new(movementVector.X, 0, movementVector.Z) * self.Movement.Speed * dt
    local addVertical = Vector3.new(0, movementVector.Y, 0) * self.Movement.Speed * dt;


    self.Broomstick:AddPosition(addHorizontal)
    self.Broomstick:AddPosition(addVertical)
    debug('ADD HORIZONTAL   ', '  Horizontal:', addHorizontal, addHorizontal/dt, '  Vertical:', addVertical, addVertical/dt)

end




function BroomstickMover:_TrackCollisions()
    self.Maid:GiveTask(game:GetService('RunService').Heartbeat:Connect(function(dt)
        if not self.Broomstick.Model:FindFirstChild('Handle') then return end;

        --check for collisions
        local parts = game.Workspace:GetPartsInPart(self.Broomstick.Model.Handle, self._Collisions.OverlapParams)

        --do we eject?
        if #parts > 0 and self.Movement.Speed >= BroomstickMover.EjectAtSpeed and not self._Ejected then
            warn('Ejecting; collided at speed ' .. self.Movement.Speed)
            self:Eject()
        end

    end))
end




function BroomstickMover:Eject()
    local player = BroomstickMover.Player;
    if not player.Character then return end;

    if self._Ejected then return end;
    self._Ejected = true;

    player.Character.Humanoid.Jump = true;
    require(game.ReplicatedStorage:WaitForChild("buildRagdoll"))(player.Character.Humanoid)
    player.Character.Humanoid.Health = 0;

    self:FireEvent('Ejected')
end





return BroomstickMover