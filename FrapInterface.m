function handles = FrapInterface()

    if ~isdeployed
        addpath('layout','jsonlab','matlab-ui-common');
    end
    
    GetBioformats();

    screen_pos = get(0,'ScreenSize');
    pos = [100 100 screen_pos(3:4) - 200];

    handles.fh = figure('NumberTitle','off',...
                    'Name','Frap Tool',...
                    'Menu','none',...
                    'Position',pos,...
                    'Toolbar','none');

    if ispref('FrapTool','last_folder')
        last_folder = getpref('FrapTool','last_folder');
        SetLastFolder(handles.fh,last_folder);
    end

    color = [117,181,170]/255;
    
    super_layout = uix.VBox('Parent',handles.fh,'Spacing',5,'BackgroundColor',color);
    
    handles.tab_panel = uix.TabPanel('Parent',super_layout,'TabWidth',200,...
                                     'FontSize',11,'FontWeight','bold');
    
    message_layout = uix.VBox('Parent',super_layout,'Padding',3,'BackgroundColor',color);
    h.message_text = uicontrol('Style','text','Parent',message_layout,...
                               'BackgroundColor',color,'ForegroundColor','k',...
                               'FontWeight','bold','HorizontalAlignment','left',...
                               'FontSize',10,'String','Choose a dataset to load');
    MessageHandler.addListener('GarvanFrap',h.message_text);
    
    super_layout.Heights = [-1 22];
    
                
    handles.panel{1} = FrapTool(handles.tab_panel,handles.fh);
    handles.panel{2} = LaFrapTool(handles.tab_panel, handles.fh);
    handles.panel{3} = IcsTool(handles.tab_panel, handles.fh);
    
    handles.tab_panel.TabTitles = {'Data Processing', 'Spatial FRAP Analysis', 'ICS'};    
    handles.tab_listener = addlistener(handles.tab_panel,'SelectionChanged',@TabChangeCallback);
    handles.menus = handles.panel{1}.SetupMenu();
    
    function TabChangeCallback(~,evt)
        cur_tab = evt.NewValue;
        delete(handles.menus);
        handles.menus = handles.panel{cur_tab}.SetupMenu();
    end
                        
end