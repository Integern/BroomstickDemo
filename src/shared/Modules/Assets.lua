--[[ MODULE via AeroFramework

Assets
Integern
27/10/2021


METHODS

    Assets:Init()
    Assets:Start()

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously


CONSTANTS

    Folder Directory
        Folder that contains all our assets
    Assets
        Reference using the same heirachy as the directory


EVENTS


--]]
local Assets = {
    YieldDuration = 5;
}

local Directory = game.ReplicatedStorage:WaitForChild('Assets');




function Assets:Start()
end

function Assets:Init()

    local function populateTableFromFolder(t, folder)
        for _,child in pairs(folder:GetChildren()) do 
            if child.ClassName == 'Folder' then
                t[child.Name] = populateTableFromFolder({}, child)
            else
                t[child.Name] = child;
            end
        end

        return t
    end

    populateTableFromFolder(Assets, Directory)

end





return Assets