print("&6Test resource loaded!")

Main.bind_key("open_item_menu", "tab")

Main.register_event("player_action_event", function(event)
    local hit_info = "nil"
    if event.hit ~= nil then
        hit_info = "selected_block=" .. event.hit.selected_block.to_string()
    end

    local selected_item_info = "nil"
    if event.selected_item ~= nil then
        selected_item_info = event.selected_item.type
        if event.selected_item.block ~= nil then
            selected_item_info = selected_item_info .. " id=" .. tostring(event.selected_item.block.id)
        end
    end

    print("&6player_action_event action=" .. tostring(event.action_type) .. " hit=" .. hit_info .. " selected_item=" .. selected_item_info)
end)

Main.register_event("button_pressed_event", function(event)
    print("&6button_pressed_event action=" .. tostring(event.action))
    if event.action == "open_item_menu" then
        print("&6open_item_menu pressed")
    end
end)
