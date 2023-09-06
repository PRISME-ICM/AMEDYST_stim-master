function [ Cross ] = PrepareFixationCross
global S

dim   = round(S.PTB.wRect(end)*S.Parameters.SEQ.FixationCross.ScreenRatio);
width = round(dim * S.Parameters.SEQ.FixationCross.lineWidthRatio);
color = S.Parameters.SEQ.FixationCross.Color;

Cross = FixationCross(...
    dim   ,...                       % dimension in pixels
    width ,...                       % width     in pixels
    color ,...                       % color     [R G B] 0-255
    [S.PTB.CenterH S.PTB.CenterV] ); % center    in pixels

Cross.LinkToWindowPtr( S.PTB.wPtr )

Cross.AssertReady % just to check

end % function
