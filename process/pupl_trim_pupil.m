
function out = pupl_trim_pupil(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    args = parseargs(varargin{:});
    out = pupl_proc(EYE, @(x) sub_trim_pupil(x, args.lims));
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'lims' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.lims)
    alldata = {};
    allnames = {};
    for dataidx = 1:numel(EYE)
        for side = {'left' 'right'}
            alldata{end + 1} = EYE(dataidx).pupil.(side{:});
            allnames{end + 1} = sprintf('%s %s pupil %s', EYE(dataidx).name, side{:}, EYE(dataidx).units.pupil{1});
        end
    end
    args.lims = UI_histgetrej(alldata,...
        'dataname', sprintf('Pupil %s (%s, %s)', EYE(1).units.pupil{:}),...
        'names', allnames);
    if isempty(args.lims)
        return
    end
end

outargs = args;

end

function data = sub_trim_pupil(data, lims)

lims = cellfun(@(x) parsedatastr(x, data), lims);

data(data < lims(1) | data > lims(2)) = nan;

end
