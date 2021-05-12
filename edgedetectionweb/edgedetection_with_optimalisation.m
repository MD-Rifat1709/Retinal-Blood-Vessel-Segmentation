function retstr = edgedetection(instruct, outfile)
% VERSION 2005/04/02 (with optimalisation)
% CREATED BY: M.B. Wieling and N. Petkov, Groningen University,
%             Department of Computer Science, Intelligent Systems
%

%% PLEASE CHANGE THE FOLLOWING PARAMETERS TO THEIR DESIRED VALUES
FTPSERVER = 'ftp://matlabserver.cs.rug.nl'; % Adress of the ftp-server which should link to /INPUTIMAGES/
WEBDIR = 'C:\MATLAB6p5\work\edgedetectionweb'; % the directory which contains the webapplication
HDOPTIMALISATION = 0; % optimalisation by use of storing for each user a directory with temporary results
HARDDISKMAXMATSIZE = 20000000000; % 20 GB is the maximum amount used for mat-files
MAXMATSIZE = 350000000; % max. of 350 MB for a large image (e.g. 'lena.jpg' with 4 phases & 16 orientations and inhibition)
                        % only change if very large inputimages (> 512x512) are added
%% END

retstr = char('');

%%% Get unique identifier (to form file name)
mlid = getfield(instruct, 'mlid');

%%% Create a specific directory for every browser window open 
%%% in which the files are stored for that browserwindow

cd(strcat(WEBDIR, '\TMPIMAGES'));
if isfield(instruct, 'privdir')
  data.privdir = instruct.privdir;
  if (exist(data.privdir, 'dir') ~= 7)
    data.privdir = sprintf('user%s', mlid);
    mkdir(data.privdir);
  end
else
  data.privdir = sprintf('user%s', mlid);
  mkdir(data.privdir);
end

% cleans up directories (removes old/illegal files) and 
% checks and possibly rescales image to max(height,width) = 512 (aspect
% ratio is kept)
cleanup(data.privdir, 512); 

if (HDOPTIMALISATION == 1)
  cd(instruct.mldir);
  % load the old values (if available), these are used for optimalisation
  cd TMPIMAGES;
    cd(data.privdir);
      olddata = [];
      if (exist('data.mat') >=1 )
        tmp = load('data.mat');
        olddata = tmp.data;
        olddataExist = 1;
      else
        olddataExist = 0;
      end
     cd ..
  cd ..
else
  olddataExist = 0;
end


