%%%%%%%%%%%%%
%%%%%%%%%%%%%
init_soc = .4;
begin_charge_soc  = .70;
end_charge_soc    = .80;
enable_rocks = true;
enable_shadows = true;
%%%%%%%%%%%%%%%
%%%%%%%%%%%%%

duty_cycle = .75;
max_soc = 1;
max_charge_period = 1; %in hours
max_store_period  = 5.3; %hours that panel is stored after excessive charging
max_shadow_time   = 3; %in mins
panel_factor = 1;
heat_motors = 18; %extra power to motors when charging for long time
heat_motors_init = 0;

%these values consider trek 3
trek_duration     =  30.5; %in hours
plan_duration     =  5;  %in hours
downlink_duration =  1.3; %in hours, 1 hour 20 mins