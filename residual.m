function Rk = ...
    residual(input_guess, stepmacro_var, loads, material, ...
             geom, stepcoh)



% Given a guess at the Fourier coefficients sk, the average particle stress
% sigmap and the interfacial strain epsint, this routine calculates the
% resulting cohesive coefficients skc and the corrected sigmap_new and
% epsint_new, and hences calculates the residual Rk


  % Note that sigma_p, eps_int and sk are local variables during the convergence loop -
  % passed as vector 'input'


%disp('Entering residual...');


%----------------------------------
% Unstack input vector
%==================================

% FIXME : check that I'm passing things correctly (i.e. name
% changes for structures)
dummy.Sigma_p=zeros(1,3);
dummy.Eps_int=zeros(1,3);
dummy.sk=zeros(1,loads.NumModes+1);

% Unstack input vector and separate into components
dummy=unstack(input_guess, loads.NumModes, 1,dummy);

Sigma_p=dummy.Sigma_p;
Eps_int=dummy.Eps_int;
sk = dummy.sk;



%-----------------------------------------------
% Compute macroscopic stresses and strains
%===============================================

% Macroscopic stresses and strains for the current timestep are computed from the given macroscopic strain eps_11
% Note that these depend on Sigma_p and Eps_int, so will be updated at every convergence step

[stepmacro_var.MacroStress, stepmacro_var.MacroStrain, stepmacro_var.Sigma_m]= macrostress(stepmacro_var.MacroStrain, Sigma_p, Eps_int, loads, geom, material);


%-----------------------------------------------
% Compute farfield loading
%===============================================

[N1, N2, omega] = principal(stepmacro_var.Sigma_m(1), stepmacro_var.Sigma_m(2),stepmacro_var.Sigma_m(3));
  

%-----------------------------------------------
% Compute displacements and cohesive tractions
%===============================================

[stepcoh,stepdisp,steppot]=common(N1, N2, omega, geom, material,loads, sk,stepcoh);


% Compute Fourier modes corresponding to cohesive tractions
skc = fouriertransform(stepcoh.traction, geom.theta, loads.NumModes);

% Compute interfacial strain and average particle stress
[Sigma_p_new, Eps_int_new] = averages(stepdisp.total_xy, stepcoh.traction_xy, geom);


% error in sk
error.sk=skc-sk;

% error in Sigma_p 
error.Sigma_p=Sigma_p_new - Sigma_p;      

% error in Eps_int 
error.Eps_int=Eps_int_new - Eps_int;      

Rk=stack(error, loads.NumModes, 1);

Rk = real(Rk);


