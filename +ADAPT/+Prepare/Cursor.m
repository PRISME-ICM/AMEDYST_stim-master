function [ cursor ] = Cursor
global S

diameter   = S.Parameters.ADAPT.Cursor.DimensionRatio*S.PTB.wRect(4);
diskColor  = S.Parameters.ADAPT.Cursor.DiskColor;
frameColor  = S.Parameters.ADAPT.Cursor.FrameColor;
Xorigin    = S.PTB.CenterH;
Yorigin    = S.PTB.CenterV;
screenX    = S.PTB.wRect(3);
screenY    = S.PTB.wRect(4);

cursor = Dot(...
    diameter   ,...     % diameter  in pixels
    diskColor  ,...     % disk  color [R G B] 0-255
    frameColor ,...     % frame color [R G B] 0-255
    Xorigin    ,...     % X origin  in pixels
    Yorigin    ,...     % Y origin  in pixels
    screenX    ,...     % H pixels of the screen
    screenY    );       % V pixels of the screen

cursor.LinkToWindowPtr( S.PTB.wPtr )

cursor.AssertReady % just to check

end % function
