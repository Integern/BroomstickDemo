--[[ CLASS via AeroFramework

BroomstickStand
Integern
27/10/2021

METHODS

    BroomstickStand:Init()
    BroomstickStand:Start()
    BroomstickStand.new()

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        new()
            Constructor for BroomstickStand class


CLASS VALUES

    Vector3 Position
        Position of primary part of our model
    Model Model
        Model for our stand; contains the broomstick model.
    Broomstick Broomstick
        Broomstick class linked to this stand


EVENTS


MODULE VALUES

    Vitality
        Reference to Vitality Library


--]]


local BroomstickStand = {}
BroomstickStand.__index = BroomstickStand





function BroomstickStand:Start()
end

function BroomstickStand:Init()
end





function BroomstickStand.new(position, broomstickModel)

--///////////////////////////////////////////////////////
    local Parent = BroomstickStand.Shared.Classes.BaseInstance
    local self = Parent.new();
    setmetatable(BroomstickStand, Parent)
    setmetatable(self, BroomstickStand);

    self:_SetClassName('BroomstickStand')
--///////////////////////////////////////////////////////


    --init position
    self.Position = position or Vector3.new(0,0,0);
    if not self.Position then
        warn('No position given for broomstick stand')
    end

    --load model
    self.Model = BroomstickStand.Shared.Modules.Assets.BroomstickStand:Clone()
    self.Model.Parent = BroomstickStand.Shared.Modules.World:GetWorldDirectory()
    self.Model:SetPrimaryPartCFrame(CFrame.new(self.Position))

    self.Maid:GiveTask(self.Model)

    --load broomstick
    broomstickModel:SetPrimaryPartCFrame(self.Model.Broomstick.PrimaryPart.CFrame)
    broomstickModel.Name = 'Broomstick'
    broomstickModel.Parent = self.Model;
    
    self.Model.Broomstick:Remove()


    self.ServerBroomstick = BroomstickStand.Shared.Classes.ServerBroomstick.new(broomstickModel)

    self:AddDestroyCallback(function()
        if self.ServerBroomstick then
            self.ServerBroomstick:Destroy()
        end
    end)



    return self

end





return BroomstickStand