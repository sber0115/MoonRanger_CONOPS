
%time_scale will change between 1 and 60 depending

time_scale = 60;
time_start = 0;
time_step  = 1;   %change between .25 and 1, .25 hours, 1 min
time_end   = trek_duration*time_scale; 

time_vector = time_start: time_step: time_end;
tv_length = length(time_vector);

%relevant modes where (1) load_out in Watts, (2) load_in in Watts
%includes 30 percent power growth

rove_link   = [50, 48*panel_factor];
charge_link = [32, 48];
nom_rove    = [50, 48*panel_factor];
charge_min  = [29, 48];  
                            
plan_trek_interval = [0: time_step: plan_duration*time_scale];
downlink_interval  = [plan_duration: time_step: downlink_duration*time_scale];
trek_phase1        = [plan_trek_interval, downlink_interval];
                                                               
battery_total = 200;
%rover speed
speed_centi  = 2;
speed_reg    = 7.2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
battery_soc        = zeros(1,tv_length);
battery_cap        = zeros(1,tv_length);
distance_travelled = zeros(1,tv_length);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
solar_incidence    = zeros(1,tv_length); %in degrees



%populating solar_incidence first since
%the load_in is dependent on angle
index = 1;
for spec_time = time_vector
     if (index > 1)
        prev_value = solar_incidence(index-1);
        divide_factor = time_step*time_scale;
        %for every .25 hours, or 1/4 hours, divide_factor was 4
        diff = (360/(29.5*24)) / divide_factor; %previously, calculation was for .25 hours
        solar_incidence(index) = prev_value + diff;
     end
     index = index + 1;
end



index = 1;
init_time_charging = 0; %in mins
max_charge_time = max_charge_period*60;
is_stored = false; %whether panel is stored to prevent overheating
panel_stored_time = 0;
max_panel_store_time = max_store_period * 60;
for spec_time = trek_phase1
    %sprintf("Current time and index: %d, %d", spec_time, index)
    init_time_charging = init_time_charging + 1;
    
    %solar angle in degrees, but must be in rad for MATLAB
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    if (ismember(spec_time, plan_trek_interval))
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*curr_sangle_offset;
    elseif (ismember(spec_time, downlink_interval))
        curr_load_out = charge_link(1);
        curr_load_in  = charge_link(2)*curr_sangle_offset;
    end
    
    if (mod(init_time_charging, max_charge_time) == 0)
        %display(init_time_charging)
        is_stored = true;
        curr_load_in = 0;
    elseif (is_stored)
         if (panel_stored_time == max_panel_store_time)
            %display("FINISHED STORING PANEL")
            curr_load_in = 0;
            is_stored = false;
            panel_stored_time = 0;
         else
            %display("PANEL GOT STORED")
            curr_load_in = 0;
            panel_stored_time = panel_stored_time + 1;
            %display(panel_stored_time)
         end
    end
    
    curr_net_power = curr_load_in - curr_load_out;

    if (index > 1)
        energy_change = (time_step*curr_net_power) / time_scale;
        battery_cap(index) = battery_cap(index-1) + energy_change;
        battery_soc(index) = battery_cap(index)/battery_total;    
    else
        battery_cap(1) = battery_total*init_soc;
        battery_soc(1) = battery_cap(1)/battery_total;
    end
    
    index = index + 1;
end


meters_per_sec = speed_centi/100;
distance_covered = meters_per_sec * time_step * time_scale;








