function result = thinning(matrix, oriensMatrix, method)
% VERSION 02/11/2005 (changing of lines 64, 66, 114 for better method)
% CREATED BY: M.B. Wieling and N. Petkov, Groningen University,
%             Department of Computer Science, Intelligent Systems
%
% THINNING: reduces the edges to a width of 1 pixel. This is done 
%           by looking at the two pixels next to the current pixel.
%           the neighbourpixels are determined by the orientation of 
%           the current point (this is stored in the exact same location
%           as in the matrix ORIENSMATRIX). A progressbar of the
%           calculations is also shown. 
%   THINNING(MATRIX, ORIENSMATRIX, METHOD) thins the edge
%      MATRIX - the matrix which should be thinned
%      ORIENSMATRIX - the matrix which holds for every pixel of MATRIX the
%                     orientation (in the same position)
%      METHOD - the method of thinning: METHOD == 1: simple method, just
%               take the value of the nearest pixels to compare with.
%               e.g. if the orientation = 20 degrees, the points S & N are chosen
%               to compare to, if the orientation = 25 degrees the points SW & NE
%               are chosen (see below, P = current point)
%                             NW  N  NE
%                             W   P   E
%                             SW  S  SE
%               METHOD == 2: the values to compare with are calculated using
%               interpolation based on the surrounding pixels (NW, N, NE, E, SE, S, SW, W) 
%
% corrected an error: <pi := <=pi
% made the method very fast, no double for-loop in linear thinning

% create the coordinate-system
h = size(matrix,1); % height of image
w = size(matrix,2); % width of image
mx = max(h,w);
[xcoords, ycoords] = meshgrid(1:mx);
xcoords = xcoords(1:h, 1:w);
ycoords = ycoords(1:h, 1:w);

% set every value between 0 and pi
oriensMatrix = mod(oriensMatrix, pi);

% add a border of zeros to 'matrix' and 'oriensMatrix' to ease calculations.
matrixB(h+2,w+2) = 0;
matrixB(2:h+1,2:w+1) = matrix(:,:);
oriensMatrixB(h+2,w+2) = 0;
oriensMatrixB(2:h+1,2:w+1) = oriensMatrix(:,:);

if (method == 1) % simple thinning, slow method with double for-loop, linear thinning is better see below
                 % this part can be made faster, but since it is not used
                 % (linear thinning is better it is not done now.
  result = 0;
  for I=2:h+1 % the rows
    for J=2:w+1 % the columns
      orien = oriensMatrixB(I,J);
      
      % calculate dx and dy - this is correct as can be seen
      % in a picture
      dx = (orien < (3/8)*pi) - (orien > (5/8)*pi); 
      dy = ((orien > (1/8)*pi) & (orien <= (1/2)*pi)) - ((orien > (1/2)*pi) & (orien < (7/8)*pi));

      % normally the same pixels would be checked if (dy and dx > 0) and (dy and dx < 0). because
      % different pixels should be checked with a gabor-orientation of 45 and 135 this difference should
      % be checked
      if (dy < 0) & (dx < 0)
       result(I,J) = ((matrixB(I,J) >= matrixB(I+dy, J+dx)) & (matrixB(I,J) > matrixB(I-dy, J-dx))) * matrixB(I,J);  
      else
       result(I,J) = ((matrixB(I,J) > matrixB(I-dy, J+dx)) & (matrixB(I,J) >= matrixB(I+dy, J-dx))) * matrixB(I,J);  
      end  
    end
  end
else % linear thinning
  h1 = waitbar(0,'Applying linear thinning, please wait ... (Step 5/7)'); % display a progressbar
  result = 0;
  
  hb = size(matrixB,1); % height of image
  wb = size(matrixB,2); % width of image
  orientation = oriensMatrixB;
 
  
  % east = shifting original matrix to the left
  east = matrixB(:, [2:wb-1, 1:1, wb:wb]);
  west = matrixB(:, [wb:wb, 1:wb-1]);
  % north = shifting down
  north = matrixB([hb:hb, 1:hb-1], :); 
  south = matrixB([2:hb-1, 1:1, hb:hb], :);
  
  northeast = matrixB([hb:hb, 1:hb-1], [2:wb-1, 1:1, wb:wb]);
  northwest = matrixB([hb:hb, 1:hb-1], [wb:wb, 1:wb-1]);
  southeast = matrixB([2:hb-1, 1:1, hb:hb], [2:wb-1, 1:1, wb:wb]);
  southwest = matrixB([2:hb-1, 1:1, hb:hb], [wb:wb, 1:wb-1]);
  
  pnt1 = zeros(size(matrixB));
  pnt2 = zeros(size(matrixB));
  
  tf = orientation <= pi;
  fraction = (orientation(tf) - (3/4)*pi) ./ ((1/4)*pi);
  pnt1(tf) = (1-fraction(tf)) .* northwest(tf) + (fraction(tf)) .* west(tf);
  pnt2(tf) = (1-fraction(tf)) .* southeast(tf) + (fraction(tf)) .* east(tf);
  
  tf = orientation <= (3/4)*pi; 
  fraction(tf) = (orientation(tf) - (1/2)*pi)./ ((1/4)*pi);
  pnt1(tf) = (1-fraction(tf)) .* north(tf) + (fraction(tf)) .* northwest(tf);
  pnt2(tf) = (1-fraction(tf)) .* south(tf) + (fraction(tf)) .* southeast(tf);
  
  tf = orientation <= (1/2)*pi;
  fraction(tf) = (orientation(tf) - (1/4)*pi)./ ((1/4)*pi);
  pnt1(tf) = (1-fraction(tf)) .* northeast(tf) + (fraction(tf)) .* north(tf);
  pnt2(tf) = (1-fraction(tf)) .* southwest(tf) + (fraction(tf)) .* south(tf);
  
  tf = orientation <= (1/4)*pi;
  fraction(tf) = (orientation(tf)) ./ ((1/4)*pi);
  pnt1(tf) = (1-fraction(tf)) .* east(tf) + (fraction(tf)) .* northeast(tf);
  pnt2(tf) = (1-fraction(tf)) .* west(tf) + (fraction(tf)) .* southwest(tf);
  
  result = ( (matrixB > pnt1) & (matrixB >= pnt2) ) .* matrixB;
        
  waitbar(1);
  close(h1);

end

% removing the borders
result = result(2:h+1, 2:w+1); 