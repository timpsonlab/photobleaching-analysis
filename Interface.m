function Interface(id, title, buttons)

    global feedback__

    if isempty(feedback__)
        feedback__ = struct;
    end
    
    fh = figure('ToolBar','none','Name',title,'NumberTitle','off','MenuBar','none');

    layout = uiextras.HBox('Parent',fh, 'Padding', 10, 'Spacing', 10);
    blayout = uiextras.VBox('Parent', layout, 'Spacing', 10);
    
    for i=1:length(buttons)
        AddButton(buttons{i}{1}, buttons{1}{2});
    end
    
    feedback__.(id) = struct();
    feedback__.(id).native = uicontrol('Style','edit','Max',3,'HorizontalAlignment','left','Parent',layout);
    jFeedback = findjobj(feedback__.(id).native);
    jEdit = jFeedback.getComponent(0).getComponent(0);
    feedback__.(id).java = jEdit;
    set(jEdit,'Editable',false);
    
    sizes = 50 * ones(1,length(blayout.Children));
    uiextras.Empty('Parent', blayout);
    set(blayout, 'Sizes', [sizes -1]);

    set(layout, 'Sizes', [200, -1])

    min_height = 600;
    height = max(min_height, length(buttons) * 60 + 30);
    
    pos = get(fh,'Position');
    pos(2:4) = [200,600,height];
    set(fh,'Position',pos);

    
    FeedbackMessage(id, 'Hello')
    FeedbackMessage(id, 'Please select an option')
    
    function AddButton(name, callback)
        uicontrol('Style','PushButton','String',name,'Parent',blayout,'Callback',@(~,~) CallbackWrapper(callback));
    end

    function CallbackWrapper(callback)
        if isdeployed()
            try 
                callback();
            catch e
                Feedback(id, e.message);
                errordlg([e.stack(1).file ', line ' num2str(e.stack(1).line)],e.message);
            end
        else
            callback()
            FeedbackMessage(id,'   ');
        end
    end

end