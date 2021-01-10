

figure
plot(time_vector/time_scale,distance_travelled, 'color', 'k')
title('Net Distance vs Time')
xlabel('Time (hrs)')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylabel('Distance (m)')


%{
subplot(2,2,3)
plot(time_vector/time_scale,azimuth_angle, 'color', 'k')
title('Solar Azimuth Angle')
xlabel('Time (hrs)')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylabel('Degrees')
%}


figure
plot(time_vector/time_scale,battery_soc*100, 'color', 'k')
hold on
title('Battery State-of-Charge vs Time')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylim([0,100]);
xlabel('Time (hrs)')
ylabel('State of Charge (100% Max)')

