function [stepcoh, stepdisp]=common(N1, N2, omega, geom,  material,loads, sk)

% Given far-field loading and Fourier modes, compute cohesive tractions and displacements
% Created from residual.m 16/7/2012
% Put displacements and tractions in structures 17/7/2012


%-----------------------------
% Initialise arrays
%==============================

%constants
zero_intpoints=zeros(1,geom.NumPoints+1);

stepdisp.farfield=zero_intpoints;
stepdisp.farfield_xy=zero_intpoints;
stepdisp.coh=zero_intpoints;
stepdisp.coh_xy=zero_intpoints;
stepdisp.total=zero_intpoints;
stepdisp.total_xy=zero_intpoints;

stepcoh.traction_xy=zero_intpoints;



%----------------------------------------
% Begin loop over integration points
%========================================

for kk=1:geom.NumPoints+1   
  % loop over all integration points
    
  %------------------------------------------------------
  % Compute potential functions from far-field loading 
  %======================================================
 
  [phi,phiprime,psi]=farfieldpotential(geom.theta(kk),geom.rho,geom.R, geom.m, N1, N2, omega);
        
  %-----------------------------------------------------
  % Compute displacements from far-field loading 
  %=====================================================
 
  stepdisp.farfield(kk)=calculatedisplacement(phi, phiprime, psi, geom.theta(kk), material.mu_m, material.kappa_m, geom.m);
  stepdisp.farfield_xy(kk)=stepdisp.farfield(kk)*exp(i*geom.beta(kk));    
 
  %-------------------------------------------------------
  % Compute potential functions due to cohesive tractions
  %=======================================================

  [phicoh, phiprimecoh, psicoh]=modes(geom.theta(kk),geom.rho,geom.R, geom.m, loads.NumModes, sk);
  
  
  %-------------------------------------------------------
  % Compute cohesive displacements 
  %=======================================================
  
  stepdisp.coh(kk)=calculatedisplacement(phicoh, phiprimecoh, psicoh, geom.theta(kk), material.mu_m, material.kappa_m, geom.m);
  stepdisp.coh_xy(kk)=stepdisp.coh(kk)*exp(i*geom.beta(kk));
  
end         
% end loop over integration points



%----------------------------------------------
% Compute total displacement
%==============================================


stepdisp.total=stepdisp.farfield+stepdisp.coh;
stepdisp.total_xy=stepdisp.farfield_xy+stepdisp.coh_xy;



%------------------------------------------------------
%Compute cohesive tractions resulting from displacement
%======================================================

stepcoh=Cohesive_Law(stepdisp.total,geom.NumPoints,material,stepcoh.lambda_max);

% *** Not sure that we're storing previous value of lambda or
% *** calculating unloading correctly!!!

for kk=1:geom.NumPoints+1
    stepcoh.traction_xy(kk)=stepcoh.traction(kk)*exp(i*beta(kk));
end


