
function pupl_UI_procwrap(func, varargin)

% Standard wrapper for processing functions

% Get text description to be added to the undo/redo timeline
if iscell(func)
    timeline_txt = help(func2str(func{:}));
else
    timeline_txt = help(func2str(func));
end
sol = find(timeline_txt ~= (' '), 1);
eol = find(timeline_txt == sprintf('\n'), 1) - 1;
timeline_txt = timeline_txt(sol:eol);
timeline_txt(1) = lower(timeline_txt(1));


updateactivedata(@() pupl_feval(func, getactivedata, varargin{:}), timeline_txt);

end