%% --------------------------------------------------------------
%%                  GATHER INPUT IMAGE LIST
%% --------------------------------------------------------------
% in case only the the image list is requested (to prepare for the initial
% page) immediately return it
if (isfield(instruct,'populatelist'))
  imagename = instruct.selImage;

  % parse imagename; if imagename comes in a cell type rather than matlab
  % array convert it (this is due to filename extraction from a list rather
  % than a single input field. 
  if (strcmp(class(imagename),'cell'))
    imagename = cell2mat(imagename);
  end;
  data.imagename = strcat('INPUTIMAGES/', imagename);
  data.simpleimagename = imagename;

  % read image from directory
  cd(strcat(WEBDIR, '\INPUTIMAGES'));
  tmp = dir;
  fileslist = char(sortrows({tmp.name}));
  data.imagelist = '';
  for I=3:size(fileslist)
    filename = deblank(fileslist(I,:));
  
    if (strcmp(deblank(imagename), filename) == 1)
      data.imagelist = sprintf('%s\n<option selected>%s</option>',data.imagelist,filename);
    else
      data.imagelist = sprintf('%s\n<option>%s</option>',data.imagelist,filename);
    end
  end
  cd ..

  data.imagename = imagename;
  cd(strcat(WEBDIR, '\WEB'));
  templatefile = which('edgedetection1.html'); 
  retstr = htmlrep(data,templatefile);
  return;
else




% initialise values
data.sigma = 0; % sigma
data.error = 0;
data.errorstring = '';
if (olddataExist == 1)
  data.selectedOriensSpec = olddata.selectedOriensSpec;
  data.fastMode = olddata.fastMode;
else
  data.fastMode = 0;
  data.selectedOriensSpec = 0;
end

%%%%%% <GABOR FILTERING PARAMETERS>
%%%% DATA.WAVELENGTH
% read all the values from the webpage
data.wavelength = str2double(instruct.wavelength);
if (isnan(data.wavelength)) | (data.wavelength < 2)
  data.errorstring =  sprintf('%s\n <li><i><b>Wavelength</b></i>: Please enter a real positive value (&ge; 2).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.wavelength);
  data.error = unique([data.error, 1]);
else
  data.error = setdiff(data.error, 1); 
  if (olddataExist == 1)
    if (olddata.wavelength ~= data.wavelength) % if the value is changed, recalculate
      data.fastMode = min(data.fastMode, 0);
    end
  end
end


%%%% DATA.ORIENTATION
data.orientationDisp = instruct.orientation;
data.orientation = str2num(data.orientationDisp) / (180/pi); % convert the numbers to radians
if (isempty(data.orientation))
  data.errorstring =  sprintf('%s\n  <li><i><b>Orientation(s)</b></i>: Please enter only numerical values between 0 and 360.<br>  Current incorrect value(s): <b>%s</b>.</li>', data.errorstring, data.orientationDisp);
  data.error = unique([data.error, 2]);
else
  data.error = setdiff(data.error, 2);  
  if (olddataExist == 1)
    orien1 = num2str(olddata.orientation);
    orien2 = num2str(data.orientation);
    if (strcmp(orien1, orien2) ~= 1) % if the value is changed, recalculate
      data.fastMode = min(data.fastMode, 0);
    end
  end
end

%%%% DATA.PHASEOFFSET
data.phaseoffsetDisp = instruct.phaseoffset; 
data.phaseoffset = str2num(data.phaseoffsetDisp) / (180/pi); % convert the numbers to radians
if (isempty(data.phaseoffset));
  data.errorstring =  sprintf('%s\n  <li><i><b>Phaseoffset(s)</b></i>: Please enter only numerical values.<br>  Current incorrect value(s): <b>%s</b>.</li>', data.errorstring, data.phaseoffsetDisp);
  data.error = unique([data.error, 3]);
else
  data.error = setdiff(data.error, 3); 
  if (olddataExist == 1)
    phase1 = num2str(olddata.phaseoffset);
    phase2 = num2str(data.phaseoffset);
    if (strcmp(phase1, phase2) ~= 1) % if the value is changed, recalculate
      data.fastMode = min(data.fastMode, 0);
    end
  end
end

%%%% DATA.ASPECTRATIO
data.aspectratio = str2double(instruct.aspectratio); 
if (isnan(data.aspectratio)) | (data.aspectratio <= 0)
  data.errorstring =  sprintf('%s\n <li><i><b>Aspectratio</b></i>: Please enter a numerical positive value (larger than 0).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.aspectratio);
  data.error = unique([data.error, 4]);
else
  data.error = setdiff(data.error, 4);
  if (olddataExist == 1)
    if (olddata.aspectratio ~= data.aspectratio) % if the value is changed, recalculate
      data.fastMode = min(data.fastMode, 0);
    end
  end
end

%%%% DATA.BANDWIDTH
data.bandwidth = str2double(instruct.bandwidth); 
if (isnan(data.bandwidth)) | (data.bandwidth <= 0)
  data.errorstring =  sprintf('%s\n <li><i><b>Bandwidth</b></i>: Please enter a numerical positive value (larger than 0).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.bandwidth);
  data.error = unique([data.error, 5]);
else
  data.error = setdiff(data.error, 5); 
  if (olddataExist == 1)
    if (olddata.bandwidth ~= data.bandwidth) % if the value is changed, recalculate
      data.fastMode = min(data.fastMode, 0);
    end
  end
end

%%%% DATA.NRORIENS
data.nroriens = str2double(instruct.nroriens); 
if (size(data.orientation, 2) <= 1)
  if (isnan(data.nroriens)) | (data.nroriens <= 0)
    data.errorstring =  sprintf('%s\n <li><i><b>Number of orientations</b></i>: Please enter a numerical positive value (larger than 0).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.nroriens);
    data.error = unique([data.error, 6]);
  else
    data.error = setdiff(data.error, 6); 
    if (olddataExist == 1)
      if (olddata.nroriens ~= data.nroriens) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 0);
      end
    end
  end
end
%%%%%% </GABOR FILTERING PARAMETERS>


%%%%%% <HALF-WAVE RECTIFICATION>
if (isfield(instruct, 'hwstate') == 1)
  data.hwCheck = 'checked';
  data.hwstate = 1;
else 
  data.hwCheck = 'unchecked';
  data.hwstate = 0;
end
if (olddataExist == 1)
  if (olddata.hwstate ~= data.hwstate) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 1);
  end
end

data.halfwave = str2double(instruct.hwperc);
if (data.hwstate == 1) && (strcmp('Gabor function', instruct.selRight) ~= 1) % only then errorchecking
  if (data.halfwave < 0) | (data.halfwave > 100) | (isnan(data.halfwave))
    data.errorstring =  sprintf('%s\n <li><i><b>Half-wave rectification</b></i>: Please enter a valid percentage (only numerical values between 0 and 100).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.hwperc);
    data.error = unique([data.error, 8]);
  else
    data.error = setdiff(data.error, 8);
    if (olddataExist == 1)
      if (olddata.halfwave ~= data.halfwave) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 1);
      end
    end
  end
end
%%%%%% </HALF-WAVE RECTIFICATION>


%%%%%% <SUPERPOSITION OF PHASES>
data.supPhasesSel1 = ''; % make sure the right option is selected in the webpage
data.supPhasesSel2 = '';
data.supPhasesSel3 = '';
data.supPhasesSel4 = '';
if (strcmp('L1 norm', instruct.supPhases) == 1)
  data.supPhases = 1;
  data.supPhasesSel1 = 'selected'; % make sure the right option is selected in the webpage
elseif (strcmp('L2 norm', instruct.supPhases) == 1)
  data.supPhases = 2;
  data.supPhasesSel2 = 'selected';
elseif (strcmp('L-infinity norm', instruct.supPhases) == 1)
  data.supPhases = 3;
  data.supPhasesSel3 = 'selected';
else
  data.supPhases = 4;
  data.supPhasesSel4 = 'selected';
end
if (olddataExist == 1)
  if (olddata.supPhases ~= data.supPhases) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 2);
  end
end
%%%%%% </SUPERPOSITION OF PHASES>

%%%%%% <SURROUND INHIBITION>
%%%% SURROUND INHIBITION METHOD
data.inhibMethodSel1 = '';
data.inhibMethodSel2 = '';
data.inhibMethodSel3 = '';
if (strcmp('No surround inhibition', instruct.inhibMethod) == 1)
  data.inhibMethod = 1;
  data.inhibMethodSel1 = 'selected';
elseif (strcmp('Isotropic surround inhibition', instruct.inhibMethod) == 1)
  data.inhibMethod = 2;
  data.inhibMethodSel2 = 'selected';
else
  data.inhibMethod = 3; % anisotropic surround inhibition
  data.inhibMethodSel3 = 'selected';
end
if (olddataExist == 1)
  if (olddata.inhibMethod ~= data.inhibMethod) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 3);
  end
end

%%%% SUPERPOSITION METHOD FOR ISOTROPIC SURROUND INHIBITION
data.supIsoinhibSel1 = '';
data.supIsoinhibSel2 = '';
data.supIsoinhibSel3 = '';
if (strcmp('L1 norm', instruct.supIsoinhib) == 1)   
  data.supIsoinhib = 1;
  data.supIsoinhibSel2 = 'selected';
elseif (strcmp('L2 norm', instruct.supIsoinhib) == 1)   
  data.supIsoinhib = 2;
  data.supIsoinhibSel3 = 'selected';
else
  data.supIsoinhib = 3;
  data.supIsoinhibSel1 = 'selected';
end
if (olddataExist == 1) && (data.inhibMethod ~= 1)
  if (olddata.supIsoinhib ~= data.supIsoinhib) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 3);
  end
