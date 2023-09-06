classdef ResponseButtons < baseObject
    % RESPONSEBUTTONS Class to prepare and draw a fixation cross in PTB
    
    % Screen('FillOval', windowPtr [,color] [,rect] [,perfectUpToMaxDiameter]);
    
    %% Properties
    
    properties
        
        % Parameters
        
        height           = zeros(0)    % size of button frame, in pixels
        side             = ''          % 'Left' or 'Right' buttons
        center           = zeros(0,2)  % [ CenterX CenterY ], in pixels
        frameColor       = zeros(1,3) % [R G B] from 0 to 255
        ovalBaseColor    = zeros(3,4)  % [R G B] from 0 to 255
        ovalCurrentColor = zeros(3,4)  % [R G B] from 0 to 255
        
        % Internal variables
        
        width     = zeros(0)   % width of each arms, in pixels
        
        frameRect = zeros(1,4) % rectangle for the frame of buttons, in pixels (grey part, support)
        ovalRect  = zeros(4,4) % rectangle for the 4 buttons, in pixels
        
        darkOvals = zeros(3,4) % [R G B] from 0 to 255
        
        f2i       = @(f) f     % function handle : finger2index
        
    end % properties
    
    
    %% Methods
    
    methods
        
        % -----------------------------------------------------------------
        %                           Constructor
        % -----------------------------------------------------------------
        function obj = ResponseButtons( height , side , center, frameColor, buttonsColor )
            % obj = ResponseButtons( height=ScreenHeight*0.6 (pixels) , side='Left' , center = [ CenterX CenterY ] (pixels), ...
            %                        frameColor = [R G B] uint8, buttonsColor [3x4] RGB uint8)
            
            % ================ Check input argument =======================
            
            % Arguments ?
            if nargin > 0
                
                % --- dim ----
                assert( isscalar(height) && isnumeric(height) && height>0 && height==round(height) , ...
                    'height = size of button frame, in pixels' )
                
                
                % --- side ----
                assert( ischar(side) && any(strcmpi(side,{'right','r','left','l'})) , ...
                    'side =  ''Left'' or ''Right'' buttons' )
                               
                % --- center ----
                assert( isvector(center) && isnumeric(center) && all( center>0 ) && all(center == round(center)) , ...
                    'center = [ CenterX CenterY ] of the cross, in pixels' )
                
                % --- frameColor ----
                assert( isvector(frameColor) && isnumeric(frameColor) && all( uint8(frameColor)==frameColor ) , ...
                    'frameColor = [R G B] from 0 to 255 uint8' )
                
                % --- buttonsColor ----
                assert( isnumeric(buttonsColor) && all(all( uint8(buttonsColor)==buttonsColor )) && ...
                    size(buttonsColor,1)==3 && size(buttonsColor,2)==4 , ...
                    'buttonsColor = [3x4] RGB uint8 from 0 to 255' )
                
                obj.height           = height;
                obj.side             = side;
                obj.center           = center;
                obj.frameColor       = frameColor;
                obj.ovalBaseColor    = buttonsColor;
                
                % ================== Callback =============================
                
                obj.GenerateObject
                
            else
                % Create empty instance
            end
            
        end
        
        
    end % methods
    
    
end % class
