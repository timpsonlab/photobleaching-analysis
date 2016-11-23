function TightAxes(ax)
    for a = ax
        a.Box = 'off';
        a.TickDir = 'out';
        a.Units = 'normalized';
        ti = a.TightInset;
        a.Position = [ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]; 
    end
end