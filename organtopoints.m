clear all; clc;
% Read VIP Man Model Data
modelFile = 'H:\MyDirectory\vipman.csv';
organID = 22;
organID2 = 30;
headerLines = 1;
fid = fopen(modelFile);
modelData = textscan(fid,'%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
modelData = modelData{:};
fid = fclose(fid);


%% Find voxel centers of all voxels in the organ(s)
elementIDs = (modelData(:,4) == organID) | (modelData(:,4) == organID2);
organModelData = modelData(elementIDs,:);

%% Create ParaView-compatible file for visualization
header = {'X','Y','Z','OrganID'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen('organpoints.csv','w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
dlmwrite('organpoints.csv',organModelData,'-append');
