--[[
    2x Bandwidth Switches Mod
    
    This mod doubles the bandwidth capacity of every switch when it's spawned in the game.
    The store display will continue to show the original value, giving players a nice bonus!
    
    Demonstrates:
    - Using callback functions to hook into game events
    - Accessing and modifying device properties
    - Working with the ModApiV1 interface
--]]

-- Called when all mods have been loaded and the engine is ready
function on_engine_load()
    print("High BW capacity switches mod loaded!")
    if ModApiV1 and ModApiV1.sanity then -- Verify the mod API is working correctly
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end
end

-- Called when the player presses the reload key (F11)
-- Useful for testing changes without restarting the game
function on_mod_reload()
    print("Pressed the reload action key (F11), reloading mod...")
end

-- Called whenever a device is spawned in the game world
---@param device DeviceUnit The device that was just spawned
function on_device_spawned(device)
    -- Check if this is a switch (device_hardware_class == 1)
    if device.device_hardware_class == 1 then
        -- Get the current bandwidth value
        local current_bw = device.logic_controller.installed_nbw
        
        -- Double the bandwidth capacity
        local new_bw = current_bw * 2
        device.logic_controller.installed_nbw = new_bw
        
        -- Log the modification for debugging
        print("Modified bandwidth of " .. device.product_name .. " from " .. current_bw .. " to " .. new_bw)
    end
end
