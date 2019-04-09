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
    h.glcm_ax = axes('Parent',p(2));
    h.ics_ax = axes('Parent',p(3));
    
    TightAxes([h.image_ax h.glcm_ax h.ics_ax]);
        
    %==== Options sidebar ====
    options_panel = uipanel(layout,'Title','Options');
    ol = options_layout(options_panel);

    ol.StartGroup('Time steps');
    h.time_interval_edit = ol.AddControl('Time step (s)','Style','edit','String',{'-'});
    h.temporal_downsampling_edit = ol.AddControl('Downsampling','Style','edit','String',{'1'});
    ol.EndGroup();
    
    ol.StartGroup('ICS');
    h.max_time_edit = ol.AddControl('Max time (s)','Style','edit','String',{'500'});
    h.fit_diffusion_popupmenu = ol.AddControl('Fit Diffusion','Style','popupmenu','String',{'Yes','No'});
    h.fit_flow_popupmenu = ol.AddControl('Fit Flow','Style','popupmenu','String',{'Yes','No'});
    ol.EndGroup();

    ol.StartGroup('OD-GLCM');
    h.max_distance_edit = ol.AddControl('Max distance (um)', 'Style', 'edit', 'String', {'2.5'});
    h.glcm_lim_edit = ol.AddControl('Intensity (DN)', 'Style', 'edit', 'String', {'2000'});
    ol.EndGroup();
    
    ol.Finish();

    layout.Widths = [200 -1 300];

    obj.handles = h;

end