%% Evaluate sediment loads from different parts of the country. 

%%% prepare workspace and pull in data from other folders 
clear all 
close all 
clc 

% Add folder with common spatial data
    addpath(genpath('C:\Users\rahul\OneDrive\Documents\Stanford Classes and Assignments\Winter 2020\Independent Research\Paani GIS files\Paani MATLAB and drainage area analysis\GIS files'))
       
%%%% DEM file
    DEM_grid='ALOS_DEM30m_hydrosheds_prj.tif';
%%%% Load gauging stations
    Gauge_shp='Gaging_Stations_Coordinates_Raw_prj.shp'
    
%% Load DEM and other gridded information

% load DEM 
DEM = GRIDobj(DEM_grid); 
[~,X,Y] = GRIDobj2mat((DEM)); % get extend of the DEM - basically it's X and Y coordinates
[~, R] = geotiffread(DEM_grid); % get the spatial reference, i.e., projection information
clear DEM_File

DEM.Z(DEM.Z<=0)=nan;
DEM.Z(DEM.Z>10000)=nan;

DEM_r=resample(DEM,90); % resample the DEM to a lower resolution for faster processing    
[~,X_r,Y_r] = GRIDobj2mat(DEM_r);
FD=FLOWobj(DEM_r); % get the flow directions
FA=flowacc(FD); % determine flow accumulation
FA_km2=FA.*DEM_r.cellsize.^2./1e6; %flow accumulation in km2

S=STREAMobj(FD,'minarea',100*10^6,'unit','mapunits'); 
MS=STREAMobj2mapstruct(S,... % transfer the stream object (vector of coordinates) to a shapefile-like struct
    'seglength',10000,... % cut the network in segments of not more than 10,000 m length
    'attributes',{'AD' FA_km2 @max}); % that is a bit complicated. Assign the drainage area of each reach to the shapefile 

Gauges=shaperead(Gauge_shp);
[xs,ys]=snap2stream(S,[Gauges.X], [Gauges.Y],'plot',1);

for iii=1:length(Gauges)

    Gauges(iii).X=xs(iii); 
    Gauges(iii).Y=ys(iii);

end 

figure
mapshow(MS)
hold on 
mapshow(Gauges)

DB=drainagebasins(FD,xs,ys);
AD_direct=accumarray(DB.Z(DB.Z>0),1); % identify how many cells have the ID number of a station
AD_direct=AD_direct.*DEM_r.cellsize.^2./10^6; % transform from cell count to drainage area in km2

figure
imagesc(DB)

DB_shp=GRIDobj2polygon(DB); % transfer raster data into a polygon shpaefile

% update the shapefile with info on station ID and the drainage area
for iii=1:length(Gauges)
    DB_shp(iii).Station=Gauges(iii).Stations__;   
    DB_shp(iii).AD_directkm2=AD_direct(iii);
    DB_shp(iii).AD_totalkm2=FA_km2.Z(coord2ind(X_r,Y_r,xs(iii),ys(iii)));
end 

% write the outputs
shapewrite(MS,[pwd '\Outputs\' 'River_Network_Paani.shp'])
shapewrite(Gauges,[pwd '\Outputs\' 'Gauges_snapped.shp'])
shapewrite(DB_shp,[pwd '\Outputs\' 'Gauging_basins.shp'])







 %             