function h_ArduinoPortOut=OpenCOMArduinoPort(ARDUINO_PORTS)
persistent h_ArduinoPort
global S
if nargin<1 || isempty(ARDUINO_PORTS)
    if ~isfield(S,'h_ArduinoPort') || isempty(S.h_ArduinoPort)
        S.h_ArduinoPort = h_ArduinoPort;
    end
    try
        fprintf('There seems to be an Arduino Port open.\n');
        h_ArduinoPort = S.h_ArduinoPort;
        IOPort('Purge', h_ArduinoPort);
        IOPort('Write', h_ArduinoPort, uint8( 0 ) );
        fprintf('Current Arduino Port is working fine.\n');
        disp(S.h_ArduinoPort)
        h_ArduinoPortOut = h_ArduinoPort;
        return
    catch
        h_ArduinoPort = [];
        % continue
    end
end

% If no port is specified, we will try to figure out ourselves..
% Names vary according to OS:
if ispc
    ARDUINO_PORTS = {'COM4'};%{'COM10' 'COM6' 'COM7' 'COM3'};
elseif isunix
    ARDUINO_PORTS = {'/dev/ttyACM0'};
end

n_ports = numel(ARDUINO_PORTS);
i_port  = 1;
while(isempty(h_ArduinoPort) && i_port<=n_ports)
    try
        [h_ArduinoPort, err_msg] = IOPort('OpenSerialPort',ARDUINO_PORTS{i_port},...
            'BaudRate=115200, Parity=None, DataBits=8, StopBits=1');
        fprintf('Arduino Port %s is open',ARDUINO_PORTS{i_port});
        S.h_ArduinoPort = h_ArduinoPort;
        IOPort('Purge', h_ArduinoPort);
        IOPort('Write', h_ArduinoPort, uint8( 0 ) );
        fprintf('Arduino Port %s is open',ARDUINO_PORTS{i_port});
    catch ME_arduino
        sca
        h_ArduinoPort = [];
        warning('Atrduino Port %s will not be used',ARDUINO_PORTS{i_port});
    end
    i_port = i_port + 1;
end
if isempty(h_ArduinoPort)
    warning('AMEDYST:TriggersMode','No COM port seems available for sending triggers\nError message: %s',err_msg)
else
    % Purge and send 0
    IOPort('Purge', h_ArduinoPort);
    IOPort('Write', h_ArduinoPort, uint8( 0 ) );
end
h_ArduinoPortOut = h_ArduinoPort;