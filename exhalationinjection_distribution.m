clear all
%% User Inputs
%% Use: to generate injection file for exhalation based on empirical correction of CFPD data for alveolar deposition
folder = 'H:\MyDirectory\';
filetoread = 'l_1.dpm';
injectionFile = 'H:\MyDirectory\injectionfile.dat'; % Original injection file used in inhalation simulations
probabilityModifier = 0.85272*0.45; % Percent of particles that were actually tracked multiplied by any modifier you want for left/right lung ratio.
backwardStep = 0.0005; % This is the backward step needed for inlet positioning correction
u = 0;
v = 0;
w = 0;
temp = 310;
massflowrate = 1;


%% Actual Code
cd(sprintf('%s',folder));
headerlines = 2;
filelines = regexp(fileread(fullfile(folder,filetoread)),'\r\n','split');
filelines = filelines.';
filelines(1:headerlines) = [];
data = {};
for j=1:size(filelines,1)
filelines{j,:} = [strsplit(filelines{j,1},{' ','(',')',':','\t'}), num2str(i)];
end
filelines(end) = [];
data{end+1} = filelines;
combineddata = [];
for i=1:length(data)
   combineddata = [combineddata; data{i}];
end

for i=1:length(combineddata)
   currentdpmdata(i,:) = combineddata{i}; 
end

currentdpmdata = currentdpmdata(:,2:end);
currentdpmdata = currentdpmdata(:,[1:3,7,4,5,6]);

currentdpmdata = cellfun(@str2num,currentdpmdata,'un',0);  
currentdpmdata = cell2mat(currentdpmdata);

% Read injection file
injfilelines = regexp(fileread(sprintf('%s',injectionFile)),'\r\n','split');
injfilelines = injfilelines.';
injdata = {};
for j=1:size(injfilelines,1)
injfilelines{j,:} = [strsplit(injfilelines{j,1},{' ','(',')',':','\t'}), num2str(i)];
end
injfilelines(end) = [];
injdata{end+1} = injfilelines;
injcombineddata = [];
for i=1:length(injdata)
   injcombineddata = [injcombineddata; injdata{i}];
end

for i=1:length(injcombineddata)
   injfiledata(i,:) = injcombineddata{i}; 
end

for i=1:length(injcombineddata)
   injfiledata(i,:) = injcombineddata{i}; 
end

injfiledata = injfiledata(:,2:end);
injfiledata = injfiledata(:,[1:3,7]);

injfiledata = cellfun(@str2num,injfiledata,'un',0);  
injfiledata = cell2mat(injfiledata);

fid = fopen(strcat(strtok(filetoread,'.'),'.inj'),'w');
fid = fopen(strcat(strtok(filetoread,'.'),'.inj'),'a');

rmpgreaterthan1 = 0;
counter = 0;
for i=1:(length(currentdpmdata))
    bincountratio(i,1) = getBinSize(currentdpmdata(i,4),injfiledata(:,4))/getBinSize(currentdpmdata(i,4),currentdpmdata(:,4)); % This is because we are looping over the outlet file. Yet original removal probability is calculated for all injected particles.
    removalProbability = probabilityModifier*getAlveolarDepositionFraction(currentdpmdata(i,4))*bincountratio(i,1);
    if (rand > removalProbability) || (removalProbability > 1) % Removal probability > 1 indicates that less particles arrived at outlet than expected
    q1(i,1) = currentdpmdata(i,1) - currentdpmdata(i,5)*backwardStep;
    q2(i,1) = currentdpmdata(i,2) - currentdpmdata(i,6)*backwardStep;
    q3(i,1) = currentdpmdata(i,3) - currentdpmdata(i,7)*backwardStep;
    v1(i,1) = u;
    v2(i,1) = v;
    v3(i,1) = w; 
    diameter(i,1) = currentdpmdata(i,4);
    temperature(i,1) = temp;
    mflow(i,1) = massflowrate;
    particleID(i,1) = i;
    fprintf(fid,'  ((   %e   %e   %e   %e   %e   %e   %e   %e   %e)     %d)\r\n',q1(i,1),q2(i,1),q3(i,1),v1(i,1),v2(i,1),v3(i,1),diameter(i,1),temperature(i,1),mflow(i,1),particleID(i,1));
    counter = counter + 1;
    end
    if removalProbability > 1
       rmpgreaterthan1 =  rmpgreaterthan1 + 1;
    end
end
fclose(fid);

fractionremoved = 1 - (counter/size(currentdpmdata,1))
fclose('all')


function output = getAlveolarDepositionFraction(pdiameter)
load('H:\MyDirectory\dfdata.mat'); % Empirical deposition data
output = interp1(x,y,pdiameter*1E+6);
end

function [binminlimit, binmaxlimit] = findBin(pdiameter)
binminlimits = 0.01:0.01:9.99;
binmaxlimits = 0.02:0.01:10;
binminlimit = nan;
binmaxlimit = nan;
for i=1:length(binminlimits)
    if pdiameter >= binminlimits(i) && pdiameter <= binmaxlimits(i)
        binminlimit = binminlimits(i);
        binmaxlimit = binmaxlimits(i);
        break;
    end
end
end

function binsize = getBinSize(pdiameter,data)
data = data  * 1E+6;
pdiameter = pdiameter * 1E+6;
[binminlimit, binmaxlimit] = findBin(pdiameter);
binsize = 0;
for i=1:1:length(data)
    if data(i) >= binminlimit && data(i) <= binmaxlimit
        binsize = binsize + 1;
    end
end

end