
D = (0.0:0.005:1);
F = 193.2*exp(-16.77.*D);
figure(1)
plot(D,F)
xlim([0.3 1])
ylim([0 1])
title('Number of Rocks vs Diameter')
xlabel('Diameter [m]') 
ylabel('Number of Rocks') 

k = [0.03639 0.0116 0.00547 0.00507 0.00360 0.00633 0.00481];
l = [-1.216 -2.163 -1.506 -2.398 -7.969 -7.563 -6.803];
D = (0.05:0.05:1);  
figure(2)

N0101 = k(1).*exp(l(1).*D);
loglog(D,N0101);
title('Cumulative Fractional Area Occupied by Rocks > D');
xlabel('Diameter [m]');
ylabel('Cumulative Fractional Area Occupied by Rocks > D');
xlim([0 1]);
ylim([10e-5 10e-2]);
xticks([0.05 0.1 0.5 1.0]);
hold on;

N0102 = k(2).*exp(l(2).*D);
loglog(D,N0102);

N0103 = k(3).*exp(l(3).*D);
loglog(D,N0103);

N0104 = k(4).*exp(l(4).*D);
loglog(D,N0104);

N0105 = k(5).*exp(l(5).*D);
loglog(D,N0105);

N0106 = k(6).*exp(l(6).*D);
loglog(D,N0106);

N0107 = k(7).*exp(l(7).*D);
loglog(D,N0107);

legend();
legend("N0101","N0102","N0103","N0104","N0105","N0106","N0107");

figure(3)
D = (0.0:0.05:1);
N = 0.0279.*exp(-867/500.*D)./D-0.04785.*expint(1867./500.*D);
loglog(D,N);
title('Cumulative Number of Rocks with Diameter > D per square meter');
xlabel('Diameter [m]');
ylabel('Cumulative Number of Rocks with Diameter > D per square meter');
xlim([0 1.25]);
ylim([10e-4 10e-1]);
xticks([0.05 0.1 0.5 1.0]);

figure(4)
D = (0.0:0.05:1.6);
H = 0.2347.*D+0.0039;
plot(D,H)
title('Rock Height vs Rock Diameter');
xlabel('Rock Diameter [m]');
ylabel('Rock Height [m]');
xlim([0 1.6]);
ylim([0 0.6]);
xticks((0:0.2:1.6));

% bellyHeight = 0.1652; %165.2mm robver belly height converted to [m]
% clearanceFactor = 0.050; %50mm clearance to safely clear a rock [m]
% maxAllowedRockHeight = bellyHeight - clearanceFactor; %max height rock rover can clear safely [m]

maxAllowedRockHeight = 0.1; %[m]
wheelWidth = 0.080; %[m]

maxDiameter = (maxAllowedRockHeight - 0.0039)/0.2347; %max diameter of a rock with the max height
roverWidth = 0.650; %[m]
roverLength = 0.650; %[m]
roverWidthProfile = (roverWidth+maxDiameter); 
distance = 1000; %distance to target [m]
travelArea = roverWidthProfile * distance; %total area profile of rover's path

rockDistribution = 0.0279*exp(-867/500*maxDiameter)/maxDiameter-0.04785*expint(1867/500*maxDiameter); %number of rocks with diameter >= maxD per square meter

numRocks = rockDistribution*travelArea;

rocks = [0.3242 0.4 0.5 0.6 0.7 0.8 0.9 1.0;
         20     5   1   0   0   0   0   0];

turnRadius = roverWidth/2 + rocks./2 + 0.300; %turn radius = roverWidth/2 + rockDiameter/2 + clearance [m]

straightLinePower = 6; %[W]

timePointTurn = 28; %time to point turn 90deg [s]
turningPower = 10; %[W]

