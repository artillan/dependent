function depstruct = readdependents(jsonfilename)


arguments
    jsonfilename string
end
fid = fopen(jsonfilename);
raw = fread(fid,inf);
fclose(fid);

str = char(raw');
structdata = jsondecode(str);
for field = fieldnames(structdata).'
    field = field{1};
    depstruct.(field) = Dependent.struct2dependent(structdata.(field));
end
end