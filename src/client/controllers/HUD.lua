--[[ CONTROLLER via AeroFramework

HUD
Integern
01/11/2021


METHODS

    HUD:Init()
    HUD:Start()

    HUD:SpeedUpdate(Number speed)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        SpeedUpdate(Number speed)
            Will update our HUD with the given speed value


CONSTANTS


EVENTS


--]]


local HUD = {
    Speed = {
        Housing = false;
        Label = false;
    };
}






function HUD:Start() --asynchronous

    --when our local broomstick has a speed update, show it on the screen.1
    self.Controllers.BroomstickController:ConnectEvent('SpeedUpdated', function(speed)
        self:SpeedUpdate(speed)
    end)

end

function HUD:Init() --synchronous
    local playerGui = HUD.Player:WaitForChild('PlayerGui')
    local hudGui = playerGui:WaitForChild('Hud')

    self.Speed.Housing = hudGui:WaitForChild('Speed')
    self.Speed.Label = self.Speed.Housing:WaitForChild('Label')
    self:SpeedUpdate(false)
end




function HUD:SpeedUpdate(speed)
    if not self.Speed.Label then return end

    if speed then
        self.Speed.Housing.Visible = true;
        self.Speed.Label.Text = math.round(speed);
    else
        self.Speed.Housing.Visible = false;
    end
end





return HUD