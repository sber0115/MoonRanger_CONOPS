

index = 1;
for spec_time = time_vector
    if (index > 1)
        battery_cap(index) = battery_cap(index-1) + time_step*net_power(index);
        battery_soc(index) = battery_cap(index)/battery_total;
    end
    
    if (ismember(spec_time, landing_intervals))
       
    elseif (ismember(spec_time, deploy_intervals))
        
    elseif (ismember(spec_time, rove_intervals) && index > 2)
        if (battery_cap(index) > 0)
            distance_travelled(index) = distance_travelled(index-1) ...
                                        + distance_covered;
        else
            distance_travelled(index) = distance_travelled(index-1);
        end
  
    else %this is the charging intervals
        distance_travelled(index) = distance_travelled(index-1);
    end
    
    index = index + 1;
end


p_index = 1;
for spec_time = time_vector
    sprintf("Time: %.2f, load_out: %.2f, load_in: %.2f", ...
            spec_time, load_out(p_index), load_in(p_index))
        
    sprintf("net_power: %.2f, battery_cap: %.2f, distance: %.2f", ...
            net_power(p_index), battery_cap(p_index), distance_travelled(p_index))
        
    p_index = p_index + 1;
end
