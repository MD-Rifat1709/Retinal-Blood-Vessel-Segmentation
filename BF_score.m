function similarity = BF_score(BW,BW2) 
BW=im2bw(BW);
%BW2=imresize(BW2,[584 565]);
BW2=im2bw(BW2);
similarity = bfscore(BW2, BW);
%BW=mat2cell(BW,605,700);
%BW2=mat2cell(BW2,605,700,3);
%ssm = evaluateSemanticSegmentation(BW2,BW);
%J=sum(sum( BW.*BW2)) / sum(sum( BW|BW2));
%mask = false(size(BW2));
%mask(25:end-25,25:end-25) = true;
%BW = activecontour(BW2, mask, 300);
%BW = logical(BW);
%BW2 = logical(BW2);
%similarity = jaccard (BW2, BW)


end