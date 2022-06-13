--control.lua

--TODO: find a way to filter trainstops that has an id signal to avoid doing (A-1)
--TODO: find a way so theres no need to do (A-2). Maybe find all id signals involved.
--TODO: iterate all trainstops to get all signals involved to avoid having to do (A-3)
--TODO: find shortest requester-provider pair
--TODO: priority
--TODO: don't send trains when station is at full limit. Caused by trains pathing to temporary stops

local NETWORK_SIGNAL_ID = {type = "virtual", name = "stl-network-id"}
local PRIORITY_SIGNAL_ID = {type = "virtual", name = "stl-priority"}

local STATION_BLOCKED_SIGNAL_NAMES = {["stl-network-id"] = true, ["stl-priority"] = true}


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


local function on_player_ammo_inventory_changed(event)

  local forces = game.forces
  for _, force in pairs(forces)
  do
    local surfaces = game.surfaces
    for surfaceIndex, _ in pairs(surfaces)
    do
      game.print("event: changed ammo")
      local trainStops = force.get_train_stops({surface = surfaceIndex})
      local logNets = {}
      local highestPrio = 0
      local lowestPrio = 0
      local currentPrio = 0

      for _,station in pairs (trainStops)
      do
        local signals = station.get_merged_signals()
        local netId = station.get_merged_signal(NETWORK_SIGNAL_ID)
        local stationControlBehavior = station.get_control_behavior()

        if netId ~= 0 and not station.get_control_behavior().disabled and station.connected_rail --(A-1)
        then
          if logNets[netId] == nil --(A-2)
          then 
            logNets[netId] = {}
            logNets[netId]["prov"] = {}
            logNets[netId]["req"] = {}
          end

          for _,signal in pairs(signals)
          do
            local sigName = signal.signal.name
            if not (STATION_BLOCKED_SIGNAL_NAMES[sigName] 
                or (stationControlBehavior.read_trains_count and sigName == stationControlBehavior.trains_count_signal.name)
                or (stationControlBehavior.read_stopped_train and sigName == stationControlBehavior.stopped_train_signal.name)
                or (stationControlBehavior.set_trains_limit and sigName == stationControlBehavior.trains_limit_signal.name))
            then 

              if logNets[netId]["prov"][sigName] == nil --(A-3)
              then 
                logNets[netId]["prov"][sigName] = {}
                logNets[netId]["req"][sigName] = {}
              end

              if signal.count > 0 and station.get_stopped_train()
              then
                -- game.print("new provider: " .. station.backer_name)
                
                table.insert(logNets[netId]["prov"][sigName], station)

              elseif signal.count < 0 and station.trains_limit-station.trains_count > 0
              then
                game.print(station.trains_limit)
                game.print(station.trains_count)
                game.print(station.trains_limit-station.trains_count)
                
                -- game.print("new requester: " .. station.backer_name)
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
    end
  end
end


local function on_built_entity(event)
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
    if station.backer_name == "LordOfTheTrains"
    then
      local signalID = {type = "virtual", name = "stl-priority"}
      game.print(station.backer_name)
      game.print(station.get_merged_signal(signalID))
      game.print(serpent.line(station.get_control_behavior().trains_count_signal))
      game.print(serpent.line(station.get_control_behavior().stopped_train_signal))
      game.print(serpent.line(station.get_merged_signals()))
      break
    end
  end
end


script.on_event(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)