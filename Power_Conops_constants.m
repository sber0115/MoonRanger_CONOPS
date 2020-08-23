
%time_scale will change between 1 and 60 depending

time_scale = 60;
time_start = 0;
time_step  = 1;   %change between .25 and 1, .25 hours, 1 min
time_end   = trek_duration*time_scale; 

time_vector = time_start: time_step: time_end;
tv_length = length(time_vector);

%relevant modes where (1) load_out in Watts, (2) load_in in Watts
%includes 30 percent power growth

rove_link   = [51, 71.3*panel_factor];
charge_link = [15, 71.3*panel_factor];
nom_rove    = [46, 71.3*panel_factor];
extreme_rove = [52, 71.3*panel_factor];
charge_min  = [8, 71.3*panel_factor];  
                            
plan_trek_interval = [0: time_step: plan_duration*time_scale];
downlink_interval  = [plan_duration: time_step: downlink_duration*time_scale];
trek_phase1        = [plan_trek_interval, downlink_interval];
                                                               
battery_total = 200;
%rover speed
speed_centi  = 2.5;
%speed_reg    = 7.2 * duty_cycle;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
battery_soc        = zeros(1,tv_length);
battery_cap        = zeros(1,tv_length);
distance_travelled = zeros(1,tv_length);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
azimuth_angle    = zeros(1, tv_length); %in degrees



%populating azimuth_angle first since
%the load_in is dependent on angle
index = 1;
for spec_time = time_vector
     if (index > 1)
        prev_value = azimuth_angle(index-1);
        divide_factor = time_step*time_scale;
        %for every .25 hours, or 1/4 hours, divide_factor was 4
        diff = (360/(29.5*24)) / divide_factor; %previously, calculation was for .25 hours
        azimuth_angle(index) = prev_value + diff;
     end
     index = index + 1;
end


sun_vectors = zeros(length(azimuth_angle), 3);
elevation_angle = 5; %fixed elevation angle of 5 degrees

for i = 1: tv_length
    sun_vectors(i,:) = sph2cart(deg2rad(azimuth_angle(i)),deg2rad(elevation_angle),1);
end

panel_normal_vector = [0,1,0];
angle_offset = zeros(1, tv_length);

for i = 1: tv_length
    angle_offset(i) = dot(panel_normal_vector, sun_vectors(i,:));
end


index = 1;
init_time_charging = 0; %in mins
max_charge_time = max_charge_period*60;
is_stored = false; %whether panel is stored to prevent overheating
panel_stored_time = 0;
max_panel_store_time = max_store_period * 60;
soc_still_good_1 = true;
for spec_time = trek_phase1
    
    if (~soc_still_good_1)
        battery_cap(index) = battery_cap(index-1);
        battery_soc(index) = battery_soc(index-1); 
        index = index+1;
        continue;
    end
    
    %sprintf("Current time and index: %d, %d", spec_time, index)
    init_time_charging = init_time_charging + 1;
    
    %solar angle in degrees, but must be in rad for MATLAB
    curr_sangle_offset = cos(deg2rad(azimuth_angle(index)));
    if (ismember(spec_time, plan_trek_interval))
        curr_load_out = charge_min(1) + heat_motors_init;
        curr_load_in  = charge_min(2)*curr_sangle_offset;
    elseif (ismember(spec_time, downlink_interval))
        curr_load_out = charge_link(1) + heat_motors_init;
        curr_load_in  = charge_link(2)*curr_sangle_offset;
    end
    
    if (mod(init_time_charging, max_charge_time) == 0)
        %display(init_time_charging)
        is_stored = true;
        curr_load_in = charge_min(2)*curr_sangle_offset - heat_motors;
    elseif (is_stored)
         if (panel_stored_time == max_panel_store_time)
            %display("FINISHED STORING PANEL")
            curr_load_in = charge_min(2)*curr_sangle_offset - heat_motors;
            is_stored = false;
            panel_stored_time = 0;
         else
            %display("PANEL GOT STORED")
            curr_load_in = charge_min(2)*curr_sangle_offset - heat_motors;
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
        battery_cap(index) = battery_total*init_soc;
        battery_soc(index) = battery_cap(index)/battery_total;
    end
    
    soc_still_good_1 = abs(battery_soc(index) - 1) > 1e-2;
    index = index + 1;
end


meters_per_sec = speed_centi/100;
distance_covered = meters_per_sec * time_step * time_scale;








