
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% START USER DEFINED PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%time_resolution = 

begin_charge_soc = .5;
end_charge_soc   = .6;
rove_duration    =  0; %in hours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% END USER DEFINED PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%26 insurmountable rocks according to rock distribution data 
%need to change this to 40 rocks
rock_findings = [150,153,156,159,165 ...
                 250, 256, 280];

is_charging = false;
is_avoiding = false;
time_avoiding = 0; %in mins
trek_phase2 = [2*time_scale + time_step : time_step: time_end - 1];

%we broke up the avoidance manuevers into 2 parts,
%one part consists of energy expended by 2 90-degree point turns
%the second part consists of energy expended while skid-steering

%don't forget to also consider the energy used by avionics
%energy used by avionics during avoidance = power * 3mins * 60s/1min
%must convert it to Wh, so divide by 3600
avoidance_duration = 3; %in mins
point_turn_energy = 10 * 28; %power*time for 90-degree turn
skid_energy = 1.2 * point_turn_energy; %according to papers we read

%next two calculations need to incorporate time_scale somehow
avionics_consumption = (45.01 * 1 * 60)/3600; %power * time in mins * 60s 
avoidance_consumption = (2*point_turn_energy + skid_energy)/(3600*avoidance_duration); %divide by 60 for per-minute consumption

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%after initial two hours of charging, battery SOC should be at around 90%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%starting at index 11, since this is where contants file left off
index = 121;
for spec_time = trek_phase2
    sprintf("Current time and index: %d, %d", spec_time, index)
    rock_found = ismember(spec_time, rock_findings);
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    
    if (rock_found && ~is_charging)
        display("rock was found")         
        is_avoiding = true;
        
        battery_cap(index) = battery_cap(index-1) ...
                             - avoidance_consumption - avionics_consumption;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
        index = index + 1;
        continue
    elseif (is_avoiding)
        if (time_avoiding == avoidance_duration)
            is_avoiding = false;
            time_avoiding = 0;
            
            energy_change = (time_step*net_power(index)) / time_scale;
            battery_cap(index) = battery_cap(index-1) + energy_change;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1)+distance_covered;
            index = index + 1;
            continue
        else
            time_avoiding = time_avoiding + 1;
            
            battery_cap(index) = battery_cap(index-1) ...
                                 - avoidance_consumption - avionics_consumption;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1)+distance_covered;
            index = index + 1;
            continue
        end
    end

    if (battery_soc(index-1) < begin_charge_soc && ~is_charging)
        is_charging = true;
        
        load_out(index) = charge_min(1);
        load_in(index)  = charge_min(2)*curr_sangle_offset;
        net_power(index) = load_in(index) - load_out(index);
        
        energy_change = (time_step*net_power(index)) / time_scale;
        battery_cap(index) = battery_cap(index-1) + energy_change;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1);
        display("STARTING TO CHARGE")
    elseif (is_charging)
        if (battery_soc(index-1) >= end_charge_soc)
            
            display("DONE CHARGING")          
            load_out(index) = nom_rove(1);
            load_in(index)  = nom_rove(2);
            net_power(index) = load_in(index) - load_out(index);
            energy_change = (time_step*net_power(index)) / time_scale;
            battery_cap(index) = battery_cap(index-1) + energy_change;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1)+distance_covered;
            
            is_charging = false;
            index = index + 1;
            continue
        else
            load_out(index) = charge_min(1);
            load_in(index)  = charge_min(2)*curr_sangle_offset;
            net_power(index) = load_in(index) - load_out(index);
            energy_change = (time_step*net_power(index)) / time_scale;
            battery_cap(index) = battery_cap(index-1) + energy_change;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1);
            
        end
    else
        load_out(index) = nom_rove(1);
        load_in(index)  = nom_rove(2);
        net_power(index) = load_in(index) - load_out(index);
        energy_change = (time_step*net_power(index)) / time_scale;
        battery_cap(index) = battery_cap(index-1) + energy_change;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
    end
   
    index = index + 1;
end