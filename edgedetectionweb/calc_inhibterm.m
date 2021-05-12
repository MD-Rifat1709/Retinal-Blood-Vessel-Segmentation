function result = calc_inhibterm(matrices, inhibMethod, supInhib, sigma, k1, k2)
% VERSION 2006/08/18 
% CREATED BY: M.B. Wieling and N. Petkov, Groningen University,
%             Department of Computer Science, Intelligent Systems
%
% CALC_INHIBTERM: calculates the inhibition term for each orientation
%   CALC_INHIBTERM(MATRICES, INHIBMETHOD, SUPINHIB, SIGMA, K1, K2) with the following parameters
%     MATRICES - the matrices (for each orientation) which should be
%     inhibited (the inhibitant)
%     INHIBMETHOD - the method of inhibition which is used (INHIBMETHOD == 2: isotropic inhibition, 
%                   INHIBMETHOD == 3: anisotropic inhibition)
%     SUPINHIB - defines the norm which should be used for the superposition which is 
%                only used with isotropic inhibition, there are three possibilities: 
%                L1 norm (SUPINHIB == 1), L2 norm (SUPINHIB == 2) or
%                L_INF norm (SUPINHIB == 3, this is maximum superposition)
%     SIGMA - standard deviation of Gaussian factor
%     K1 - defines the factor for the negative gaussian (second)
%     K2 - Odefines the factor for the positive gaussian (first)

% precondition: inhibMethod == 2 || inhibMethod == 3

% calculate the inhibitionterm (only if isotropic inhibition is used)
if (inhibMethod == 2) 
    % initialize the starting values
    if (supInhib == 3) 
        inhibitor = -inf; % starting value for maximum superposition (every value > -Inf)
    else
        inhibitor = 0;
        tmpinhibitor = 0;
    end
    
    for cnt1 = 1:size(matrices,3)
        if (supInhib == 1)
            inhibitor = inhibitor + abs(matrices(:,:,cnt1));
        elseif (supInhib == 2)
            % first calculate X1^2 + X2^2 + XN^2, the square-root is taken after the loop
            tmpinhibitor  = tmpinhibitor + matrices(:,:,cnt1).*matrices(:,:,cnt1);
        else
            inhibitor = max(abs(matrices(:,:,cnt1)), inhibitor);
        end
    end
    
    % if the L2 norm was chosen, the square-root should be taken
    % since L2 = SQRT(X1^2 + X2^2 + ... XN^2)
    if (supInhib == 2) 
        inhibitor = sqrt(tmpinhibitor);
    end
end

w = inhibkernel2d(sigma, k1, k2); % calculate the inhibitionkernel

% store the inhibitionterm for every orientation
for cnt1 = 1:size(matrices,3)
    if (inhibMethod == 3) % anisotropic inhibition
        result(:,:,cnt1) = convolution(matrices(:,:,cnt1), w);
    elseif (inhibMethod == 2) % isotropic inhibition
        result(:,:,cnt1) = convolution(inhibitor, w);
    end
end
