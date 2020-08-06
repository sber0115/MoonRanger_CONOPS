


figure
subplot(2,2,1)
plot(time_vector/60,distance_travelled)
title('Total Distance Travelled')
xlabel('Time (hrs)')
xlim([0, 6])
xticks(0:1:6)
ylabel('Distance (m)')



subplot(2,2,3)
plot(time_vector/60,solar_incidence)
title('Solar Incidence Angle from Absolute')
xlabel('Time (hrs)')
xlim([0, 18])
xticks(0:3:18)
ylabel('Degrees')



subplot(2,2,2)
plot(time_vector/60,battery_soc*100)
title('Battery SOC over Time')
xlim([0, 6])
xticks(0:1:6)
ylim([30, 65])
xlabel('Time (hrs)')
ylabel('State of Charge (100% Max)')

