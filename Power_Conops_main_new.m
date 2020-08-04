
%26 insurmountable rocks according to rock distribution data 
rock_findings = [3, 5, 6.5, 9, 11.5, 14, 15.5, ...
                 16.5, 22, 24, 26.5, 28.75, ...
                 31, 33.75, 35, 37, 38.5, 40 ...
                 41.5, 43, 45.75, 47, 48.5, ...
                 50, 51];

is_charging = false;
time_charging = 0;
trek_phase2 = [2.25 : .25: 50.75];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%after initial two hours of charging, battery SOC should be at around 90%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%starting at index 11, since this is where contants file left off
index = 11;
for spec_time = trek_phase2
    display(spec_time)
    rock_found = ismember(spec_time, rock_findings);
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    
    if (rock_found && ~is_charging)
        display("rock was found")   
        %a 90-degree point turn consumes about 96 joules of energy
        
        %we broke up the avoidance manuevers into 2 parts,
        %one part consists of energy expended by 2 90-degree point turns
        %the second part consists of energy expended through skid-turn
        battery_cap(index) = battery_cap(index-1) - 560/3600;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
        index = index + 1;
        continue
    end
    
    display(battery_soc(index-1) < .25 && ~is_charging)
    if (battery_soc(index-1) < .25 && ~is_charging)
        is_charging = true;
        
        load_out(index) = charge_min(1);
        load_in(index)  = charge_min(2)*curr_sangle_offset;
        net_power(index) = load_in(index) - load_out(index);
        battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1);
        display("STARTING TO CHARGE")
    elseif (is_charging)
        if (battery_soc(index-1) >= .75)
            
            display("DONE CHARGING")
            time_charging = 0;
            
            load_out(index) = nom_rove(1);
            load_in(index)  = nom_rove(2);
            net_power(index) = load_in(index) - load_out(index);
            battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1)+distance_covered;
            
            is_charging = false;
            index = index + 1;
            continue
        else
            time_charging = time_charging + .25;
            
            load_out(index) = charge_min(1);
            load_in(index)  = charge_min(2)*curr_sangle_offset;
            net_power(index) = load_in(index) - load_out(index);
            battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1);
            
        end
    else
        load_out(index) = nom_rove(1);
        load_in(index)  = nom_rove(2);
        net_power(index) = load_in(index) - load_out(index);
        battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
    end
   
    index = index + 1;
end