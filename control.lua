--control.lua

--TODO: find a way to filter trainstops that has an id signal to avoid doing (A-1)
--TODO: find a way so theres no need to do (A-2). Maybe find all id signals involved.
--TODO: iterate all trainstops to get all signals involved to avoid having to do (A-3)
--TODO: find shortest requester-provider pair
--TODO: check if train can path (add option to disable)
--TODO: priority
--TODO: ignore signals coming out of the train (stopped train, train count)
--TODO: multi-surface support
--TODO: multi-force support
--TODO: no path warning opt-out setting for better performance

local NETWORK_SIGNAL_ID = {type = "virtual", name = "stl-network-id"}
local PRIORITY_SIGNAL_ID = {type = "virtual", name = "stl-priority"}

-- changes the next schedule and sends the train to the target station
-- appends schedule if the current is last.
-- wait condition will be set to empty if train has cargo, filled if cargo is empty
-- insert a temporary stop just before the target station to support stations with same names
local function sendTrainToStation(train, station)
  local schedule = train.schedule
  if table_size(train.get_contents()) == 0
  then
    schedule.records[train.schedule.current + 1] = {station = station.backer_name, wait_conditions = {{type = "full", compare_type = "or"}}}
  else
    schedule.records[train.schedule.current + 1] = {station = station.backer_name, wait_conditions = {{type = "empty", compare_type = "or"}}}
  end
    table.insert(schedule.records, train.schedule.current + 1, {rail = station.connected_rail, rail_direction = station.connected_rail_direction, temporary = true, wait_conditions = {{compare_type = "or", ticks = 0, type = "time"}}})
  schedule.current = train.schedule.current + 1
  train.schedule = schedule

end


local function canPath(train, station)

end

script.on_event(defines.events.on_player_ammo_inventory_changed,
  function(event)
    game.print("event: changed ammo")
    local trainStops = game.get_train_stops()
    local logNets = {}
    local highestPrio = 0
    local lowestPrio = 0
    local currentPrio = 0

    for _,station in pairs (trainStops)
    do
      local signals = station.get_merged_signals()
      local netId = station.get_merged_signal(NETWORK_SIGNAL_ID)

      if netId ~= 0 and not station.get_control_behavior().disabled and station.connected_rail --(A-1)
      then
        if logNets[netId] == nil --(A-2)
        then 
          logNets[netId] = {}
          logNets[netId]["prov"] = {}
          logNets[netId]["req"] = {}
        end

        -- game.print(station.backer_name .. " : " .. serpent.line(signals))

        for _,signal in pairs(signals)
        do

          local sigName = signal.signal.name

          if not (sigName == "stl-network-id" or sigName == "stl-priority")
          then 

            game.print(station.backer_name .. " : " .. serpent.line(signal))

            if logNets[netId]["prov"][sigName] == nil --(A-3)
            then 
              logNets[netId]["prov"][sigName] = {}
              logNets[netId]["req"][sigName] = {}
            end

            

            if signal.count > 0 and station.get_stopped_train()
            then
              game.print("new provider: " .. station.backer_name)
              
              table.insert(logNets[netId]["prov"][sigName], station)

            elseif signal.count < 0 and station.trains_limit-station.trains_count > 0
            then
              game.print("new requester: " .. station.backer_name)
              table.insert(logNets[netId]["req"][sigName], station)
            end
          end

        end
      end
    end


    for netId, network in pairs(logNets)
    do
      for signal, requesterList in pairs(network["req"])
      do
        for _, requester in pairs(requesterList)
        do
          for iProv, provider in pairs(network["prov"][signal])
          do
            game.print(provider.backer_name .. " -> " .. requester.backer_name)

            sendTrainToStation(provider.get_stopped_train(), requester)
            table.remove(network["prov"][signal], iProv)
            
            break
          end

        end
      end
    end


  end)


script.on_event(defines.events.on_built_entity,
  function(event)
  
    game.print("event: built entity")
    -- local trains = game.get_surface("nauvis").get_trains()

    -- local schedule= {}
    -- for k,v in pairs(trains)
    -- do
    --   game.print(v.id)
    --   schedule = v.schedule
    --   game.print(serpent.line(schedule))
    --   break
    -- end


    -- local inv = {}
    -- for k,v in pairs(trains)
    -- do
    --   game.print(v.id)
    --   inv = v.get_contents()
    --   break
    -- end

    -- game.print(#inv)

    -- for k,v in pairs(inv)
    -- do
    --   game.print(k .. ":" .. v)
    -- end


    local stations = game.get_train_stops()
    for k,station in pairs(stations)
    do
      local signalID = {type = "virtual", name = "stl-priority"}
      game.print(station.backer_name)
      game.print(station.get_merged_signal(signalID))
      break
    end

  end)