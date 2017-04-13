function SetupLayout(obj, parent, fig)
%
% Setup interface for FRAP tool
%

    obj.fh = fig;
    
    h = struct();
            
    layout = uix.HBox('Parent',parent,'Spacing',5,'Padding',5);
    
    h.files_list = uicontrol('Style','listbox','Parent',layout);
    
    h.tab_panel = uix.TabPanel('Parent',layout);
        
    %==== Display tab ====
    display_layout_top = uix.HBox('Parent',h.tab_panel,'Spacing',5);
    
    display_layout = uix.VBox('Parent',display_layout_top,'Spacing',5,'Padding',5);
    
    display_buttons_layout = uix.HBox('Parent',display_layout);
    
    load(['matlab-ui-common' filesep 'icons.mat']); 
    h.tool_roi_rect_toggle = uicontrol('Style','togglebutton','CData',rect_icon,'Parent',display_buttons_layout);
    h.tool_roi_circle_toggle = uicontrol('Style','togglebutton','CData',ellipse_icon,'Parent',display_buttons_layout);
    h.tool_roi_poly_toggle = uicontrol('Style','togglebutton','CData',poly_icon,'Parent',display_buttons_layout);
    
    uicontrol('Style','text','String','Selected ROI: ','HorizontalAlignment','right','Parent',display_buttons_layout);
    h.roi_name_edit = uicontrol('Style','edit','String','','Enable','off','Parent',display_buttons_layout);
    h.roi_type_popup = uicontrol('Style','popupmenu','String',{'Bleached Region','Photobleaching Control'},'Parent',display_buttons_layout);
    h.delete_roi_button = uicontrol('Style','pushbutton','String','Delete','Parent',display_buttons_layout);
    uix.Empty('Parent',display_buttons_layout);
    display_buttons_layout.Widths = [30 30 30 80 150 150 100 -1];
    
    h.image_ax = axes('Parent',display_layout);
    set(h.image_ax,'Units','normalized','Position',[0.02 0.02 0.94 0.94]);

    h.image = imagesc(0,'Parent',h.image_ax);

    scroll_layout = uix.HBox('Parent',display_layout);
    h.play_button = uicontrol('Style','togglebutton','String','Play','Parent',scroll_layout);
    h.image_scroll = uicontrol('Style','slider','Min',1,'Max',100,...
                               'Value',1,'SliderStep',[1 1],'Parent',scroll_layout,...
                               'Callback',@(~,~) obj.UpdateDisplay);
    h.scroll_text = uicontrol('Style','text','String','t = 0s','Parent',scroll_layout);
    scroll_layout.Widths = [100 -1 75];

    recovery_layout = uix.VBox('Parent',display_layout_top);
    h.recovery_ax = axes('Parent',recovery_layout);

    recovery_layout.Heights = [-1]; 
    display_layout.Heights = [22 -1 22];                      
    display_layout_top.Widths = [-1 -1];       
        
    %==== Drawing tab =====
    obj.junction_artist = JunctionArtist(h.tab_panel);
    
    %==== Kympograph tab ====
    kymograph_layout = uix.VBox('Parent',h.tab_panel,'Spacing',5,'Padding',5);
    h.kymograph_select = uicontrol('Style','popupmenu','Parent',kymograph_layout,...
                                   'Callback',@(~,~) obj.UpdateKymograph);
    
    h.kymograph_ax = axes('Parent',kymograph_layout);
    h.od_glcm_ax = axes('Parent',kymograph_layout);
    
    kymograph_layout.Heights = [22 -2 -1];
        
    h.tab_panel.TabTitles = {'Display', 'Junctions', 'Kymographs'};
    h.tab_panel.TabWidth = 90;
    
    %==== Options sidebar ====
    options_panel = uipanel(layout,'Title','Options');
    ol = options_layout(options_panel);

    ol.StartGroup('Data');
    h.load_option_popup = ol.AddControl('Load','Style','popupmenu','String',{'All Data','Only First'},'Value',1);
    h.channel_popup = ol.AddControl('Channel','Style','popupmenu','String',{'1'});
    h.dt_edit = ol.AddControl('Time Step (s)','Style','edit','String','1','Enable','inactive');
    h.pixel_size_edit = ol.AddControl('Pixel Size (um)','Style','edit','String','1','Enable','inactive');
    ol.EndGroup();
        
    ol.StartGroup('Motion Compensation');
    h.drift_compensation_popup = ol.AddControl('Drift Compensation','Style','popupmenu','String',{'Off','On'},'Value',1);
    h.flow_compensation_popup = ol.AddControl('Flow Compensation','Style','popupmenu','String',{'Off','On'},'Value',1);
    h.frame_binning_popup = ol.AddControl('Frame Binning','Style','popupmenu','String',{'1','2','4','8','16'},'Value',4);
    h.image_smoothing_popup = ol.AddControl('Image Smoothing','Style','popupmenu','String',{'0','2','3','4','5','6','7','8'},'Value',5);
    h.flow_smoothing_popup = ol.AddControl('Flow Smoothing','Style','popupmenu','String',{'1','2','3','4','5','6','7','8','9','10','11','12'},'Value',8);
    h.reload_button = ol.AddButton('String','Reload');
    ol.EndGroup();        
    
    ol.StartGroup('Photobleaching Correction');
    h.photobleaching_status = ol.AddControl('Calibration','Style','text','String','None Loaded','ForegroundColor','r','Value',2);
    h.photobleaching_popup = ol.AddControl('Correction','Style','popupmenu','String',{'Off','On'},'Enable','off');
    h.estimate_photobleaching_button = ol.AddButton('String','Estimate Photobleaching');
    ol.EndGroup();

    ol.StartGroup('Junctions');
    h.junction_width = ol.AddControl('Width (px)','Style','edit','String','9');
    ol.EndGroup();
    
    ol.Finish();
    
    
    layout.Widths = [200 -1 200];
    obj.handles = h;
    
end