function SetupLayout(obj)
%
% Setup interface for FRAP tool
%
    obj.fh = figure('NumberTitle','off',...
                    'Name','Frap Analysis',...
                    'Menu','none',...
                    'Toolbar','none');
                
    h = struct();
    
    layout = uix.HBox('Parent',obj.fh,'Spacing',5,'Padding',5);
    
    h.files_list = uicontrol('Style','listbox','Parent',layout);
    
    right_layout = uix.VBox('Parent',layout);

    h.tab_panel = uix.TabPanel('Parent',right_layout);
        
    display_layout = uix.VBox('Parent',h.tab_panel);
    h.image_ax = axes('Parent',display_layout);
    h.image = imagesc(0,'Parent',h.image_ax);
    
    drawing_layout = uix.VBox('Parent',h.tab_panel);
    h.draw_ax = axes('Parent',drawing_layout);
    h.draw_image = imagesc(0,'Parent',h.draw_ax);
    
    h.TabNames = {'Display', 'Drawing'};
    
    h.image_scroll = uicontrol('Style','slider','Min',1,'Max',100,...
                               'Value',1,'SliderStep',[1 1],'Parent',display_layout,...
                               'Callback',@(~,~) obj.UpdateDisplay);
    display_layout.Heights = [-1 22];                      
                           
    
    h.plot_ax = axes('Parent',right_layout);
    layout.Widths = [200 -1];
    right_layout.Heights = [-3 -1];
 
    obj.handles = h;
    
end