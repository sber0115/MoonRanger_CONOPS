
%need to assume that at the start of this trek
%we are at 50% SOC


%1 hours of charging
%1 hour of charging and downlink


%can still iterate over the time, but just explicitly calculate each value
%needed for calculations

rock_findings = [];

trek_time = setdiff([0: .25: 2], time_vector);

index = 1;
for spec_time = trek_time
    curr_sangle_offset = cos(deg2rad(solar_incidence(index)));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %below code runs two hours after trek start (two hours of charging)
    %after two hours, battery SOC should be at around 90%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rock_found = ismember(spec_time, rock_findings);
    battery_
    
    %if we came across rock, avoid_obstacle
    if (rock_found) 
        %decrease total energy by amount expended during a CLC
        
        %decrease distance by total amount that could be travelled during
        %time of turning?
        avoid_obstacle(battery_cap, distance_travelled);
    end
    
    
    
    
    net_power(index) = load_in(index) - load_out(index);
    index = index + 1;
end