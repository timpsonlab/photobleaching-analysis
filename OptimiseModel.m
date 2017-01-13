function [model,fval,fitted] = OptimiseModel(model, fields, lb, ub, x, t, data, fcn, use_global)

    vars0 = zeros(1,length(fields));
    for j=1:length(fields)
        vars0(j) = model.(fields{j});
    end
    
    evals = 0;
    
    if use_global
        opts = optimoptions(@fmincon,'Algorithm','interior-point');
        problem = createOptimProblem('fmincon','objective',...
        @evalmodel,'x0',vars0,'lb',lb,'ub',ub,'options',opts);
        ms = MultiStart('UseParallel',true,'Display','iter');    
        gs = GlobalSearch;
        [vars,fval] = run(ms,problem,50)
    else
        opts = optimoptions('fmincon','MaxFunEvals',5000,'MaxIter',5000,...
           'OptimalityTolerance',1e-10,...
           'StepTolerance',1e-10);
        [vars,fval] = fmincon(@evalmodel,vars0,[],[],[],[],lb,ub,[],opts);
    end
    
    
    for j=1:length(fields)
        model.(fields{j}) = vars(j);
    end
    
    fitted = [];
    evalmodel(vars,false);
    
    function R = evalmodel(vars,display)
        
        if nargin < 2
           display = false;
        end
        
        m = model;
        for i=1:length(fields)
            m.(fields{i}) = vars(i);
        end
        
        A = fcn(m,x,t);
        fitted = A;
        R = (A - double(data)).^2;
        R = nanmean(R(:));
   
        if mod(evals,200) == 0 || display
            if length(t) == 1
                plot(x,A);
                hold on;
                plot(x,data);
                hold off;
            else
                imagesc(t,x,A);
                colorbar
                caxis([0 1.2])
                drawnow
            end
        end

        evals = evals + 1;        
    end

end