clear all; clc; close all;
% Description: Deposition fraction calculator as function of time for
%              monodisperse aerosols with uniform parcels
% Author: Khaled Talaat
%% User Input
folder = 'H:\MyDirectory\'; % Put all dpm files in one folder
particlecount = 100000; % Number of tracked injected parcels/points/whatever
timeshift = 0; % Leave it zero unless you want to start from release time instead of flow time then put release time

%% Read Ansys Fluent's surface deposition .dpm files
headerlines = 2;
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
   originalxyz(i,:) = combineddata{i}; 
end
% originalxyz: x y z u v w diameter t parcel-mass mass n-in-parcel time name fileid
originalxyz = originalxyz(:,2:end);
originalxyz(:,13) = []; % Assume only one injection (injection-0)
originalxyz(:,14) = []; % Empty cell
originalxyz = cellfun(@str2num,originalxyz,'un',0);  
originalxyz = cell2mat(originalxyz);

fileloop = unique(originalxyz(:,14)).';

for i=fileloop
   filedata = originalxyz(originalxyz(:,14) == i,:);
   filename = strcat(strtok(myfiles(i).name,'.'),'.csv'); 
   % Remove duplicates within file (if any)
   filedata = unique(filedata,'rows');
   % Shift in time if needed
   filedata(:,12) = filedata(:,12) - timeshift;
   % Sort in time
   filedata = sortrows(filedata,12);
   % Get deposition fraction (%)
   df = 100*(1:1:length(filedata)).'/particlecount;
   time = filedata(:,12);
   % Write csv file with df vs time
   csvwrite(sprintf('%s',filename),[time,df]);
end

