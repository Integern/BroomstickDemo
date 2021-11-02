--[[ CLASS via AeroFramework

ClientBroomstick
Integern
27/10/2021

METHODS

    ClientBroomstick:Init()
    ClientBroomstick:Start()
    ClientBroomstick.new()

    ClientBroomstick:SetPosition(Vector3 position)
    ClientBroomstick:AddPosition(Vector3 position)
    ClientBroomstick:SetOrientation(CFrame cframe)
    ClientBroomstick:SetYRotation(Number angleInDegrees)
    ClientBroomstick:SetTiltRotation(Number angleInDegrees)
    ClientBroomstick:GetRotation()
    ClientBroomstick:SetRollRotation(Number angle)
    ClientBroomstick:AddRollRotation(Number angle)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        new()
            Constructor for ClientBroomstick class

        SetPosition(Vector3 position)
            Sets the position of our broomstick to move to

        SetOrientation(CFrame cframe)
            Sets the cframe rotation of our broomstick to go to

        AddPosition(Vector3 position)
            Adds an offset to our position

        SetYRotation(Number angleInDegrees)
            Sets the y rotation of our broomstick (as in rotation around the Y axis)

        SetTiltRotation(Number angleInDegrees)
            Sets the tilt rotation of the broomstick; 0 degrees has the broomstick completely flat

        GetRotation()
            Returns the current rotation defined for the broomstick.

            GetRotation() == {Tilt = ?, Y = ?}

            Where Y is the rotation about the Y axis, and tilt is if the broomstick is pointing up or down.

        SetRollRotation(Number angle)
            Sets the roll of the broomstick, where an angle of 180 degrees would have us flying upside down

        AddRollRotation(Number angle)
            " but adds to our current roll angle


CLASS VALUES

    Model Model
        Model of our broomstick
    Seat Seat
    Player CurrentOccupant
        Player currently sat on the seat
    Vector3 Position
        The position of our broomstick; will inform the bodyposition.
    CFrame OrientationCFrame
        The rotational cframe of our broomstick; will inform the bodygyro.


EVENTS


MODULE VALUES


--]]


local ClientBroomstick = {}
ClientBroomstick.__index = ClientBroomstick





function ClientBroomstick:Start()
end

function ClientBroomstick:Init()
end





function ClientBroomstick.new(broomstickModel)

--///////////////////////////////////////////////////////
    local Parent = ClientBroomstick.Shared.Classes.BaseInstance
    local self = Parent.new();
    setmetatable(ClientBroomstick, Parent)
    setmetatable(self, ClientBroomstick);

    self:_SetClassName('ClientBroomstick')
--///////////////////////////////////////////////////////

    --load model
    self.Model = broomstickModel;
    self.Seat = self.Model.Seat;

    self.Maid:GiveTask(self.Model)

    --load body velocities and initialise position+orientation
    self._BodyPosition = self.Model.Handle.BodyPosition:Clone();
    self._BodyPosition.Parent = self.Model.Handle
    self._BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self._BodyPosition.Name ..= 'Client'

    self._BodyGyro = self.Model.Handle.BodyGyro:Clone();
    self._BodyGyro.Parent = self.Model.Handle
    self._BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    self._BodyGyro.Name ..= 'Client'

    self.Position = self._BodyPosition.Position;
    self.OrientationCFrame = self._BodyGyro.CFrame;

    --rotation storage
    self._Rotation = {
        Tilt = 30;
        Y = 0;
        Roll = 0;
    };


    --mounting
    self.CurrentOccupant = false;
    self:AddEvent('OccupantChanged')
    self:AddEvent('Dismounted')

    self.Maid:GiveTask(
        self.Seat:GetPropertyChangedSignal('Occupant'):Connect(function()
            self:_OccupantChanged()
        end)
    )



    return self

end




function ClientBroomstick:_Mounted(player)
    
    --admin
    self.CurrentOccupant = player;
    self:FireEvent('OccupantChanged', player)
end

function ClientBroomstick:_Dismounted(player)
    
    --admin
    self.CurrentOccupant = false;
    self:FireEvent('OccupantChanged', false)
    self:FireEvent('Dismounted')
end



function ClientBroomstick:_OccupantChanged()
    local occupantHumanoid = self.Seat.Occupant;
    local player = occupantHumanoid and game.Players:FindFirstChild(occupantHumanoid.Parent.Name) or false

    if not self.CurrentOccupant and player then
        self:_Mounted(player)
    elseif self.CurrentOccupant and not player then
        self:_Dismounted(self.CurrentOccupant)
    end
end




function ClientBroomstick:SetPosition(position)
    self.Position = position;
    self._BodyPosition.Position = position
end

function ClientBroomstick:AddPosition(position)
    self:SetPosition(self.Position + position)
end



function ClientBroomstick:SetOrientation(cframe)
    self.OrientationCFrame = cframe;
    self._BodyGyro.CFrame = cframe;
end


function ClientBroomstick:SetYRotation(angle)
    self._Rotation.Y = angle;
    self:_UpdateRotation()
end

function ClientBroomstick:SetTiltRotation(angle)
    self._Rotation.Tilt = angle;
    self:_UpdateRotation()
end

function ClientBroomstick:SetRollRotation(angle)
    self._Rotation.Roll = angle;
    self:_UpdateRotation()
end

function ClientBroomstick:AddRollRotation(angle)
    self:SetRollRotation(self._Rotation.Roll + angle)
end


function ClientBroomstick:_UpdateRotation()

    local newCFrame = CFrame.fromEulerAnglesYXZ( 
        math.rad(self._Rotation.Tilt),
        math.rad(self._Rotation.Y),
        math.rad(self._Rotation.Roll)
    )

    self:SetOrientation(newCFrame)
    --[[

    self:SetOrientation(CFrame.fromOrientation( 
        math.rad(-90 + self._Rotation.Tilt),
        math.rad(self._Rotation.Y),
        0
    ))

    ]]
end



function ClientBroomstick:GetRotation()
    return self._Rotation;
end







return ClientBroomstick