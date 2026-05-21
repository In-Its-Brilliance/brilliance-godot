Main.bind_key("toggle_inventory", "tab")

local inventory_root = Main.ui.modal("inventory")
local inventory_dim = Main.ui.color_rect(Main.color(0.0, 0.0, 0.0, 0.12))
local inventory_panel = Main.ui.panel()
local inventory_slots_root = Main.ui.grid(8)

Main.ui.add_child(inventory_root)
inventory_root:add_child(inventory_dim)
inventory_root:add_child(inventory_panel)
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
