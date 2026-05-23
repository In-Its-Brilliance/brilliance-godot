Main.bind_key("toggle_inventory", "tab")

local inventory_shader = Main.ui.create_shader()
inventory_shader:add_resource("res://assets/shaders/blure.gdshader")
local inventory_vignette_shader = Main.ui.create_shader()
inventory_vignette_shader:add_resource("res://assets/shaders/vignette_dithered.gdshader")

local inventory_material = Main.ui.create_material()
inventory_material:set_shader(inventory_shader)
inventory_material:set_shader_parameter("blur_amount", 2.0)
inventory_material:set_shader_parameter("darken", 0.35)

local inventory_vignette_material = Main.ui.create_material()
inventory_vignette_material:set_shader(inventory_vignette_shader)
inventory_vignette_material:set_shader_parameter("darken_amount", 1.0)
inventory_vignette_material:set_shader_parameter("vignette_strength", 1.0)
inventory_vignette_material:set_shader_parameter("vignette_start", 0.4)

local inventory_root = Main.ui.modal("inventory")
local inventory_dim = Main.ui.color_rect(Main.color(0.0, 0.0, 0.0, 0.0))
inventory_dim:set_material(inventory_material)
local inventory_vignette = Main.ui.color_rect(Main.color(0.0, 0.0, 0.0, 0.0))
inventory_vignette:set_material(inventory_vignette_material)

Main.ui.add_child(inventory_root)
inventory_root:add_child(inventory_dim)
inventory_root:add_child(inventory_vignette)

local top_bar = Main.ui.top_bar()
inventory_root:add_child(top_bar)

local inventory_tab = top_bar:add_tab("inventory", "Inventory")
local skills_tab = top_bar:add_tab("skills", "Skills")
local quests_tab = top_bar:add_tab("quests", "Quests")

local inventory_center = Main.ui.control()
inventory_tab:add_child(inventory_center)

local inventory_panel = Main.ui.panel()
inventory_center:add_child(inventory_panel)

local inventory_slots_root = Main.ui.grid(8)
inventory_panel:add_child(inventory_slots_root)
inventory_root:hide()

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
    top_bar:set_active("inventory")
    inventory_root:show()
    Main.ui.show_mouse()
end

local function close_inventory()
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
