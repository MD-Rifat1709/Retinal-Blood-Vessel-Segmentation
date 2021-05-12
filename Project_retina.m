function varargout = Project_retina(varargin)
% PROJECT_RETINA MATLAB code for Project_retina.fig
%      PROJECT_RETINA, by itself, creates a new PROJECT_RETINA or raises the existing
%      singleton*.
%
%      H = PROJECT_RETINA returns the handle to a new PROJECT_RETINA or the handle to
%      the existing singleton*.
%
%      PROJECT_RETINA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROJECT_RETINA.M with the given input arguments.
%
%      PROJECT_RETINA('Property','Value',...) creates a new PROJECT_RETINA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Project_retina_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Project_retina_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Project_retina

% Last Modified by GUIDE v2.5 29-Mar-2021 00:48:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Project_retina_OpeningFcn, ...
                   'gui_OutputFcn',  @Project_retina_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Project_retina is made visible.
function Project_retina_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Project_retina (see VARARGIN)

% Choose default command line output for Project_retina
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Project_retina wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Project_retina_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in input.
function input_Callback(hObject, eventdata, handles)
% hObject    handle to input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA) 
global cvipImage

    [filename, pathname] = uigetfile({'*.*', 'All Files (*.*)';...
        '*.tif','TIFF (*.tif)'; '*.bmp','BMP (*.bmp)';...
        '*.jpg', 'JPEG/JPEG2000 (*.jpg)'; '*.png','PNG (*.png)';...
        '*.pbm ; *.ppm;*.pgm; *.pnm',...
        'PBM/PPM/PGM/PNM (*.pbm,*.ppm,*.pgm, *.pnm)';...
        '*.gif','GIF (*.gif)'}, ...
        'Select an input image file', 'MultiSelect','off'); %mulitple file selection option is OFF, single image file only 

    %check if user has successfuly made the file selection
    if ~isequal(filename,0)
        % read the selected image from given path
        [cvipImage,map]=imread([pathname filename]);
        
        %check image is either indexed image or rgb image
        %indexed image consists of a data matrix and a colormap matrix.
        %rgb image consists of a data matrix only.        
        if ~isempty(map) %indexed image if map is not empty
            cvipImage = ind2rgb(cvipImage,map);%convert indexed image into rgb image 
        end
        
    else 
        warning('Image file not selected!!!');  %warn user if cancelled
        cvipImage=[];             %return empty matrix if user has cancelled the selection
    end


imshow(cvipImage)

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

