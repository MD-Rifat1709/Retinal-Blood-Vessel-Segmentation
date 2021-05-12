function C = kclustering(RGB,fv1)
I = rgb2gray(im2single(RGB));
nrows = size(RGB,1);
ncols = size(RGB,2);
[X,Y] = meshgrid(1:ncols,1:nrows);
featureSet = cat(3,I,fv1,X,Y);
L1 = imsegkmeans(featureSet,2,'NormalizeInput',true);
C = labeloverlay(RGB,L1);
end