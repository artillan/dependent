A=[1,2,3;4,5,6];
A(:,:,2)=[7,8,9;10,11,12];

myA = Dependent(A, 'x', [10; 20], 'y', [100, 200, 300], 'z', [1000, 2000]);
myA.Label = 'test';

myA
myA(1,2:3,:)
myA{10,200:300,:}
myA.value
myA.Parameters
myA.Dependency
myA.Label
