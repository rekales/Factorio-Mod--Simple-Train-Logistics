--data.lua

--TODO: Reset Schedule Signal
--TODO: Cancel Provide Signal
--TODO: Cancel Request Signal
--TODO: Wait for Wait Condition Signal
--TODO: Alert For Movement Signal

data:extend({
    {
        type = "item-subgroup",
        name = "STL-signal",
        group = "signals",
        order = "f",
    },
    {
        type = "virtual-signal",
        name = "stl-network-id",
        icon = "__simple-train-logistics__/graphics/icons/network_id.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-a"
    },
    {
        type = "virtual-signal",
        name = "stl-priority",
        icon = "__simple-train-logistics__/graphics/icons/priority.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-b"
    },

})