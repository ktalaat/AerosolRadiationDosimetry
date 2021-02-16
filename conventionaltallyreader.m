clear all; clc;
directory = 'H:\MyDirectory\'; %Working Directory
datafile = 'mctal'; %MCNP Output File Name
totalyield = 1.00; % Use total yield of 1 to get per source particle. For per decay, add up the yields for energies simulated.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%---------------------Read file and tallies--------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('organvoxelcount.mat') % Read the number of voxels per organ for tally correction sorted by organID
load('organmass.mat') % Read organ mass data sorted by organID

cd(sprintf('%s',directory));
filelines_notdelimited = regexp(fileread(datafile),'\t|\n','split');
filelines_notdelimited = filelines_notdelimited.';

TFCIndex = find(contains(filelines_notdelimited,'tfc'));
ValIndex = TFCIndex-1;
TalIndex = find(contains(filelines_notdelimited,'tally'));

for i=1:length(TalIndex)
[~,tal{i,1}] = strtok(filelines_notdelimited{TalIndex(i)},' ');
tal{i,1} = strtok(tal{i,1},' ');
tallyid(i,1) = str2num(tal{i,1});

organid(i,1) = str2num(strtok(filelines_notdelimited{TalIndex(i)+4},' '));

val{i,1} = filelines_notdelimited{ValIndex(i)};
temp = str2num(val{i,1});
tallyvalue(i,1) = temp(end-1);

tallyrelativerror(i,1) = temp(end);

correctedtallyvalue(i,1) = tallyvalue(i,1)/organvoxelcount(i);

organdoseperdecay(i,1) = 160.2*correctedtallyvalue(i,1)*totalyield;

organtotalenergyperdecay(i,1) = correctedtallyvalue(i,1)*organmass(i)*totalyield;


organs{i,1} = strtok(filelines_notdelimited{TalIndex(i)+2},' ');
end

percentoftotaldose = 100*organtotalenergyperdecay/nansum(organtotalenergyperdecay);

cd(sprintf('%s',directory));
header = {'Tally ID','Organ ID','Organ Name','Uncorrected Tally (MeV/g/sp)','Relative Error','Corrected Tally (MeV/g/sp)','Total Energy Absorbed (MeV/bq.sec)','Percent of Total Dose','Dose per Decay (picoGy/bq.sec)'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen(strcat(datafile,'.csv'),'w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
fid = fopen(strcat(datafile,'.csv'),'a'); 
for i=1:length(organs)
    fprintf(fid,'%d,%d,%s,%e,%e,%e,%e,%e,%e\n',tallyid(i,1),organid(i,1),char(organs{i,1}),tallyvalue(i,1),tallyrelativerror(i,1),correctedtallyvalue(i,1),organtotalenergyperdecay(i,1),percentoftotaldose(i,1),organdoseperdecay(i,1))
end

fclose(fid)
