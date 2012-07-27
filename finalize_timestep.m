function [cohesive, disp, loads, potential]=finalize_timestep(stepcoh, stepdisp, stepload,steppot,loads,tt)

% This subroutine writes step quantities to global quantities at the
% end of a converged loadstep.  

tolerance=1e-8;
if abs(loads.MacroStrain(tt,1)-stepload.MacroStrain(1))<tolerance
  loads.MacroStrain(tt,:)=stepload.MacroStrain(:);
else
  error('stepload.MacroStrain has been changed!!!');
end

loads.MacroStress(tt,:)=stepload.MacroStress(:);
loads.Sigma_m(tt,:)=stepload.Sigma_m(:);


disp.farfield(tt,:)=stepdisp.farfield(:);
disp.farfield_xy(tt,:)=stepdisp.farfield_xy(:);
disp.coh(tt,:)=stepdisp.coh(:);
disp.coh_xy(tt,:)=stepdisp.coh_xy(:);
disp.total(tt,:)=stepdisp.total(:);
disp.total_xy(tt,:)=stepdisp.total_xy(:);


cohesive.traction(tt,:)=stepcoh.traction(:);
cohesive.traction_xy(tt,:)=stepcoh.traction_xy(:);
cohesive.lambda(tt,:)=stepcoh.lambda(:);
cohesive.lambda_xy(tt,:)=stepcoh.lambda_xy(:);
cohesive.lambda_max(tt,:)=stepcoh.lambda_max(:);
cohesive.loading(tt,:)=stepcoh.loading(:);


potential.phi(tt,:)=steppot.phi(:);
potential.phiprime(tt,:)=steppot.phiprime(:);
potential.psi(tt,:)=steppot.psi(:);
potential.phicoh(tt,:)=steppot.phicoh(:);
potential.phiprimecoh(tt,:)=steppot.phiprimecoh(:);
potential.psicoh(tt,:)=steppot.psicoh(:);


