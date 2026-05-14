print("&6Test resource loaded!")

Main.bind_key("open_item_menu", "tab")

local lua_window = Main.ui.window("Lua Block selection", true)
local lua_tabs = Main.ui.tabs()
lua_window:add_child(lua_tabs)

local block_hover_template = "[font_size=14][color=#CDCDCD]#%s %s[/color]\n[font_size=10][color=#8B8B8B]Content: %s[/color][/font_size]"

for _, category in ipairs(Main.blocks.categories()) do
    local tab = lua_tabs:add_tab(category, category)
    local scroll = Main.ui.scroll()
    local flow = Main.ui.flow()
    tab:add_child(scroll)
    scroll:add_child(flow)

    for _, block in ipairs(Main.blocks.list({ category = category })) do
        local icon = Main.blocks.icon(block.id)
        icon:set_hover_text(string.format(block_hover_template, tostring(block.id), tostring(block.slug), tostring(block.content)))
        flow:add_child(icon)
    end
end

lua_window:hide()

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

Main.register_event("input_action_pressed_event", function(event)
    print("&6input_action_pressed_event action=" .. tostring(event.action))
    if event.action == "open_item_menu" then
        print("&6open_item_menu pressed")
        lua_window:toggle()
    end
end)
