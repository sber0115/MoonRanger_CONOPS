

init_soc = .8;             %initial state of charge
begin_charge_soc  = .60;
end_charge_soc    = 1;
trek_duration     =  28.5; %[Hrs]

choose_power_multiplier = 6; %select the occlusion multipliers to use (1-5)

plan_duration     =  0;    %[Hrs]
downlink_duration =  0;  %[Hrs, 1hr and 20mins]

%% User can see how energy expenditure changes by disabling/enabling rocks/craters
enable_rocks = false;
enable_shadows = false;
enable_craters = false;

max_soc = 1;           %maximum state of charge [100%]
max_charge_period = 0; %[Hrs]
max_shadow_time   = 60*60; %[secs, 3 mins total]

%change "heater_power" to vary discrete heater power
%this power is added to the total power consumption during a specific mode
heater_power = 0; 

