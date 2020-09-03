
if (enable_rocks)
    rock_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 100);
else
    rock_findings = [];
end

if (enable_shadows)
    shadow_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 100);
else
    shadow_findings = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%vectors below will be used to plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%different colors
curr_rock_index = 1;
rock_indexes = zeros(1, length(rock_findings)*avoidance_duration);
curr_shadow_index = 1;
shadow_indexes = zeros(1, length(shadow_findings));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

is_charging = false;
is_avoiding = false;
shadow_found = false;
in_shadow    = false;
time_avoiding = 0; %in mins
time_inshadow = 0; %in mins
start_time    = plan_duration + downlink_duration;

trek_phase2 = [start_time*time_scale + time_step : time_step: time_end];

%we broke up the avoidance manuevers into 2 parts,
%one part consists of energy expended by 2 90-degree point turns
%the second part consists of energy expended while skid-steering

%don't forget to also consider the energy used by avionics
%energy used by avionics during avoidance = power * 4mins * 60s/1min
%must convert it to Wh, so divide by 3600
point_turn_energy = 10 * 28; %power*time for 90-degree turn
skid_energy = 1.2 * point_turn_energy; %according to papers we read

%next two calculations need to incorporate time_scale somehow
%right now, consumption values are per minute
avionics_consumption = (extreme_rove(1) * 60)/3600; %power * time in mins 
avoidance_consumption = 3560 / (3600*avoidance_duration); %for .342m rocks, check slides
%avoidance_consumption = (2*point_turn_energy + skid_energy)/(3600*avoidance_duration);



%{
Factor by which the distance travelled decreases is determined by calculating two times

Time 1: Determining time required to execute avoidance
Time 2: Determining time it takes rover to travel (diameter of turn) meters, 
    assuming a straight path

Take the ratio of time2/time1
%}


%calculate linear distance factor (factor by which we our speed is affected during skid-steer)
skid_speed = meters_per_sec / 2;
reg_linear_distance = .796*2; %for .342 diameter rock
reg_total_time = reg_linear_distance / meters_per_sec;
skid_total_time = avoidance_duration * 60;

linear_distance_factor = reg_total_time / skid_total_time;


soc_under_100 = true;
for i = length(trek_phase1)+1:length(time_vector)
    spec_time = time_vector(i);
    sprintf("Current time and index: %d, %d", spec_time, i)
    rock_found = ismember(spec_time, rock_findings);
    shadow_found = ismember(spec_time, shadow_findings);
    curr_solar_offset = cos(deg2rad(angle_offset(i)));
    avionics_consumption = avionics_consumption*curr_solar_offset;
    
    if (rock_found && ~is_charging)
        rock_indexes(curr_rock_index) = i;
        curr_rock_index = curr_rock_index + 1;
        %display("rock was found")         
        is_avoiding = true;
        display("FOUND ROCK");
        energy_change = -1 *(avoidance_consumption + avionics_consumption);
        
        temp_cap = battery_cap(i-1) + energy_change;
        battery_cap(i) = battery_cap(i-1) + energy_change;
        battery_soc(i) = battery_cap(i)/battery_total;
        
        distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
        continue
    elseif (is_avoiding)
        if (time_avoiding == avoidance_duration-1)
            is_avoiding = false;
            time_avoiding = 0;
            curr_net_power = nom_rove(2) - nom_rove(1)*curr_solar_offset;
            energy_change = (time_scale*curr_net_power) / 3600;
            battery_cap(i) = battery_cap(i-1) + energy_change;
            battery_soc(i) = battery_cap(i)/battery_total;
            
            distance_travelled(i) = distance_travelled(i-1)+distance_covered;
            continue
        else
            time_avoiding = time_avoiding + 1;
            rock_indexes(curr_rock_index) = i;
            curr_rock_index = curr_rock_index + 1;
            energy_change = -1 *(avoidance_consumption + avionics_consumption);
            battery_cap(i) = battery_cap(i-1) + energy_change;
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
            continue
        end
    end

    if (battery_soc(i-1) < begin_charge_soc && ~is_charging)
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*curr_solar_offset;
        curr_net_power = curr_load_in - curr_load_out;
        if (shadow_found)
            in_shadow = true;
            display("found shadow");
            curr_net_power = -1*curr_load_out;
            sprintf("Net power, in shadow: %d", curr_net_power)
        elseif (in_shadow && time_inshadow < max_shadow_time)
            time_inshadow = time_inshadow + 1;
            curr_net_power = -1*curr_load_out;
            sprintf("Net power, in shadow: %d", curr_net_power)
        elseif (time_inshadow == max_shadow_time)
            in_shadow = false;
            time_inshadow = 0;
            is_charging = true;
        else
            is_charging = true;
        end
        %is_charging = true;
        sprintf("Net power, charging: %d", curr_net_power)
        energy_change = (time_scale*curr_net_power) / 3600;
        battery_cap(i) = battery_cap(i-1) + energy_change;
        battery_soc(i) = battery_cap(i)/battery_total;
        distance_travelled(i) = distance_travelled(i-1);
        %display("STARTING TO CHARGE")
    elseif (is_charging)
        if (battery_soc(i-1) >= end_charge_soc)
            
            %display("DONE CHARGING")          
            curr_load_out = nom_rove(1);
            curr_load_in  = nom_rove(2)*curr_solar_offset;
            curr_net_power = curr_load_in - curr_load_out;
            sprintf("Net power, done charging: %d", curr_net_power)
            
            energy_change = (time_scale*curr_net_power) / 3600;
            battery_cap(i) = battery_cap(i-1) + energy_change;
            battery_soc(i) = battery_cap(i)/battery_total;
            
            distance_travelled(i) = distance_travelled(i-1)+distance_covered;
            is_charging = false;
            continue
        else
            curr_load_out = charge_min(1);
            curr_load_in  = charge_min(2)*curr_solar_offset;
            curr_net_power = curr_load_in - curr_load_out;       
            sprintf("Net power, is charging: %d", curr_net_power)
            energy_change = (time_scale*curr_net_power) / 3600;
            battery_cap(i) = battery_cap(i-1) + energy_change;
            battery_soc(i) = battery_cap(i)/battery_total;
            
            distance_travelled(i) = distance_travelled(i-1);
        end
    else
        curr_load_out = nom_rove(1);
        curr_load_in  = nom_rove(2)*curr_solar_offset;
        curr_net_power = curr_load_in - curr_load_out;
        sprintf("Net power, just roving: %d", curr_net_power)
        if (shadow_found)
            %display("In shadow")
            display("shadow found");
            in_shadow = true;
            curr_net_power = -1*curr_load_out;
        elseif (in_shadow && time_inshadow < 3)
            time_inshadow = time_inshadow + 1;
            curr_net_power = -1*curr_load_out;   
        elseif (time_inshadow == 3)
            %display("Escaped shadow")
            in_shadow = false;
            time_inshadow = 0;
        end
        
        energy_change = (time_scale*curr_net_power) / 3600;
        battery_cap(i) = battery_cap(i-1) + energy_change;
        battery_soc(i) = battery_cap(i)/battery_total;
        
        distance_travelled(i) = distance_travelled(i-1)+distance_covered;
    end
end