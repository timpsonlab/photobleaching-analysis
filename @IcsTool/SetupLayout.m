function SetupLayout(obj, parent, fig)

    obj.fh = fig;
    layout = uix.HBox('Parent',parent,'Spacing',5,'Padding',5);

    %==== Files  ====
    h = struct();    
    h = obj.AddFilesLayout(layout, h);

    central_layout = uix.VBox('Parent',layout,'Spacing',5,'Padding',5,'BackgroundColor','w');
    p(1) = uipanel('Parent',central_layout,'BorderType','none','BackgroundColor','w');
    
    bottom_layout = uix.HBox('Parent',central_layout,'Spacing',5,'BackgroundColor','w');
    p(2) = uipanel('Parent',bottom_layout,'BorderType','none','BackgroundColor','w');
    p(3) = uipanel('Parent',bottom_layout,'BorderType','none','BackgroundColor','w');

    
    h.image_ax = axes('Parent',p(1));
    h.profile_ax = axes('Parent',p(2));
    h.fit_ax = axes('Parent',p(3));
    
    TightAxes([h.image_ax h.profile_ax h.fit_ax]);
        
    %==== Options sidebar ====
    options_panel = uipanel(layout,'Title','Options');
    ol = options_layout(options_panel);

    ol.StartGroup('Limits');
    h.max_time_edit = ol.AddControl('Max Time (s)','Style','edit','String',{'500'});
    ol.EndGroup();
    
    ol.Finish();

    layout.Widths = [200 -1 300];

    obj.handles = h;

end