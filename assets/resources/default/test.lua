Main.bind_key("open_item_menu", "tab")

selected_item = nil

local block_preview_anchor = Main.ui.node3d("BlockPreviewAnchor")
block_preview_anchor:hide()
block_preview_anchor:set_position({ x = 0, y = 0, z = 0 })
block_preview_anchor:set_rotation_degrees({ x = 0, y = 0, z = 0 })
block_preview_anchor:set_scale({ x = 1, y = 1, z = 1 })

local block_menu_window = Main.ui.window("Block selection", true)
local block_menu_tabs = Main.ui.tabs()
block_menu_window:add_child(block_menu_tabs)

local block_hover_template = "[font_size=14][color=#CDCDCD]#%s %s[/color]\n[font_size=10][color=#8B8B8B]Content: %s[/color][/font_size]"
local current_preview_mesh = nil

local block_selection = Main.ui.selection_box("Selection")
block_selection:hide()
block_selection:set_position(Vector3.new(0, 0, 0))
block_selection:set_rotation_degrees(Vector3.new(0, 0, 0))
block_selection:set_scale(Vector3.new(1, 1, 1))

for _, category in ipairs(Main.blocks.categories()) do
    local tab = block_menu_tabs:add_tab(category, category)
    local scroll = Main.ui.scroll()
    local flow = Main.ui.flow()
    tab:add_child(scroll)
    scroll:add_child(flow)

    for _, block in ipairs(Main.blocks.list({ category = category })) do
        local icon = Main.blocks.icon(block.id)
        icon:set_hover_text(string.format(block_hover_template, tostring(block.id), tostring(block.slug), tostring(block.content)))
        icon:on("clicked", function(clicked_block_id)
            selected_item = BlockDataInfo.new(block.id)
            local mesh = Main.blocks.mesh(block.id)
            mesh:set_preview_color({ r = 0, g = 1, b = 0 }, 0.5)
            if selected_item ~= nil and selected_item.face ~= nil then
                mesh:set_face_rotation(selected_item.face)
            end
            current_preview_mesh = mesh
            block_preview_anchor:clear_children()
            block_preview_anchor:show()
            block_preview_anchor:add_child(mesh)
            block_menu_window:toggle()
        end)
        flow:add_child(icon)
    end
end

block_menu_window:hide()

Main.register_event("look_at_event", function(look_at)
    if look_at == nil then
        block_selection:hide()
        block_preview_anchor:hide()
        return
    end

    block_selection:show()
    block_selection:set_global_position(look_at.selected_block + Vector3.new(0.5, 0.5, 0.5))

    if selected_item == nil then
        block_preview_anchor:hide()
        return
    end

    if current_preview_mesh == nil then
        local mesh = Main.blocks.mesh(selected_item.id)
        mesh:set_preview_color({ r = 0, g = 1, b = 0 }, 0.5)
        if selected_item.face ~= nil then
            mesh:set_face_rotation(selected_item.face)
        end
        current_preview_mesh = mesh
        block_preview_anchor:clear_children()
        block_preview_anchor:add_child(mesh)
    end

    block_preview_anchor:show()
    block_preview_anchor:set_global_position(look_at.place_block + Vector3.new(0.5, 0.5, 0.5))
end)

Main.register_event("player_action_event", function(event)
    if event.hit ~= nil then
        if event.action_type == "main" then
            if selected_item ~= nil then
                local slug = "place_block"
                Main.send_network_event(slug, {
                    position = event.hit.place_block,
                    new_block_info = selected_item,
                })
            end
        elseif event.action_type == "second" then
            local slug = "delete_block"
            Main.send_network_event(slug, {
                position = event.hit.selected_block,
            })
        end
    end
end)

Main.register_event("input_action_pressed_event", function(event)
    if event.action == "open_item_menu" then
        block_menu_window:toggle()
    elseif event.action == "rotate_left" then
        if selected_item ~= nil then
            selected_item.face = selected_item.face:rotate_left()
            if current_preview_mesh ~= nil then
                current_preview_mesh:set_face_rotation(selected_item.face)
            end
        end
    elseif event.action == "rotate_right" then
        if selected_item ~= nil then
            selected_item.face = selected_item.face:rotate_right()
            if current_preview_mesh ~= nil then
                current_preview_mesh:set_face_rotation(selected_item.face)
            end
        end
    elseif event.action == "cancel_selection" then
        selected_item = nil
        current_preview_mesh = nil
        block_preview_anchor:clear_children()
        block_preview_anchor:hide()
        block_menu_window:hide()
    end
end)
