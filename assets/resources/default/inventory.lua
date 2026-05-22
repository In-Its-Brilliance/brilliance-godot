Main.bind_key("toggle_inventory", "tab")

local inventory_shader = Main.ui.create_shader()
inventory_shader:add_resource("res://assets/shaders/blure.gdshader")

local inventory_material = Main.ui.create_material()
inventory_material:set_shader(inventory_shader)
inventory_material:set_shader_parameter("blur_amount", 2.0)
inventory_material:set_shader_parameter("darken", 0.35)

local inventory_root = Main.ui.modal("inventory")
local inventory_dim = Main.ui.color_rect(Main.color(0.0, 0.0, 0.0, 0.0))
inventory_dim:set_material(inventory_material)
local inventory_panel = Main.ui.panel()
local inventory_slots_root = Main.ui.grid(8)

Main.ui.add_child(inventory_root)
inventory_root:add_child(inventory_dim)
inventory_root:add_child(inventory_panel)

local inventory_top_panel = Main.ui.panel()
inventory_top_panel:set_position(Main.vec2(0.0, 0.0))
inventory_top_panel:set_width(1.0)
inventory_top_panel:set_height_px(50)
inventory_top_panel:set_margin(0, 0, 0, 0)
inventory_top_panel:set_axis_stretch(1, 0)
inventory_top_panel:set_frame_margins(0, 10, 0, 10)
inventory_top_panel:set_texture("res://assets/gui/textures/bar/bb_bar.png")
inventory_top_panel:flip_texture_height()
inventory_root:add_child(inventory_top_panel)

local top_bar_row = Main.ui.h_box_container()
top_bar_row:set_width(1.0)
top_bar_row:set_height_px(44)
inventory_top_panel:add_child(top_bar_row)

local left_side = Main.ui.texture()
left_side:set_minimum_size_px(24, 44)
left_side:set_texture("res://assets/gui/textures/bar/bb_button_side.png")
top_bar_row:add_child(left_side)

local right_side = Main.ui.texture()
right_side:set_minimum_size_px(24, 44)
right_side:set_texture("res://assets/gui/textures/bar/bb_button_side.png")
right_side:flip_texture_width()
top_bar_row:add_child(right_side)

local inventory_button = Main.ui.button("Inventory")
inventory_button:set_height_px(45)
inventory_button:set_width_px(110)
inventory_button:set_texture_normal("res://assets/gui/textures/bar/bb_button.png")
inventory_button:set_texture_hover("res://assets/gui/textures/bar/bb_button.png")
inventory_button:set_texture_pressed("res://assets/gui/textures/bar/bb_button.png")
top_bar_row:add_child(inventory_button)

local skills_button = Main.ui.button("Skills")
skills_button:set_height_px(45)
skills_button:set_width_px(110)
skills_button:set_texture_normal("res://assets/gui/textures/bar/bb_button.png")
skills_button:set_texture_hover("res://assets/gui/textures/bar/bb_button.png")
skills_button:set_texture_pressed("res://assets/gui/textures/bar/bb_button.png")
top_bar_row:add_child(skills_button)

inventory_panel:add_child(inventory_slots_root)
inventory_root:hide()
inventory_panel:hide()

local inventory = Main.player.get_inventory()

if inventory == nil then
    error("inventory not found")
end

for index = 1, #inventory:get_slots() do
    local slot_ui = Main.ui.inventory_slot(index - 1)
    inventory_slots_root:add_child(slot_ui)
end

local function open_inventory()
    inventory_panel:fit_and_center()
    inventory_root:show()
    inventory_panel:show()
    Main.ui.show_mouse()
end

local function close_inventory()
    inventory_panel:hide()
    inventory_root:hide()
    Main.ui.hide_mouse()
end

Main.register_event("input_action_pressed_event", function(event)
    if event.action == "toggle_inventory" then
        if inventory_root:is_visible() then
            close_inventory()
        else
            open_inventory()
        end
    end
end)
