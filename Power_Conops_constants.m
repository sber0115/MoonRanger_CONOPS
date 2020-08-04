%to be modified down the road
time_start = 0;
time_step  = .25;
time_end   = 51;

time_vector = time_start: time_step: time_end;
tv_length = length(time_vector);

%relevant modes where (1) load_out in Watts, (2) load_in in Watts
%includes 30 percent power growth
rove_link   = [45.01, 50];
charge_link = [19.89,  50];
nom_rove    = [45.01, 25];
charge_min  = [20.76, 50];  %update this solar in
                            %with new power calculations


%relevant time invterals (same as current google sheets)
landing_intervals = [0: .25: 0];
deploy_intervals  = [.25: .25: .25];
rove_intervals    = [(.5: .25: 5.25),(9.5: .25: 15.75), ...
                   (21.75: .25: 27.75), (33.75: .25: 39.25), ...
                   (45.75 : .25 : 50)];
             
charge_intervals  = setdiff([.5: .25: 50], rove_intervals);
    

                            
%plan_trek_interval = [0: .25: 1];
%downlink_interval  = [1: .25: 2];
                            

                                               
%Battery Characteristics at Deployment
battery_total = 200;
init_soc       = .50;

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
%the solar_in vector values are dependent on angle
index = 1;
for spec_time = time_vector
     if (index > 1)
        prev_value = solar_incidence(index-1);
        solar_incidence(index) = prev_value+(360/(29.5*24))/4;
     end
     index = index + 1;
end



index = 1;
for spec_time = time_vector 
    %solar angle in degrees, but must be in rad
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    
    if (ismember(spec_time, landing_intervals))
        load_out(index) = landing(1);
        load_in(index)  = landing(2)*curr_sangle_offset;
    elseif (ismember(spec_time, deploy_intervals))
        load_out(index) = deploy(1);
        load_in(index)  = deploy(2)*curr_sangle_offset;
    elseif (ismember(spec_time, rove_intervals))
        load_out(index) = nom_rove(1);
        load_in(index)  = nom_rove(2)*curr_sangle_offset;
    else %this is the charge interval
        load_out(index) = charge_min(1);
        load_in(index)  = charge_min(2)*curr_sangle_offset;
    end
    index = index + 1;
end



net_power = load_in(:) - load_out(:);
battery_cap(1) = battery_total*init_soc + net_power(1);

secs_in_step = time_step * 3600;
meters_per_sec = speed_centi/100;
distance_covered = meters_per_sec * secs_in_step;






