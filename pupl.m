function pupl(varargin)

args = lower(varargin);

if isempty(args)
    pupl_init;
else
    switch args{1}
        case 'init'
            pupl_init(args{2:end});
        case 'history'
            pupl_history;
        case 'redraw'
            update_UI;
        case {'settings' 'globals'}
            global pupl_globals
            fprintf('PuPl''s global settings and variables, as set in pupl_init.m:\n\n')
            disp(pupl_globals)
        case 'path'
            fprintf('%s\n', fileparts(mfilename('fullpath')));
        otherwise
            fprintf('Unrecognized command line argument ''%s''\n', args{1});
    end
end

end