
function selector = pupl_epoch_selector(EYE)
% Creates a struct to select epochs
%
% Input:
%   EYE: struct
%       eye data
% Output:
%   selector: struct
%       can be used to select epochs
% Example:
%   manually select epochs and get data
%   selector = pupl_epoch_selector(eye_data)
%   data = pupl_epoch_getdata(eye_data, selector)

%% Select by timelocking event attributes
selector = [];
tmp = [];
filt = pupl_epoch_selUI(EYE, 'Select by timelocking event attributes');
if isempty(filt)
    return
else
    tmp.filt = filt;
end

%% Select by epoch type
type_opts = mergefields(EYE, 'epoch', 'name');
sel = listdlgregexp(...
    'PromptString', 'Select by epoch type',...
    'ListString', type_opts,...
    'regexp', false);
if isempty(sel)
    return
else
    tmp.type = type_opts(sel);
end

%% Select by epoch set

set_opts = mergefields(EYE, 'epochset', 'name');
sel = listdlgregexp(...
    'PromptString', 'Select by epoch type',...
    'ListString', set_opts,...
    'regexp', false);
if isempty(sel)
    return
else
    tmp.set = set_opts(sel);
end

idx = inputdlg('Epoch indices:');
if isempty(idx)
    return
else
    tmp.idx = eval(idx{:});
end

selector = tmp;

end