end

%%%% ALPHA
data.alpha = str2double(instruct.alpha); 
if (data.inhibMethod ~=1) && (strcmp('Filter output', instruct.selRight) == 1)% with no surround inhibition, no error checking
  if (isnan(data.alpha))
    data.errorstring =  sprintf('%s\n <li><i><b>Alpha</b></i>: Please enter a numerical value.<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.alpha);
    data.error = unique([data.error, 9]);
  else
    data.error = setdiff(data.error, 9); 
    if (olddataExist == 1)
      if (olddata.alpha ~= data.alpha) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 3);
      end
    end
  end
end

%%%% K1
data.k1 = str2double(instruct.k1); 
data.k2 = str2double(instruct.k2); 
if (data.inhibMethod ~=1) && (strcmp('Gabor function', instruct.selRight) ~= 1)  % with no surround inhibition, no error checking
  if (isnan(data.k1)) | (data.k1 == 0)
    data.errorstring =  sprintf('%s\n <li><i><b>K1</b></i>: Please enter a numerical (non zero) value, which is unequal to K2 (%s).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.k2, instruct.k1);
    data.error = unique([data.error, 10]);
  elseif (data.k1 == data.k2) % k1 should be not equal to k1
    data.errorstring =  sprintf('%s\n <li><i><b>K1</b></i>: Please enter a numerical (non zero) value, which is unequal to K2 (%s).<br>  Current incorrect value: <b>%s (equal to K2)</b>.</li>', data.errorstring, instruct.k2, instruct.k1);
    data.error = unique([data.error, 12]);
  else
    data.error = setdiff(data.error, 10); 
    data.error = setdiff(data.error, 12);
    if (olddataExist == 1)
      if (olddata.k1 ~= data.k1) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 3);
      end
    end
  end
end

%%%% K2
if (data.inhibMethod ~=1) && (strcmp('Gabor function', instruct.selRight) ~= 1) % with no surround inhibition, no error checking
  if (isnan(data.k2)) | (data.k2 == 0)
    data.errorstring =  sprintf('%s\n <li><i><b>K2</b></i>: Please enter a numerical (non zero) value, which is unequal to K1 (%s).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.k1, instruct.k2);
    data.error = unique([data.error, 11]);
  elseif (data.k1 == data.k2) % k1 should be not equal to k1
    data.errorstring =  sprintf('%s\n <li><i><b>K2</b></i>: Please enter a numerical (non zero) value, which is unequal to K1 (%s).<br>  Current incorrect value: <b>%s (equal to K1)</b>.</li>', data.errorstring, instruct.k1, instruct.k2);
    data.error = unique([data.error, 12]);
  else
    data.error = setdiff(data.error, 11); 
    data.error = setdiff(data.error, 12);
    if (olddataExist == 1)
      if (olddata.k2 ~= data.k2) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 3);
      end
    end
  end
end
%%%%%% </SURROUND INHIBITION>


%%%%%% <VIEWING ORIENTATIONS>
% create list of orientations which should be displayed
nrtheta = size(data.orientation,2);
iterations = data.nroriens;
theta = data.orientation;
nors = data.nroriens;

if (nrtheta == 1)
  theta(1) = mod(theta(1), 2*pi);
  index = 2; 
  % add orientations to current variable theta
  while (iterations > 1)
    theta(index) = mod(theta(index-1) + (2*pi)/nors, 2*pi);
    iterations = iterations - 1;
    index = index + 1;
  end

else
  theta = mod(theta, 2*pi);
end
theta = unique(theta); % sort the orientations and remove duplicates
data.orienslist = theta;

