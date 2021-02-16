clear all; clc;
%% User Inputs 
density = 1000;
totalmass = 0; % If set to 0, the code will calculate it. Hint: Useful for exhalation. In exhalation use same total mass as inhalation.
useaveragediameter = 0; % Set to 1 if you wish to calculate the total mass in each file using the average dimater
%% Read Ansys Fluent's surface deposition .dpm files
headerlines = 2;
folder = 'H:\MyDirectory\';
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

originalxyz = originalxyz(:,2:end);
originalxyz = originalxyz(:,[1:3,14,7]);

originalxyz = cellfun(@str2num,originalxyz,'un',0);  
originalxyz = cell2mat(originalxyz);

flag = 0;
if totalmass == 0
    flag = 1;
end

for i=1:length(originalxyz)
   originalxyz(i,6) =  density *((1/6) * pi * originalxyz(i,5)^3);
   if flag
   totalmass = totalmass + originalxyz(i,6);
   end
end

if useaveragediameter && flag
   totalmass =  length(originalxyz)*density *((1/6) * pi * mean(originalxyz(:,5))^3);
end


results = cell(size(myfiles,1),6);
results(:) = {0};
for i=1:size(myfiles,1)
    count = 0;
    for j=1:size(originalxyz,1)
       if originalxyz(j,4) == i
           count = count + 1;
           results{i,1} = myfiles(i).name; % File name
           results{i,2} = count; % Particle count
           results{i,3} = results{i,3} + originalxyz(j,5); % Just to calculate average diameter
           results{i,4} = results{i,4} + (1/6) * pi * originalxyz(j,5)^3; % Just to calculate average volume
           results{i,5} = results{i,5} + originalxyz(j,6); % Total mass in that file 
       end
    end
    results{i,6} = 100* results{i,5}/totalmass; % Deposition fraction (%) 
    results{i,3} = results{i,3}/results{i,2}; % Average diameter
    results{i,4} = results{i,4}/results{i,2}; % Average particle volume
    if useaveragediameter
        massinfile = results{i,2}*density*((1/6) * pi * results{i,3}^3);   
        results{i,6} = 100*massinfile/totalmass; %  underestimates mass in file compared to total mass which has outlier particles included
    end
end

% File Name, Particle Count, Average Diameter, Average Volume, Total Mass, Deposition Fraction (%)
disp(results) 
