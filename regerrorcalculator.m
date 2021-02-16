% Read VIP Man Model Data
modelFile = 'H:\MyDirectory\vipman.csv';
headerLines = 1;
fid = fopen(modelFile);
modelData = textscan(fid,'%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
modelData = modelData{:};
fid = fclose(fid);

% Read Aerosol File
aerosolFile = 'H:\MyDirectory\aerosol.csv';
headerLines = 1;
fid = fopen(aerosolFile);
aerosolData = textscan(fid,'%f,%f,%f,%f,%f\n','HeaderLines',headerLines,'CollectOutput',1);
aerosolData = aerosolData{:};
fid = fclose(fid);

regerrors = 0;
for i=1:length(aerosolData)
   x = aerosolData(i,1);
   y = aerosolData(i,2);
   z = aerosolData(i,3);
   mX = modelData(modelData(:,1) == x,:);
   mY = mX(mX(:,2) == y,:);
   mZ = mY(mY(:,3) == z,:);
   organID = mZ(4);
   if organID ~= 22 && organID ~= 30
      regerrors = regerrors + 1; 
   end
end