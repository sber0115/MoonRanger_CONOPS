
if (enable_rocks)
    rock_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 200);
else
    rock_findings = [];
end

if (enable_shadows)
    shadow_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 200);
else
    shadow_findings = [];
end

if (enable_craters)
    crater_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 100);
else
    crater_findings = [];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rock_find_index = 1;
rock_turn_energy = 0;
rock_straight_distance = 0;
rock_turn_time = 0;
num_rocks_found = 0;
num_shadows_found = 0;

crater_find_index = 1;
crater_turn_energy = 0;
crater_straight_distance = 0;
crater_turn_time = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

is_charging = false;
is_avoiding_rock = false;
is_avoiding_crater = false;
in_shadow    = false;
time_avoiding_rock = 0; %in mins
time_avoiding_crater = 0; %in mins
time_inshadow = 0; %in mins
start_time = plan_duration + downlink_duration;

%{
Factor by which the distance travelled decreases is determined by calculating two times

Time 1: Determining time required to execute avoidance
Time 2: Determining time it takes rover to travel (diameter of turn) meters, 
    assuming a straight path

Take the ratio of time2/time1
%}

soc_under_100 = true;
for i = length(trek_phase1)+1:length(time_vector)
    spec_time = time_vector(i);
    %sprintf("Current time and index: %d, %d", spec_time, i)
    rock_found = ismember(spec_time, rock_findings);
    shadow_found = ismember(spec_time, shadow_findings);
    crater_found = ismember(spec_time, crater_findings);
    curr_solar_offset = cos(deg2rad(angle_offset(i)));
    
    can_avoid_rock = ~is_charging && ~is_avoiding_rock && ~is_avoiding_crater ...
                     && rock_find_index <= length(rockAvoidances);
    
    can_avoid_crater = ~is_charging && ~is_avoiding_crater && ~is_avoiding_rock ...
                       && crater_find_index <= length(craterAvoidances);
          
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    %%%%%%%%%%%%%%%%%%%%%%%START OF AVOIDANCE HANDLING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ROCK AVOIDANCE
    if (rock_found && can_avoid_rock)    
        is_avoiding_rock = true;
        num_rocks_found = num_rocks_found+1;
        time_avoiding_rock = 0;
        rock_turn_energy = rockAvoidances(1,rock_find_index);
        rock_straight_distance = rockAvoidances(2, rock_find_index);
        rock_avoidance_duration = rockAvoidances(3,rock_find_index);
        %calculate linear distance factor (factor by which we our speed is affected during skid-steer)
        straight_total_time = rock_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / rock_avoidance_duration;
        
        avionics_consumption = (extreme_rove(1)/3600); %[J/s] * 1Wh/3600J = Wh/s
        avoidance_consumption = rock_turn_energy / (3600*rock_avoidance_duration); %[Wh/s]
        curr_load_in = (extreme_rove(2)*curr_solar_offset/3600)*.5;    %[Wh/s]      
        energy_change = curr_load_in + -1 *(avoidance_consumption + avionics_consumption);    
        temp_cap = battery_cap(i-1) + energy_change;
        
        if (abs(temp_cap/battery_total - 1) > 1e-2)
            battery_cap(i) = battery_cap(i-1) + energy_change;
        else
            battery_cap(i) = battery_cap(i-1);
        end
        battery_soc(i) = battery_cap(i)/battery_total;
        
        distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
        rock_find_index = rock_find_index + 1;
        continue
    elseif (is_avoiding_rock)
        if (time_avoiding_rock == rock_avoidance_duration-1)
            is_avoiding_rock = false;
            time_avoiding_rock = 0;
            curr_net_power = nom_rove(2)*curr_solar_offset - nom_rove(1);
            energy_change = curr_net_power / 3600; %[J/s] * 1Wh/3600J = Wh/s
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1)+distance_covered;
            continue
        else
            time_avoiding_rock = time_avoiding_rock + 1;
            curr_load_in = (extreme_rove(2)*curr_solar_offset/3600)*.5;    %[Wh/s]   
            energy_change = curr_load_in + -1 *(avoidance_consumption + avionics_consumption); %[J/s] * 1Wh/3600J = Wh/s 
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
            continue
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CRATER AVOIDANCE
    if (crater_found && can_avoid_crater)    
        is_avoiding_crater = true;
        sprintf("FOUND CRATER WITH DIAMETER OF %d m, at t = %d", D(crater_find_index), i)
        time_avoiding_crater = 0;
        crater_turn_energy = craterAvoidances(1,crater_find_index);
        crater_straight_distance = craterAvoidances(2, crater_find_index);
        crater_avoidance_duration = craterAvoidances(3,crater_find_index);
        %calculate linear distance factor (factor by which we our speed is affected during skid-steer)
        straight_total_time = crater_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / crater_avoidance_duration;
        avionics_consumption = (extreme_rove(1)/3600); %[J/s] * 1Wh/3600J = Wh/s
        avoidance_consumption = crater_turn_energy / (3600*crater_avoidance_duration); %[J/s] * 1Wh/3600J = Wh/s
        curr_load_in = (extreme_rove(2)*curr_solar_offset/3600)*.5;    %[Wh/s]   
        energy_change = curr_load_in + -1 *(avoidance_consumption + avionics_consumption); %[J/s] * 1Wh/3600J = Wh/s
        temp_cap = battery_cap(i-1) + energy_change;
        
        if (abs(temp_cap/battery_total - 1) > 1e-2)
            battery_cap(i) = battery_cap(i-1) + energy_change;
        else
            battery_cap(i) = battery_cap(i-1);
        end
        battery_soc(i) = battery_cap(i)/battery_total;
        
        distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
        crater_find_index = crater_find_index + 1;
        continue
    elseif (is_avoiding_crater)
        if (time_avoiding_crater == crater_avoidance_duration-1)
            is_avoiding_crater = false;
            time_avoiding_crater = 0;
            curr_net_power = nom_rove(2)*curr_solar_offset - nom_rove(1);
            energy_change = curr_net_power*curr_solar_offset / 3600; %[J/s] * 1Wh/3600J = Wh/s
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1)+distance_covered;
            continue
        else
            time_avoiding_crater = time_avoiding_crater + 1;
            curr_load_in = (extreme_rove(2)*curr_solar_offset/3600)*.5;    %[Wh/s]   
            energy_change = curr_load_in + -1 *(avoidance_consumption + avionics_consumption); %[J/s] * 1Wh/3600J = Wh/s        
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1)+(distance_covered*linear_distance_factor);
            continue
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%END OF AVOIDANCE HANDLING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if (battery_soc(i-1) < begin_charge_soc && ~is_charging)
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*curr_solar_offset;
        curr_net_power = curr_load_in - curr_load_out;
        if (shadow_found)
            in_shadow = true;
            num_shadows_found = num_shadows_found + 1;
            curr_net_power = -1*curr_load_out;
        elseif (in_shadow && time_inshadow < max_shadow_time)
            time_inshadow = time_inshadow + 1;
            curr_net_power = -1*curr_load_out;
        elseif (time_inshadow == max_shadow_time)
            in_shadow = false;
            time_inshadow = 0;
            is_charging = true;
        else
            is_charging = true;
        end
        
        energy_change = curr_net_power / 3600; %[Wh/s]
        temp_cap = battery_cap(i-1) + energy_change;
        
        if (abs(temp_cap/battery_total - 1) > 1e-2)
            battery_cap(i) = battery_cap(i-1) + energy_change;
        else
            battery_cap(i) = battery_cap(i-1);
        end
        battery_soc(i) = battery_cap(i)/battery_total;
        distance_travelled(i) = distance_travelled(i-1);
    
    elseif (is_charging)
        if (battery_soc(i-1) >= end_charge_soc)        
            curr_load_out = nom_rove(1);
            curr_load_in  = nom_rove(2)*curr_solar_offset;
            curr_net_power = curr_load_in - curr_load_out;
            energy_change = curr_net_power / 3600;
            
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            
            distance_travelled(i) = distance_travelled(i-1)+distance_covered;
            is_charging = false;
            continue
        else
            curr_load_out = charge_min(1);
            curr_load_in  = charge_min(2)*curr_solar_offset;
            curr_net_power = curr_load_in - curr_load_out;       
            energy_change = curr_net_power / 3600;
            
            temp_cap = battery_cap(i-1) + energy_change;
        
            if (abs(temp_cap/battery_total - 1) > 1e-2)
                battery_cap(i) = battery_cap(i-1) + energy_change;
            else
                battery_cap(i) = battery_cap(i-1);
            end
            battery_soc(i) = battery_cap(i)/battery_total;
            distance_travelled(i) = distance_travelled(i-1);
        end
    else
        curr_load_out = nom_rove(1);
        curr_load_in  = nom_rove(2)*curr_solar_offset;
        curr_net_power = curr_load_in - curr_load_out;
        if (shadow_found)
            num_shadows_found = num_shadows_found + 1;
            in_shadow = true;
            curr_net_power = -1*curr_load_out;
        elseif (in_shadow && time_inshadow < max_shadow_time)
            time_inshadow = time_inshadow + 1;
            curr_net_power = -1*curr_load_out;   
        elseif (time_inshadow == max_shadow_time)
            in_shadow = false;
            time_inshadow = 0;
        end
        
        energy_change = curr_net_power / 3600;
        temp_cap = battery_cap(i-1) + energy_change;

        if (abs(temp_cap/battery_total - 1) > 1e-2)
            battery_cap(i) = battery_cap(i-1) + energy_change;
        else
            battery_cap(i) = battery_cap(i-1);
        end
        battery_soc(i) = battery_cap(i)/battery_total;
        distance_travelled(i) = distance_travelled(i-1)+distance_covered;
    end
end