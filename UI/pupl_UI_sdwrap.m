
function pupl_UI_sdwrap(func, varargin)

% Standard wrapper for processing functions

updateactivedata(@() pupl_applytoarray(func, getactivedata, varargin{:}))

end