function [x,y] = estimate_intersection(preDot, endDot, circle)
% ESTIMATE_INTERSECTION Summary of this function goes here
%   Detailed explanation goes here
R = (circle.diameter - circle.thickness)/2;

% Which of Pre vs End Dot Position is closest to the target distance.
[mini,ind] = min(abs([preDot.R endDot.R] - R));

if mini < (circle.thickness/2)
    if ind == 1
        x = preDot.X;
        y = preDot.Y;
    elseif ind == 2
        x = endDot.X;
        y = endDot.Y;
    end
else

    % INterpolate between the two dot positiosn
    p = polyfit([preDot.X endDot.X],[preDot.Y endDot.Y],1);
    fx =  @(x) ((x)^2 + (p(1).*x + p(2))^2 - R^2);
    x  = fsolve(fx,min([preDot.X endDot.X]));
    y  = round(p(1)*x + p(2));
    x  = round(x);
end

end

