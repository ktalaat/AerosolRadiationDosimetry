clear
%% Use: to generate particles for inhalation simulations for the lung model for aerosol injection in Fluent
inletArea = 0.855*(84281/100000)*0.00043714; % Area of the circular inlet in m2
inletPosition = 0.855*[-0.0008, 0.0912, 0.08]; % Position of the center of the inlet
numberOfParticles = 100000;
amad = 1E-6; % Aerodynamic median aerosol diameter. 
gsd = 2.48; % Use 1 if you wish to use a constant diameter.
minimumDiameter = 0.01E-6; % Minimum particle diameter
maximumDiameter = 10E-6;
flowRate = 15; % Flow rate in liters of air per minute
u = 0;
v = 0;
w = -(flowRate/60)*1E-3*(1/inletArea);
w = 0;
temp = 310;
massflowrate = 1;

mu = log(amad);
sigma = log(gsd);
inletRadius = sqrt(inletArea/pi);

fid = fopen('injectionfile.dat','w');
fid = fopen('injectionfile.dat','a');
particlesAccepted = 0;
i = 1;
nthrows = 0;
while(1)
nthrows = nthrows + 1;
a = -1 + 2*rand;
b = -1 + 2*rand;
if (a^2 + b^2) < 1
    q1(i,1) = a*inletRadius + inletPosition(1);
    q2(i,1) = b*inletRadius + inletPosition(2);
    q3(i,1) = inletPosition(3);
    v1(i,1) = u;
    v2(i,1) = v;
    v3(i,1) = w; 
    randomDiameter = lognrnd(mu,sigma);
    diameterOk = 0;
    while diameterOk == 0
    if (randomDiameter < minimumDiameter) || (randomDiameter > maximumDiameter)
        randomDiameter = lognrnd(mu,sigma);
    else 
        diameterOk = 1;
    end
    end
    diameter(i,1) = randomDiameter;
    temperature(i,1) = temp;
    mflow(i,1) = massflowrate;
    particleID(i,1) = particlesAccepted + 1;
    fprintf(fid,'  ((   %e   %e   %e   %e   %e   %e   %e   %e   %e)     %d)\r\n',q1(i,1),q2(i,1),q3(i,1),v1(i,1),v2(i,1),v3(i,1),diameter(i,1),temperature(i,1),mflow(i,1),particleID(i,1));
end
if (a^2 + b^2) > 1
 continue;
end
particlesAccepted = particlesAccepted + 1;
if particlesAccepted == numberOfParticles
    break;
end
i = i + 1;
end
fclose(fid)

% Check
estimatedPI = 4*particlesAccepted/nthrows;
%plot(q1,q2);

%% Create ParaView-compatible file for visualization
header = {'X','Y','Z'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen('particlelocations.csv','w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
dlmwrite('particlelocations.csv',[q1,q2,q3],'-append');

% We also should write out the total mass to be able to calculate the mass
% fraction