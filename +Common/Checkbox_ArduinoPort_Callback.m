function h_ArduinoPort=Checkbox_ArduinoPort_Callback(hObject,~)

if get(hObject,'Value')==1
    h_ArduinoPort=Common.OpenCOMArduinoPort();

    if isempty(h_ArduinoPort)
        disp('COM/Arduino port not working')
        %
        % set(hObject,'Value',0);
    end
end


return

opp_path = which('OpenParPort.m');

if isempty(opp_path)
    
    disp('Parallel port library NOT DETECTED')
    set(hObject,'Value',0);
    
else
    
    switch get(hObject,'Value')
        
        case 0
            disp('Parallel port library OFF')
            set(hObject,'Value',0);
            
        case 1
            disp('Parallel port library ON')
            set(hObject,'Value',1);
    end
    
end


end  % function
