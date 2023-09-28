function ParPortMessages = PrepareParPort
global S

%% On ? Off ?

switch S.ParPort

    case 'Parallel'
        % Open parallel port
        OpenParPort;
        % Set pp to 0
        WriteParPort(0);

    case 'Arduino'
        S.h_ArduinoPort = Common.OpenCOMArduinoPort();

case 'Off'
    disp('No trigger will be sent.')
end

ParPortMessages = Common.PrepareEventCodes; % shortcut

end % function
