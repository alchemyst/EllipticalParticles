function [step] = Cohesive_Law(NumPoints, material, step)

% This is a new function to replace the functionality of
% old_cohesivetractions.m and old_Cohesive_Law.m   ---4 July 2012

%disp('Entering Cohesive_Law');

% This function computes the interfacial tractions by using the cohesive
% law.  This is done by knowing the displacement jumps and the interfacial
% properties.  The interfacial tractions are then returned.
% --- NumPoints is the number of integration points around the ellipse
% --- material is a structure containing material data
% --- step contains step data
%     --- displacement is the calculated displacement jumps, vector
%                  length NumPoints (complex)
%     --- lambda_max is the maximum value of lambda achieved to date, vector length NumPoints 


% --- delopen is the critical opening displacement (Delta n_c)
delopen = material.delopen;

% --- delslide is the critical sliding displacement (Delta t_c)
delslide = material.delslide;

% --- gint is the cohesive energy
gint=material.gint;

% --- lambda_e is the critical damage parameter
lambda_e=material.lambda_e;

%constants
zero_intpoints=zeros(1,NumPoints);

% displacement
displacement = step.displacement.total; 

% Previous maximum damage
lambda_max=step.cohesive.lambda_max;

% Are we loading or unloading?
loading=step.cohesive.loading;

% Initialise data
lambda=zero_intpoints;

lambda_max_temp=step.cohesive.lambda_max;
loading_temp=step.cohesive.loading;

% Structure of code:
   % Integration loop around particle
      % At each point, determine cohesive tractions, which requires
          % Knowing displacements, compute lambda
          % Know loading from previous converged timestep, 
          % Compare lambda with lambda_max, and determine loading or unloading --- 
               % These will be used in next timestep
          % Determine which stage of loading we are in, compute dphi/dlambda
          % Compute cohesive tractions step.cohesive.traction 
          % Do temporary store of new lambda_max, new loading where applicable.  
          % After convergence, lambda_max and loading get updated

% Integration loop around the particle to determine step.cohesive tractions

tolerance=lambda_e/10;

for jj=1:NumPoints

  % Displacement jump
  U=real(displacement(jj));
  V=imag(displacement(jj));

  % compute damage parameter lambda
  if U<0
    % don't allow damage under compression
    lambda(jj) = sqrt((V/delslide)^2);
  else
    lambda(jj) = sqrt((U/delopen)^2+(V/delslide)^2);  
  end
  
  
    
  %----------------------------------------------------
  % Determine the cohesive normal and tangential slopes  
  %====================================================  
  
  % Now we will compute kn and kt, where kn is the slope of normal
  % interfacial traction and normal opening kn=S/U and kt is slope of the
  % tangential interfacial traction and tangential opening kt=T/V

  
  % The slopes of the energy based trilinear cohesive law where 
  % --- kilinear is the initial slope 
  % --- ktilde is the slope in the second stage
  % --- khat is the unloading slope

  klinear=2*gint/lambda_e;                  
  ktilde=2*gint/(1-lambda_e);
  if lambda_max_temp(jj)>tolerance
    khat=ktilde*(1-lambda_max_temp(jj))/lambda_max_temp(jj);
  else
    khat=klinear;
  end
  
  
  % Three different stages, described with an if statement.  
  
  % When in compression, we do not allow damage to advance, so we check
  % this condition at the end and adjust for compression

  % Unloading only affects the slope in Stage II.
  
  % For nonlinear model
  if lambda(jj)<=lambda_e                   
    % Check for Stage I
    kn=klinear/delopen^2;
    kt=klinear/delslide^2;
    
  elseif lambda(jj)>lambda_e && lambda(jj)<1    
    % Check for Stage II
    if loading(jj)                      
      % Check for loading
      kn=ktilde*(1-lambda(jj))/lambda(jj)/delopen^2;
      kt=ktilde*(1-lambda(jj))/lambda(jj)/delslide^2;
    
    else                                
      % unloading
      kn=khat/delopen^2;
      kt=khat/delslide^2;
    end
  
  elseif lambda(jj)>=1                      
    % Check for Stage III
    kn=0;
    kt=0;
  else                                  
    % Check for errors
    jj
    lambda(jj)
    error('Incorrect value of lambda');   
  end

  
  % Now we correct for compression   **** Not sure we're doing this right!!!***
  % Allow damage in shear even under normal compression.  
  if U<0
    kn=klinear/delopen^2;
  end
  
  kn=kn;
  kt=kt;
   
  % Find S,T interfacial tractions
  S=kn*U;
  T=kt*V;
  
  step.cohesive.traction(jj)=S+i*T;
  
  % Compute new lambda_max_temp and loading_temp 
  % ----> These do not get used until next step
  if lambda(jj)>=lambda_max_temp(jj)                  
    % If loading
    loading_temp(jj)=true;                                   
    % set loading flag to true
    lambda_max_temp(jj)=lambda(jj);                  
    % update lambda_max_temp
  else
    % If unloading
    loading_temp(jj)=false;                                   
    % set loading flag to 0, don't update lambda_max_temp
  end   
  

  
end
% end of the integration loop

step.cohesive.loading_temp=loading_temp;
step.cohesive.lambda_max_temp=lambda_max_temp;
step.cohesive.lambda=lambda;


%disp('Leaving Cohesive_Law...');
