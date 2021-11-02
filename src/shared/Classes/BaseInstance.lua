--[[ CLASS via AeroFramework

BaseInstance
Integern
27/10/2021

METHODS

    BaseInstance:Init()
    BaseInstance:Start()
    BaseInstance.new()

    BaseInstance:IsA(String some_className) Bool doesInherit
    BaseInstance:Destroy()
    BaseInstance:AddDestroyCallback(Function callback)
    BaseInstance:AddEvent(String event_name)
    BaseInstance:FireEvent(String event_name, ...)
    BaseInstance:ConnectEvent(String event_name, Function callback) Listener listener

    DOCUMENTATION:

        Init()
            Called upon reference of module; run asynchronously

        Start()
            Called upon refernece of module after Init(); run synchronously

        new()
            Constructor for BaseInstance class

        IsA(String some_className)
            Tells us if this class inherits from the given Classname

        Destroy()
            Destroys the class, cleans everything up. Will also run destroy callbacks

        AddDestroyCallback(Function callback)
            Gives a callback function which will run when Destroy() is called

        AddEvent(String event_name)
            Creates an event in the class

        FireEvent(String event_name, ...)
            Will fire the given event (if it has been added to the class with the same name) with the given arguments

        ConnectEvent(String event_name, Function callback)
            Will run the callback function when the named event is fired with its given arguments. Returns a listener


CLASS VALUES

    String ClassName
        "


EVENTS

    Destroying()
        Called just before the class gets destroyed


MODULE VALUES


--]]


local BaseInstance = {}
BaseInstance.__index = BaseInstance





function BaseInstance:Start()
end

function BaseInstance:Init()
end





function BaseInstance.new(...)

    --///////////////////////////////////////////////////////
    local self = {}
    setmetatable(self, BaseInstance)

    self._Inheritance = {}
    self.ClassName = false;
    self:_SetClassName("BaseInstance") -- Class Name
    --///////////////////////////////////////////////////////
    
    self.Maid = BaseInstance.Shared.Maid.new();

    self._Events = {};
    
    self._DestroyCallbacks = {}
    self:AddEvent('Destroying')



    return self
    
end







function BaseInstance:IsA(some_className)
    for _,inherit in pairs(self._Inheritance) do
        if inherit == some_className then
            return true;
        end
    end

    return false;
end



function BaseInstance:Destroy()
    self:FireEvent('Destroying')
    wait()

    for _,destroyCallback in pairs(self._DestroyCallbacks) do
        destroyCallback(self)
    end

    self.Maid:DoCleaning()
end

function BaseInstance:AddDestroyCallback(callback)
    table.insert(self._DestroyCallbacks, callback)
end





function BaseInstance:AddEvent(event_name)
    if self._Events[event_name] then
        warn('Event ' .. event_name .. 'already exists.')
        return
    end

    local signal = BaseInstance.Shared.Signal.new(self.Maid);
    self._Events[event_name] = signal;

    self.Maid:GiveTask(signal)
end

function BaseInstance:RegisterEvent(...) --cheeky override from aeroframework
    self:AddEvent(...)
end

function BaseInstance:FireEvent(event_name, ...)
    self:_GetEvent(event_name):Fire(...)
end

function BaseInstance:ConnectEvent(event_name, callback)
    local listener = self:_GetEvent(event_name):Connect(callback)
    self.Maid:GiveTask(listener);

    return listener;
end

function BaseInstance:_GetEvent(event_name)
    if not self._Events[event_name] then
        error('No event ' .. event_name)
    end

    return self._Events[event_name]
end




function BaseInstance:_SetClassName(class_name)
    table.insert(self._Inheritance, class_name)
    self.ClassName = class_name
end
    





return BaseInstance