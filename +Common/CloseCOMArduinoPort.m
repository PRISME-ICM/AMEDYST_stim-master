function CloseCOMArduinoPort(h_arduinoport)
global S
if nargin<1
    h_arduinoport = S.h_ArduinoPort;
end
IOPort( 'Close', h_arduinoport );