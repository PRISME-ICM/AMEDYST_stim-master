function h_ArduinoPort=OpenCOMArduinoPort(ARDUINO_PORTS)
% 
err_msg = '';
if nargin<1 || isempty(ARDUINO_PORTS)
    % If no port is specified, we will try to figure out ourselves..
    % Names vary according to OS:
    if ispc
        ARDUINO_PORTS = {'COM10' 'COM6' 'COM7' 'COM3'};
    elseif isunix
        ARDUINO_PORTS = {'/dev/ttyACM0'};
    end
end
n_ports = numel(ARDUINO_PORTS);
i_port  = 1;
h_ArduinoPort = [];
while(isempty(h_ArduinoPort) && i_port<=n_ports)
    try
        [h_ArduinoPort, err_msg] = IOPort('OpenSerialPort',ARDUINO_PORTS{i_port},...
            'BaudRate=115200, Parity=None, DataBits=8, StopBits=1');
        IOPort('Purge', h_ArduinoPort);
        IOPort('Write', h_arduinoport, uint8( 0 ) );
    catch ME_arduino
        h_ArduinoPort = [];
    end
    i_port = i_port + 1;
end
if isempty(h_ArduinoPort)
    warning('AMEDYST:TriggersMode','No COM port seems available for sending triggers\nError message: %s',err_msg)
else
    % Purge and send 0
    IOPort('Purge', h_ArduinoPort);
    IOPort('Write', h_arduinoport, uint8( 0 ) );
end