mod_gui = require("mod-gui")


script.on_init(function()
    storage.players = storage.players or {}
end)

script.on_event(defines.events.on_console_command, function(event)
    if event.command ~= "waypoints" then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    storage.players[player.index] = storage.players[player.index] or {}
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow["tp_button"] then
        print("Creating button for player: " .. player.name)
        button_flow.add { type = "sprite-button", name = "tp_button", sprite = "utility/refresh", style = mod_gui.button_style }
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    print("Player created: " .. player.name)
    if not player or not player.valid then
        return
    end
    storage.players[player.index] = storage.players[player.index]
    local button_flow = mod_gui.get_button_flow(player)
    print("Creating button for player: " .. player.name)
    button_flow.add { type = "sprite-button", name = "tp_button", sprite = "utility/refresh", style = mod_gui.button_style }
end)

---@param player LuaPlayer
function create_waypoint_frame(player)
    local screen = player.gui.screen
    local frame = screen.add {
        type = "frame",
        name = "tp_waypoint_frame",
        caption = "Waypoints",
        direction = "vertical",
        style = mod_gui.frame_style,

    }
    frame.location = { x = 0, y = 60 }

    local waypoints_flow = frame.add { type = "flow", direction = "vertical", name = "tp_waypoints_flow" }

    for i, waypoint in pairs(storage.players[player.index] or {}) do
        print("Adding waypoint for player: " .. player.name .. " - " .. (waypoint.name or "Unnamed"))
        if waypoint then
            local waypoint_flow = waypoints_flow.add { type = "flow", direction = "horizontal", name = "tp_waypoint_flow_" .. i }
            local warp_button = waypoint_flow.add {
                type = "button",
                name = "tp_warp_to_waypoint_" .. waypoint.name,
                caption = waypoint.name or "Unnamed",
                style = mod_gui.button_style
            }
            warp_button.style.width = 160
            warp_button.style.height = 30
            local delete_button = waypoint_flow.add {
                type = "button",
                name = "tp_delete_waypoint_" .. waypoint.name,
                caption = "[virtual-signal=signal-trash-bin]",
                style = mod_gui.button_style
            }
            delete_button.style.width = 30
            delete_button.style.height = 30
        end
    end

    -- Create the input field for waypoint name
    local name_flow = frame.add { type = "flow", direction = "horizontal", name = "tp_waypoint_name_flow" }
    local name_input = name_flow.add { type = "textfield", name = "tp_waypoint_name" }
    name_input.style.width = 160
    name_input.style.height = 30
    local name_button = name_flow.add {
        type = "button",
        name = "tp_add_waypoint",
        caption = "[virtual-signal=shape-cross]",
        style = mod_gui.button_style
    }
    name_button.style.width = 30
    name_button.style.height = 30
end

---@param player LuaPlayer
function refresh(player)
    if not player or not player.valid then
        return
    end

    local frame = player.gui.screen["tp_waypoint_frame"]
    if frame then
        frame.destroy()
    end

    create_waypoint_frame(player)
end

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "tp_button" then
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if player.gui.screen["tp_waypoint_frame"] then
            player.gui.screen["tp_waypoint_frame"].destroy()
            return
        end

        create_waypoint_frame(player)
        return
    end

    if event.element.name == "tp_add_waypoint" then
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local name_input = player.gui.screen["tp_waypoint_frame"]["tp_waypoint_name_flow"]["tp_waypoint_name"]
        if not name_input or not name_input.valid then
            return
        end

        local waypoint_name = name_input.text
        if waypoint_name and #waypoint_name > 0 then
            storage.players[player.index] = storage.players[player.index] or {}
            storage.players[player.index][waypoint_name] = {
                name = waypoint_name,
                position = player.position,
                surface = player.surface.name
            }
            player.print("Waypoint '" .. waypoint_name .. "' added at your current position.")
            name_input.text = ""
            refresh(player)
        else
            player.print("Please enter a valid waypoint name.")
        end
        return
    end

    if string.find(event.element.name, "^tp_warp_to_waypoint_") ~= nil then
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local waypoint_name = string.sub(event.element.name, 21)
        if storage.players[player.index] and storage.players[player.index][waypoint_name] then
            local waypoint = storage.players[player.index][waypoint_name]
            if waypoint and waypoint.position and waypoint.surface then
                local surface = game.get_surface(waypoint.surface)
                if surface then
                    player.teleport(waypoint.position, surface)
                    player.print("Warped to waypoint '" .. waypoint_name .. "'.")
                else
                    player.print("Surface '" .. waypoint.surface .. "' does not exist.")
                end
            else
                player.print("Invalid waypoint data for '" .. waypoint_name .. "'.")
            end
        else
            player.print("Waypoint '" .. waypoint_name .. "' does not exist.")
        end
    end

    if string.find(event.element.name, "^tp_delete_waypoint_") ~= nil then
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local waypoint_name = string.sub(event.element.name, 20)
        if storage.players[player.index] and storage.players[player.index][waypoint_name] then
            storage.players[player.index][waypoint_name] = nil
            player.print("Waypoint '" .. waypoint_name .. "' deleted.")
            refresh(player)
        else
            player.print("Waypoint '" .. waypoint_name .. "' does not exist.")
        end
    end
end)
