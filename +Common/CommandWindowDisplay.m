function CommandWindowDisplay( EP, evt )
% CommandWindowDisplay wrapper

% Command window display
fprintf( '\n' )
fprintf( '\n ----- %s  \n' , EP.Data{evt,1} )
fprintf( ' Onset     = % 3.3g (s) \t' , EP.Data{evt,2} )
fprintf( ' Duration  = % 3.3g (s) \t' , EP.Data{evt,3} )
fprintf( ' Remaining = % 3.3g (s) \n' , EP.Data{end,2} - EP.Data{evt,2} )
fprintf( '\n' )

end % function
