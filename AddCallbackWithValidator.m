function AddCallbackWithValidator(control, callback, validator)
% Use with editbox

    control.Callback = @super_callback;

    if nargin < 3
        validator = @(x) isfinite(str2double(x));
    end
    
    control.UserData = control.String;
    
    
    function super_callback(obj,~)
       
        if ~validator(obj.String)
            obj.String = control.UserData;
        
        else
            control.UserData = obj.String;
        end
        
        callback();
    
    end
end