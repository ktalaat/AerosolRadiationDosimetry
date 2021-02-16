clear all; clc; close all;
%% User Inputs 
organID = 30; % ID of the organ 
organID2 = 22; % ID of a second organ (use same as first if you want 1 organ)
voxelsize = [0.4,0.4,0.4]; % Voxel size in cm
particlesPerVoxel = 1; % Preferrably >= 1  - Random sampling is used if smaller
erg = 0.5; % MeV
par = 'p'; % Particle type

% Compartment Deposition Fractions
head_df = 0.0785;
lu_df = 0.0769;
ll_df = 0.152;
ru_df = 0.078;
rm_df = 0.0387;
rl_df = 0.152;

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
selectionVector = zeros(length(organModelData),1);

totalVoxels = length(organModelData);
% Get number of voxels per compartment 
compVoxelCount = zeros(6,1);
for i=1:length(organModelData)
    % Head
    if organModelData(i,3) >= 63.65
        compVoxelCount(1) = compVoxelCount(1) + 1;
    end
    
    % RU
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 63.65 && organModelData(i,3) >= 56.16
        compVoxelCount(2) = compVoxelCount(2) + 1;
    end
    
   % RM
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 56.16 && organModelData(i,3) > 52.143
        compVoxelCount(3) = compVoxelCount(3) + 1;
    end
    
    % RL
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 52.143
        compVoxelCount(4) = compVoxelCount(4) + 1;
    end
    
    % LL
    if organModelData(i,1) > -1.48750 && organModelData(i,3) < 53.20
        compVoxelCount(5) = compVoxelCount(5) + 1;
    end
    
    % LU
    if organModelData(i,1) > -1.48750 && organModelData(i,3) >= 53.20 && organModelData(i,3) < 63.65
        compVoxelCount(6) = compVoxelCount(6) + 1;
    end
end

for i=1:length(organModelData)
    % Head
    if organModelData(i,3) >= 63.65
        organModelData(i,5) = head_df*totalVoxels/compVoxelCount(1);
    end
    
    % RU
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 63.65 && organModelData(i,3) >= 56.16
        organModelData(i,5) = ru_df*totalVoxels/compVoxelCount(2);
    end
    
   % RM
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 56.16 && organModelData(i,3) > 52.143
        organModelData(i,5) = rm_df*totalVoxels/compVoxelCount(3);
    end
    
    % RL
    if organModelData(i,1) < -1.48750 && organModelData(i,3) < 52.143
        organModelData(i,5) = rl_df*totalVoxels/compVoxelCount(4);
    end
    
    % LL
    if organModelData(i,1) > -1.48750 && organModelData(i,3) < 53.20
        organModelData(i,5) = ll_df*totalVoxels/compVoxelCount(5);
    end
    
    % LU
    if organModelData(i,1) > -1.48750 && organModelData(i,3) >= 53.20 && organModelData(i,3) < 63.65
        organModelData(i,5) = lu_df*totalVoxels/compVoxelCount(6);
    end
end

%% Create particle location matrix
sourceParticles = [];
for i=1:length(organModelData)
    if particlesPerVoxel < 1
        if rand <= particlesPerVoxel
            sourceParticles(end+1,:) = organModelData(i,[1:3,5]);
        end
    elseif particlesPerVoxel == 1
        sourceParticles(end+1,:) = organModelData(i,[1:3,5]);
    elseif particlesPerVoxel > 1
        for j=1:floor(particlesPerVoxel)
            sourceParticles(end+1,:) = organModelData(i,[1:3,5]);
        end
        if rand <= (particlesPerVoxel - floor(particlesPerVoxel))
            sourceParticles(end+1,:) = organModelData(i,[1:3,5]);
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
fprintf(fid,'     %f\n',sourceParticles(i,4));
end
fclose('all')