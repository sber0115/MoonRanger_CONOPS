%to be modified down the road
time_start = 0;
time_step  = .25;
time_end   = 18;

time_vector = time_start: time_step: time_end;
tv_length = length(time_vector);

%relevant modes where (1) load_out in Watts, (2) load_in in Watts
%includes 30 percent power growth
rove_link   = [45.01, 41];
charge_link = [19.28,  41];
nom_rove    = [44.4, 25];
charge_min  = [20.15, 41];  %update this solar in
                            %with new power calculations
                            
plan_trek_interval = [0: .25: 1];
downlink_interval  = [1: .25: 2];
trek_phase1        = [plan_trek_interval, downlink_interval];
                                                               
%Battery Characteristics at Deployment
battery_total = 200;
init_soc      = .40;

%rover speed
speed_centi  = 2;
speed_reg    = 7.2;

load_out           = zeros(1,tv_length);
load_in            = zeros(1,tv_length);
battery_soc        = zeros(1,tv_length);
net_power          = zeros(1,tv_length);
battery_cap        = zeros(1,tv_length);
solar_incidence    = zeros(1,tv_length); %in radians
distance_travelled = zeros(1,tv_length);


%populating solar_incidence first since
%the load_in vector values are dependent on angle
index = 1;
for spec_time = time_vector
     if (index > 1)
        prev_value = solar_incidence(index-1);
        solar_incidence(index) = prev_value+(360/(29.5*24))/4;
     end
     index = index + 1;
end



index = 1;
%this is the first two hours where we have downlink
for spec_time = trek_phase1
    %solar angle in degrees, but must be in rad for MATLAB
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    
    if (ismember(spec_time, plan_trek_interval))
        load_out(index) = charge_min(1);
        load_in(index)  = charge_min(2)*curr_sangle_offset;
    elseif (ismember(spec_time, downlink_interval))
        load_out(index) = charge_link(1);
        load_in(index)  = charge_link(2)*curr_sangle_offset;
    end
    
    net_power(index) = load_in(index) - load_out(index);

    if (index > 1)
        battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
        battery_soc(index) = battery_cap(index)/battery_total;    
    else
        battery_cap(1) = battery_total*init_soc + net_power(1);
        battery_soc(1) = battery_cap(1)/battery_total;
    end
    
    index = index + 1;
end


secs_in_step = time_step * 3600;
meters_per_sec = speed_centi/100;
distance_covered = meters_per_sec * secs_in_step;






