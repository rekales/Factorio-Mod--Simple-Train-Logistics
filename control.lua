--control.lua

--TODO: find a way to filter trainstops that has an id signal to avoid doing (A-1)
--TODO: find a way so theres no need to do (A-2). Maybe find all id signals involved.
--TODO: iterate all trainstops to get all signals involved to avoid having to do (A-3)
--TODO: find shortest requester-provider pair
--TODO: priority
--TODO: Reset Schedule Signal
--TODO: Cancel Provide Signal
--TODO: Cancel Request Signal
--TODO: Wait for Wait Condition Signal
--TODO: Alert For Movement Signal
--TODO: Optimize (A-5)

local NETWORK_SIGNAL_ID = {type = "virtual", name = "stl-network-id"}
local PRIORITY_SIGNAL_ID = {type = "virtual", name = "stl-priority"}
local RESET_SCHEDULE_SIGNAL_ID = {type = "virtual", name = "stl-reset-schedule"}
local WAIT_FOR_CONDITION_SIGNAL_ID = {type = "virtual", name = "stl-wait-for-condition"}
local ALERT_FOR_MOVEMENT_SIGNAL_ID = {type = "virtual", name = "stl-alert-for-movement"}
local CANCEL_PROVIDE_SIGNAL_ID = {type = "virtual", name = "stl-cancel-provide"}
local CANCEL_REQUEST_SIGNAL_ID = {type = "virtual", name = "stl-cancel-request"}

local STATION_BLOCKED_SIGNAL_NAMES = 
{
  ["stl-network-id"] = true,
  ["stl-priority"] = true,
  ["stl-reset-schedule"] = true,
  ["stl-wait-for-condition"] = true,
  ["stl-alert-for-movement"] = true,
  ["stl-cancel-provide"] = true,
  ["stl-cancel-request"] = true,
}


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


local function mainLoopThing(event)

  if (event.tick % 300 == 0)
  then
    -- game.print("event: changed ammo")
    local forces = game.forces
    for _, force in pairs(forces)
    do
      if #force.players > 0
      then
        local surfaces = game.surfaces
        for _, surface in pairs(surfaces)
        do
          local trainStops = force.get_train_stops({surface = surface})
          if #trainStops > 0
          then
            local logNets = {}
            local signals
            local stationControlBehavior

            for _,station in pairs (trainStops)
            do
              
              local netId = station.get_merged_signal(NETWORK_SIGNAL_ID)
              

              if netId ~= 0 and not station.get_control_behavior().disabled and station.connected_rail --(A-1)
              then
                if logNets[netId] == nil --(A-2)
                then 
                  logNets[netId] = {}
                  logNets[netId]["prov"] = {}
                  logNets[netId]["req"] = {}
                end
                signals = station.get_merged_signals()
                stationControlBehavior = station.get_control_behavior()


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
                      local trains = station.get_train_stop_trains() --(A-5)
                      local occupied = false
                      for _,train in pairs(trains)
                      do
                        if train.schedule.records[train.schedule.current].temporary and train.schedule.records[train.schedule.current].rail == station.connected_rail
                        then
                          occupied = true
                          break
                        end
                      end
                      
                      if not occupied
                      then
                        table.insert(logNets[netId]["req"][sigName], station)
                        -- game.print("new requester: " .. station.backer_name)
                      end

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
                    -- game.print(signal .. ": " ..provider.backer_name .. " -> " .. requester.backer_name)
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
    end
  end
end


-- local function on_built_entity(event)

-- end

local function on_train_changed_state(event)
  if event.train.state == defines.train_state.wait_station and event.train.station and event.train.station.get_merged_signal(RESET_SCHEDULE_SIGNAL_ID) > 0
  then
    local schedule = event.train.schedule
    schedule.records = {schedule.records[schedule.current]}
    schedule.current = 1
    event.train.schedule = schedule
  end
end


script.on_event(defines.events.on_tick, mainLoopThing)
script.on_event(defines.events.on_train_changed_state, on_train_changed_state)
-- script.on_event(defines.events.on_built_entity, on_built_entity)