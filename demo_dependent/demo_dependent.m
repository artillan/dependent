
%% example data
% A: Store 3D data in a Dependent of parameters 'x', 'y' and 'z'
dataA=[1,2,3;4,5,6];
dataA(:,:,2)=[7,8,9;10,11,12];
A = Dependent(dataA, ...
    Parameters=struct('x', 10:10:20,'y', 100:100:300, 'z', 1000:1000:2000), ...
    Label = 'A', ...
    Log = 'blah blah');

% B: Store 3D data in a Dependent of parameters 'x', 'y' and 'z'
B = Dependent(complex([1.1,1.2;2.1,2.2;3.1,3.2], [11,12;21,22;31,32]), ...
    Parameters=struct('u', [1,2,3],'v', [10,20]), ...
    Label = 'B');

%% Dependent fields
A
A.value
A.Parameters
A.Dependency
A.Label

%% get values
% create subset from parameter indexes and read value
A(1,2:3,1).value
A(1,2:3,:).value

%% squeeze
A(1,2:3,:).squeeze.value

% create subset from parameter values
A{10,200:300,:}

%% set vlaues
A(1,2,1).value
A(1,2,1)=6;
A(1,2,1).value

A(1,2:3,1).value
A(1,2:3,1)=[5,4];
A(1,2:3,1).value

%% read and write a Dependent (json format)
A.writejson('A.json');
AA = Dependent.readjson('A.json');

B.writejson('B.json');
BB = Dependent.readjson('B.json');

%% struct of dependents
DATA.A=A;
DATA.B=B;

%%
writedependentblock(jsonFileName, DATA);
% % % 
% % % FileName = "IV";
% % % % FileName = "CW_freqswpXS_thetaswp_phiswp";
% % % 
% % % matFileName = FileName+".mat";
% % % load(matFileName, "DATA");
% % % 
% % % jsonFileName = FileName+".json";
% % % writedependentblock(jsonFileName, DATA);
% % % 
% % % MEAS2 = readdependentblock(jsonFileName);
