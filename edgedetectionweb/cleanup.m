function cleanup(privdir, maxpix, nrdays)
% VERSION 2005/11/01
% CREATED BY: M.B. Wieling and N. Petkov, Groningen University,
%             Department of Computer Science, Intelligent Systems
%
% CLEANUP: 1. Cleans up ml*edgedetection.png-files and corresponding .txt-files older than one hour.
%             Directories which are empty are also deleted (except the workingdir.)
%          2. Removes all images older than 2 weeks (except the original images)
%          3. Checks ftp directories for (illegal) non-image files and deletes them if present
%          4. Rescales the image files in the ftp directory to have a
%             maximum width or height of maxpix pixels. The original aspect
%             ratio is kept.
%          5. Converts tif/tiff images to png images (browsers can't display tiff images so well)
% CLEANUP(PRIVDIR, MAXPIX, NRDAYS):
%   PRIVDIR: The current workingdirectory
%   MAXPIX: Maximum nr. of pixels (width/height) of images in ftp directory
%   NRDAYS: Number of days images are kept on the server

NUMBER_OF_DAYS = nrdays; % number of days a file should be left on the server

tmp = dir;
dirlist = char(sortrows({tmp.name}));
for I=3:size(dirlist)
  dirname = deblank(dirlist(I,:));
  wscleanup('ml*edgedetectionpng.txt', 1, strcat(strcat(pwd,'\'),dirname));
  wscleanup('ml*edgedetection.png', 1, strcat(strcat(pwd,'\'),dirname));
  wscleanup('ml*edgedetection.mat', 1, strcat(strcat(pwd,'\'),dirname));
  wscleanup('ml*edgedetection.asc', 1, strcat(strcat(pwd,'\'),dirname));

  % remove empty directories except the working-directory one
  if (strcmp(privdir, dirname) ~= 1)
    cd(dirname);
    tmp2 = dir;
    dirsize = size(char(sortrows({tmp2.name})));

    if (dirsize == 2) % no files only '.' and '..'
      cd ..
      res = rmdir(dirname);
    else
      cd ..
    end
  end
end

cd ..;


%%% remove from ftp-directory all non-image files and files with size 0 and resize the images if
%%% they are too large. Replace spaces in a filename with an underscore (_).
%%% NEW: remove images if they are more than a week old
imgf = ['.jpg'; '.gif'; '.png'; '.bmp'; '.hdf'; '.pbm'; '.pcx'; '.pgm'; '.pnm'; '.ppm'; '.ras'; '.tif'; '.xwd'; '.JPG'; '.GIF'; '.PNG'; '.BMP'; '.HDF'; '.PBM'; '.PCX'; '.PGM'; '.PNM'; '.PPM'; '.RAS'; '.TIF'; '.XWD'];
imgfl = ['.tiff'; '.jpeg'; '.TIFF'; '.JPEG'];
cd INPUTIMAGES;


%%% delete images which are more than a week old and not the original image set (images which are more than 1 year old) 
imagelist = dir;
nowdatenum = now;
for I=3:size(imagelist)
  if  (nowdatenum - datenum(imagelist(I).date) > NUMBER_OF_DAYS) && ((nowdatenum - datenum(imagelist(I).date)) < 360) 
    wscleanup(imagelist(I).name,0);
  end
end

tmp = dir;
fileslist = char(sortrows({tmp.name}));
for I=3:size(fileslist)
  sizec = 0; % if sizec doesn't get larger than 0, the file is not an image file
  filename = deblank(fileslist(I,:));
  
  % replace spaces and &-symbol in filename with underscores
  filenameWithoutBlanks = regexprep(filename, ' ', '_'); 
  filenameWithoutBlanks = regexprep(filenameWithoutBlanks, '&', '_'); 
  if (strcmp(filename, filenameWithoutBlanks) ~= 1)
    movefile(filename, filenameWithoutBlanks); % rename the file
    filename = filenameWithoutBlanks;
  end
 
  for I = 1:size(imgf,1)
    sizec = max(sizec, size(regexp(filename, strcat(strcat('.+', imgf(I,:)), '$'))));
  end
  for I = 1: size(imgfl, 1)
    sizec = max(sizec, size(regexp(filename, strcat(strcat('.+', imgfl(I,:)), '$'))));
  end
  
  if (sizec <= 0)
    wscleanup(filename, 0); % remove illegal files
  else % resize to max 512 pixels for width and height (aspect ratio is kept)    
    try
      inimage = imread(filename);
      maxsize = max(size(inimage));
      factor = maxpix / maxsize;
      if (factor < 1) % only there should be a resize
        outimage = imresize(inimage, factor, 'bicubic');
        imwrite(outimage, filename);
      end
    catch
      wscleanup(filename, 0);
    end

  end    
end


%%% Convert all tif/ff images to a png image
tmp = dir;
fileslist = char(sortrows({tmp.name}));
for I=3:size(fileslist)
  filename = deblank(fileslist(I,:));
  % check if it is a tif/f file 
  if ( ( size(regexp( filename, strcat(strcat('.+', 'tif'), '$') ) ) > 0 ) | ( size(regexp( filename, strcat(strcat('.+', 'TIF'), '$') ) ) > 0 ) )
     img = imread(filename); % read the image
     filenameLength = size(filename,2);
     filenamePNG = strcat(filename(1:filenameLength-3), 'png'); % create a new filename by removing the tif extension and adding png
     imwrite(img, filenamePNG, 'png'); % save the image
     wscleanup(filename, 0); % remove the tiff image original image
  elseif ( ( size(regexp( filename, strcat(strcat('.+', 'tiff'), '$') ) )  > 0 ) | ( size(regexp( filename, strcat(strcat('.+', 'TIFF'), '$') ) )  > 0 ) )
     img = imread(filename); % read the image
     filenameLength = size(filename,2);
     filenamePNG = strcat(filename(1:filenameLength-4), 'png'); % create a new filename by removing the tiff extension and adding png
     imwrite(img, filenamePNG, 'png'); % save the image
     wscleanup(filename, 0); % remove the tiff image original image
  end
end

cd ..