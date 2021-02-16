clear all; clc; close all;
%% Program maps data from tallyCSV to voxel phantom defined in modelFile by organID
%% Read Model File
modelFile = 'H:\MyDirectory\vipman.csv'; % A csv file with x,y,z,organID columns for the voxel phantom
headerLines = 1;

fid = fopen(modelFile);
modelData = textscan(fid,'%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
modelData = modelData{:};
fid = fclose(fid);


%% Read organ tallies from CSV file
tallyCSV = 'H:\MyDirectory\uniform_photons.csv'; % Organ tallies you want to visualize (first column must be organID)
fid = fopen(tallyCSV);
tallyData = textscan(fid,'%f,%f,%f\r\n','CollectOutput',1);
tallyData = tallyData{:};
fid = fclose(fid);

%% Run actual process
for j = 1:size(tallyData,1)
organ = tallyData(j,1);
voxelCount = length(find(modelData(:,4) == organ));

for i=1:length(modelData)
    if (modelData(i,4) == organ)
        modelData(i,5) = voxelCount;
        modelData(i,6) = tallyData(j,2);
        modelData(i,7) = tallyData(j,3);
    end
end  
end

%% Write output file for ParaView
header = {'X','Y','Z','Organ ID','Voxel Count','Total Energy','Dose'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen('Output.csv','w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
dlmwrite('Output.csv',modelData,'-append');