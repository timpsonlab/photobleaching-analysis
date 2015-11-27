function FeedbackMessage(id, message, type)

    global feedback__
    
    if ~isempty(feedback__) && isstruct(feedback__) ...
       && isfield(feedback__,id) && ishandle(feedback__.(id).native)
       
        f = feedback__.(id);
        text = get(f.native,'String');
        if isempty(text)
            text = {message};
        else
            text = [text; message];
        end
        set(f.native,'String',text);
        drawnow;
        
        f.java.setCaretPosition(f.java.getDocument.getLength);
    end
    
    disp(message);
       
end