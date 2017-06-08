function Compile

    addpath('matlab-ui-common','jsonlab');

    get_bioformats();
    get_gui_layout_toolbox();

    compile_function('FrapInterface.m','Photobleaching_Analysis',{'matlab-ui-common','jsonlab'});
    
end