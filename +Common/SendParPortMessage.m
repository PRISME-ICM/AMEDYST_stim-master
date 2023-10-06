function SendParPortMessage( message )
global S
if strcmp( S.ParPort , 'Off' )
    return
end
if strcmp( S.ParPort , 'Parallel' )
    % Send Trigger on Parallel Port
    WriteParPort( S.ParPortMessages.(message) );
    WaitSecs    ( S.ParPortMessages.duration  );
    WriteParPort( 0                           );
elseif strcmp( S.ParPort , 'Arduino' )
    % Send Trigger
    IOPort( 'Write', S.h_ArduinoPort, uint8(S.ParPortMessages.(message)));
    WaitSecs( S.ParPortMessages.duration  );
    IOPort( 'Write', S.h_ArduinoPort, uint8( 0 ) );
end

if S.Verbosity
    fprintf('Trigger: %s [%d]\n',message, S.ParPortMessages.(message));
end



end % function


% 
% persistent SendMessage
% 
%     if isempty(SendMessage)
%         if strcmp( S.ParPort , 'Parallel' )
%             SendMessage = @(msg) WriteParPort(msg);
%         elseif strcmp( S.ParPort , 'Arduino' )
%             SendMessage = @(msg) IOPort( 'Write', S.h_ArduinoPort, uint8(msg));
%         end
%     end
% 
%     SendMessage( S.ParPortMessages.(message) );
%     WaitSecs   ( S.ParPortMessages.duration  );
%     SendMessage( 0                           );