% define which orientations are selected in the webpage
if (isfield(instruct, 'selectedOriens') == 1)
  if (strcmp(instruct.selectedOriens, '1'))
    data.selectedOriensSpec = 0;
    data.selection = (1:size(data.orienslist,2)); % all orientations
  else
    data.selectedOriensSpec = 1;
    if (isfield(instruct, 'selection') == 1)
      data.selection = [];
      tmp = data.orienslist*360/(2*pi);
      for I=1:size(tmp,2);
	if (strmatch(num2str(tmp(I)), instruct.selection) > 0)
          data.selection = [data.selection, I];
        end
      end
    else
      data.selection = {};
    end
  end
else
  data.selection = (1:size(data.orienslist,2));
  data.selectedOriensSpec = 0;
end

% if only illegal values are selected, set the default to all selected
if (size(data.selection,2) == 0)
  data.selection = (1:size(data.orienslist,2));
  data.selectedOriensSpec = 0;
end

% if number of orientations or the separate orientations are changed, the 
% selected orientations are set to 'all'
if (olddataExist == 1)
  orien1 = num2str(data.orientation);
  orien2 = num2str(olddata.orientation);
  if ((data.nroriens ~= olddata.nroriens) && (size(data.orientation,2) == 1)) || (strcmp(orien1, orien2) ~= 1)  
    data.selection = (1:size(data.orienslist,2));
    data.selectedOriensSpec = 0;
  end
end


% set the efficiency (fastMode) modus if another selection is made
if (olddataExist == 1)
  if (isfield(olddata, 'selection') == 1) && (isfield(data, 'selection') == 1)
    sel1 = num2str(data.selection);
    sel2 = num2str(olddata.selection);
    if (strcmp(sel1, sel2) ~= 1) % if the value is changed, recalculate   
      data.fastMode = min(data.fastMode, 4);
    end
  end
end
%%%%%% </VIEWING ORIENTATIONS>


%%%%%% <THRESHOLDING>
if (isfield(instruct, 'thinning') == 1)
  data.thinning = 1;
  data.thinCheck = 'checked';
else
  data.thinning = 0;
  data.thinCheck = 'unchecked';
end
if (olddataExist == 1)
  if (olddata.thinning ~= data.thinning) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 5);
  end
end

if (isfield(instruct, 'hyst') == 1)
  data.hyst = 1;
  data.hystCheck = 'checked';
else
  data.hyst = 0;
  data.hystCheck = 'unchecked';
end
if (olddataExist == 1)
  if (olddata.hyst ~= data.hyst) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 6);
  end
end

data.tlow = str2double(instruct.tlow); % only used when hyst==1
data.thigh = str2double(instruct.thigh); % only used when hyst==1
if (data.hyst == 1) && (strcmp('Filter output', instruct.selRight) == 1)% only then error-checking
  if (isnan(data.tlow)) | (data.tlow <= 0) | (data.tlow >= 1)
    data.errorstring =  sprintf('%s\n <li><i><b>T-low</b></i>: Please enter a value larger than 0 and smaller than 1, which is smaller than T-high (%s).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.thigh, instruct.tlow);
    data.error = unique([data.error, 13]);
  elseif (data.tlow >= data.thigh)
    data.errorstring =  sprintf('%s\n <li><i><b>T-low</b></i>: Please enter a value larger than 0 and smaller than 1, which is smaller than T-high (%s).<br>  Current incorrect value: <b>%s (>= T-high)</b>.</li>', data.errorstring, instruct.thigh, instruct.tlow);
    data.error = unique([data.error, 15]);
    data.error = setdiff(data.error, 13);
  else
    data.changeRight = 1;
    data.error = setdiff(data.error, 13); 
    data.error = setdiff(data.error, 15);
    if (olddataExist == 1)
      if (olddata.tlow ~= data.tlow) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 6);
      end
    end
  end

  if (isnan(data.thigh)) | (data.thigh <= 0) | (data.thigh >= 1)
    data.errorstring =  sprintf('%s\n <li><i><b>T-high</b></i>: Please enter a value larger than 0 and smaller than 1, which is larger than T-low (%s).<br>  Current incorrect value: <b>%s</b>.</li>', data.errorstring, instruct.tlow, instruct.thigh);
    data.error = unique([data.error, 14]);
  elseif (data.tlow >= data.thigh)
    data.errorstring =  sprintf('%s\n <li><i><b>T-high</b></i>: Please enter a value larger than 0 and smaller than 1, which is larger than T-low (%s).<br>  Current incorrect value: <b>%s (<= T-low)</b>.</li>', data.errorstring, instruct.tlow, instruct.thigh);
    data.error = unique([data.error, 15]);
    data.error = setdiff(data.error, 14);
  else
    data.changeRight = 1;
    data.error = setdiff(data.error, 14); 
    data.error = setdiff(data.error, 15);
    if (olddataExist == 1)
      if (olddata.thigh ~= data.thigh) % if the value is changed, recalculate
        data.fastMode = min(data.fastMode, 6);
      end
    end
  end
end
%%%%%% </THRESHOLDING>
 

%%%%%% <SELECT DISPLAY>
data.selRightSel1 = '';
data.selRightSel2 = '';
data.selRightSel3 = '';
data.selRightSel4 = '';
if (strcmp('Filter output', instruct.selRight) == 1)   
  data.selRight=1;
  data.selRightSel1 = 'selected';
elseif (strcmp('Gabor function', instruct.selRight) == 1)   
  data.selRight=2;
  data.selRightSel2 = 'selected';
