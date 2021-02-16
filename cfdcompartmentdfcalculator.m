clear all; clc; close all;
%% User Inputs 
cfdAerosolFile = 'H:\MyDirectory\aerosol.csv';
headerLines = 1;
particleCount = 84000;

% Initialize Deposition Fractions
head_df = 0; 
ru_df = 0; 
rm_df = 0; 
rl_df = 0; 
lu_df = 0; 
ll_df = 0; 

%% Read Model File
fid = fopen(cfdAerosolFile);
aerosolData = textscan(fid,'%f,%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
aerosolData = aerosolData{:};
fid = fclose(fid);

%% Model Specific Processes
aerosolData(:,5) = [];
aerosolData(:,4) = [];

%% Find voxel centers of all voxels in the organ

totalVoxels = length(aerosolData);
% Get number of voxels per compartment (VIP-MAN)
compVoxelCount = zeros(6,1);
for i=1:length(aerosolData)
    % Head
    if aerosolData(i,3) >= 63.65
        head_df = head_df + 1;
    end
    
    % RU
    if aerosolData(i,1) < -1.48750 && aerosolData(i,3) < 63.65 && aerosolData(i,3) >= 56.16
        ru_df = ru_df + 1;
    end
    
   % RM
    if aerosolData(i,1) < -1.48750 && aerosolData(i,3) < 56.16 && aerosolData(i,3) > 52.143
        rm_df = rm_df + 1;
    end
    
    % RL
    if aerosolData(i,1) < -1.48750 && aerosolData(i,3) < 52.143
        rl_df = rl_df + 1;
    end
    
    % LU
    if aerosolData(i,1) > -1.48750 && aerosolData(i,3) >= 53.20 && aerosolData(i,3) < 63.65
        lu_df = lu_df + 1;
    end
    
    % LL
    if aerosolData(i,1) > -1.48750 && aerosolData(i,3) < 53.20
        ll_df = ll_df + 1;
    end   
end

head_df = head_df/particleCount
lu_df = lu_df/particleCount
ll_df = ll_df/particleCount
ru_df = ru_df/particleCount
rm_df = rm_df/particleCount
rl_df = rl_df/particleCount

