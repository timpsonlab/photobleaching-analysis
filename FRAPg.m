function A = FRAPg(m,x,t)

    if nargin < 1
        m = struct();
        
        m.I0 = 1; % inital intensity
        m.fb = 0.8; % bleach fraction
        m.m = 10; % steepness of edges
        m.dx = 3.0; % extent of bleach region
        m.x0 = 0; % bleach centre
        
        m.If = 0.5; % immobile fraction
        m.D = 0.01; % Diffusion coefficent
        m.koff1 = 0.001; % Transport rate 1
        m.koff2 = 0.001; % Transport rate 2
        m.kf1 = 0.5;
        
        m.k_bleach = 0;
        
        x = linspace(-5,5,100);
        t = linspace(0,400,200);
    end
        
    x = x - m.x0;
    [T,X] = meshgrid(t,x);
    
    A = (1-m.If) * a(X,T) + m.If * a(X,zeros(size(T)));
    A = A * m.I0;
    
    function A = a(X,T)
        n = sqrt(4*m.D*m.m^2*T+1);
        A = 1 - m.fb / 2 * (m.kf1 * exp(-m.koff1 * T) + (1-m.kf1) * exp(-m.koff2 * T))  .* ...
            ( erf(m.m * (m.dx/2 - X) ./ n) + erf(m.m * (m.dx/2 + X) ./ n) );
        A = A .* exp(-T * m.k_bleach);
    end

end