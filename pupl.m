function pupl(varargin)
% Interface to several functions
%
% Command line arguments:
%   init: initialize PuPl
%   history: print processing history
%   redraw: redraw the user interface
%   [settings/globals]: print the global settings
%   path: print PuPl's home directory
%   [save/cache]: save a copy of the current dataset to the undo/redo
%      timeline
% Example:
%   >> pupl init noweb
global pupl_globals

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
            fprintf('PuPl''s global settings and variables, as set in pupl_init.m:\n\n')
            disp(pupl_globals)
        case 'path'
            fprintf('%s\n', fileparts(mfilename('fullpath')));
        case {'save' 'cache'}
            pupl_timeline('a', evalin('base', pupl_globals.datavarname));
        otherwise
            pupl_init(args{:});
    end
end

end