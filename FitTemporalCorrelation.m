function [model,fit] = FitTemporalCorrelation(t, rt1, options)

    if ~isfield(options,'fit_diffusion')
        options.fit_diffusion = true;
    end
    if ~isfield(options,'fit_flow')
        options.fit_flow = true;
    end

    t = t(:);
    rt1 = rt1(:);
    
    % Calculate mean correlation time
    rt1c = rt1;
    rt1c(rt1c<0) = 0;
    model.mean_tau = nansum(rt1c .* t) / nansum(rt1c);

    % Set up fitted variable transformation
    minval = 5;
    maxval = 20*max(t);
    function y = forward(x)
        y = 2 * (x - minval) / (maxval - minval) - 1;
        y = atanh(y);
    end
    function x = reverse(y)
        x = 0.5 * (tanh(y) + 1);
        x = x * (maxval - minval) + minval;
    end

    % Remove inf/nan
    sel = isfinite(rt1) & rt1 > 0;

    % Setup initial parameters
    x0 = [];
    if options.fit_diffusion
        x0(end+1) = model.mean_tau;
    end
    if options.fit_flow
        x0(end+1) = model.mean_tau;
    end
    
    % Fit
    y = fminsearch(@opt,forward(x0));
    [~,g,fit] = opt(y);
    
    % Extract fitted parameters
    g = g / sum(g);
    
    x = reverse(y);
    model.tau_diffusion = 0;
    model.tau_flow = 0;
    model.mobile_diffusion = 0;
    model.mobile_flow = 0;
    
    idx = 1;
    if options.fit_diffusion
        model.tau_diffusion = x(idx); 
        model.mobile_diffusion = g(idx);
        idx = idx + 1;
    end
    if options.fit_flow
        model.tau_flow = x(idx); 
        model.mobile_flow = g(idx);
        idx = idx + 1;
    end    
    model.immobile = g(idx);
    
    
    function [r,g,fit] = opt(y)
        x = reverse(y);

        X = [];
        idx = 1;
        if options.fit_diffusion
            tau_d = x(idx); idx = idx + 1;
            X(:,end+1) = 1./(1+t/tau_d);
        end
        if options.fit_flow
            tau_f = x(idx); idx = idx + 1;
            X(:,end+1) = exp(-(t/tau_f).^2);
        end
        X(:,end+1) = ones(size(t));
                
        g = lsqnonneg(X(sel,:),rt1(sel));
        fit = X*g;
        
        r = nansum((fit(sel) - rt1(sel)).^2);
    end

end