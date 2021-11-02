--[[

    02/11/2021, Joel Broad application for Dubit Games

    Vehicle Challenge: BROOMSTICK

    README (4 minutes)


    I have created a Broomstick vehicle, with a small area with obstacles in which to test the vehicle. Flying your broomstick into
    obstacles or other players will result in falling off the broomstick (ejection).

    After mounting the broomstick, you can fly it around the map by either accelerating forward in the direction your facing or by tilting the broomstick down and
    letting gravity come into play. Turning too sharply will result in a reduction in speed.




    PROJECT STRUCTURE

    -I created this project in Roblox Studio, using Rojo+VSCode to write my code. I made use of the AeroGameFramework to run+stucture my code.
        [ AreoGameFramework: https://sleitnick.github.io/AeroGameFramework/ ]

    -Code is split up into Server, Client and Shared files; the directories for the code can be found under:
        Server -> game.ServerStorage.Areo
        Client -> game.StarterPlayer.StarterPlayerScripts.Aero
        Shared -> game.ReplicatedStorage.Aero.Shared

        Code can also be found on my github:

    -game.World is where most parts are stored; any parts in here can collide with the broomstick and will cause in ejection.

    -game.RagdollLoader is a module by EchoReaper for easy implementation of ragdolls
        [ RagdollLoader: https://devforum.roblox.com/t/r15-rthro-ragdolls/338580 ]

    -game.ReplicatedStorage.Assets contains any assets for this project not found in the workspace e.g. broomstick models.
        Broomstick models are not mine, and were found in the Roblox Studio Toolbox.
        The WindSound is not mine, and was found on a royalty-free website.

    -I made use of Object Orientated Programming by the use of metatables. You can find the BaseInstance class in Shared.Classes.BaseInstance,
        every class inherits from this as it has useful methods (including inheritance, as well as adding/firing/connecting custom events)



    
    FEATURES

    - Clientside Network Ownership
    - Custom 3rd person perspective camera system
    - Heads up Display
    - Broomstick (re)spawning, mounting, flying and ejection
    - Collision detection
    - OOP; useful for easily creating/destroying broomsticks
    - Custom animation loader/player
    - Custom assets module, converting roblox heirachy to a table
    - Raycasting




    GAMEPLAY FLOWCHART

    For a startpoint, check out Services.BroomstickService:SetupSpawning()

    - Server spawns BroomstickStand(s), which has a broomstick model attached. 
    - When a player sits on a seat on a broomstick model, it assigns the player to that broomstick. We inform their client of this.
    - We give player control of the broomstick on their client; by giving different inputs (moving direction and looking ddirection and keybinds),
        we can cause the broomstick to move in the way we want.
    - Fly the broomstick around the map, dodging and weaving between obstacles, accelerating up and diving down for increased speed.
    - There is varying acceleration based on your current speed (drag calculations), how tight you turn, tilt angle (gravity)
    - If you crash, or press the ejection keybind, you fall off the broomstick into a ragdoll then respawn at the broomsticks.


]]