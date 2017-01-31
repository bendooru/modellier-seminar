function varargout = Gui(varargin)
%GUI MATLAB code file for Gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('Property','Value',...) creates a new GUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Gui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      GUI('CALLBACK') and GUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in GUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Gui

% Last Modified by GUIDE v2.5 30-Jan-2017 15:09:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Gui_OpeningFcn, ...
                   'gui_OutputFcn',  @Gui_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before Gui is made visible.
function Gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for Gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_tag_Callback(hObject, eventdata, handles)
% hObject    handle to edit_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tag as text
%        str2double(get(hObject,'String')) returns contents of edit_tag as a double


% --- Executes during object creation, after setting all properties.
function edit_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_monat_Callback(hObject, eventdata, handles)
% hObject    handle to edit_monat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_monat as text
%        str2double(get(hObject,'String')) returns contents of edit_monat as a double


% --- Executes during object creation, after setting all properties.
function edit_monat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_monat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_laufen_Callback(hObject, eventdata, handles)
% hObject    handle to edit_laufen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_laufen as text
%        str2double(get(hObject,'String')) returns contents of edit_laufen as a double


% --- Executes during object creation, after setting all properties.
function edit_laufen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_laufen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on button press in checkbox_Karte.
function checkbox_Karte_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Karte (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Karte




    


function edit_lat_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lat as text
%        str2double(get(hObject,'String')) returns contents of edit_lat as a double


% --- Executes during object creation, after setting all properties.
function edit_lat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lon_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lon as text
%        str2double(get(hObject,'String')) returns contents of edit_lon as a double


% --- Executes during object creation, after setting all properties.
function edit_lon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_los.
function pushbutton_los_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_los (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% pushbutton_los_Callback.Enable='off';
if get(handles.checkbox_profil_manuell, 'Value') == 1
    fitness.walkpause = sscanf(get(handles.edit_laufen,'String'), '%d,', [2 Inf]);
    fitness.f = { @(t) str2double(get(handles.edit_geschwindigkeit, 'String')) };
end
if get(handles.checkbox_profil1, 'Value') == 1
    fitness.walkpause = [180;30];
    fitness.f = { @(t) 90 };
end
if get(handles.checkbox_profil2, 'Value') == 1
    fitness.walkpause = [180;30];
    fitness.f = { @(t) 90 };
end
if get(handles.checkbox_profil3, 'Value') == 1
    fitness.walkpause = [180;30];
    fitness.f = { @(t) 90 };
end
ax = handles.axes1;
tag = str2double(get(handles.edit_tag, 'String'));
monat = str2double(get(handles.edit_monat, 'String'));
if get(handles.checkbox_koordinaten, 'Value') == 1
    coord = [str2double(get(handles.edit_lon,'String')), ...
             str2double(get(handles.edit_lat,'String'))];
    osm_gui(tag, monat, fitness, 'Animate', 'Coord', coord, 'Axis',ax);
else
    osm_gui(tag, monat, fitness, 'Animate', 'Axis', ax);
end
% pushbutton_los_Callback.Enable='on';

% --------------------------------------------------------------------
function menue_Callback(hObject, eventdata, handles)
% hObject    handle to menue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Karten_loeschen_Callback(hObject, eventdata, handles)
% hObject    handle to Karten_loeschen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isdir('maps')
    rmdir('maps','s');
end
if isdir('tiles')
    rmdir('tiles','s');
end



function edit_geschwindigkeit_Callback(hObject, eventdata, handles)
% hObject    handle to edit_geschwindigkeit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_geschwindigkeit as text
%        str2double(get(hObject,'String')) returns contents of edit_geschwindigkeit as a double


% --- Executes during object creation, after setting all properties.
function edit_geschwindigkeit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_geschwindigkeit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_profil_manuell.
function checkbox_profil_manuell_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_profil_manuell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_profil_manuell
if(get(hObject, 'Value')==0)
    if handles.checkbox_profil1.Value || handles.checkbox_profil2.Value || handles.checkbox_profil3.Value 
        handles.edit_geschwindigkeit.Visible='off';
        handles.text_geschwindigkeit.Visible='off';
        handles.edit_laufen.Visible='off';
        handles.text_laufen.Visible='off';
    else
        handles.checkbox_profil_manuell.Value=1;
    end
else
    handles.edit_geschwindigkeit.Visible='on';
    handles.text_geschwindigkeit.Visible='on';
    handles.edit_laufen.Visible='on';
    handles.text_laufen.Visible='on';
    handles.checkbox_profil1.Value=0;
    handles.checkbox_profil2.Value=0;
    handles.checkbox_profil3.Value=0;
end


% --- Executes on button press in checkbox_profil1.
function checkbox_profil1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_profil1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_profil1
if(get(hObject, 'Value')==1)
    handles.checkbox_profil2.Value=0;
    handles.checkbox_profil3.Value=0;
    handles.checkbox_profil_manuell.Value=0;
    handles.edit_geschwindigkeit.Visible='off';
    handles.text_geschwindigkeit.Visible='off';
    handles.edit_laufen.Visible='off';
    handles.text_laufen.Visible='off';
else
    if ~(handles.checkbox_profil2.Value || handles.checkbox_profil3.Value || handles.checkbox_profil_manuell.Value) 
    handles.checkbox_profil1.Value=1;
    end
end
% --- Executes on button press in checkbox_profil2.
function checkbox_profil2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_profil2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_profil2
if(get(hObject, 'Value')==1)
    handles.checkbox_profil1.Value=0;
    handles.checkbox_profil3.Value=0;
    handles.checkbox_profil_manuell.Value=0;
    handles.edit_geschwindigkeit.Visible='off';
    handles.text_geschwindigkeit.Visible='off';
    handles.edit_laufen.Visible='off';
    handles.text_laufen.Visible='off';
else
    if ~(handles.checkbox_profil1.Value || handles.checkbox_profil3.Value || handles.checkbox_profil_manuell.Value) 
    handles.checkbox_profil2.Value=1;
    end
end

% --- Executes on button press in checkbox_profil3.
function checkbox_profil3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_profil3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_profil3
if(get(hObject, 'Value')==1)
    handles.checkbox_profil1.Value=0;
    handles.checkbox_profil2.Value=0;
    handles.checkbox_profil_manuell.Value=0;
    handles.edit_geschwindigkeit.Visible='off';
    handles.text_geschwindigkeit.Visible='off';
    handles.edit_laufen.Visible='off';
    handles.text_laufen.Visible='off';
else
    if ~(handles.checkbox_profil1.Value || handles.checkbox_profil2.Value || handles.checkbox_profil_manuell.Value) 
    handles.checkbox_profil3.Value=1;
    end
end




% --------------------------------------------------------------------
function bsp_Callback(hObject, eventdata, handles)
% hObject    handle to bsp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_bsp1.Visible='on';
handles.checkbox_bsp2.Visible='on';
handles.checkbox_bsp3.Visible='on';


% --- Executes on button press in checkbox_bsp1.
function checkbox_bsp1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_bsp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_bsp1


% --- Executes on button press in checkbox_bsp2.
function checkbox_bsp2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_bsp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_bsp2


% --- Executes on button press in checkbox_bsp3.
function checkbox_bsp3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_bsp3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_bsp3



% --- Executes on button press in checkbox_koordinaten.
function checkbox_koordinaten_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_koordinaten (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_koordinaten
if(get(hObject, 'Value')==0)
    handles.edit_lon.Visible='off';
    handles.text_lon.Visible='off';
    handles.edit_lat.Visible='off';
    handles.text_lat.Visible='off';
    
else
    handles.edit_lon.Visible='on';
    handles.text_lon.Visible='on';
    handles.edit_lat.Visible='on';
    handles.text_lat.Visible='on';
end