% --- Executes on button press in final_output.
function final_output_Callback(hObject, eventdata, handles)
% hObject    handle to final_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cvipImage
global K
rgb = cvipImage;
greenchannel=rgb(: , : , 2);
se=strel('disk',3);
tophat=imtophat(greenchannel,se);
se1=strel('disk',7);
tophat1=imtophat(greenchannel,se1);
se2=strel('disk',11);
tophat2=imtophat(greenchannel,se2);
se3=strel('disk',15);
tophat3=imtophat(greenchannel,se3);
se4=strel('disk',19);
tophat4=imtophat(greenchannel,se4);
se5=strel('disk',23);
tophat5=imtophat(greenchannel,se5);
bse=strel('disk',3);
bothat=imbothat(greenchannel,bse);
bse1=strel('disk',7);
bothat1=imbothat(greenchannel,bse1);
bse2=strel('disk',11);
bothat2=imbothat(greenchannel,bse2);
bse3=strel('disk',15);
bothat3=imbothat(greenchannel,bse3);
bse4=strel('disk',19);
bothat4=imbothat(greenchannel,bse4);
bse5=strel('disk',23);
bothat5=imbothat(greenchannel,bse5);
h1 = fspecial('gaussian', 10, 50);
h2 = fspecial('gaussian', 10, 10); 
gauss1 = conv2(greenchannel, h1, 'same');
gauss2 = conv2(greenchannel, h2, 'same');
dogImg = gauss1 - gauss2;
h3 = fspecial('gaussian', 10, 40);
h4 = fspecial('gaussian', 10, 10); 
gauss3 = conv2(greenchannel, h3, 'same');
gauss4 = conv2(greenchannel, h4, 'same');
dogImg1 = gauss3 - gauss4;
h5 = fspecial('gaussian', 10, 25);
h6 = fspecial('gaussian', 10, 5); 
gauss5 = conv2(greenchannel, h5, 'same');
gauss6 = conv2(greenchannel, h6, 'same');
dogImg2 = gauss5 - gauss6;
h7 = fspecial('gaussian', 10, 2.828);
h8 = fspecial('gaussian', 10, 2); 
gauss7 = conv2(greenchannel, h7, 'same');
gauss8 = conv2(greenchannel, h8, 'same');
dogImg3 = gauss7 - gauss8;
h9 = fspecial('gaussian', 10, 2);
h10 = fspecial('gaussian', 10, 1.414); 
gauss9 = conv2(greenchannel, h9, 'same');
gauss10 = conv2(greenchannel, h10, 'same');
dogImg4 = gauss9 - gauss10;
lab = rgb2lab(rgb);
L=lab(:,:,1);
RGB = im2double(rgb);
[R,G,B]=imsplit(RGB);
G1 = 0.06 * R + 0.63 * G + 0.27 * B;
G2 = 0.3 * R + 0.04 * G - 0.35 * B;
Gclahe = adapthisteq(greenchannel,'NumTiles',[8 8],'ClipLimit',0.01,'NBins',256,'Distribution','Uniform');
Lclahe = adapthisteq(L,'NumTiles',[8 8],'ClipLimit',0.01,'NBins',256,'Distribution','Uniform');
G1clahe = adapthisteq(G1,'NumTiles',[8 8],'ClipLimit',0.01,'NBins',256,'Distribution','Uniform');
G2clahe = adapthisteq(G2,'NumTiles',[8 8],'ClipLimit',0.01,'NBins',256,'Distribution','Uniform');
Ggabor6 = post(Gclahe,6);
Ggabor7 = post(Gclahe,7);
Ggabor8 = post(Gclahe,8);
Lgabor6 = post(Lclahe,6);
Lgabor7 = post(Lclahe,7);
Lgabor8 = post(Lclahe,8);
G1gabor6 = post(G1clahe,6);
G1gabor7 = post(G1clahe,7);
G1gabor8 = post(G1clahe,8);
G2gabor6 = post(G2clahe,6);
G2gabor7 = post(G2clahe,7);
G2gabor8 = post(G2clahe,8);
fv1 = (greenchannel);
fv1(:,:,2) = (tophat);
fv1(:,:,3) = (tophat1);
fv1(:,:,4) = (tophat2);
fv1(:,:,5) = (tophat3);
fv1(:,:,6) = (tophat4);
fv1(:,:,7) = (tophat5);
fv1(:,:,8) = (bothat);
fv1(:,:,9) = (bothat1);
fv1(:,:,10) = (bothat2);
fv1(:,:,11) = (bothat3);
fv1(:,:,12) = (bothat4);
fv1(:,:,13) = (bothat5);
fv1(:,:,14) = (dogImg);
fv1(:,:,15) = (dogImg1);
fv1(:,:,16) = (dogImg2);
fv1(:,:,17) = (dogImg3);
fv1(:,:,18) = (dogImg4);
fv1(:,:,19) = (Gclahe);
fv1(:,:,20) = (Lclahe);
fv1(:,:,21) = (G1clahe);
fv1(:,:,22) = (G2clahe);
fv1(:,:,23) = (Ggabor6);
fv1(:,:,24) = (Ggabor7);
fv1(:,:,25) = (Ggabor8);
fv1(:,:,26) = (Lgabor6);
fv1(:,:,27) = (Lgabor7);
fv1(:,:,28) = (Lgabor8);
fv1(:,:,29) = (G1gabor6);
fv1(:,:,30) = (G1gabor7);
fv1(:,:,31) = (G1gabor8);
fv1(:,:,32) = (G2gabor6);
fv1(:,:,33) = (G2gabor7);
fv1(:,:,34) = (G2gabor8);
K = kclustering(rgb,fv1);
final = im2bw(K);
imshow(final)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in similarity.
function similarity_Callback(hObject, eventdata, handles)
% hObject    handle to similarity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global K
global BW


    [filename, pathname] = uigetfile({'*.*', 'All Files (*.*)';...
        '*.tif','TIFF (*.tif)'; '*.bmp','BMP (*.bmp)';...
        '*.jpg', 'JPEG/JPEG2000 (*.jpg)'; '*.png','PNG (*.png)';...
        '*.pbm ; *.ppm;*.pgm; *.pnm',...
        'PBM/PPM/PGM/PNM (*.pbm,*.ppm,*.pgm, *.pnm)';...
        '*.gif','GIF (*.gif)'}, ...
        'Select an input image file', 'MultiSelect','off'); %mulitple file selection option is OFF, single image file only 

    %check if user has successfuly made the file selection
    if ~isequal(filename,0)
        % read the selected image from given path
        [BW,map]=imread([pathname filename]);
        
        %check image is either indexed image or rgb image
        %indexed image consists of a data matrix and a colormap matrix.
        %rgb image consists of a data matrix only.        
        if ~isempty(map) %indexed image if map is not empty
            BW = ind2rgb(BW,map);%convert indexed image into rgb image 
        end
        
    else 
        warning('Image file not selected!!!');  %warn user if cancelled
        BW=[];             %return empty matrix if user has cancelled the selection
    end
similarity = BF_score(BW,K);

imshowpair(K,BW)
similarity = similarity*100;
set(handles.edit4,'string',similarity);


function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
