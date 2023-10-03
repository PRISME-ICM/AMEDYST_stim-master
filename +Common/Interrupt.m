function [ EXIT, StopTime ] = Interrupt( ER, RR, StartTime )
global S

% Fetch keys
[keyIsDown, ~, keyCode] = KbCheck;
if keyIsDown && any(keyCode(S.Parameters.Keybinds.Stop_Escape_ASCII))
    
    % Flag
    EXIT = 1;
    
    % Stop time
    StopTime = GetSecs;

    if nargin>0
        % Record StopTime
        ER.AddStopTime( 'StopTime', StopTime - StartTime );
        RR.AddStopTime( 'StopTime', StopTime - StartTime );
    end
    ShowCursor;
    Priority( S.PTB.oldLevel );
    
    fprintf( 'ESCAPE key pressed \n');
    if S.Verbosity
        fprintf( 'StopTime: %g\n', StopTime);
    end
    
else
    
    EXIT = 0;
    StopTime  = [];
    
end
