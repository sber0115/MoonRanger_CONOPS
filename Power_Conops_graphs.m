


figure
subplot(2,2,1)
plot(time_vector,distance_travelled)
title('Total Distance Travelled')
xlabel('Time (hrs)')
ylabel('Distance (m)')

subplot(2,2,2)
plot(time_vector,solar_incidence)
title('Solar Incidence Angle from Absolute')
xlabel('Time (hrs)')
ylabel('Degrees')


subplot(2,2,3)
plot(time_vector,battery_soc)
title('Battery SOC over Time')
xlabel('Time (hrs)')
ylabel('State of Charge')