function  too = istooOut(preDot, currentDot, R)
%ISTOOOUT Summary of this function goes here
%   Detailed explanation goes here
distance = sqrt( (currentDot.X -preDot.X)^2 + (currentDot.Y-preDot.Y)^2 );

if R - currentDot.R <= distance + 10
    too = 1;
else
    too = 0;
end

end

