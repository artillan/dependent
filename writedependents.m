function writedependents(depstruct, jsonfilename)
%WRITEDEPSTRUCT Write a Depset (structure of Dependents) to a json encoded file.
%
%   WRITEDEPSTRUCT(DEPSTRUCT, JSONFILENAME) writes the structure of Dependents DEPSTRUCT to the file JSONFILENAME.
%
%   WRITEDEPSTRUCT overwrites any existing file by default.

arguments
    depstruct struct
    jsonfilename string
end
fid = fopen(jsonfilename,'w');
fprintf(fid,'%s',jsonencode(depstruct));
fclose(fid);
end