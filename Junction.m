classdef Junction < handle

    properties
        positions;
        type;
    end
    
    properties(Transient)
        tracked_positions;
        handle;
    end

    properties(Constant)
        types = {'Bleach','Adjacent','Distant'};
        junction_color = {[1 0 0],[0 1 0],[0 0 1]};
    end

    methods

        function obj = Junction(ax,type)
            obj.type = type;
            obj.CreatePlot(ax);
        end

        function CreatePlot(obj,ax)
            
            if isempty(obj.positions)
                p = nan;
            else
                p = obj.positions;
            end
            
            obj.handle = plot(ax,real(p),imag(p),...
                'Marker','o',...
                'MarkerSize',7,...
                'Color',obj.junction_color{obj.type},...
                'LineStyle','-',...
                'MarkerFaceColor',obj.junction_color{obj.type});            
        end
        
        function AddPosition(obj,p)
            obj.positions(end+1) = p;
            obj.UpdateLine();
        end

        function RemoveLastPosition(obj)
            if ~isempty(obj.positions)
                obj.positions(end) = [];
                obj.UpdateLine();
            end
        end

        function d = ShortestDistanceToPosition(obj,p)
            d = abs(obj.positions - p);
            d = min(d);
            if isempty(d)
                d = inf;
            end
        end

        function UpdateLine(obj)
            set(obj.handle,'XData',real(obj.positions),'YData',imag(obj.positions));
        end
        
        function tracked = IsTracked(obj)
            tracked = ~isempty(obj.tracked_positions);
        end
        
        function empty = IsEmpty(obj)
            empty = isempty(obj.positions);
        end

        function delete(obj)
            if ~isempty(obj.handle)
                delete(obj.handle);
            end
        end

    end
end