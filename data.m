function selection = data(orienslist)
  selection = [];
  tmp = orienslist*360/(2*pi);
  for I=1:size(tmp,2);
	if (tmp(I) > 0)
      selection = [selection, I];
    end
  end
if (size(selection,2) == 0)
  selection = (1:size(orienslist,2));
end
end
