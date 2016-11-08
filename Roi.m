classdef Roi
    
    properties
        position;
        
        type;
        tracked_offset = 0;
        
        label = 'ROI';
    end
   
    methods
        
        function obj = Roi(x,y)
            if nargin < 2
                x = [];
                y = [];
            end
            x = x(:); y = y(:);
            obj.position = x + 1i * y;
        end
        
        function x = x(obj)
            x = real(obj.position);
        end
        
        function y = y(obj)
            y = imag(obj.position);
        end
        
        function p = tracked_position(obj, cur)
            offset = 0;
            if length(obj.tracked_offset) > cur
                offset = obj.tracked_offset(cur);
            end
            p = obj.position + offset;
        end
        
        function [x,y] = GetCoordsForPlot(obj, cur)

            if nargin < 2
                cur = 1;
            end
            
            p = [];
            for i=1:length(obj)
                p_i = obj(i).tracked_position(cur);
                p = [p; nan; p_i; p_i(1)];
            end
            x = real(p);
            y = imag(p);
        
        end
        
        function obj = Track(obj, flow)
            p = mean(obj.position);
            obj.tracked_offset = TrackJunction(flow,p) - p;
        end
                
    end
    
end