elseif(strcmp('Gabor function (power spectrum)', instruct.selRight) == 1)
  data.selRight=4;
  data.selRightSel4 = 'selected';
else
  data.selRight=3;
  data.selRightSel3 = 'selected';
end
%%%%%% </SELECT DISPLAY>

%%%%%% <INVERT CHECKBUTTON>
if (isfield(instruct, 'invertOutput') == 1)
  data.invertOutput = 1;
  data.invertCheck = 'checked';
else
  data.invertOutput = 0;
  data.invertCheck = 'unchecked';
end
if (olddataExist == 1)
  if (olddata.invertOutput ~= data.invertOutput) % if the value is changed, recalculate
    data.fastMode = min(data.fastMode, 7);
  end
end
%%%%%% </INVERT CHECKBUTTON>


%%% load new image
data.imagename=strcat('INPUTIMAGES/', instruct.selImage); % init. imagename
if (olddataExist == 1)
  if (strcmp(olddata.imagename, data.imagename) ~= 1) % if the value is changed, recalculate
   data.fastMode = min(data.fastMode, 0);
  end
end

%%% create list of available images
cd INPUTIMAGES;
tmp = dir;
fileslist = char(sortrows({tmp.name}));
data.dispstring = '';
for I=3:size(fileslist)
  filename = deblank(fileslist(I,:));
  
  if (strcmp(deblank(instruct.selImage), filename) == 1)
    data.dispstring = sprintf('%s\n<option selected>%s</option>', data.dispstring, filename);
  else
    data.dispstring = sprintf('%s\n<option>%s</option>', data.dispstring, filename);
  end
end
cd ..

%%% scale image to a nice size for viewing in the web-application
tmp = imread(data.imagename);

data.dispwidth = size(tmp,2);
data.dispheight = size(tmp,1);

if (HDOPTIMALISATION == 1)
  if (data.dispwidth > 512) || (data.dispheight > 512)
    storeMatFile = 0; % if the imagefile is too large, it takes more time to save than having less calculations saves time
  end
end

while (data.dispwidth < 300)
  data.dispwidth = data.dispwidth*1.1;
  data.dispheight = data.dispheight*1.1;
end
while (data.dispwidth > 400)
  data.dispwidth = data.dispwidth*0.9;
  data.dispheight = data.dispheight*0.9;
end
while (data.dispheight > 400)
  data.dispwidth = data.dispwidth*0.9;
  data.dispheight = data.dispheight*0.9;
end

%% set the ftpserver
data.host = FTPSERVER;

%%% depending on the efficiency-mode (fastMode) copy values from the
%%% previous result
if (olddataExist == 1)
  if (data.fastMode >= 1)
    data.img = olddata.img;
    data.orienslist = olddata.orienslist;
    data.sigmaC = olddata.sigmaC;
    data.convResult = olddata.convResult;
  end
  if (data.fastMode >= 2) %also >= 1, so the previous statements are also executed
    data.hwResult = olddata.hwResult;
  end
  if (data.fastMode >= 3)
    data.superposResult = olddata.superposResult;
  end
  if (data.fastMode >= 4)
    data.inhibResult = olddata.inhibResult;
  end
  if (data.fastMode >= 5)
    data.viewResult = olddata.viewResult;
    data.oriensMatrix = olddata.oriensMatrix;
  end 
  if (data.fastMode >= 6)
    data.thinResult = olddata.thinResult;
  end  
  if (data.fastMode >= 7)
    data.hystResult = olddata.hystResult;
  end 
  if (data.fastMode >= 8)
    data.result = olddata.result;
  end 
end


