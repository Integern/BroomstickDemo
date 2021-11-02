--[[ SERVICE via AeroFramework

BroomstickService
Integern
27/10/2021


METHODS

    BroomstickService:Init()
    BroomstickService:Start()
    BroomstickService:SetupSpawning()

    BroomstickService.Client:ClearServerBodyMovers(Player player)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        SetupSpawning()
            Sets up the spawning of broomstick stands



        ClearServerBodyMovers(Player player)
            "; allows client body position and body gyro to take over control of their broomstick


CONSTANTS

    BroomstickService.Client
        Table that can be accessed by the client for communication with this service

    BroomstickService.Spawning
        Settings for spawning the stands for the broomsticks


SERVER EVENTS


CLIENT EVENTS

    BroomstickMounted([Player player,] Model broomstickModel)
        Informs the specified player that they have mounted the given broomstick model, and can take control of it.


--]]


local BroomstickService = {
    Client={};

    Spawning = {
        Count = 5; --how many to spawn
        Origin = Vector3.new(8, 0, 0); --position of first broomstick stand
        Offset = Vector3.new(0, 0, 8); --how far away to spawn the next broomstick stand

        RespawnWait = 15; --how long to wait before respawning a stand
    };

    Broomsticks = {};

    Debug = true;

}



local function debug(...)
    print('BROOMSTICKSERVICE', ...)
end



function BroomstickService:Start() --asynchronous
    self:SetupSpawning()
end

function BroomstickService:Init() --synchronous
    self:RegisterClientEvent('BroomstickMounted')

    game.Players.PlayerAdded:Connect(function(player)

        --clear broomstick if it exists
        if self.Broomsticks[player] then 
            self.Broomsticks[player]:Destroy()
            self.Broomsticks[player] = nil
        end

    end)

end









function BroomstickService:_FreshBroomstickStand(broomstickStand)

    local serverBroomstick = broomstickStand.ServerBroomstick;

    --listen for a player mounting the broomstick
    local mountListener;
    mountListener = serverBroomstick:ConnectEvent('OccupantChanged', function(player)
        if not player then return end;
        mountListener:Disconnect() --got our player!


        --inform the client they've got control of this broomstick
        self:FireClientEvent('BroomstickMounted', player, serverBroomstick.Model)

        --record this to the server
        self.Broomsticks[player] = serverBroomstick

        --track dismount of this player
        serverBroomstick:ConnectEvent('OccupantChanged', function(player)
            if player then
                warn('Had player ' .. player.Name .. ' mount?')
                return;
            end

            serverBroomstick:Destroy()
            self.Broomsticks[player] = nil;

            --dont need to inform client, as they're tracking this themself.
        end)

        --broomstick admin
        serverBroomstick.Model.Name ..= player.Name
        serverBroomstick.Model.Parent = self.Shared.Modules.World:GetWorldDirectory()
        broomstickStand.ServerBroomstick = false --detach reference from the broomstick in the broomstickstand so it does not get removed

        wait(BroomstickService.Spawning.RespawnWait) --give them time to float up
        broomstickStand:Destroy()


    end)

end




function BroomstickService:SetupSpawning()
    local settings = BroomstickService.Spawning

    local function spawn(position, name, model)
        local broomstickStand = BroomstickService.Shared.Classes.BroomstickStand.new(
            position,
            model:Clone()
        )

        --runs code for the new broomstick stand e.g. when someone hops on it
        self:_FreshBroomstickStand(broomstickStand)

        --spawn a (same) new one when it gets destroyed
        broomstickStand:ConnectEvent('Destroying', (function()
            spawn(position, name, model)
        end))
    end


    --spawn broomstick stands
    local i = 1;
    for name, model in pairs(self.Shared.Modules.Assets.Broomsticks) do 
        spawn(settings.Origin + settings.Offset * (i-1), name, model)
        i += 1;
    end

end




function BroomstickService.Client:ClearServerBodyMovers(player)
    local broomstick = BroomstickService.Broomsticks[player]
    if broomstick then
        if broomstick.BodyPosition then
            broomstick.BodyPosition.Parent = broomstick.BodyPosition.Parent.Parent;
        end
        if broomstick.BodyGyro then
            broomstick.BodyGyro.Parent = broomstick.BodyGyro.Parent.Parent;
        end
    else
        debug('No bodymovers for', player)
        return false;
    end

    debug('Cleared bodymovers for', player)
    return true;
end





return BroomstickService

