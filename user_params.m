%%
clear
clc
close all

%% User can see how energy expenditure changes by disabling/enabling rocks/craters
init_soc = .4;             %initial state of charge
begin_charge_soc  = .70;
end_charge_soc    = .80;
trek_duration     =  30.5; %[Hrs]
plan_duration     =  5;    %[Hrs]
downlink_duration =  1.3;  %[Hrs, 1hr and 20mins]
enable_rocks = true;
enable_shadows = true;
enable_craters = true;

max_soc = 1;           %maximum state of charge [100%]
max_charge_period = 1; %[Hrs]
max_shadow_time   = 3*60; %[secs, 3 mins total]
heat_motor_power = 18; %extra power to motors when charging for over an hr

