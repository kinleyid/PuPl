
function out = nanvar_bc(varargin)

% Old Matlab: var(_, 'omitnan') doesn't exist
% New Matlab: nanvar() costs extra

try
    out = nanvar(varargin{:});
catch
    out = var(varargin{:}, 'omitnan');
end

end
    