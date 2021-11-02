--[[ MODULE via AeroFramework

GetMoveVector
Integern
27/10/2021


METHODS

    GetMoveVector:Init()
    GetMoveVector:Start()

    GetMoveVector:Get()

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        Get()
            Returns our current move direction, regardless of physical input device


CONSTANTS

    Vitality
        Reference to Vitality Library


EVENTS


--]]
local GetMoveVector = {}
local Vitality;





--function GetMoveVector:Start()
--end

--function GetMoveVector:Init()
--    Vitality = GetMoveVector.Shared.Vitality
--end



function GetMoveVector:Get()
    return require(game.Players.LocalPlayer:WaitForChild("PlayerScripts").PlayerModule:WaitForChild("ControlModule")):GetMoveVector()
end





return GetMoveVector