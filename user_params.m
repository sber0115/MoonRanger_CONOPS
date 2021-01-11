
%% User can see how energy expenditure changes by disabling/enabling rocks/craters
init_soc = .8;             %initial state of charge
begin_charge_soc  = .70;
end_charge_soc    = .85;
trek_duration     =  28.5; %[Hrs]

plan_duration     =  0;    %[Hrs]
downlink_duration =  0;  %[Hrs, 1hr and 20mins]
enable_rocks = true;
enable_shadows = true;
enable_craters = true;

max_soc = 1;           %maximum state of charge [100%]
max_charge_period = 0; %[Hrs]
max_shadow_time   = 60*60; %[secs, 3 mins total]
heat_motor_power = 30; 

