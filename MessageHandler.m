classdef (Sealed) MessageHandler < handle
   
    properties
        last_message = '';
    end
    
    events
        NewMessage; 
    end
   
    methods (Access = private)
        function obj = MessageHandler()
        end
      
        function sendMessage(obj,message)
            obj.last_message = message;
            notify(obj,'NewMessage');
            disp(message)
        end
      
    end
   
    methods (Static)
        function send(group, message)
            g = MessageHandler.get(group);
            g.sendMessage(message);
        end
        
        function singleObj = get(group)
            persistent localObj
            if isempty(localObj) || ~isstruct(localObj) || ~isfield(localObj,group)
                localObj.(group) = MessageHandler();
            end
            singleObj = localObj.(group);
        end
        
        function addListener(group, control)
            g = MessageHandler.get(group);
            addlistener(g,'NewMessage',@update);
                        
            function update(~,~)
                if isvalid(control)
                    set(control,'String',g.last_message)
                    drawnow;
                end
            end
            
        end
    end
end