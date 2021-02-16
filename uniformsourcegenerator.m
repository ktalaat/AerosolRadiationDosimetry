clear all; clc; close all;
%% User Inputs 
organID = 30; % ID of the organ 
organID2 = 22; % ID of a second organ (use same as first if you want 1 organ)
voxelsize = [0.4,0.4,0.4]; % Voxel size in cm
particlesPerVoxel = 1; % Preferrably >= 1  - Random sampling is used if smaller
erg = 0.364; % keV
par = 'p'; % Particle type

%% Read Model File
modelFile = 'H:\MyDirectory\vipman.csv';
headerLines = 1;

fid = fopen(modelFile);
modelData = textscan(fid,'%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
modelData = modelData{:};
fid = fclose(fid);

%% Find voxel centers of all voxels in the organ
elementIDs = (modelData(:,4) == organID) | (modelData(:,4) == organID2);
organModelData = modelData(elementIDs,:);

%% Create particle location matrix
sourceParticles = [];
for i=1:length(organModelData)
    if particlesPerVoxel < 1
        if rand <= particlesPerVoxel
            sourceParticles(end+1,:) = organModelData(i,1:3);
        end
    elseif particlesPerVoxel == 1
        sourceParticles(end+1,:) = organModelData(i,1:3);
    elseif particlesPerVoxel > 1
        for j=1:floor(particlesPerVoxel)
            sourceParticles(end+1,:) = organModelData(i,1:3);
        end
        if rand <= (particlesPerVoxel - floor(particlesPerVoxel))
            sourceParticles(end+1,:) = organModelData(i,1:3);
        end
    end
end

%% Generate source cards for MCNP
% Remember: MCNP uses cm as unit for length. Unit must be cm.
header = {'sdef','par ',par,' erg ',char(num2str(erg)),' pos D1'};
delimitedHeader = [header;repmat({' '},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
sdefcardhead = cell2mat(delimitedHeader);
fid = fopen('sdefu.txt','w'); 
fprintf(fid,'%s\n',sdefcardhead);
fid = fopen('sdefu.txt','a');
fprintf(fid,'SI1 L &\n');
for i=1:length(sourceParticles)
fprintf(fid,'     %f %f %f\n',sourceParticles(i,1),sourceParticles(i,2),sourceParticles(i,3));
end
fprintf(fid,'SP1 &\n')
for i=1:length(sourceParticles)
fprintf(fid,'     1\n');
end
fclose('all')