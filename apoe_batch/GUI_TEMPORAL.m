function varargout = GUI_TEMPORAL(varargin)
% GUI_TEMPORAL M-file for GUI_TEMPORAL.fig
%      GUI_TEMPORAL, by itself, creates a new GUI_TEMPORAL or raises the existing
%      singleton*.
%
%      H = GUI_TEMPORAL returns the handle to a new GUI_TEMPORAL or the handle to
%      the existing singleton*.
%
%      GUI_TEMPORAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TEMPORAL.M with the given input arguments.
%
%      GUI_TEMPORAL('Property','Value',...) creates a new GUI_TEMPORAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_TEMPORAL_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_TEMPORAL_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_TEMPORAL

% Last Modified by GUIDE v2.5 11-Jul-2012 12:57:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_TEMPORAL_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_TEMPORAL_OutputFcn, ...
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


% --- Executes just before GUI_TEMPORAL is made visible.
function GUI_TEMPORAL_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_TEMPORAL (see VARARGIN)

% Choose default command line output for GUI_TEMPORAL
handles.output = hObject;

set(hObject,'toolbar','figure');

% Build a colormap that consists of 2 separate
% colormaps.
cmap1 = gray(128);
cmap2 = hot(128);
cmap = [cmap1;cmap2];
colormap(cmap)
handles.acq.cmap = cmap;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_TEMPORAL wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_TEMPORAL_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in load_image.
function load_image_Callback(hObject, eventdata, handles)
% hObject    handle to load_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% [open_FileName,open_PathName] = uigetfile('*.iq.bmode','Ouvrir un fichier de donn�es');

if isfield(handles, 'acq')
    if isfield(handles.acq, 'open_PathName');
        [open_FileName,open_PathName] = uigetfile('*.iq.bmode','Ouvrir un fichier de donn�es',handles.acq.open_PathName);
    elseif isfield(handles.acq, 'working_directory')
        [open_FileName,open_PathName] = uigetfile('*.iq.bmode','Ouvrir un fichier de donn�es',handles.acq.working_directory);   
    else
        [open_FileName,open_PathName] = uigetfile('*.iq.bmode','Ouvrir un fichier de donn�es');
    end
else
   [open_FileName,open_PathName] = uigetfile('*.iq.bmode','Ouvrir un fichier de donn�es');
end


if (open_FileName)
    
    data_path = strcat([open_PathName open_FileName]);
    handles.acq.data_path = data_path;
    handles.acq.open_FileName = open_FileName;
    handles.acq.open_PathName = open_PathName;
    
    str_temp = strfind(data_path, '.bmode');
    
    if (str_temp)
        short_data_path = data_path(1:str_temp-1);
        shortest_data_path = data_path(1:str_temp-4);
        handles.acq.short_data_path = short_data_path;
        handles.acq.shortest_data_path = shortest_data_path;
        
        xml_data_path = [data_path(1:str_temp) 'xml'];

        param = VsiParseXmlModif(xml_data_path,'.bmode');
        handles.acq.param = param;
        
        % Set offsets in interface
        set(handles.edit_yoffset,'string', num2str(param.BmodeYOffset));
        set(handles.edit_voffset,'string', num2str(param.BmodeVOffset));
        handles.acq.YOffset = param.BmodeYOffset;
        handles.acq.VOffset = param.BmodeVOffset;        
        set(handles.edit_yoffset,'enable', 'on');
        set(handles.edit_voffset,'enable', 'on');    
        
        
        % Calculate number of frames in file
        handles.acq.n_frames = VsiFindNFrames(short_data_path, '.bmode');
        
        % Get the Time Stamp Data for all frames
        handles.acq.TimeStampData = VsiBModeIQTimeFrame(short_data_path, '.bmode', handles.acq.n_frames);       
        
        
        figure;plot( handles.acq.TimeStampData/1000);
        
        % Display US (for frame 1)
        handles = VsiBModeReconstructRFModif(handles, short_data_path, 1);
        
        % Display PA (for frame 1)
        if (get(handles.checkbox_pa_display,'value'))
            VsiBeamformPaModif(handles, short_data_path, 1, 1);
        end
        
        handles.acq.frame_number = 1;
        set(handles.frame_number,'string',num2str(1));
        set(handles.frame_number,'enable','on');
        set(handles.total_frames,'string',num2str(handles.acq.n_frames));
        set(handles.next_button,'enable','on');
        set(handles.display_filename, 'string', open_FileName);
    end
