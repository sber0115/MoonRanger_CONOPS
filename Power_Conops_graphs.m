%rock_indexes = nonzeros(transpose(rock_indexes));
%rock_indexes = transpose(rock_indexes);

figure
subplot(2,2,1)
plot(time_vector/60,distance_travelled, 'color', 'k')
title('Net Distance vs Time')
xlabel('Time (hrs)')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylabel('Distance (m)')



subplot(2,2,3)
plot(time_vector/60,azimuth_angle, 'color', 'k')
title('Solar Azimuth Angle')
xlabel('Time (hrs)')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylabel('Degrees')



subplot(2,2,2)
plot(time_vector/60,battery_soc*100, 'color', 'k')
hold on
%plot(time_vector(rock_indexes)/60, battery_soc(rock_indexes)*100, 'color', 'r')
title('Battery State-of-Charge vs Time')
xlim([0, trek_duration])
xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
%ylim([(begin_charge_soc - .1)*100, 90])
ylim([0,100]);
xlabel('Time (hrs)')
ylabel('State of Charge (100% Max)')

