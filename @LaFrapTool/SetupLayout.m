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

    central_layout = uix.VBox('Parent',layout);

    h.ax = axes('Parent',central_layout);
    
    
    %==== Options sidebar ====
    options_panel = uipanel(layout,'Title','Options');
    ol = OptionsLayout(options_panel);

    %ol.StartGroup('Hello');

    %ol.EndGroup();

    ol.Finish();

    layout.Widths = [200 -1 200];

    obj.handles = h;

end