end

guidata(hObject, handles);


function display_filename_Callback(hObject, eventdata, handles)
% hObject    handle to display_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of display_filename as text
%        str2double(get(hObject,'String')) returns contents of display_filename as a double


% --- Executes during object creation, after setting all properties.
function display_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to display_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

frame_number = handles.acq.frame_number;

frame_number = frame_number + 1;

set(handles.frame_number, 'string', num2str(frame_number));
handles.acq.frame_number = frame_number;

% Display US
handles = VsiBModeReconstructRFModif(handles, handles.acq.short_data_path, frame_number);

% Display PA
if (get(handles.checkbox_pa_display,'value'))
    VsiBeamformPaModif(handles, handles.acq.short_data_path, frame_number, frame_number);
end
        
if frame_number >= handles.acq.n_frames
   set(handles.next_button, 'enable','off'); 
   set(handles.next_copy_button, 'enable','off'); 
else
   set(handles.previous_button, 'enable','on');
end


guidata(hObject, handles);



function frame_number_Callback(hObject, eventdata, handles)
% hObject    handle to frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frame_number as text
%        str2double(get(hObject,'String')) returns contents of frame_number as a double


frame_number = str2num(get(handles.frame_number, 'string'));

handles.acq.frame_number = frame_number;

% Display US
handles = VsiBModeReconstructRFModif(handles, handles.acq.short_data_path, frame_number);

% Display PA
if (get(handles.checkbox_pa_display,'value'))
    VsiBeamformPaModif(handles, handles.acq.short_data_path, frame_number, frame_number);
end

if frame_number == handles.acq.n_frames
    set(handles.next_button,'enable','off');
    set(handles.next_copy_button,'enable','off');
    set(handles.previous_button,'enable','on');
end

if frame_number == 1
    set(handles.previous_button,'enable','off');
    set(handles.next_button,'enable','on');
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function frame_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function total_frames_Callback(hObject, eventdata, handles)
% hObject    handle to total_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of total_frames as text
%        str2double(get(hObject,'String')) returns contents of total_frames as a double


% --- Executes during object creation, after setting all properties.
function total_frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to total_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in previous_button.
function previous_button_Callback(hObject, eventdata, handles)
% hObject    handle to previous_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

frame_number = handles.acq.frame_number;

frame_number = frame_number - 1;

set(handles.frame_number, 'string', num2str(frame_number));
handles.acq.frame_number = frame_number;

% Display US
handles = VsiBModeReconstructRFModif(handles, handles.acq.short_data_path, frame_number);

% Display PA
if (get(handles.checkbox_pa_display,'value'))
    VsiBeamformPaModif(handles, handles.acq.short_data_path, frame_number, frame_number);
end

if frame_number <= 1
   set(handles.previous_button, 'enable','off');
else
   set(handles.next_button, 'enable','on');
end

guidata(hObject, handles);


% --- Executes on button press in checkbox_pa_display.
function checkbox_pa_display_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_pa_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_pa_display



function edit_voffset_Callback(hObject, eventdata, handles)
% hObject    handle to edit_voffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_voffset as text
%        str2double(get(hObject,'String')) returns contents of edit_voffset as a double

VOffset = str2num(get(handles.edit_voffset,'string'));
handles.acq.VOffset = VOffset;

% Display US
frame_number = handles.acq.frame_number;
handles = VsiBModeReconstructRFModif(handles, handles.acq.short_data_path, frame_number);

% Display PA
if (get(handles.checkbox_pa_display,'value'))
    VsiBeamformPaModif(handles, handles.acq.short_data_path, frame_number, frame_number);
end

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit_voffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_voffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_yoffset_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yoffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yoffset as text
%        str2double(get(hObject,'String')) returns contents of edit_yoffset as a double
YOffset = str2num(get(handles.edit_yoffset,'string'));
handles.acq.YOffset = YOffset;

% Display US
frame_number = handles.acq.frame_number;
handles = VsiBModeReconstructRFModif(handles, handles.acq.short_data_path, frame_number);

% Display PA
if (get(handles.checkbox_pa_display,'value'))
    VsiBeamformPaModif(handles, short_data_path, frame_number, frame_number);
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_yoffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_yoffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end