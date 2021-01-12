%%
%each element in time vector represents a 
%second [time in seconds] increment
time_scale = 60^2;
time_start = 0;
time_step  = 1;  
time_end   = trek_duration*time_scale; %[Hrs]*[36000 sec/Hr] = sec
tolerance  = 1e-2; %used to check if battery state of charge exceeds 100%

time_vector = time_start: time_step: time_end;
tv_length = length(time_vector);


%% Occlusion defaults
occ_index = 1;
occ_times       = [7087, 14175, 21262, 28349, 35437, 42524, 49611, ...
                    56699, 63786, 70873, 77961, 85048, 92135];

%100 percent interpolation (site 1)
occ_multipliers_site1 = [1, 0.93, 0.8, 0.69, 0.57, 0.51, ...
                    0.45, 0.26, 0.21, 0.24, 0.47, 0.74, 0.98];
        
%0 percent interpolation (site 2)
occ_multipliers_site2 = [1, 0.97, 0.91, 0.83, 0.73, 0.76 ...
                        0.82, 0.9, 0.9, 0.9, 0.93, 0.97, 0.98];

%75 percent interpolation (site 3)
occ_multipliers_site3 = [1, 0.94, 0.835, 0.725, 0.61, 0.5725, ...
                        0.5425, 0.42, 0.3825, 0.405, 0.585, 0.7975, 0.981];


%50 percent interpolation (site 4)
occ_multipliers_site4 = [1, 0.95, 0.86, 0.76, 0.65, 0.635, 0.635, ...
                        0.58, 0.555, 0.57, 0.7, 0.855, 0.981];


%25 percent interpolation (site 25)
occ_multipliers_site5 = [1, 0.96, 0.885, 0.795, 0.69, 0.6975, ...
                        0.7275, 0.74, 0.7275, 0.735, 0.815, 0.9125, 0.98];
                    
%130 percent interpolation
occ_multipliers_site6 = [1, 0.918, 0.78, 0.648, 0.522, 0.435, ...
                        0.339, 0.068, 0.003, 0.042, 0.332, 0.671, 0.98];


%% Power consumption and generation for different modes
%relevant modes where (1) load_out in Watts, (2) load_in in Watts
%includes 30 percent power growth
rove_link   = [50 + heater_power, 75];
charge_link = [17 + heater_power, 75]; %if charging for over an hour, an extra 18W go to heaters
nom_rove    = [53 + heater_power, 75];
extreme_rove = [57 + heater_power, 75];
charge_min  = [8 + heater_power, 75];  
     
%%
plan_trek_interval = [0: time_step: plan_duration*time_scale];
downlink_interval  = [plan_duration: time_step: downlink_duration*time_scale];
trek_phase1        = [plan_trek_interval, downlink_interval];                                                       
battery_total = 200; %maximum battery energy capacity in W/hrs
velocity_cm  = 2.5; %speed made good in cm/s
velocity_m = velocity_cm/100;
distance_covered = velocity_m;
battery_soc        = zeros(1,tv_length);
battery_cap        = zeros(1,tv_length);

% Initialize vectors for battery soc and cap of overlaid curve (power fraction 2)
battery_soc_2 = zeros(1, tv_length);
battery_cap_2 = zeros(1,tv_length);
%%
distance_travelled = zeros(1,tv_length);
azimuth_angle      = zeros(1, tv_length); %in degrees



%populating azimuth_angle first since
%the load_in is dependent on angle
for i = 1:length(time_vector)
     if (i > 1)
        prev_value = azimuth_angle(i-1);
        divide_factor = time_step*time_scale;
        %for every .25 hours, or 1/4 hours, divide_factor was 4
        diff = (360/(29.5*24)) / divide_factor; %previously, calculation was for .25 hours
        azimuth_angle(i) = prev_value + diff;
     end
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


time_charging = 0; %[mins]
max_charge_time = max_charge_period*time_scale;
is_heating_motors = false; 
soc_under_100 = true;
for i = 1:length(trek_phase1)
    spec_time = trek_phase1(i);
    if (~soc_under_100)
        battery_cap(i) = battery_cap(i-1);
        battery_soc(i) = battery_soc(i-1); 
        battery_cap_2(i) = battery_cap_2(i-1);
        battery_soc_2(i) = battery_soc_2(i-1); 
        continue;
    end
    
    time_charging = time_charging + 1;
    
    %solar angle in degrees, but must be in rad for MATLAB
    curr_sangle_offset = cos(deg2rad(azimuth_angle(i)));
    if (ismember(spec_time, plan_trek_interval))
        curr_load_out = charge_min(1);
        curr_load_in  = charge_min(2)*curr_sangle_offset;
    elseif (ismember(spec_time, downlink_interval))
        curr_load_out = charge_link(1);
        curr_load_in  = charge_link(2)*curr_sangle_offset;
    else 
       curr_load_out = 0;
       curr_load_in = 0;
    end
    
    if (mod(time_charging, max_charge_time) == 0)
        is_heating_motors = true;
        curr_load_in = charge_min(2)*curr_sangle_offset - heater_power ;
    end
    
    curr_net_power = curr_load_in - curr_load_out;

    if (i > 1)
        energy_change = curr_net_power / 3600; %[W, or J/s, * 1Wh/3600J = Wh/s
        battery_cap(i) = battery_cap(i-1) + energy_change;
        battery_soc(i) = battery_cap(i)/battery_total;   
        battery_cap_2(i) = battery_cap_2(i-1) + energy_change;
        battery_soc_2(i) = battery_cap_2(i)/battery_total;    
        
    else
        battery_cap(i) = battery_total*init_soc;
        battery_soc(i) = battery_cap(i)/battery_total;
        battery_cap_2(i) = battery_total*init_soc;
        battery_soc_2(i) = battery_cap(i)/battery_total;
    end
    
    soc_under_100 = abs(battery_soc(i) - 1) > 1e-2;
end











