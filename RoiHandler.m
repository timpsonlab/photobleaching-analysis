classdef RoiHandler < handle
       
    properties
        handles;
        
        roi_handle = [];

        point_mode = true;
        waiting = false;
                
        roi_callback_id;
    end
    
    properties
        roi;
    end
    
    events
        roi_updated;
    end
    
    methods
    
        function obj = RoiHandler(handles)
            obj.handles = handles;
            h = obj.handles;
            
            set(h.tool_roi_rect_toggle,'State','off');
            set(h.tool_roi_poly_toggle,'State','off');
            set(h.tool_roi_circle_toggle,'State','off');
                       
            set(h.tool_roi_rect_toggle,'OnCallback',@obj.on_callback);
            set(h.tool_roi_rect_toggle,'OffCallback',@obj.off_callback);
            
            set(h.tool_roi_poly_toggle,'OnCallback',@obj.on_callback);
            set(h.tool_roi_poly_toggle,'OffCallback',@obj.off_callback);
            
            set(h.tool_roi_circle_toggle,'OnCallback',@obj.on_callback);
            set(h.tool_roi_circle_toggle,'OffCallback',@obj.off_callback);            
        end
                        
        function on_callback(obj,src,~)
            
            if ~obj.waiting
                
                h = obj.handles;
              
                obj.waiting = true;  
                obj.point_mode = false;
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
              
                switch src
                    case h.tool_roi_rect_toggle

                        set(h.tool_roi_poly_toggle,'State','off');
                        set(h.tool_roi_circle_toggle,'State','off');

                        obj.roi_handle = imrect(h.image_ax);

                    case h.tool_roi_poly_toggle

                        set(h.tool_roi_rect_toggle,'State','off');
                        set(h.tool_roi_circle_toggle,'State','off');

                        obj.roi_handle = impoly(h.image_ax);

                    case h.tool_roi_circle_toggle

                        set(h.tool_roi_poly_toggle,'State','off');
                        set(h.tool_roi_rect_toggle,'State','off');

                        obj.roi_handle = imellipse(h.image_ax);

                end

                
                
                if ~isempty(obj.roi_handle)
                
                    addlistener(obj.roi_handle,'ObjectBeingDestroyed', @obj.roi_being_destroyed);
                    obj.roi_callback_id = addNewPositionCallback(obj.roi_handle, @obj.roi_change_callback);        
                    obj.update_mask();

                    notify(obj,'roi_updated');
                end

                obj.point_mode = true;
                obj.waiting = false;
            end
            
            set(src,'State','off');

        end
        
        function off_callback(obj,~,~)
           %set(src,'State','off');
           % if an roi is part complete then use robot framework to fire
           % esc to cancel
           if obj.waiting
               robot = java.awt.Robot;
               robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
               robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE); 
               pause(0.1);
               if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                delete(obj.roi_handle);
               end
               obj.waiting = false;
           end
        end
        
        function roi_change_callback(obj,~,~)
            obj.update_mask();
            notify(obj,'roi_updated');
        end

        function click_callback(obj,src,~)
            
            if obj.point_mode
                click_pos = get(src,'CurrentPoint');
                click_pos = click_pos(1,1:2);
                click_pos = floor(click_pos); 
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
                    
                obj.roi_handle = impoint(obj.handles.intensity_axes,click_pos);
               
                addlistener(obj.roi_handle,'ObjectBeingDestroyed',@obj.roi_being_destroyed);
                
                obj.update_mask();
                notify(obj,'roi_updated');
            end
        end
        
        function update_mask(obj)
            if ~isempty(obj.roi_handle)
                pos = obj.roi_handle.getPosition();
                
                roi_class = class(obj.roi_handle);
                switch roi_class
                    case 'imrect'
                        x = [pos(1) pos(1)        pos(1)+pos(3) pos(1)+pos(3)];
                        y = [pos(2) pos(2)+pos(4) pos(2)+pos(4) pos(2)       ];
                    
                    case 'imellipse'
                        s = linspace(0,2*pi,50);                        
                        x = 0.5 * pos(4) * sin(s) + pos(1);
                        y = 0.5 * pos(4) * cos(s) + pos(2);
                        
                    case 'impoly'
                        x = pos(:,1);
                        y = pos(:,2);
                end
                
                obj.roi = Roi(x,y);
                obj.roi.label = ['ROI ' roi_class(3:end)];
                notify(obj,'roi_updated');
                delete(obj.roi_handle);
            end
        end
            
        function roi_being_destroyed(obj,~,~)
            obj.roi_handle = [];
            if ~isempty(obj.roi_callback_id)
                try
                removeNewPositionCallback(obj.roi_handle,obj.roi_callback_id);
                catch e
                end
            end
            obj.roi_callback_id = [];
        end
        
        
    end
    
    
end