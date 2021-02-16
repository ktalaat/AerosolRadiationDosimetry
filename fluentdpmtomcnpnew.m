clear all
%% User Input:
unitsFactor = 100; % Factor to convert the units
scalingFactor = 1; % Scaling is done before translation // 0.9*0.95
rotateAbout = {'x','x'}; % Axis to rotate about
rotateBy = [90,-5]; % Rotation angles in degrees
translationVector = [(29.3-29.2),(17.2-17),(27.1-93.8+188-54)]; % Translate by that much in final units (Use ParaView to figure out these values for your models)
weightparticles = 1; % Turn particle position weighting on and off
%% Trimming (optional)
trimaxis = '0';
trimkeep = '0';
trimthreshold = 0;
%% MCNP Source Cards
erg = 0.364489; % Energy in MeV
par = 'p'; % Soure particle type

%% Read VIP Man Model
modelFile = 'H:\MyDirectory\vipman.csv';
headerLines = 1;

fid = fopen(modelFile);
modelData = textscan(fid,'%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
modelData = modelData{:};
fid = fclose(fid);


%% Find voxel centers of all voxels in the lung and respiratory system
elementIDs = (modelData(:,4) == 30) | (modelData(:,4) == 22);
organModelData = modelData(elementIDs,:);

%% Read Ansys Fluent's surface deposition .dpm files
headerlines = 2;
folder = 'H:\MyDirectory\'; % Must use outlet cleanup script first to empirically correct for alveolar deposition
cd(sprintf('%s',folder));
myfiles = dir('*.dpm');
data = {};
for i=1:size(myfiles,1)
 filelines = {};
 filetoread = char(myfiles(i).name);
 filelines = regexp(fileread(fullfile(folder,filetoread)),'\r\n','split');
 filelines = filelines.';
 filelines(1:headerlines) = [];
 for j=1:size(filelines,1)
 filelines{j,:} = [strsplit(filelines{j,1},{' ','(',')',':','\t'}), num2str(i)];
 end
 filelines(end) = [];
 data{end+1} = filelines;
end
combineddata = [];
for i=1:length(data)
   combineddata = [combineddata; data{i}];
end

for i=1:length(combineddata)
   originalxyz(i,:) = combineddata{i}([1:9,end]); 
end

originalxyz = originalxyz(:,2:end);
originalxyz = originalxyz(:,[1:3,9,7]);

originalxyz = cellfun(@str2num,originalxyz,'un',0);  
originalxyz = cell2mat(originalxyz);

for i=1:length(originalxyz)
   originalxyz(i,6) = originalxyz(i,5)^3;
end

%% Change the units
originalxyz(:,1:3) = unitsFactor * originalxyz(:,1:3);

%% Scale the model
originalxyz(:,1:3) = scalingFactor * originalxyz(:,1:3);

%% Perform multiple rotations as needed
rotatedData = originalxyz(:,1:3);
for m=1:length(rotateBy)
switch rotateAbout{m}
    case 'x'
        a = 1;
        b = 2;
        c = 3;
    case 'y'
        a = 2;
        b = 3;
        c = 1;
    case 'z' 
        a = 3;
        b = 1;
        c = 2;
end
originalxyz(:,1:3) = rotatedData;
theta = deg2rad(rotateBy(m));
for i=1:1:length(originalxyz)
    rotatedData(i,a) = originalxyz(i,a);
    rotatedData(i,b) = originalxyz(i,b)*cos(theta) - originalxyz(i,c)*sin(theta);
    rotatedData(i,c) = originalxyz(i,b)*sin(theta) + originalxyz(i,c)*cos(theta);
end
end

%% Translate
aerosolLocations = rotatedData + translationVector;

%% Concatenate with source file ID
aerosolLocations = [aerosolLocations, originalxyz(:,4), originalxyz(:,6)];

%% Trim if necessary
switch trimaxis
    case 'x'
        trimaxis = 1;
    case 'y'
        trimaxis = 2;
    case 'z'
        trimaxis = 3;
    otherwise
        trimaxis = 0;
end
if strcmp(trimkeep,'LessThan')
aerosolLocations = aerosolLocations(aerosolLocations(:,trimaxis) < trimthreshold,:);
elseif strcmp(trimkeep,'GreaterThan')
aerosolLocations = aerosolLocations(aerosolLocations(:,trimaxis) > trimthreshold,:);
end

%% Move particles to nearest voxel center in the respiratory system
newAerosolLocations = {};
parfor i=1:1:length(aerosolLocations)
    particlelocation = aerosolLocations(i,1:3);
    dist = zeros(length(organModelData),1);
    for j=1:length(organModelData)
     dist(j,1) = norm([particlelocation-organModelData(j,1:3)]);
    end
    [~,voxelindex] = min(dist);
    newAerosolLocations{i} = organModelData(voxelindex,1:3);
end

for i=1:1:length(aerosolLocations)
   aerosolLocations(i,1:3) = newAerosolLocations{i}; 
end

%% Weight particle position based on aerosol particle volume
particleweights = ones(length(aerosolLocations),1);
if weightparticles == 1
for i=1:1:length(aerosolLocations)
    particleweights(i,1) =  aerosolLocations(i,5)/sum(aerosolLocations(:,5));
end
end

%% Visualize in Matlab
plot3(aerosolLocations(:,1),aerosolLocations(:,2),aerosolLocations(:,3),'o')

%% Create ParaView-compatible file for visualization
header = {'X','Y','Z','SourceFileID'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen('aerosol.csv','w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
dlmwrite('aerosol.csv',aerosolLocations,'-append');

%% Generate source cards for MCNP
% Remember: MCNP uses cm as unit for length. Unit must be cm.
header = {'sdef','par ',par,' erg ',char(num2str(erg)),' pos D1'};
delimitedHeader = [header;repmat({' '},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
sdefcardhead = cell2mat(delimitedHeader);
fid = fopen('sdef.txt','w'); 
fprintf(fid,'%s\n',sdefcardhead);
fid = fopen('sdef.txt','a');
fprintf(fid,'SI1 L &\n');
for i=1:length(aerosolLocations)
fprintf(fid,'     %f %f %f\n',aerosolLocations(i,1),aerosolLocations(i,2),aerosolLocations(i,3));
end
fprintf(fid,'SP1 &\n')
for i=1:length(aerosolLocations)
fprintf(fid,'     %f\n',particleweights(i,1));
end
fclose('all')

function mybin = findBin(pdiameter)
pdiameter = pdiameter * 1E+6;
binminlimits = 0.00:0.5:9.99;
binmaxlimits = 0.50:0.5:10;
binminlimit = nan;
binmaxlimit = nan;
for i=1:length(binminlimits)
    if pdiameter >= binminlimits(i) && pdiameter <= binmaxlimits(i)
        binminlimit = binminlimits(i);
        binmaxlimit = binmaxlimits(i);
        break;
    end
end
mybin = find(binminlimits == binminlimit,1);
end