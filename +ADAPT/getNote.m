function note = getNote( angle, anglesReference, notesReference)
%GETNOT Summary of this function goes here
%   Detailed explanation goes here

index = discretize(angle, anglesReference);
note  = notesReference(index);



end

