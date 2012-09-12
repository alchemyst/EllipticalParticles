function test_stack

% Number of loadsteps
NumSteps=3;

% Tolerance of error
epsilon=1e-10;

struct_in.Sigma_p=zeros(NumSteps,3);
struct_in.Eps_int=zeros(NumSteps,3);

struct_in.Sigma_p=[3 2 1; 4 3 2; 5 4 3];
struct_in.Eps_int=[-1 -2 -3; -2 -3 -4; -3 -4 -5];


% Test for zero modes
NumModes=0;
struct_in.sk = zeros(NumSteps, NumModes+1);
struct_in.sk = [4+2i; 3-5i; i];
tt = 2;
vect_out = stack(struct_in, NumModes, tt);

vector_check = [3 -5 4 3 2 -2 -3 -4];
assert(allequal(vect_out, vector_check, epsilon), ...
       'Vector not properly stacked for NumModes=0');

% Test for two modes
NumModes = 2;
struct_in.sk = zeros(NumSteps, NumModes+1);
struct_in.sk =[4+2i 3-i 1+2i; 3-5i 0 2+6i; i -1-i 2+i];

tt = 1;
vect_out=stack(struct_in, NumModes, tt);

vector_check=[4 3 1 2 -1 2 3 2 1 -1 -2 -3];
assert(allequal(vect_out, vector_check, epsilon), ...
       'Vector not properly stacked for NumModes=2');