%%% Calculation of the result
if (size(data.error,2) == 1) % no errors, so everything can be calculated
  % all values are legal - display the filter/inhibitionkernel/superposition image
  if (data.selRight == 2) % select the output image to be changed
    data.filterresult = filterkernel_onscreen(data.imagename, data.wavelength,0,data.orientation,data.phaseoffset,data.aspectratio,data.bandwidth, data.invertOutput);
  elseif (data.selRight == 4)
    data.filterpowerresult = filterkernelpower_onscreen(data.imagename, data.wavelength,0,data.orientation,data.phaseoffset,data.aspectratio,data.bandwidth, data.invertOutput);
  elseif (data.selRight == 3)
    % calculate the sigma
    slratio = (1/pi) * sqrt( (log(2)/2) ) * ( ((2^data.bandwidth)+1) / ((2^data.bandwidth)-1) );
    data.sigmaC = slratio * data.wavelength;
    % calculate the inhibitionkernel and display it on screen
    data.inhibresult = inhibkernel_onscreen(data.imagename, data.sigmaC, data.k1, data.k2, data.halfwave, data.invertOutput);
  else % output image
    if (data.fastMode < 1)
      % initialization and calculation of convolutions
      % note that the list of orientations is sorted and contains no
      % duplicate values
      [data.img, data.orienslist, data.sigmaC] = readandinit(data.imagename, data.orientation, data.nroriens, data.sigma, data.wavelength, data.bandwidth); % initialisation
      data.convResult = gaborfilter(data.img, data.wavelength, data.sigma, data.orienslist, data.phaseoffset, data.aspectratio, data.bandwidth);
    end
    if (data.fastMode < 2)
      % calculation of half-wave rectification
      if (data.hwstate == 1)
        data.hwResult = calc_halfwaverect(data.convResult, data.orienslist, data.phaseoffset, data.halfwave);
      else
	    data.hwResult = data.convResult;
      end
    end
    if (data.fastMode < 3)
      % calculation of the superposition of phases
      data.superposResult = calc_phasessuppos(data.hwResult, data.orienslist, data.phaseoffset, data.supPhases);
    end
    if (data.fastMode < 4)
      % calculation of the surround inhibition
      data.inhibResult = calc_inhibition(data.superposResult, data.inhibMethod, data.supIsoinhib, data.sigmaC, data.alpha, data.k1, data.k2);
    end
    if (data.fastMode < 5)
      % calculation of the orientationmatrix (maximum orientation response
      % per point) and merges the images per orientation to one image
      [data.viewResult, data.oriensMatrix] = calc_viewimage(data.inhibResult, data.selection, data.orienslist);
    end
    if (data.fastMode < 6)
      % calculation of the thinned image
      data.thinResult = calc_thinning(data.viewResult, data.oriensMatrix, data.thinning);
    end
    if (data.fastMode < 7)
      % calculation of the hysteresis thresholded image
      data.hystResult = calc_hysteresis(data.thinResult, data.hyst, data.tlow, data.thigh);
    end
    if (data.fastMode < 8)
       if (data.invertOutput == 1) % the image should be inverted, precondition values between [0..1]
         data.result = 1 - data.hystResult;
       else
         data.result = data.hystResult;
       end
    end
    if (olddataExist == 1)
      data.fastMode = 8;
    end
  end

  %%% create the string (html-code) of orientations to display in the GUI
  if (data.selRight == 1)
    if (isfield(data, 'orienslist') == 1) 
      tmp = data.orienslist*360/(2*pi);
      if (size(data.selection,2) ~= 0)
        tmpOriens = tmp(data.selection);
        str = num2str(tmpOriens(1),4);
        for I = 2:size(tmpOriens,2)
          str = [str ', ' num2str(tmpOriens(I),4)];
        end
        data.disp = str;
        data.dispOriens = strcat('<i>Displayed orientation(s)</i>:&nbsp;', str);
        data.dispOriens = strcat('<tr> <td colspan="12">', data.dispOriens);
        data.dispOriens = strcat(data.dispOriens, '</td></tr>');
      else
        data.dispOriens = '<tr> <td colspan="12"><i>Displayed orientation(s)</i>:</td></tr>';
      end

      % display the selection of all the orientations
      data.dispOriensstring = '';
      tmp = transpose(data.orienslist(:)*360/(2*pi));
      data.dispOriensstring = sprintf('%s\n%s', data.dispOriensstring, data.dispOriens);
      data.dispOriensstring = sprintf('%s\n<tr>', data.dispOriensstring);
      if (data.selectedOriensSpec == 1)
        data.dispOriensstring = sprintf('%s\n<td colspan="4"><input type="radio" checked name="selectedOriens" value="0">Display specific orientation(s)</td>', data.dispOriensstring);
        data.dispOriensstring = sprintf('%s\n<td colspan="5"><input type="radio" name="selectedOriens" value="1">Display all orientation(s)</td>', data.dispOriensstring);
        data.dispOriensstring = sprintf('%s\n<td colspan="3">&nbsp;</td><td colspan="1"><input type="submit" name="Submit" value="Update view!"></td>', data.dispOriensstring); 
      else
        data.dispOriensstring = sprintf('%s\n<td colspan="4"><input type="radio" name="selectedOriens" value="0">Display specific orientation(s)</td>', data.dispOriensstring);
        data.dispOriensstring = sprintf('%s\n<td colspan="5"><input type="radio" checked name="selectedOriens" value="1">Display all orientation(s)</td>', data.dispOriensstring);
        data.dispOriensstring = sprintf('%s\n<td colspan="3">&nbsp;</td><td colspan="1"><input type="submit" name="Submit" value="Update view!"></td>', data.dispOriensstring); 
      end
      data.dispOriensstring = sprintf('%s\n</tr>', data.dispOriensstring);
      data.dispOriensstring = sprintf('%s\n<tr><td colspan="4">', data.dispOriensstring);
      data.dispOriensstring = sprintf('%s\n<select height="28" name="selection" multiple size="%i">', data.dispOriensstring, max(size(data.orienslist,2)/2,4));
      for I=1:size(tmp,2)
        found = 0;
        for J=1:size(tmpOriens,2)
          if (tmp(I) == tmpOriens(J))
            data.dispOriensstring = sprintf('%s\n<option selected>%s</option>', data.dispOriensstring, num2str(tmp(I),4));
            found = 1; 
	  end
        end
        if (found ~= 1)
          data.dispOriensstring = sprintf('%s\n<option>%s</option>', data.dispOriensstring, num2str(tmp(I),4));
        end
      end 
      data.dispOriensstring = sprintf('%s\n</select>', data.dispOriensstring);
      data.dispOriensstring = sprintf('%s\n</td></tr>', data.dispOriensstring);
      data.dispOriensstring = sprintf('%s\n<tr><td colspan="6"><small>Note: please make sure the correct button is selected.</small></td></tr><tr>', data.dispOriensstring);
      data.dispOriensstring = sprintf('%s\n<td colspan="14"> <hr> </td> </tr>', data.dispOriensstring);
    else
      data.dispOriens = '';
      data.dispOriensstring = '<tr><td></td></tr>';
    end
  else
    data.dispOriens = '';
    data.dispOriensstring = '<tr><td></td></tr>';
  end


  %%% save the result as an image
  data.imgfilename = sprintf('%sedgedetection.png', mlid);
  data.directory = sprintf('%s\\TMPIMAGES\\%s\\', pwd, data.privdir);
  if (data.selRight == 1)
    cd TMPIMAGES;
      cd(data.privdir);
        if (HDOPTIMALISATION == 1)
          if (storeMatFile == 1) % there is enough space
  	        save 'data.mat' data; % only save as the edgedetection is calculated and image is not larger than 512x512
	      end
        end
        imwrite(data.result, data.imgfilename);
      cd ..;
    cd ..;
    data.savefilename = paramswrite(data.directory, data.imgfilename, data, instruct);
  elseif (data.selRight == 2)
    cd TMPIMAGES;
      cd(data.privdir);
        imwrite(data.filterresult, data.imgfilename);
      cd ..;
    cd ..;
    data.savefilename = paramswrite(data.directory, data.imgfilename, data, instruct);
  elseif (data.selRight == 4)
    cd TMPIMAGES;
      cd(data.privdir);
        imwrite(data.filterpowerresult, data.imgfilename);
      cd ..;
    cd ..;
    data.savefilename = paramswrite(data.directory, data.imgfilename, data, instruct);
  else
    cd TMPIMAGES;
      cd(data.privdir);
        imwrite(data.inhibresult, data.imgfilename);
      cd ..;
    cd ..
    data.savefilename = paramswrite(data.directory, data.imgfilename, data, instruct);
  end
