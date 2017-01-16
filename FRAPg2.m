function A = FRAPg2(m,x,t)

    x = x - m.bleach.x0;
    [T,X] = meshgrid(t,x);
    
    fleft = 1;
    f = [];
    for i=1:(length(m.component)-1)
        f(i) = m.component(i).f * fleft;
        fleft = fleft * (1-m.component(i).f);
    end
    f(end+1) = fleft;


    A = 0;
    for i=1:length(m.component)
        A = A + f(i) * a(X,T,m.bleach,m.component(i));
    end
    A = A * m.bleach.I0;
    
    function A = a(X,T,b,c)
        n = sqrt(4*c.D*b.m^2*T+1);
        A = 1 - b.fb / 2 * exp(-c.koff * T)  .* ...
            ( erf(b.m * (b.dx/2 - X) ./ n) + erf(b.m * (b.dx/2 + X) ./ n) );
    end

end