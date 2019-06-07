
function out = nanstat(stat, varargin)

% Old Matlab: <stat>(_, 'omitnan') doesn't exist
% New Matlab: nan<stat>() costs extra

try
    eval('out = nan%s(varargin{:});', stat);
catch
    eval('out = %s(varargin{:}, ''omitnan'');', stat);
end

end