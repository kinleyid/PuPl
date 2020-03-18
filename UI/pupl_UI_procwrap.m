
function pupl_UI_procwrap(func, varargin)

% Standard wrapper for processing functions

updateactivedata(@() pupl_feval(func, getactivedata, varargin{:}))

end