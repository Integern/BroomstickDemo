--[[ MODULE via AeroFramework

Raycasting
Integern
27/10/2021


METHODS

    Raycasting:Init()
    Raycasting:Start()
    Raycasting:Raycast(Vector3 position, Vector3 direction, Number distance, Table filterDescendantsInstances)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        Raycast(Vector3 position, Vector3 direction, Number distance, Table filterDescendantsInstances)
            Will raycast with the given parameters, where distance is how far it will check from position. If given filterDescendantsInstances,
            will only check raycast against objects+their descendants in the table.


CONSTANTS

    RaycastParams RaycastParameters
        RaycastParams that is used for raycasting; expensive to create a new one for every raycast


EVENTS


--]]
local Raycasting = {}

local RaycastParameters = RaycastParams.new()
RaycastParameters.FilterDescendantsInstances = {};
RaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist;





--function Raycasting:Start()
--end

--function Raycasting:Init()
--end




function Raycasting:Raycast(position, direction, distance, filterDescendantsInstances)
    
    direction = direction.Unit * distance;
    RaycastParameters.FilterDescendantsInstances = filterDescendantsInstances or false;


    return game.Workspace:Raycast(position, direction, RaycastParameters);
end





return Raycasting