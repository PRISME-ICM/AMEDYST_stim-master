function state = IsInCircle( Cursor, Circle )

distance = sqrt( (Cursor.Xptb-Circle.Xptb)^2 + (Cursor.Yptb-Circle.Yptb)^2 );
rayon = (Circle.diameter - Circle.thickness)/2;
if rayon >= distance 
    state = 1  ;  % in 
elseif rayon < distance 
    state = 0 ;  % out
end 
    