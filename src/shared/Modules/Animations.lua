--[[ MODULE via AeroFramework

Animations
Integern
01/11/2021


METHODS

    Animations:Init()
    Animations:Start()

    Animations:RunOnCharacter(String animation_name, Character character)

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        RunOnCharacter(String animation_name, Character character)
            Will play the animation with the given name (from our table Animations.Ids) on the given character


CONSTANTS

    Table Animations.Ids
        Store our animation IDs with a given name


EVENTS


--]]
local Animations = {}

Animations.Ids = {
    BroomstickSit = 'rbxassetid://7851126809';
    BroomstickFly = 'rbxassetid://7851128375';

    __index = function(_,index)
        error('No animation ' .. index)
    end
}

Animations._CharacterInfo = {}





--function Animations:Start()
--end

function Animations:Init()
end




function Animations:RunOnCharacter(animation_name, character)

    local info = Animations:_GetCharacterInfo(character);

    if not info.animations[animation_name] then
        local animation = Instance.new('Animation')
        animation.AnimationId = Animations.Ids[animation_name]

        local animationTrack = info.animator:LoadAnimation(animation);
        info.animations[animation_name] = animationTrack

        info.maid:GiveTask(animation)
        info.maid:GiveTask(animationTrack)
    end

    info.animations[animation_name]:Play()

    return info.animations[animation_name]

end




function Animations:_GetCharacterInfo(character)
    if not Animations._CharacterInfo[character] then

        local maid = Animations.Shared.Maid.new()
        maid:GiveTask(character:GetPropertyChangedSignal('Parent'):Connect(function()
            if character.Parent == nil then --been removed
                Animations:_ClearCharacterInfo(character)
            end
        end))

        Animations._CharacterInfo[character] = {
            maid = maid;
            animations = {};
            animator = character:WaitForChild('Humanoid')
        }
    end

    return Animations._CharacterInfo[character]
end

function Animations:_ClearCharacterInfo(character)
    local info = Animations:_GetCharacterInfo(character)
    if info then
        info.maid:DoCleaning()
        Animations._CharacterInfo[character] = nil
    end
end





return Animations