end  % this ends the part of which is executed when no errors are present


%%% display the resulting webpage
if not(size(data.error,2) == 1)
  cd WEB;
  templatefile = which('edgedetection_error.html'); % display error page
else
  cd WEB;
  templatefile = which('edgedetection2.html'); 
end
cd ..;
if (nargin == 1)
   retstr = htmlrep(data, templatefile);
elseif (nargin == 2)
   retstr = htmlrep(data, templatefile, outfile);
end

clear data; % clear all variables in data
end

% Save the values of all parameters belonging to the saved image to a file.
% A specific file is created when the filter- or inhibitionkernel is saved.

function savefilename = paramswrite(pathname, filename, data, instruct)
% define the name of the savefile by removing the '.' and adding '.txt'
length = size(filename,2);
savefilename = strcat(filename(:,1:length-4), strcat(filename(:,length-2:length), '.txt'));

fid = fopen([pathname savefilename], 'w+'); % open the file

% print the values
fprintf(fid, '*****************************************************************\n');
fprintf(fid, '*  This file was created on %s                *\n', datestr(now));
fprintf(fid, '*  by the Gabor filter contour detection demo (v. 1.20050402):  *\n');
fprintf(fid, '*  http://matlabserver.cs.rug.nl                                *\n');
fprintf(fid, '*                                                               *\n');
fprintf(fid, '*  The program is designed by:                                  *\n');
fprintf(fid, '*  M.B. Wieling and N.Petkov, University of Groningen           *\n');
fprintf(fid, '*  Department of Computer Science, Intelligent Systems          *\n');
fprintf(fid, '*  Comments: - m.b.wieling@student.rug.nl                       *\n');
fprintf(fid, '*            - petkov@cs.rug.nl                                 *\n');
fprintf(fid, '*****************************************************************\n\n');

