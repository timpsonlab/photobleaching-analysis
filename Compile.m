function Compile(exit_on_fail)

    if nargin < 1
        exit_on_fail = true;
    end
    
    if exit_on_fail
        try
            run()
        catch e
            disp(getReport(e));
            exit(1)
        end
    else
        run();
    end
            
            
    
    function run()

        GetBioformats();

        tool_name = 'Photobleaching_Analysis';
        friendly_name = 'Photobleaching Analysis';

        % Get version
        [~,ver] = system('git describe','-echo');
        ver = ver(1:end-1);
        is_release = isempty(regexp(ver,'-\d-+[a-z0-9]+','ONCE'));

        % Get GUI extras
        if ~exist('uiextras.VBox','class')
            websave('guilayout.zip','http://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/47982/versions/6/download/zip')
            unzip('guilayout.zip');
            addpath('layout');
        end

        % Build App
        try
        rmdir('build','s');
        catch
        end

        mkdir('build');
        delete(['build' filesep '*']);
        mcc('-m','RunFrapTool.m', ...
            '-a','bfmatlab', ...
            '-a',['layout' filesep '+uix'], ...
            '-v', '-d', 'build', '-o', tool_name);

        if ispc
            ext = '.exe';
        else
            ext = '.app';
        end

        new_file = [friendly_name ' ' ver ' ' computer('arch')];
        movefile(['build' filesep tool_name ext], ['build' filesep new_file ext]);

        if ismac
            mkdir(['build' filesep 'dist']);
            movefile(['build' filesep new_file ext], ['build' filesep 'dist' filesep new_file ext]);
            cmd = ['hdiutil create "./build/' new_file '.dmg" -srcfolder ./build/dist/ -volname "' new_file '" -ov'];
            system(cmd)
            final_file = ['build/' new_file '.dmg'];
        else
            final_file = ['build' filesep new_file ext];
        end

        if is_release
            dir1 = 'release';
        else 
            dir1 = 'latest';
        end
        mkdir(['build' filesep dir1]);
        mkdir(['build' filesep dir1 filesep ver]);

        movefile(final_file, ['build' filesep dir1 filesep ver]);
    end
end