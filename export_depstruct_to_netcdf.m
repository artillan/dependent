% Example
% >>load("...\meas\20240526 IgnacioMay24\GaNHEMT\OPEN_W2x25um_B3Gaudencio\SP.mat")
% >>export_depstruct_to_netcdf(struct_of_deps_DATA, 'SHORT_W2x25um_B3Gaudencio.nc')

% Exports the .nc in the current dir
% Complex numbers are converted to 2 float64 _real _imag

function export_depstruct_to_netcdf(DATA, filename)
    % Delete existing file if it exists
    if exist(filename, 'file') == 2
        delete(filename);
    end
    
    % Initialize NetCDF file using modern Schema API
    ncid = netcdf.create(filename, 'CLOBBER');
    netcdf.close(ncid); % Close to open in schema mode via ncwriteschema
    
    % Get field names and filter out 'Header'
    fields = fieldnames(DATA);
    fields = fields(~strcmp(fields, 'Header'));
    
    % Build NetCDF structure definition
    schema = struct();
    schema.Name = '/';
    schema.Format = 'classic';
    schema.Dimensions = struct('Name', {}, 'Length', {});
    schema.Variables = struct('Name', {}, 'Dimensions', {}, 'Datatype', {}, 'Attributes', {});
    schema.Attributes = struct('Name', {}, 'Value', {});
    
    % Track existing dimensions across variables
    definedDims = containers.Map();
    
    % 1. Define Dimensions and Variables in Schema
    for i = 1:length(fields)
        varName = fields{i};
        depObj = DATA.(varName);
        
        dataVal = depObj.value;
        params = depObj.Parameters;
        
        % Read parameter names (coordinate names)
        paramNames = fieldnames(params);
        varDimStructs = struct('Name', {}, 'Length', {});
        
        % Define dimensions based on Parameters
        for d = 1:length(paramNames)
            dimName = paramNames{d};
            coordVec = params.(dimName);
            dimLen = length(coordVec);
            
            % If dimension not defined yet, add to global schema
            if ~definedDims.isKey(dimName)
                definedDims(dimName) = dimLen;
                schema.Dimensions(end+1) = struct('Name', dimName, 'Length', dimLen);
                
                % Also define Coordinate Variable for xarray compatibility
                coordVar = struct();
                coordVar.Name = dimName;
                coordVar.Dimensions = struct('Name', dimName, 'Length', dimLen);
                coordVar.Datatype = class(coordVec);
                coordVar.Attributes = struct('Name', {}, 'Value', {});
                schema.Variables(end+1) = coordVar;
            end
            
            varDimStructs(d) = struct('Name', dimName, 'Length', dimLen);
        end
        
        % Base metadata attributes
        attrs = struct('Name', {}, 'Value', {});
        if isfield(depObj, 'Log') && ~isempty(depObj.Log)
            attrs(end+1) = struct('Name', 'Log', 'Value', char(depObj.Log));
        end
        
        baseLabel = char(depObj.Label);
        
        % Check if the data is complex
        if ~isreal(dataVal)
            % Define _real variable
            realVar = struct();
            realVar.Name = [baseLabel, '_real'];
            realVar.Dimensions = varDimStructs;
            realVar.Datatype = class(real(dataVal));
            realVar.Attributes = attrs;
            schema.Variables(end+1) = realVar;
            
            % Define _imag variable
            imagVar = struct();
            imagVar.Name = [baseLabel, '_imag'];
            imagVar.Dimensions = varDimStructs;
            imagVar.Datatype = class(imag(dataVal));
            imagVar.Attributes = attrs;
            schema.Variables(end+1) = imagVar;
        else
            % Define standard real variable
            mainVar = struct();
            mainVar.Name = baseLabel;
            mainVar.Dimensions = varDimStructs;
            mainVar.Datatype = class(dataVal);
            mainVar.Attributes = attrs;
            schema.Variables(end+1) = mainVar;
        end
    end
    
    % Write schema structure to NetCDF
    ncwriteschema(filename, schema);
    
    % 2. Write Data to NetCDF
    % Write coordinate variable values
    dimKeys = definedDims.keys();
    for k = 1:length(dimKeys)
        dimName = dimKeys{k};
        for i = 1:length(fields)
            depObj = DATA.(fields{i});
            if isfield(depObj.Parameters, dimName)
                ncwrite(filename, dimName, depObj.Parameters.(dimName));
                break;
            end
        end
    end
    
    % Write data array values
    for i = 1:length(fields)
        varName = fields{i};
        depObj = DATA.(varName);
        dataVal = depObj.value;
        baseLabel = char(depObj.Label);
        
        if ~isreal(dataVal)
            ncwrite(filename, [baseLabel, '_real'], real(dataVal));
            ncwrite(filename, [baseLabel, '_imag'], imag(dataVal));
        else
            ncwrite(filename, baseLabel, dataVal);
        end
    end
    
    fprintf('Successfully exported DATA to %s\n', filename);
end
