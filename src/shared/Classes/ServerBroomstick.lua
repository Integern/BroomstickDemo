--[[ CLASS via AeroFramework

Broomstick
Integern
27/10/2021

METHODS

    Broomstick:Init()
    Broomstick:Start()
    Broomstick.new()

    ServerBroomstick:UpdateCFrame(CFrame cframe)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        new()
            Constructor for Broomstick class

        UpdateCFrame(CFrame cframe)
            Updates the cframe of the broomstick model to the given cframe


CLASS VALUES

    Model Model
        Model of our broomstick
    Seat Seat
    Player CurrentOccupant
        Player currently sat on the seat
    BodyPosition BodyPosition
        The BodyPosition instance for this broomstick; guides the position
    BodyGyro BodyGyro
        The BodyGyro instance for this broomstick; guides the rotation


EVENTS

    OccupantChanged(Player player)


MODULE VALUES


--]]


local ServerBroomstick = {}
ServerBroomstick.__index = ServerBroomstick





function ServerBroomstick:Start()
end

function ServerBroomstick:Init()
end





function ServerBroomstick.new(broomstickModel)

--///////////////////////////////////////////////////////
    local Parent = ServerBroomstick.Shared.Classes.BaseInstance
    local self = Parent.new();
    setmetatable(ServerBroomstick, Parent)
    setmetatable(self, ServerBroomstick);

    self:_SetClassName('ServerBroomstick')
--///////////////////////////////////////////////////////

    --load model
    self.Model = broomstickModel;
    self.Seat = self.Model.Seat;

    self.Maid:GiveTask(self.Model)

    --setup bodyvectors
    self.BodyPosition = self.Model.Handle.BodyPosition;
    self.BodyGyro = self.Model.Handle.BodyGyro;

    self.BodyPosition.Position = self.Model.PrimaryPart.Position;
    self.BodyGyro.CFrame = self.Model.PrimaryPart.CFrame;

    self.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

    self.Model.Handle.Anchored = false;


    --mounting
    self.CurrentOccupant = false;
    self:AddEvent('OccupantChanged')

    self.Maid:GiveTask(
        self.Seat:GetPropertyChangedSignal('Occupant'):Connect(function()
            self:_OccupantChanged()
        end)
    )



    return self

end




function ServerBroomstick:_Mounted(player)

    --give player control of the model
    self.Model.PrimaryPart:SetNetworkOwner(player)
    
    --admin
    self.CurrentOccupant = player;
    self:FireEvent('OccupantChanged', player)

end

function ServerBroomstick:_Dismounted(player)

    --clear player control of the model
    self.Model.PrimaryPart:SetNetworkOwner(nil)
    
    --admin
    self.CurrentOccupant = false;
    self:FireEvent('OccupantChanged', false)
end



function ServerBroomstick:_OccupantChanged()
    local occupantHumanoid = self.Seat.Occupant;
    local player = occupantHumanoid and game.Players:FindFirstChild(occupantHumanoid.Parent.Name) or false

    if not self.CurrentOccupant and player then
        self:_Mounted(player)
    elseif self.CurrentOccupant and not player then
        self:_Dismounted(self.CurrentOccupant)
    end
end




function ServerBroomstick:UpdateCFrame(cframe)
    self.Model:SetPrimaryPartCFrame(cframe)
end






return ServerBroomstick