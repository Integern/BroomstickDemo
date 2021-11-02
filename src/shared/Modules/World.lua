--[[ MODULE via AeroFramework

World
Integern
27/10/2021


METHODS

    World:Init()
    World:Start()
    World:GetWorldDirectory() Folder directory

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        GetWorldDirectory()
            Returns the directory for all our world parts


CONSTANTS

    Folder Directory
        Directory for all the parts that make up our world


EVENTS


--]]
local World = {}
local Vitality;

local Directory = game.Workspace:WaitForChild('World')



--function World:Start()
--end

--function World:Init()
--end




function World:GetWorldDirectory()
    return Directory
end





return World