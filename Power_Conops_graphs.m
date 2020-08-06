


figure
subplot(2,2,1)
plot(time_vector,distance_travelled)
title('Total Distance Travelled')
xlabel('Time (mins)')
ylabel('Distance (m)')

subplot(2,2,2)
plot(time_vector,solar_incidence)
title('Solar Incidence Angle from Absolute')
xlabel('Time (mins)')
ylabel('Degrees')


subplot(2,2,3)
plot(time_vector,battery_soc*100)
title('Battery SOC over Time')
ylim([30, 100])
xlabel('Time (mins)')
ylabel('State of Charge (100% Max)')
