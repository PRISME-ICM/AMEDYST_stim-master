function [ TaskData ] = Task_edited
global S prevX prevY newX newY






try
    %% Tunning of the task
    
    
    [ EP, Parameters ] = ADAPT.PlanningEdited;
    
    % End of preparations
    EP.BuildGraph;
    TaskData.EP = EP;
    
    
    %% Prepare event record and keybinf logger
    
    [ ER, RR, KL, SR, OutRecorder, InRecorder ] = Common.PrepareRecorders( EP );
    
    
    %% Prepare objects
    
    Cross                  = ADAPT.Prepare.Cross      ;
    BigCircle              = ADAPT.Prepare.BigCircle  ;
    [ Target, PrevTarget ] = ADAPT.Prepare.Target     ;
    Cursor                 = ADAPT.Prepare.Cursor     ;
%    Reward                 = ADAPT.Prepare.Reward     ;
    Probility              = ADAPT.Prepare.Probability;
%    RushTimer              = ADAPT.Prepare.RushTimer(Parameters);
    MarkingPoint           = Cursor.CopyObject;
    
    %% Prepare the conversion [0% .. 100%] chance into color [gray .. gold]
    
    % %     gray = S.Parameters.ADAPT.Circle.FrameColor;
    %     gray = [0 0 0];
    %     gold = S.Parameters.ADAPT.Target.ValueColor;
    %
    %     p = nan(3,2);
    %     for c = 1 : 3 % RGB
    %         p(c,:) = polyfit([0 100],[gray(c) gold(c)],1);
    %     end
    %
    %     GetColor = @(x) [polyval(p(1,:), x) polyval(p(2,:), x) polyval(p(3,:), x)];
    
    
    %% Note Reward and Punishment Recorder
    %     NRPR = EventRecorder({'Reward','Punishment', 'block'}, EP.Data{end-1,5}+5);
    %     NRPR.AddEvent({0,[],1});
    %% Eyelink
    % TaskData.nrp = NRPR;
    Common.StartRecordingEyelink
    
    
    %% Go
    
    % Initialize some variables
    EXIT = 0;
    TargetBigCirclePosition = (BigCircle.diameter-BigCircle.thickness)/2;
    
    Red    = [255 0   0  ];
    Green  = [0   255 0  ];
    Yellow = [255 255 0 ];
    MarkingPoint.diskCurrentColor = Yellow;
    % Loop over the EventPlanning
    for evt = 1 : size( EP.Data , 1 )
        
        % Common.CommandWindowDisplay( EP, evt );
        
        switch EP.Data{evt,1}
            
            case 'StartTime' % --------------------------------------------
                
                % Fetch initialization data
                switch S.InputMethod
                    case 'Joystick'
                        [newX, newY] = ADAPT.QueryJoystickData( Cursor.screenX, Cursor.screenY );
                    case 'Mouse'
                        SetMouse(Cursor.Xptb,Cursor.Yptb,Cursor.wPtr);
                        [newX, newY] = ADAPT.QueryMouseData( Cursor.wPtr, Cursor.Xorigin, Cursor.Yorigin, Cursor.screenY );
                end
                
                % Here at initialization, we don't apply deviation, just fetche raw data
                Cursor.Move(newX,newY);
                
                prevX = newX;
                prevY = newY;
                
                % BigCircle.Draw
                Cross.Draw
                Screen('DrawingFinished',S.PTB.wPtr);
                Screen('Flip',S.PTB.wPtr);
                
                StartTime = Common.StartTimeEvent;
                
            case 'StopTime' % ---------------------------------------------
                
                StopTime = GetSecs;
                
                % Record StopTime
                ER.AddStopTime( 'StopTime' , StopTime - StartTime );
                RR.AddStopTime( 'StopTime' , StopTime - StartTime );
                
                ShowCursor;
                Priority( 0 );
                
            case 'PauseTime'
                
                disp('pause time')
                stepPauseTimes = 1 ;
                counter_step_pause_notes  = 0;
                if  EP.Get('Rew',evt - 1) && S.Feedback
                    ind = find(OutRecorder.Data(:,1) == EP.Get('Bloc',evt-1));
                    sumNotes = sum(OutRecorder.Get('Points', ind));
                    proba_str = sprintf( '\n%s%d total points\n' ,Parameters.Puni, sumNotes);%ER.Get('Rew',evt)) ); % looks like "33 %"
                elseif ~S.Feedback && EP.Get('Rew',evt - 1)
                    Probility.color =     S.Parameters.Text.Color    % S.Parameters.TextColor = [128 128 128]
                    proba_str = sprintf( 'End of this block' );
                else
                    proba_str = sprintf( '' );
                end
                
                while stepPauseTimes
                    
                    counter_step_pause_notes = counter_step_pause_notes + 1;
                    
                    BigCircle.Draw
                    
                    if lastFlipOnset <= step6onset + (Parameters.PauseBetweenBlocks/2 )
                        Probility.Draw( proba_str );
                    end
                    
                    
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt-1))
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    % Record trial onset & step onset
                    if counter_step_show_reward_notes == 1
                        RR.AddEvent({['ShowSumNote__' EP.Data{evt-1,1}] lastFlipOnset-StartTime [] EP.Data{evt-1,4} EP.Data{evt-1,5} EP.Data{evt-1,6} EP.Data{evt-1,7} EP.Data{evt-1,8} EP.Data{evt-1,9}})
                        step6onset = lastFlipOnset;
                        Common.SendParPortMessage( 'ShowSumNote' )
                    end
                    
                    if lastFlipOnset >= step6onset + Parameters.PauseBetweenBlocks
                        stepPauseTimes = 0;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while
                
                
                
                
            case {'Direct_Pre', 'Deviation', 'No_vision'} % --------------------------------
                
                
                % Echo in the command window
                %               fprintf('#%3d deviation=%3° target=%3d° value=%3d%% Noreward=%d \n', round( cell2mat(EP.Data(evt,[5 6 7 9]))))
                
                
                %% ~~~ Jitter between trials ~~~
                
                stepJitterRunning  = 1;
                counter_step_jitter = 0;
                
                while stepJitterRunning
                    
                    counter_step_jitter = counter_step_jitter + 1;
                    
                    BigCircle.Draw
                    Cross.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    %   % Record trial onset & step onset
                    if counter_step_jitter == 1
                        % Original version:
                        % ER.AddEvent({EP.Data{evt,1}              lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        % KND: Add signedAUC and PeakVelocity per trial info
                        ER.AddEvent({EP.Data{evt,1}              lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        RR.AddEvent({['Jitter__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} 0})
                        step0onset = lastFlipOnset;
                        Common.SendParPortMessage( 'Jitter' )
                    end
                    
                    if lastFlipOnset >= step0onset + EP.Data{evt,8}
                        stepJitterRunning = 0;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while
                
                if EXIT
                    break
                end
                
                
                %                 %% ~~~ Pause before dislpay of the reward ~~~
                %
                %                 stepPauseBeforeRewardRunning  = 1;
                %                 counter_step5 = 0;
                %
                %                 while stepPauseBeforeRewardRunning
                %
                %                     counter_step5 = counter_step5 + 1;
                %
                %                     BigCircle.Draw
                %                     Cross.Draw
                %                     ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                %
                %                     Screen('DrawingFinished',S.PTB.wPtr);
                %                     lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                %                     SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                %
                %                     % Record trial onset & step onset
                %                     if counter_step5 == 1
                %                         RR.AddEvent({['preReward__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} EP.Data{evt,10} })
                %                         step5onset = lastFlipOnset;
                %                     end
                %
                %                     if lastFlipOnset >= step5onset +Parameters.RewardDisplayTime
                %                         stepPauseBeforeRewardRunning = 0;
                %                     end
                %
                %                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                     % Fetch keys
                %                     [keyIsDown, ~, keyCode] = KbCheck;
                %                     if keyIsDown
                %                         % ~~~ ESCAPE key ? ~~~
                %                         [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                %                         if EXIT
                %                             break
                %                         end
                %                     end
                %                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %
                %                 end % while
                
                
                %% ~~~ Show probability of reward ~~~
                
                
                
                if EXIT
                    break
                end
                
                
                %% ~~~ Pause before start of motor sequence ~~~
                
                stepPauseBeforeMotor  = 1;
                counter_step_pause_preMotor = 0;
                
                while stepPauseBeforeMotor
                    
                    counter_step_pause_preMotor = counter_step_pause_preMotor + 1;
                    
                    BigCircle.Draw
                    Cross.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    % Record trial onset & step onset
                    if counter_step_pause_preMotor == 1
                        RR.AddEvent({['PausePreMotor__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                        step5onset = lastFlipOnset;
                        Common.SendParPortMessage( 'PausePreMotor' )
                    end
                    
                    if lastFlipOnset >= step5onset +Parameters.PausePreMotor
                        stepPauseBeforeMotor = 0;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while
                
                
                
                %% ~~~ Draw target @ center ~~~
                
                BigCircle.Draw
                Cross.Draw
                
                Target.frameCurrentColor = Target.frameBaseColor;
                Target.Move(0,0)
                %                 Target.value = 0;
                %                 Target.valueCurrentColor = Target.diskCurrentColor;
                Target.Draw
                
                PrevTarget.frameCurrentColor = Red;
                PrevTarget.Move( TargetBigCirclePosition, EP.Get('Target',evt)  )
                
                ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                Cursor.Draw
                
                Screen('DrawingFinished',S.PTB.wPtr);
                flipOnset_step_3 = Screen('Flip',S.PTB.wPtr);
                SR.AddSample([flipOnset_step_3-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                RR.AddEvent({['GoBack__Start__' EP.Data{evt,1}] flipOnset_step_3-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                Common.SendParPortMessage( 'GoBack__Start' )
                
                
                %% ~~~ User moves cursor to target @ center ~~~
                
                startCursorInTarget = [];
                stepGoBackRunning   = 1;
                
                draw_PrevTraget      = 1;
                has_already_traveled = 0;
                
                frame_start = SR.SampleCount;
                
                counter_step_go_back = 0;
                
                while stepGoBackRunning
                    
                    counter_step_go_back = counter_step_go_back + 1;
                    
                    BigCircle.Draw
                    Cross.Draw
                    Target.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    Cursor.Draw
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    % Record step onset
                    if counter_step_go_back == 1
                        RR.AddEvent({['Move@Center__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                    end
                    
                    % Is cursor center in the previous target (@ ring) ?
                    if     ADAPT.IsOutside(Cursor,PrevTarget) &&  draw_PrevTraget % yes
                    elseif ADAPT.IsOutside(Cursor,PrevTarget) && ~draw_PrevTraget % back inside
                    elseif draw_PrevTraget % just outside
                        PrevTarget.frameCurrentColor = PrevTarget.frameBaseColor;
                        draw_PrevTraget = 0;
                        ReactionTimeIN = lastFlipOnset - flipOnset_step_3;
                        RR.AddEvent({['GoBack__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                    else
                    end
                    
                    
                    
                    % Is cursor center in target ?
                    if ADAPT.IsInside(Cursor,Target) % yes
                        
                        Target.frameCurrentColor = Green;
                        
                        if isempty(startCursorInTarget) % Cursor has just reached the target
                            
                            startCursorInTarget = lastFlipOnset;
                            
                            if ~has_already_traveled
                                TravelTimeIN = lastFlipOnset - flipOnset_step_3 - ReactionTimeIN;
                                has_already_traveled = 1;
                            end
                            
                        elseif lastFlipOnset >= startCursorInTarget + Parameters.TimeSpentOnTargetToValidate % Cursor remained in the target long enough
                            stepGoBackRunning = 0;
                            RR.AddEvent({['GoBack__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                            Common.SendParPortMessage( 'GoBack__TT' )
                        end
                        
                    else % no, then reset
                        startCursorInTarget = []; % reset
                        Target.frameCurrentColor = Target.frameBaseColor;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while : Setp 4
                
                Target.frameCurrentColor = Target.frameBaseColor;
                frame_stop = SR.SampleCount;
                
                if EXIT
                    break
                else
                    InRecorder.AddSample([EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,8} EP.Data{evt,6} EP.Data{evt,9} EP.Data{evt,7} frame_start frame_stop round(ReactionTimeIN*1000) round(TravelTimeIN*1000)])
                end
                
                
                %% ~~~ Draw target @ big ring ~~~
                
                BigCircle.Draw
                Cross.Draw
                
                Target.frameCurrentColor = Target.frameBaseColor;
                Target.Move( TargetBigCirclePosition, EP.Get('Target',evt) )
                %                 Target.value = EP.Get('Probability',evt);
                %                 Target.valueCurrentColor = GetColor(Target.value);
                Target.Draw
                
                PrevTarget.frameCurrentColor =  BigCircle.frameBaseColor;
                PrevTarget.Move( 0, 0 )
                PrevTarget.Draw
                
                ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                
                Screen('DrawingFinished',S.PTB.wPtr);
                flipOnset_step_Action = Screen('Flip',S.PTB.wPtr);
                
                SR.AddSample([flipOnset_step_Action-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                RR.AddEvent({['Motor__Start' EP.Data{evt,1}] flipOnset_step_Action-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                Common.SendParPortMessage( 'Motor__Start' )
                
                
                %% ~~~ User moves cursor to target @ big ring  ~~~
                
%                startCursorInTarget = [];
                stepActionRunning   = 1;
                
                draw_PrevTraget      = 1;
                has_already_traveled = 0;
                passed    = 0;
                frame_start = SR.SampleCount;
                
                counter_step_Action = 0;
                
                ReactionTimeOUT = NaN;
                TravelTimeOUT   = NaN;
                
                too_late = 0;
                
               
                while stepActionRunning
                    
                    %Cursor.diskCurrentColor = S.Parameters.Video.ScreenBackgroundColor;
                    %Cursor.frameCurrentColor = S.Parameters.Video.ScreenBackgroundColor;
                    counter_step_Action = counter_step_Action + 1;
                    
%                     if counter_step_Action > 1
%                         
%                         value = Parameters.TrialMaxDuration - (lastFlipOnset - flipOnset_step_Action);
%                         if value < S.PTB.slack
%                             stepActionRunning = 0;
%                             too_late = 1;
%                         else
%                             RushTimer.Draw( value )
%                         end
%                     end
                    BigCircle.Draw   % ici
                    Cross.Draw
                    Target.Draw
                    if draw_PrevTraget
                        PrevTarget.Draw
                        
                    end
                
                    PrevCursor = Cursor.CopyObject;     %%%% � modifier
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    
                    if Cursor.R <= TargetBigCirclePosition - 2;
                    if draw_PrevTraget || ~strcmp(EP.Data{evt,1}, 'No_vision') 
                        Cursor.Draw
                    end
                    end
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                   
%                     if ADAPT.istooOut(PrevCursor, Cursor, TargetBigCirclePosition)
%                        Cursor.diskCurrentColor  = S.Parameters.Video.ScreenBackgroundColor;
%                        Cursor.frameCurrentColor = S.Parameters.Video.ScreenBackgroundColor;
%                        
%                     end
                    % Record step onset
                    if counter_step_Action == 1
                        RR.AddEvent({['Move@Ring__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                    end
                    
                    % Is cursor center in the previous target (@ center) ?
%                     if abs(PrevCursor.R - Cursor.R) >= 10  && draw_PrevTraget
%                          draw_PrevTraget = 0;
%                           ReactionTimeOUT = lastFlipOnset - flipOnset_step_Action;
%                     end
                    if     ADAPT.IsOutside(Cursor,PrevTarget) &&  draw_PrevTraget % yes
                    elseif ADAPT.IsOutside(Cursor,PrevTarget) && ~draw_PrevTraget % back inside
                    elseif draw_PrevTraget % just outside
                        PrevTarget.frameCurrentColor = PrevTarget.frameBaseColor;
                        draw_PrevTraget = 0;
                        ReactionTimeOUT = lastFlipOnset - flipOnset_step_Action;
                        RR.AddEvent({['Motor__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                        Common.SendParPortMessage( 'Motor__RT' )
                    else
                    end
                  
                    % disp(abs(Cursor.R - BigCircle.diameter/2))
                    
                    % Is cursor center in target ?
                    if (lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT) >= Parameters.TravelMaxDuration && ~has_already_traveled
                        Target.frameCurrentColor    = Red;
                        % BigCircle.frameCurrentColor = Red;
                        TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;
                        too_late  = 1;
                        RR.AddEvent({['Motor__TTOVER__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        Common.SendParPortMessage( 'Motor__TO' )
                        stepActionRunning = 0;
                        eAngle = 0;
                        note   = 0;
                        disp('Null');
                    end
                    
                    if ADAPT.IsInside(Cursor,Target) && ~too_late % yes
                        
                        Target.frameCurrentColor = Green;
                        
                        %if isempty(startCursorInTarget) % Cursor has just reached the target
                        
                        % startCursorInTarget = lastFlipOnset;
                        
                        if ~has_already_traveled
                            TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;
                            has_already_traveled = 1;
                        end
                        
                        % elseif lastFlipOnset >= startCursorInTarget + Parameters.TimeSpentOnTargetToValidate % Cursor remained in the target long enough
                        if EP.Get('Rew',evt)
                            note = Parameters.HitTarget(EP.Get('Rew',evt));
                        else
                            note = 0;
                        end
                        stepActionRunning = 0;
                        eAngle = 0;
                        RR.AddEvent({['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        
                        Common.SendParPortMessage( 'Motor__TT' )
                        %   end
                        
                        % no, then reset
                        % startCursorInTarget = []; % reset
                        %                        Target.frameCurrentColor = Target.frameBaseColor;
                        
                    elseif ((Cursor.R >= TargetBigCirclePosition - 1) && PrevCursor.R < TargetBigCirclePosition ) || passed   % ADAPT.IsInCircle( PrevCursor, BigCircle )  % (abs(Cursor.R - BigCircle.diameter/2) < 8
                        % is cursor out BigCircle
                         TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;
                         
                        %                               BigCircle.frameCurrentColor = Red;
                        [x,y ] = ADAPT.estimate_intersection(PrevCursor, Cursor, BigCircle);
                        passed = 1;
                        MarkingPoint.Move(x,y);
                        
                        if ADAPT.IsInside(MarkingPoint,Target)
                            Target.frameCurrentColor = Green;
                            passed = 0;
                            if EP.Get('Rew',evt)
                                note = Parameters.HitTarget(EP.Get('Rew',evt));
                            else
                                note = 0;
                            end
                            eAngle = 0
                            RR.AddEvent({['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                            
                            Common.SendParPortMessage( 'Motor__TT' )
                            stepActionRunning = 0;
                            
                        else
                            %MarkingPoint.Draw;
                            %disp('OK ici %%%%%%%%%%%%%%%%%')
                            Target.frameCurrentColor = Red;
                            eAngle = ADAPT.errorAngle(Target.THETA ,  MarkingPoint.Theta );
                            note   = ADAPT.getNote(eAngle, Parameters.AnglesError,Parameters.Points);
                            RR.AddEvent({['Motor__TOut__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}});
                            Common.SendParPortMessage( 'Motor__TOut' )
                            stepActionRunning = 0;
                            
                            
                        end
                        
                        
                        %
                        
                        
                    end
                    
                    
                    
                    
                    
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  
                end % while : Setp 2
                
                %                NRPR.AddEvent({note,[],1});
                
                frame_stop = SR.SampleCount;
                

                
                stepShowRewardNotes  = 1;
                counter_step_show_reward_notes = 0;
                failedTrial = 0;

              
                if TravelTimeOUT < Parameters.TravelMinDuration 
                     Probility.color =     S.Parameters.Text.Color    % S.Parameters.TextColor = [128 128 128]
                     proba_str = sprintf('\nToo fast\n');
                     Target.frameCurrentColor = Red;
                     TravelTimeOUT
                     passed = 0;
                    % eAngle = 0;
                     note   = 0;
                     failedTrial = 1;
                elseif too_late
                    Probility.color =     S.Parameters.Text.Color    % S.Parameters.TextColor = [128 128 128]
                    proba_str = sprintf( '\nToo late\n');
                    failedTrial  = 1 ; 
                else
                    if  EP.Get('Rew',evt) && S.Feedback
                        proba_str = sprintf( '\n%s%d\n' ,Parameters.Puni, note);%ER.Get('Rew',evt)) ); % looks like "33 %"
                    elseif ~ S.Feedback && EP.Get('Rew',evt)
                        Probility.color =     S.Parameters.Text.Color    % S.Parameters.TextColor = [128 128 128]
                        proba_str = sprintf( '_ | o' );
                    else
                        proba_str = sprintf( '' );
                    end
                end

                
                if EXIT
                    break
                else
                    OutRecorder.AddSample([EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,8} EP.Data{evt,6} EP.Data{evt,9} EP.Data{evt,7} frame_start frame_stop round(ReactionTimeOUT*1000) round(TravelTimeOUT*1000) round(eAngle) round(note) failedTrial])
                end
                
                
                
                while stepShowRewardNotes
                    
                    counter_step_show_reward_notes = counter_step_show_reward_notes + 1;
                    
                    
                    BigCircle.Draw
                    Target.Draw
                    if passed 
                        MarkingPoint.Draw;
                    end
                    Probility.Draw( proba_str );
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    % Record trial onset & step onset
                    if counter_step_show_reward_notes == 1
                        RR.AddEvent({['ShowNote__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        step6onset = lastFlipOnset;
                        Common.SendParPortMessage( 'ShowNote' )
                    end
                    
                    if lastFlipOnset >= step6onset + Parameters.RewardNoteDuration
                        stepShowRewardNotes = 0;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while
                               Probility.color =     S.Parameters.TextColor    
  
                
                %% ~~~ Pause before dislpay of the reward ~~~
                BigCircle.frameCurrentColor = BigCircle.frameBaseColor;
                Target.frameCurrentColor = Target.frameBaseColor;
                Cursor.diskCurrentColor  =  Cursor.diskBaseColor;
                Cursor.frameCurrentColor =  Cursor.frameBaseColor;
                stepPausePostMotor = 1;
                counter_step_pause_postMotor = 0;
                
                while stepPausePostMotor
                    
                    counter_step_pause_postMotor = counter_step_pause_postMotor + 1;
                    
                    BigCircle.Draw
                    Cross.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                    
                    % Record trial onset & step onset
                    if counter_step_pause_postMotor == 1
                        RR.AddEvent({['PausePreReward__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        step5onset = lastFlipOnset;
                        Common.SendParPortMessage( 'PausePreReward' )
                    end
                    
                    if lastFlipOnset >= step5onset + Parameters.PausePostMotor
                        stepPausePostMotor = 0;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fetch keys
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % ~~~ ESCAPE key ? ~~~
                        [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                        if EXIT
                            break
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end % while : step 5
                BigCircle.frameCurrentColor = BigCircle.frameBaseColor;
                
                %% ~~~ Show reward ~~~
                
                %                 stepShowRealReward = 1;
                %                 counter_step_show_real_reward = 0;
                %
                %                 while stepShowRealReward
                %
                %                     counter_step_show_real_reward = counter_step_show_real_reward + 1;
                %
                %                     BigCircle.Draw
                %                     if S.Feedback
                %                         if too_late
                %                             Reward.Draw( 0 );
                %                         else
                %                             Reward.Draw( S.Feedback );
                %                         end
                %                     else
                %                         % pass, don't sow anything
                %                     end
                %                     ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                %
                %                     Screen('DrawingFinished',S.PTB.wPtr);
                %                     lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                %                     SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                %
                %                     % Record trial onset & step onset
                %                     if counter_step_show_real_reward == 1
                %                         RR.AddEvent({['ShowReward__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                %                         step6onset = lastFlipOnset;
                %                         Common.SendParPortMessage( 'ShowReward' )
                %                     end
                %
                %                     if lastFlipOnset >= step6onset + Parameters.ShowRewardDuration
                %                         stepShowRealReward = 0;
                %                     end
                %
                %                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                     % Fetch keys
                %                     [keyIsDown, ~, keyCode] = KbCheck;
                %                     if keyIsDown
                %                         % ~~~ ESCAPE key ? ~~~
                %                         [ EXIT, StopTime ] = Common.Interrupt( keyCode, ER, RR, StartTime );
                %                         if EXIT
                %                             break
                %                         end
                %                     end
                %                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %
                %                 end % while : step 6
                
                if EXIT
                    break
                end
                
                
            otherwise % ---------------------------------------------------
                
                error('unknown envent')
                
        end % switch
        
        % This flag comes from Common.Interrupt, if ESCAPE is pressed
        if EXIT
            break
        end
        
    end % for
    
    % "The end"
    BigCircle.Draw
    Cross.Draw
    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
    Screen('DrawingFinished',S.PTB.wPtr);
    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
    
    
    %% End of stimulation
    
    TaskData = Common.EndOfStimulation( TaskData, EP,ER, RR, KL, SR, StartTime, StopTime );
    TaskData.Parameters = Parameters;
    
    OutRecorder.ClearEmptySamples;
    InRecorder. ClearEmptySamples;
    TaskData.OutRecorder = OutRecorder;
    TaskData.InRecorder  = InRecorder;
    assignin('base','OutRecorder', OutRecorder)
    assignin('base','InRecorder' , InRecorder )
    
    TaskData.TargetBigCirclePosition = TargetBigCirclePosition;
    
    
    
catch err
    
    Common.Catch( err );
    
end

end % function
