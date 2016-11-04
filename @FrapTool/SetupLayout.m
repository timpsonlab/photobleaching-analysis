function SetupLayout(obj)
%
% Setup interface for FRAP tool
%

    screen_pos = get(0,'ScreenSize');
    pos = [100 100 screen_pos(3:4) - 200];

    obj.fh = figure('NumberTitle','off',...
                    'Name','Frap Analysis',...
                    'Menu','none',...
                    'Position',pos,...
                    'Toolbar','none');
                                
    h = struct();
    
    color = [117,181,170]/255;
    
    super_layout = uix.VBox('Parent',obj.fh,'Spacing',5);
    
    layout = uix.HBox('Parent',super_layout,'Spacing',5,'Padding',5);
    
    message_layout = uix.VBox('Parent',super_layout,'Padding',3,'BackgroundColor',color);
    h.message_text = uicontrol('Style','text','Parent',message_layout,...
                               'BackgroundColor',color,'ForegroundColor','k',...
                               'FontWeight','bold','HorizontalAlignment','left',...
                               'FontSize',10,'String','Choose a dataset to load');
    MessageHandler.addListener('GarvanFrap',h.message_text);
    
    super_layout.Heights = [-1 22];
    
    
    h.files_list = uicontrol('Style','listbox','Parent',layout);
    
    h.tab_panel = uix.TabPanel('Parent',layout);
        
    % Options sidebar
    options_panel = uipanel(layout,'Title','Options');
    options_layout = uix.VBox('Parent',options_panel,'Spacing',2,'Padding',5);

    uicontrol('Style','text','String','Data','FontWeight','bold','Parent',options_layout);
    grid = uix.Grid('Parent',options_layout,'Spacing',5);    
    uicontrol('Style','text','String','Time Step (s)','Parent',grid,'Enable','inactive');
    uicontrol('Style','text','String','Pixel Size (um)','Parent',grid,'Enable','inactive');
    h.dt_edit = uicontrol('Style','edit','String','1','Parent',grid);
    h.pixel_size_edit = uicontrol('Style','edit','String','1','Parent',grid);

    grid.Widths = [100 -1];
    grid.Heights = [22 22];

    
    uicontrol('Style','text','String','Motion Compensation','FontWeight','bold','Parent',options_layout);
    grid = uix.Grid('Parent',options_layout,'Spacing',5);    
    uicontrol('Style','text','String','Drift Compensation','Parent',grid);
    uicontrol('Style','text','String','Frame Binning','Parent',grid);
    uicontrol('Style','text','String','Image Smoothing','Parent',grid);
    uicontrol('Style','text','String','Flow Smoothing','Parent',grid);
    h.drift_compensation_popup = uicontrol('Style','popupmenu','String',{'Off','On'},'Parent',grid,'Value',2);
    h.frame_binning_popup = uicontrol('Style','popupmenu','String',{'1','2','4','8','16'},'Parent',grid,'Value',4);
    h.image_smoothing_popup = uicontrol('Style','popupmenu','String',{'0','2','3','4','5','6','7','8'},'Parent',grid,'Value',5);
    h.flow_smoothing_popup = uicontrol('Style','popupmenu','String',{'1','2','3','4','5','6','7','8','9','10','11','12'},'Parent',grid,'Value',8);

    grid.Widths = [100 -1];
    grid.Heights = [22 22 22 22];
    
    h.reload_button = uicontrol('Style','pushbutton','String','Reload','Parent',options_layout);

    uix.Empty('Parent',options_layout);    
    uicontrol('Style','text','String','Photobleaching Correction','FontWeight','bold','Parent',options_layout);
    grid = uix.Grid('Parent',options_layout,'Spacing',5);    
    uicontrol('Style','text','String','Calibration','Parent',grid);
    uicontrol('Style','text','String','Correction','Parent',grid);
    h.photobleaching_status = uicontrol('Style','text','String','None Loaded','ForegroundColor','r','Parent',grid,'Value',2);
    h.photobleaching_popup = uicontrol('Style','popupmenu','String',{'Off','On'},'Enable','off','Parent',grid);

    grid.Widths = [100 -1];
    grid.Heights = [18 22];
    
    h.estimate_photobleaching_button = uicontrol('Style','pushbutton','String','Estimate Photobleaching','Parent',options_layout);
    
    
    uix.Empty('Parent',options_layout);
    options_layout.Heights = [22 120 22 120 22 30 22 60 22 -1];
    
    % Display tab
    display_layout_top = uix.HBox('Parent',h.tab_panel);
    
    display_layout = uix.VBox('Parent',display_layout_top);
    h.image_ax = axes('Parent',display_layout);
    h.image = imagesc(0,'Parent',h.image_ax);
    h.display_frap_roi = plot(h.image_ax,nan,nan,'r');
    h.display_tracked_roi = plot(h.image_ax,nan,nan,'r');

    h.image_scroll = uicontrol('Style','slider','Min',1,'Max',100,...
                               'Value',1,'SliderStep',[1 1],'Parent',display_layout,...
                               'Callback',@(~,~) obj.UpdateDisplay);

    h.recovery_ax = axes('Parent',display_layout_top);

                           
    display_layout.Heights = [-1 22];                      
    display_layout_top.Widths = [-1 -1];                      
    
    % Drawing tab
    obj.junction_artist = JunctionArtist(h.tab_panel);
    
    % Kympograph tab
    kymograph_layout = uix.VBox('Parent',h.tab_panel,'Spacing',5,'Padding',5);
    h.kymograph_select = uicontrol('Style','popupmenu','Parent',kymograph_layout,...
                                   'Callback',@(~,~) obj.UpdateKymograph);
    
    h.kymograph_ax = axes('Parent',kymograph_layout);
    h.od_glcm_ax = axes('Parent',kymograph_layout);
    
    kymograph_layout.Heights = [22 -2 -1];
    
    
    
    h.tab_panel.TabTitles = {'Display', 'Junctions', 'Kymographs'};
    h.tab_panel.TabWidth = 90;
        
    layout.Widths = [200 -1 200];
 
    obj.handles = h;
    
end