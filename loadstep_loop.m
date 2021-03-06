function [cohesive, displacement, loads, macro_var, potential, percentage, soln]= ...
    loadstep_loop(geom, material, loads, macro_var, soln, displacement, ...
                  cohesive, potential, percentage, inputname)


% Allocate step structures 

  step = initialize_step_variables(loads, geom);

%-----------------------------------------
% Begin loop through loadsteps
%=========================================

for tt=1:loads.timesteps  % Loop through loading steps
  
  disp(['Beginning timestep ' num2str(tt) ' of ' num2str(loads.timesteps) ...
        ' with macroscopic strain = ' num2str(loads.DriverStrain(tt))]);
  

  
  % The complex fourier terms are  split into real and imaginary 
  % parts before going into the solution loop.  
  if tt>1
    input_guess = stack(soln.sk(tt-1,:), soln.Sigma_p(tt-1,:), ...
                        soln.Eps_int(tt-1,:));
  else
    assert(tt == 1, 'Something funny happening here');
    input_guess = stack(soln.sk(tt,:), soln.Sigma_p(tt,:), ...
                        soln.Eps_int(tt,:));    
  end
  
  exitflag=0;
  counter=0;
  
%   %TODO: Figure out proper scaling values
%   default_values = zeros(size(input_guess));
%   variance = ones(size(input_guess));

  [default_values, variance] = scaling_values(loads, material);
  scale = @(x) (x - default_values)./variance;
  unscale = @(x) x.*variance + default_values;

  scaled_previous_solution = scale(input_guess);
  magnification = 1; % sphere radius magnifier
  while exitflag<=0        
    % Convergence loop
    tic;
    counter=counter+1
    
    scaled_input_guess = scale(input_guess);
    % Solve for sk, Sigma_p, Eps_int    
    scaled_residuals = @(x) residual(unscale(x), loads, material, ...
                                     geom, step, tt, cohesive)./variance;
    
    guess_fval = scaled_residuals(scaled_input_guess);
    [scaled_output, scaled_fval, exitflag, optim_output] = fsolve(scaled_residuals, scaled_input_guess);
    output = unscale(scaled_output);
    fval = scaled_fval.*variance;
   
    converge.fval = fval;
    converge.guess_fval = guess_fval;
    converge.exitflag = exitflag;
    converge.ii = counter;
    converge.input_guess = input_guess;
    converge.output = output;
    converge.optim_output = optim_output;
    converge.time = toc;
    
    
    
    if tt == 1
      scaled_previous_solution(:) = 0;
      delta_strain = loads.DriverStrain(tt);
    else
      delta_strain = loads.DriverStrain(tt) - loads.DriverStrain(tt-1);
    end
    
    sphere_radius = magnification*sqrt(loads.NumModes + 7)
    
    distance_from_previous = norm(scaled_output - scaled_previous_solution)
    outsidesphere = distance_from_previous > sphere_radius
    
    if exitflag ~= 1 || (exitflag == 1 && outsidesphere)
      if counter < loads.NumRestarts
        exitflag = 0;
        input_guess = (rand(size(input_guess)) ...
                       - 0.5)*material.sigmax*10;
        magnification = magnification*(1 + 0.2*outsidesphere);
      else
        break
      end  
    end
    
  
  end
  % end convergence loop
  
  soln.exitflag(tt) = exitflag;
  
  
  if exitflag ~= 1 
    output = output*0;
  end

  soln = unstack(output,loads.NumModes,tt,soln);

  
  % Calculate final values based on converged sk, sigma_p and eps_int
  %disp('Entering final')
  step = final(soln, loads, material, geom, step, tt, cohesive);

  
  % Write final step values to global values
  [cohesive, displacement, macro_var, potential, percentage] = ...
      finalize_timestep(step, cohesive, displacement, macro_var, ...
                        potential, percentage, loads, tt); 

  % Write output data for JSON
  
  outputdata.loads = loads;
  outputdata.material = material;
  outputdata.geom = geom;
  outputdata.converge = converge;
  outputdata.step = step;
              
  outputname = sprintf('%s/strain_%04i.json', inputname, round(loads.DriverStrain(tt)*10000));
  
  json = savejson('', outputdata, outputname);
  
  
end      % end loop through loading steps


