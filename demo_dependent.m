A=[1,2,3;4,5,6];
A(:,:,2)=[7,8,9;10,11,12];

myA = Dependent(A, ...
    Parameters=struct('x', 10:10:20,'y', 100:100:300, 'z', 1000:1000:2000), ...
    Label = 'test', ...
    Log = 'IFbandwith:100kHz\nPower:-20dBm');


% read
myA
myA(1,2:3,1).value

myA(1,2:3,:).value
myA(1,2:3,:).squeeze.value

myA{10,200:300,:}
myA.value
myA.Parameters
myA.Dependency
myA.Label

%write
myA(1,2,1).value
myA(1,2,1)=6;
myA(1,2,1).value


myA(1,2:3,1).value
myA(1,2:3,1)=[5,4];
myA(1,2:3,1).value
