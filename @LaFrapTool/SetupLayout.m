function SetupLayout(obj, parent, fig)

    obj.fh = fig;
    layout = uix.HBox('Parent',parent,'Spacing',5,'Padding',5);

    %==== Files  ====
    files_layout = uix.VBox('Parent',layout);
    button_layout = uix.HBox('Parent',files_layout);
    h.add_button = uicontrol('Style','pushbutton','String','Add','Parent',button_layout);
    h.remove_button = uicontrol('Style','pushbutton','String','Remove','Parent',button_layout);
    h.files_list = uicontrol('Style','listbox','Parent',files_layout,'Min',0,'Max',2);
    files_layout.Heights = [30 -1];

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
    ol = OptionsLayout(options_panel);

    ol.StartGroup('Resampling');
    h.distance_edit = ol.AddControl('Distance (um)','Style','edit','String',{'10.0'});
    h.max_time_edit = ol.AddControl('Duration (s)','Style','edit','String',{'500'});
    ol.EndGroup();

    ol.StartGroup('Plotting');
    h.spatial_display_popup = ol.AddControl('Show spatial','Style','popupmenu','String',{'Data','Fitted'});
    h.include_outliers_popup = ol.AddControl('Scale outliders','Style','popupmenu','String',{'No','Yes'});
    ol.EndGroup();
    
    params.names = {'dx','fb','x0','I0','m'};
    params.initial_values = {3, 0.8, 0, 1, 1};
    params.lim_min = {1, 0, -5, 0, 0.1};
    params.lim_max = {5, 1, 5, 1.5, 30};
    params.fit = {false, true, true, true, true};

    l = ol.StartCustomGroup('Bleach Fitting');
    h.bleach_param_table = FitParameterTable(l, params);
    ol.SetLastControlHeight(120);
    ol.EndGroup();
    
    params.names = {'If','D','koff1','koff2','kf1','k_bleach'};
    params.initial_values = {0.5, 0.01, 0.01, 0.001, 1, 0};
    params.lim_min = {0, 0, 0, 0, 0, 0};
    params.lim_max = {1, 1, 1, 1, 1, 1};
    params.fit = {true, true, true, false, false, true};

    l = ol.StartCustomGroup('Recovery Fitting');
    h.recovery_param_table = FitParameterTable(l, params);
    ol.SetLastControlHeight(120);
    h.fit_button = ol.AddButton('String','Fit');    
    ol.EndGroup();

    l = ol.StartCustomGroup('Fit Results');
    h.fit_table = uitable('Parent',l);
    ol.SetLastControlHeight(150);
    ol.EndGroup();
    
    ol.Finish();

    layout.Widths = [200 -1 300];

    obj.handles = h;

end