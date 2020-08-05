
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% START USER DEFINED PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%time_resolution = 

begin_charge_soc = .5;
end_charge_soc   = .6;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% END USER DEFINED PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%26 insurmountable rocks according to rock distribution data 
rock_findings = [3, 5, 6.5, 9, 11.5, 14, 15.5, ...
                 16.5, 22, 24, 26.5, 28.75, ...
                 31, 33.75, 35, 37, 38.5, 40 ...
                 41.5, 43, 45.75, 47, 48.5, ...
                 50, 51];

is_charging = false;
time_charging = 0;
trek_phase2 = [2.25 : .25: 17.75];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%after initial two hours of charging, battery SOC should be at around 90%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%starting at index 11, since this is where contants file left off
index = 11;
for spec_time = trek_phase2
    rock_found = ismember(spec_time, rock_findings);
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    
    if (rock_found && ~is_charging)
        display("rock was found")         
        %we broke up the avoidance manuevers into 2 parts,
        %one part consists of energy expended by 2 90-degree point turns
        %the second part consists of energy expended while skid-steering
        
        %don't forget to also consider the energy used by avionics
        %energy used by avionics during avoidance = power * 3mins * 60s/1min
        %must convert it to Wh, so divide by 3600
        
        avoidance_duration = 3; %in mins
        point_turn_energy = 10 * 28; %power*time for 90-degree turn
        skid_energy = 1.2 * point_turn_energy; %according to papers we read
        avionics_consumption = (45.01 * 3 * 60)/3600;
        avoidance_consumption = (2*point_turn_energy + skid_energy)/3600;
        battery_cap(index) = battery_cap(index-1) ...
                             - avoidance_consumption - avionics_consumption;
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1)+distance_covered;
        index = index + 1;
        continue
    end

    if (battery_soc(index-1) < begin_charge_soc && ~is_charging)
        is_charging = true;
        
        load_out(index) = charge_min(1);
        load_in(index)  = charge_min(2)*curr_sangle_offset;
        net_power(index) = load_in(index) - load_out(index);
        battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
        battery_soc(index) = battery_cap(index)/battery_total;
        distance_travelled(index) = distance_travelled(index-1);
        display("STARTING TO CHARGE")
    elseif (is_charging)
        if (battery_soc(index-1) >= end_charge_soc)
            
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