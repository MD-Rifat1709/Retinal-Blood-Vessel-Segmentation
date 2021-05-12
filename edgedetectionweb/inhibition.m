function result = inhibition(matrices, inhibitor, sigma, alpha, k1, k2)
% VERSION 2006/08/18
% CREATED BY: M.B. Wieling and N. Petkov, Groningen University,
%             Department of Computer Science, Intelligent Systems
%
% INHIBITION: applies surround inhibition to the MATRIX according to the other
%             parameters.
%   INHIBITION(MATRICES, INHIBITOR, SIGMA, ALPHA, K1, K2) with the following parameters
%     MATRICES - the matrices to which surround inhibition should be
%     applied (the inhibitant)
%     INHIBITOR - the matrix which is the inhibitor
%     SIGMA - the standard deviation for the Gaussian function
%     ALPHA - defines the suppression of the inhibition
%     K1 - defines the factor for the negative gaussian (second)
%     K2 - defines the factor for the positive gaussian (first)

% if alpha is unequal to one calculate the resulting matrices after the
% inhibition
if (alpha == 0)
  b = matrices; % no inhibition
else 
  w = inhibkernel2d(sigma, k1, k2); % calculate the inhibitionkernel
  inhibitionterm = convolution(inhibitor, w); % calculate the inhibitionterm
  for cnt1 = 1:size(matrices,3); % the number of matrices is equal to the number of orientations
    b(:,:,cnt1) = matrices(:,:,cnt1) - alpha*inhibitionterm; % apply the surround inhibition according to the suppression factor ALPHA
  end
end
result = (b.*(b>0)); % set every negative value to 0 (H-function)