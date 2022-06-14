--data.lua

data:extend({
    {
        type = "item-subgroup",
        name = "STL-signal",
        group = "signals",
        order = "f-b-b-b",
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
    {
        type = "virtual-signal",
        name = "stl-reset-schedule",
        icon = "__simple-train-logistics__/graphics/icons/reset.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-c"
    },
    {
        type = "virtual-signal",
        name = "stl-wait-for-condition",
        icon = "__simple-train-logistics__/graphics/icons/wait.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-d"
    },
    {
        type = "virtual-signal",
        name = "stl-alert-for-movement",
        icon = "__simple-train-logistics__/graphics/icons/alert.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-e"
    },
    {
        type = "virtual-signal",
        name = "stl-cancel-provide",
        icon = "__simple-train-logistics__/graphics/icons/cancel_provide.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-f"
    },
    {
        type = "virtual-signal",
        name = "stl-cancel-request",
        icon = "__simple-train-logistics__/graphics/icons/cancel_request.png",
        icon_size = 64,
        subgroup = "STL-signal",
        order = "a-g"
    },



})