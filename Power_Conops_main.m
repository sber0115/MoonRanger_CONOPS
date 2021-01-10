%% Populating crater and rock vectors according to user parameters
%  Crater and rock characteristics determined by the Rock and
%  CraterDistribution files
if (enable_rocks)
    %up to 200 rocks are "seen" at random times as long as rover isn't
    %charging. Energy consumed during avoidance dependent upon rock
    %characteristics
    rock_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 200);
else
    rock_findings = [];
end

if (enable_shadows)
    %up to 200 shadows are "seen" at random times, even if rover is
    %charging. Rover charging is null for 3 mins [180 sec] when rover is in shadow
    shadow_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 200);
else
    shadow_findings = [];
end

if (enable_craters)
    %up to 100 craters are "seen" at random times as long as rover isn't
    %charging. Energy consumed during avoidance is dependent upon crater
    %characteristics
    crater_findings = randi([length(trek_phase1)+1, trek_duration*time_scale], 1, 100);
else
    crater_findings = [];
end

%%
rock_find_index = 1;
rock_turn_energy = 0;
rock_straight_distance = 0;
rock_turn_time = 0;

crater_find_index = 1;
crater_turn_energy = 0;
crater_straight_distance = 0;
crater_turn_time = 0;

is_charging = false;
is_avoiding_rock = false;
is_avoiding_crater = false;
in_shadow    = false;
time_avoiding_rock = 0; %[secs]
time_avoiding_crater = 0; %[secs]
time_in_shadow = 0; %[secs]

%{
Factor by which the distance travelled toward target decreases 
is determined by calculating two times

Time 1: Determining time required to execute avoidance
Time 2: Determining time it takes rover to travel (diameter of turn) meters, 
        assuming a straight path
Take the ratio of time2/time1
%}

%% Control flow during obstacle avoidance, more complex with more variables
soc_under_100 = true; %flag to make sure battery state of charge is under 100%
for i = length(trek_phase1)+1:length(time_vector)
    spec_time = time_vector(i);
    rock_found = ismember(spec_time, rock_findings);
    shadow_found = ismember(spec_time, shadow_findings);
    crater_found = ismember(spec_time, crater_findings);
    change_power_fraction = ismember(spec_time, occ_times);
    
    if (change_power_fraction && occ_index < length(occ_times))
       occ_index = occ_index + 1; 
    end
    power_fraction = occ_multipliers(occ_index);
    
    %power_fraction is the factor by which max power is multiplied (< 1)
    %%power_fraction = cos(deg2rad(angle_offset(i)));
    
    %not all randomized rocks will be seen since rover may be charging at
    %that specific time, but can't exceed number of rocks generated by
    %other matlab script
    can_avoid_rock = ~is_charging && ~is_avoiding_rock && ~is_avoiding_crater ...
                     && rock_find_index <= length(rockAvoidances);
    %similarly for craters
    can_avoid_crater = ~is_charging && ~is_avoiding_crater && ~is_avoiding_rock ...
                       && crater_find_index <= length(craterAvoidances);
                   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ROCK AVOIDANCE
    if (rock_found && can_avoid_rock)    
        is_avoiding_rock = true;
        time_avoiding_rock = 0;
        rock_turn_energy = rockAvoidances(1,rock_find_index);
        rock_straight_distance = rockAvoidances(2, rock_find_index);
        rock_avoidance_duration = rockAvoidances(3,rock_find_index);
        %calculate linear distance factor (factor by which speed is affected during skid-steer)
        straight_total_time = rock_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / rock_avoidance_duration;
        
        avionics_consumption = (extreme_rove(1)/3600); %[J/s] * 1Wh/3600J = Wh/s
        %note, rock turn energy given in Joules, but total energy must be
        %expended over the duration of the entire manuever, so we must
        %divide by the manuever duration 
        avoidance_consumption = rock_turn_energy / (3600*rock_avoidance_duration); %[Wh/s]
        curr_load_in = (extreme_rove(2)*power_fraction/3600);    %[Wh/s]      
        energy_change = curr_load_in + -1 *(avoidance_consumption + avionics_consumption);    
        temp_cap = battery_cap(i-1) + energy_change;
        
        %check to see if rover is energy rich and doesn't exceed 100% SOC
        %if too much energy is being generated, then it will cap out on
        %the state-of-charge graph
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
            curr_net_power = nom_rove(2)*power_fraction - nom_rove(1);
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
        else %still avoiding rock
            time_avoiding_rock = time_avoiding_rock + 1;
            curr_load_in = (extreme_rove(2)*power_fraction/3600);    %[Wh/s]   
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
        time_avoiding_crater = 0;
        crater_turn_energy = craterAvoidances(1,crater_find_index);
        crater_straight_distance = craterAvoidances(2, crater_find_index);
        crater_avoidance_duration = craterAvoidances(3,crater_find_index);
        %calculate linear distance factor (factor by which speed is affected during skid-steer)
        straight_total_time = crater_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / crater_avoidance_duration;
        avionics_consumption = (extreme_rove(1)/3600); %[J/s] * 1Wh/3600J = Wh/s
        avoidance_consumption = crater_turn_energy / (3600*crater_avoidance_duration); %[J/s] * 1Wh/3600J = Wh/s
        curr_load_in = (extreme_rove(2)*power_fraction/3600);    %[Wh/s]   
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
            %finished avoiding crater so back to nominal rove
            curr_net_power = nom_rove(2)*power_fraction - nom_rove(1);
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
        else %still avoiding crater
            time_avoiding_crater = time_avoiding_crater + 1;
            curr_load_in = (extreme_rove(2)*power_fraction/3600);    %[Wh/s]   
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
%% Control flow to handle charging periods
    if (battery_soc(i-1) < begin_charge_soc && ~is_charging)
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*power_fraction;
        curr_net_power = curr_load_in - curr_load_out;
        if (shadow_found) %rover charging is null is in shadow
            in_shadow = true;
            curr_net_power = -1*curr_load_out;
            is_charging = false;
        elseif (in_shadow && time_in_shadow < max_shadow_time)
            time_in_shadow = time_in_shadow + 1;
            curr_net_power = -1*curr_load_out;
        elseif (time_in_shadow == max_shadow_time)
            in_shadow = false;
            time_in_shadow = 0;
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
        if (battery_soc(i-1) >= end_charge_soc) %SOC reached charging threshold
            curr_load_out = nom_rove(1);
            curr_load_in  = nom_rove(2)*power_fraction;
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
        else %use power consumption/generation values during charging mode
            curr_load_out = charge_min(1);
            curr_load_in  = charge_min(2)*power_fraction;
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
    else %no need to charge/is not charging, just rove
        curr_load_out = nom_rove(1);
        curr_load_in  = nom_rove(2)*power_fraction;
        curr_net_power = curr_load_in - curr_load_out;
        if (shadow_found) %may encounter shadow
            in_shadow = true;
            curr_net_power = -1*curr_load_out;
        elseif (in_shadow && time_in_shadow < max_shadow_time)
            time_in_shadow = time_in_shadow + 1;
            curr_net_power = -1*curr_load_out;   
        elseif (time_in_shadow == max_shadow_time)
            in_shadow = false;
            time_in_shadow = 0;
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