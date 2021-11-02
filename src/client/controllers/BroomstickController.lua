--[[ CONTROLLER via AeroFramework

BroomstickController
Integern
27/10/2021


METHODS

    BroomstickController:Init()
    BroomstickController:Start()

    BroomstickController:NewBroomstick(Model broomstickModel)
    BroomstickController:ClearBroomstick()
    BroomstickController:BroomstickDismounted()
    BroomstickController:BindBroomstickMovement()
    BroomstickController:PlayAnimation(String animationName)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        NewBroomstick(Model broomstickModel)
            Called when we're informed by the server that we have mounted a new broomstick; this will do all necessary
            setup for the client

        ClearBroomstick()
            Clears the clientside broomstick stuff

        BroomstickDismounted()
            Can/will be call when we dismount the broomstick, and runs the necessary stuffs

        BindBroomstickMovement()
            Will create a broomstick mover object (+setup) which allows us to give input to move the broomstick

        PlayAnimation(String animationName)
            Plays the given animation; for broomstick animations.


CONSTANTS

    UserInputService UserInputService

    ClientBroomstick BroomstickController.CurrentBroomstick
    AnimationTrack BroomstickController.CurrentAnimation
        If we're playing an animation, this is the track. Allows us to stop it to allow us to load a new one.
    Vector3 BroomstickController.MoveInput
        Our move input vector from the roblox core scripts
    Table BroomstickController.Eject
        Contains information pertaining to sending an eject request to a broomstick mover


EVENTS

    SpeedUpdated(Number speed)


--]]


local BroomstickController = {

    CurrentBroomstick = false;

    CurrentAnimation = false;

    MoveInput = Vector3.new(1,2,3);
    
    Maids = {
        CurrentBroomstick = false;
    };

    Eject = {
        Keybinds = {
            Enum.KeyCode.X
        };
    };

}

local UserInputService = game:GetService('UserInputService')






function BroomstickController:Start() --asynchronous

    --listen in to server events
    self.Services.BroomstickService['BroomstickMounted']:Connect(function(broomstickModel)
        self:NewBroomstick(broomstickModel)
    end)

end

function BroomstickController:Init() --synchronous
    self.Maids.CurrentBroomstick = self.Shared.Maid.new();

    self:RegisterEvent('SpeedUpdated')
end







function BroomstickController:NewBroomstick(broomstickModel)

    if self.CurrentBroomstick then
        self:ClearBroomstick()
    end

    local maid = self.Maids.CurrentBroomstick;
    
    --create our clientside broomstick
    local clientBroomstick = self.Shared.Classes.ClientBroomstick.new(broomstickModel);
    self.CurrentBroomstick = clientBroomstick;

    maid:GiveTask(clientBroomstick)


    --listen to dismount
    maid:GiveTask(clientBroomstick:ConnectEvent('Dismounted', function()
        self:BroomstickDismounted()
    end))


    --float up upon initial moun
    clientBroomstick:AddPosition(Vector3.new(0, 15, 0))
    self:PlayAnimation('BroomstickSit')
    
    
    --Now begin tracking movement
    self:BindBroomstickMovement()


    --wind sound
    local windSound = self.Shared.Modules.Assets.WindSound:Clone()
    windSound.Volume = 0;
    windSound.Looped = true;
    windSound.Parent = broomstickModel

    windSound:Play()

    maid:GiveTask(windSound)
    maid:GiveTask(self:ConnectEvent('SpeedUpdated', function(speed)
        speed = speed or 0;
        windSound.Volume = math.clamp(speed/300, 0, 1);
    end))

end

function BroomstickController:ClearBroomstick()
    self.Maids.CurrentBroomstick:DoCleaning()
end




function BroomstickController:BroomstickDismounted()
    self:ClearBroomstick()
end




function BroomstickController:BindBroomstickMovement()
    local broomstick, maid = self.CurrentBroomstick, self.Maids.CurrentBroomstick

    --create our broomstickMover class, and inform it of our client input. This is what will give movement to our broomstick
    local broomstickMover = self.Shared.Classes.BroomstickMover.new(broomstick);
    maid:GiveTask(broomstickMover)

    --track speed updates
    maid:GiveTask(broomstickMover:ConnectEvent('SpeedUpdated', function(speed)
        self:FireEvent('SpeedUpdated', speed)
    end))
    --when maid is called, we are no longer flying so dont have a speed.
    maid:GiveTask(function()
        self:FireEvent('SpeedUpdated', false)
    end)

    --tell server to clear bodymovers, so the client ones get enabled.
    self.Services.BroomstickService:ClearServerBodyMovers()

    --reparent our movers; weird quirk, we need to find a child added event again for the bodymovers somewhere in the source code.
    local bp = broomstick._BodyPosition;
    local bg = broomstick._BodyGyro;
    local bpParent = bp.Parent;
    local bgParent = bg.Parent;

    bp.Parent = nil     bp.Parent = bpParent;
    bg.Parent = nil     bg.Parent = bgParent;
    

    --track movement direction input
    maid:GiveTask(game:GetService('RunService').Heartbeat:Connect(function(dt)

        local currentMoveDir = self.Modules.GetMoveVector:Get();
        if currentMoveDir ~= self.MoveInput then
            self.MoveInput = currentMoveDir;
            if self.MoveInput.magnitude > 0 then
                self.MoveInput = self.MoveInput.Unit
            end
            broomstickMover:UpdateMoveInput(self.MoveInput)
            self:_AnimateFromMoveInput(self.MoveInput)
        end

    end))

    --track where we're looking
    maid:GiveTask(self.Controllers.CameraController:ConnectEvent('AnglesChanged', function(angles)
        broomstickMover:UpdateLookAngles(angles)
    end))
    broomstickMover:UpdateLookAngles(self.Controllers.CameraController:GetRotation())

    --listen to keybind for ejection
    UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end;

        if table.find(self.Eject.Keybinds, inputObject.KeyCode) then 
            broomstickMover:Eject()
        end
    end)

    --when we lose our broomstick, reset our move input.
    maid:GiveTask(function()
        self.MoveInput = Vector3.new(); 
    end)

    --clearing up
    maid:GiveTask(
        broomstickMover:ConnectEvent('Ejected', function()
            maid:DoCleaning()
        end)
    )

end



function BroomstickController:_AnimateFromMoveInput(moveInput)
    if moveInput.Z >= 0 then --not moving forward
        self:PlayAnimation('BroomstickSit')
    else
        self:PlayAnimation('BroomstickFly')
    end
end

function BroomstickController:PlayAnimation(animationName)
    local character = BroomstickController.Player.Character;
    if not character then
        warn('No character')
        return;
    end

    local oldAnimation = self.CurrentAnimation;
    self.CurrentAnimation = BroomstickController.Shared.Modules.Animations:RunOnCharacter(animationName, character)

    if oldAnimation and oldAnimation ~= self.CurrentAnimation then
        oldAnimation:Stop()
    end  
end





return BroomstickController