if (data.selRight == 1) % output image
  if (data.invertOutput == 1)
    fprintf(fid, 'The generated image (inverted): %s\n', filename);
  else
    fprintf(fid, 'The generated image: %s\n', filename); 
  end
  fprintf(fid, 'is based on the following parameters:\n');

  fprintf(fid, '\n*** Original image ***\n');
  fprintf(fid, 'Original image: %s\n', instruct.selImage);

  fprintf(fid, '\n*** Gabor filtering parameters ***\n');
  fprintf(fid, 'Wavelength: %g\n', data.wavelength);
  % format the list of orientations
  str = num2str(data.orientation(1)*360/(2*pi),4);
  for I = 2:size(data.orientation,2)
    str = [str ', ' num2str(data.orientation(I)*360/(2*pi),4)];
  end
  fprintf(fid, 'Orientation(s): %s\n', str);
  % format the list of phase offsets
  str = num2str(data.phaseoffset(1)*360/(2*pi),4);
  for I = 2:size(data.phaseoffset,2)
    str = [str ', ' num2str(data.phaseoffset(I)*360/(2*pi),4)];
  end
  fprintf(fid, 'Phase offset(s): %s\n', str); 
  fprintf(fid, 'Aspect ratio: %g\n', data.aspectratio);
  fprintf(fid, 'Bandwidth: %g\n', data.bandwidth);
  if (size(data.orientation,2) == 1) % nroriens is not ignored
    fprintf(fid, 'Number of orientations: %g\n', data.nroriens);
  end

  fprintf(fid, '\n*** Half-wave rectification parameters ***\n');
  if (data.hwstate == 1)
    fprintf(fid, 'Half-wave rectification enabled\n');
    fprintf(fid, 'Half-wave rectification percentage: %g\n', data.halfwave); 
  else
    fprintf(fid, 'Half-wave rectification disabled\n'); 
  end

  fprintf(fid, '\n*** Superposition of phases parameters ***\n');
  fprintf(fid, 'Superposition method: ');
  if (data.supPhases == 1)
    fprintf(fid, 'L1 norm\n');
  elseif (data.supPhases == 2)
    fprintf(fid, 'L2 norm\n');
  elseif (data.supPhases == 3)
    fprintf(fid, 'L-infinity norm\n');
  else
    fprintf(fid, 'None\n');
  end

  fprintf(fid, '\n*** Surround inhibition parameters ***\n');
  if (data.inhibMethod == 1)
    fprintf(fid, 'Surround inhibition disabled\n');
  elseif (data.inhibMethod == 2)
    fprintf(fid, 'Surround inhibition method: Isotropic\n');
    fprintf(fid, 'Alpha: %g\n', data.alpha);
    fprintf(fid, 'K1: %g\n', data.k1);
    fprintf(fid, 'K2: %g\n', data.k2);
    fprintf(fid, 'Superposition method for the inhibitionterm: ');
    if (data.supIsoinhib == 1)
      fprintf(fid, 'L1 norm\n');
    elseif (data.supIsoinhib == 2)
      fprintf(fid, 'L2 norm\n');
    else
      fprintf(fid, 'L-infinity norm\n');
    end
  else
    fprintf(fid, 'Surround inhibition method: Anisotropic\n');
    fprintf(fid, 'Alpha: %g\n', data.alpha);
    fprintf(fid, 'K1: %g\n', data.k1);
    fprintf(fid, 'K2: %g\n', data.k2);
  end

  fprintf(fid, '\n*** Thresholding parameters ***\n');
  if (data.thinning == 1)
    fprintf(fid, 'Thinning enabled\n');
  else
    fprintf(fid, 'Thinning disabled\n');
  end
  if (data.hyst == 1)
    fprintf(fid, 'Hysteresis thresholding enabled\n');
    fprintf(fid, 'T-low: %g\n', data.tlow);
    fprintf(fid, 'T-high: %g\n', data.thigh);
  else
    fprintf(fid, 'Hysteresis thresholding disabled\n');
  end

  fprintf(fid, '\n*** Displayed orientations ***\n');
  % create the displaystring
  if (data.selectedOriensSpec == 0)
    fprintf(fid, 'Orientations to display: All (%s)\n',data.disp);
  else
    fprintf(fid, 'Orientations to display: Specific (%s)\n',data.disp);
  end
elseif (data.selRight == 2) % Gabor function or filterkernel
  if (data.invertOutput == 1)
    fprintf(fid, 'The generated Gabor function (inverted): %s\n', filename);
  else  
    fprintf(fid, 'The generated Gabor function: %s\n', filename);
  end
  fprintf(fid, 'is based on the following parameters:\n\n');
  fprintf(fid, '- Original image (used for scaling purposes): %s\n', instruct.selImage);
  fprintf(fid, '- Wavelength: %g\n', data.wavelength);
  fprintf(fid, '- Orientation: %s\n', num2str(data.orientation(1)*360/(2*pi),4));
  fprintf(fid, '- Phase offset: %s\n', num2str(data.phaseoffset(1)*360/(2*pi),4)); 
  fprintf(fid, '- Aspect ratio: %g\n', data.aspectratio);
  fprintf(fid, '- Bandwidth: %g\n', data.bandwidth);
elseif (data.selRight == 4) % Gabor function or filterkernel (power spectrum)
  if (data.invertOutput == 1)
    fprintf(fid, 'The generated power spectrum of the Gabor function (inverted): %s\n', filename);
  else  
    fprintf(fid, 'The generated power spectrum of the Gabor function: %s\n', filename);
  end
  fprintf(fid, 'is based on the following parameters:\n\n');
  fprintf(fid, '- Original image (used for scaling purposes): %s\n', instruct.selImage);
  fprintf(fid, '- Wavelength: %g\n', data.wavelength);
  fprintf(fid, '- Orientation: %s\n', num2str(data.orientation(1)*360/(2*pi),4));
  fprintf(fid, '- Phase offset: %s\n', num2str(data.phaseoffset(1)*360/(2*pi),4)); 
  fprintf(fid, '- Aspect ratio: %g\n', data.aspectratio);
  fprintf(fid, '- Bandwidth: %g\n', data.bandwidth);
else % inhibitionkernel
  if (data.invertOutput == 1)
    fprintf(fid, 'The generated inhibition surround (inverted): %s\n', filename);
  else  
    fprintf(fid, 'The generated inhibition surround: %s\n', filename);
  end
  fprintf(fid, 'is based on the following parameters:\n\n');
  fprintf(fid, '- Original image (used for scaling purposes): %s\n', instruct.selImage);
  fprintf(fid, '- Wavelength (used to calculate Sigma): %g\n', data.wavelength);
  fprintf(fid, '- Bandwidth (used to calculate Sigma): %g\n', data.bandwidth);
  fprintf(fid, '- Sigma (calculated): %g\n', data.sigmaC);
  fprintf(fid, '- K1: %g\n', data.k1);
  fprintf(fid, '- K2: %g\n', data.k2);
  if (data.hwstate == 1)
    fprintf(fid, '- Half-wave rectification percentage: %g\n', data.halfwave); 
  end
end
fclose(fid);