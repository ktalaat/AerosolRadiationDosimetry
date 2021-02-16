% Purpose of the code: To identify the positions (x, y, z) of the voxels
% for different organs. 
%% Read lattice
skipfirstsection = 1; %Set to 1 to skip reading the data again
if ~skipfirstsection
clear
% Required Inputs:
folder = 'H:\VIP Man Model'; % Folder where MCNP file is located
filetoread = 'vp-n.inp'; % MCNP file
headerlines = 195; % Number of lines before the lattice data
lastline = 237865; % Last line of lattice data
x_range = -73:73; % The range of the lattice in x
y_range = -43:42; % The range of the lattice in y
z_range = -235:234; % The range of the lattice in z
voxelsize = [4,4,4]; % The size of the voxel in mm
outputunits = 'cm'; % Units for output geometry
organgroups = {[22,30]}; % The code will group these together with a group tag
% End of User Input
 
filelines = regexp(fileread(fullfile(folder,filetoread)),'\n','split');
filelines = filelines.';

filelines(lastline+1:end) = [];
if headerlines > 0
filelines(1:headerlines) = [];
end
 
for j=1:size(filelines,1)
filelines{j,:} = strsplit(filelines{j,1},{' ','(',')',':','\t'});
end

data = {}; % stores the lattice elements as in the file
elements = {}; % stores the lattice elements each in a different row
data = filelines;

for i=1:length(data) 
cleandata = data{i,1};    
data{i,1} = cleandata(~cellfun('isempty',data{i,1}));
clear cleandata
% Now expand the data
elements = [elements; reshape(data{i,1},[],1)];
end
end

%% Replace repeats with actual universe numbers
newElements = {};
for i=1:size(elements,1)
    
if isempty(strfind(elements{i},'r'))
    newElements{end + 1,1} = elements{i};
end

if ~isempty(strfind(elements{i},'r'))   
    repetition = str2num(strtok(elements{i},'r'));
    repeatedElement = elements{i-1};
    sizeNewElements = length(newElements);
    for j = (sizeNewElements+1):1:(sizeNewElements+repetition)
    newElements{j,1} = repeatedElement;
    end
end
    
end

elements = flip(newElements);

%% Determine x, y, z
if strcmp(outputunits,'cm')
    voxelsize = voxelsize/10;
elseif strcmp(outputunits,'m')
    voxelsize = voxelsize/1000; 
end
i = 1;
output = zeros(length(elements),5); % Stores x, y, z and organ number.
for z=z_range
   for y=y_range
       for x=x_range
           output(i,1) = (x)*voxelsize(1);
           output(i,2) = (y)*voxelsize(2);
           output(i,3) = (z)*voxelsize(3);
           output(i,4) = str2num(elements{i,1});
           output(i,5) = getgroupid(output(i,4),organgroups);
           i = i + 1;
       end
   end
end

header = {'X','Y','Z','Organ Number','Group'};
delimitedHeader = [header;repmat({','},1,numel(header))];
delimitedHeader = delimitedHeader(:)';
csvHeader = cell2mat(delimitedHeader);
fid = fopen('vipman.csv','w'); 
fprintf(fid,'%s\n',csvHeader)
fclose(fid)
dlmwrite('vipman.csv',output,'-append');


%% Notes:
% Open output file in ParaView. Then click on Filters - > Alphabetical then
% select Table to Structured Grid. Define the extents. Then color by organ
% number. Apply a threshold from Filter - > thresholds to hide the air.