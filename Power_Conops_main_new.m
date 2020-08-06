
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
%rock_findings = [];
shadow_findings = randi([121, 18*time_scale], 1, 100);
%shadow_findings = []

is_charging = false;
is_avoiding = false;
found_shadow = false;
in_shadow    = false;
time_avoiding = 0; %in mins
time_inshadow = 0; %in mins
trek_phase2 = [2*time_scale + time_step : time_step: time_end];

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
avionics_consumption = (nom_rove(1) * 1 * 60)/3600; %power * time in mins * 60s 
avoidance_consumption = (2*point_turn_energy + skid_energy)/(3600*avoidance_duration); %divide by 60 for per-minute consumption

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%after initial two hours of charging, battery SOC should be at around 90%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

index = 122;
for spec_time = trek_phase2
    sprintf("Current time and index: %d, %d", spec_time, index)
    rock_found = ismember(spec_time, rock_findings);
    found_shadow = ismember(spec_time, shadow_findings);
    
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
            
            energy_change = (time_step*curr_net_power) / time_scale;
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
        
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*curr_sangle_offset;
        curr_net_power = curr_load_in - curr_load_out;
        energy_change = (time_step*curr_net_power) / time_scale;
        battery_cap(index) = battery_cap(index-1) + energy_change;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1);
        display("STARTING TO CHARGE")
    elseif (is_charging)
        if (battery_soc(index-1) >= end_charge_soc)
            
            display("DONE CHARGING")          
            curr_load_out = nom_rove(1);
            curr_load_in  = nom_rove(2);
            curr_net_power = curr_load_in - curr_load_out;
            energy_change = (time_step*curr_net_power) / time_scale;
            battery_cap(index) = battery_cap(index-1) + energy_change;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1)+distance_covered;
            
            is_charging = false;
            index = index + 1;
            continue
        else
            curr_load_out = charge_min(1);
            curr_load_in  = charge_min(2)*curr_sangle_offset;
            curr_net_power = curr_load_in - curr_load_out;        
            energy_change = (time_step*curr_net_power) / time_scale;
            battery_cap(index) = battery_cap(index-1) + energy_change;
            battery_soc(index) = battery_cap(index)/battery_total;
            distance_travelled(index) = distance_travelled(index-1);
            
        end
    else
        curr_load_out = nom_rove(1);
        curr_load_in  = nom_rove(2);
        curr_net_power = curr_load_in - curr_load_out;
        
        if (found_shadow)
            display("In shadow")
            in_shadow = true;
        elseif (in_shadow && time_inshadow < 3)
            time_inshadow = time_inshadow + 1;
            curr_net_power = -1*curr_load_out;   
        elseif (time_inshadow == 3)
            display("Escaped shadow")
            in_shadow = false;
            time_inshadow = 0;
        end
        
        if (in_shadow); curr_net_power = -1*nom_rove(1); end
        energy_change = (time_step*curr_net_power) / time_scale;
        battery_cap(index) = battery_cap(index-1) + energy_change;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
    end
   
    index = index + 1;
end