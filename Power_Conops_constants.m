time_scale = 60^2;
time_start = 0;
time_step  = 1;  
time_end   = trek_duration*time_scale; 
normalize = 3600;
tolerance = 1e-2; 

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
velocity_cm  = 2.5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%
battery_soc        = zeros(1,tv_length);
battery_cap        = zeros(1,tv_length);
distance_travelled = zeros(1,tv_length);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
azimuth_angle    = zeros(1, tv_length); %in degrees



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
    end
    
    if (mod(time_charging, max_charge_time) == 0)
        is_heating_motors = true;
        curr_load_in = charge_min(2)*curr_sangle_offset - heat_motor_power;
    end
    
    curr_net_power = curr_load_in - curr_load_out;

    if (i > 1)
        energy_change = curr_net_power / time_scale;
        battery_cap(i) = battery_cap(i-1) + energy_change;
        battery_soc(i) = battery_cap(i)/battery_total;    
    else
        battery_cap(i) = battery_total*init_soc;
        battery_soc(i) = battery_cap(i)/battery_total;
    end
    
    soc_under_100 = abs(battery_soc(i) - 1) > 1e-2;
end


velocity_m = velocity_cm/100;
distance_covered = velocity_m;








