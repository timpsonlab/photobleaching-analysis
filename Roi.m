classdef Roi
    
    properties
        position;
        
        type = 'Bleached Region';
        tracked_offset = 0;
        
        untracked_recovery;
        tracked_recovery;
        
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
                if ~isempty(p_i)
                    p = [p; nan; p_i; p_i(1)];
                end
            end
            x = real(p);
            y = imag(p);
        
        end
        
        function obj = Compute(obj, data)
            p = mean(obj.position);
            obj.tracked_offset = TrackJunction(data.flow,p) - p;
           
            % Get centre of roi and stabalise using optical flow
            obj.tracked_recovery = ExtractRecovery(data.images, obj.position, obj.tracked_offset); 
            obj.untracked_recovery = ExtractRecovery(data.images, obj.position);
        end
                
    end
    
end