function SendParPortMessage( message )
global S
persistent SendMessage
if strcmp( S.ParPort , 'Off' )
    return
end
if isempty(SendMessage)
    if strcmp( S.ParPort , 'Parallel' )
        SendMessage = @(msg)WriteParPort(msg);
    elseif strcmp( S.ParPort , 'Arduino' )
        SendMessage = @(msg)IOPort( 'Write', S.h_arduinoport, uint8(msg));
    end

end

SendMessage( S.ParPortMessages.(message) );
WaitSecs   ( S.ParPortMessages.duration  );
SendMessage( 0                           );

% if strcmp( S.ParPort , 'Parallel' )
% 
%     % Send Trigger
%     WriteParPort( S.ParPortMessages.(message) );
%     WaitSecs    ( S.ParPortMessages.duration  );
%     WriteParPort( 0                           );
% 
% elseif strcmp( S.ParPort , 'Arduino' )
%     % Send Trigger
%     IOPort( 'Write', S.h_arduinoport, uint8(S.ParPortMessages.(message)));
%     WaitSecs( S.ParPortMessages.duration  );
%     IOPort( 'Write', h_arduinoport, uint8( 0 ) );
% 
% end

end % function
