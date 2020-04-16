
function out = pupl_trim_pupil(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_trim_pupil(EYE, varargin{:});
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
            if isfield(EYE(dataidx).pupil, side{:})
                alldata{end + 1} = EYE(dataidx).pupil.(side{:});
                allnames{end + 1} = sprintf('%s %s pupil %s', EYE(dataidx).name, side{:}, EYE(dataidx).units.pupil{1});
            end
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
fprintf('Valid pupil size measurements are between %s and %s\n', args.lims{:});

end

function EYE = sub_trim_pupil(EYE, varargin)

args = parseargs(varargin{:});

if isgraphics(gcbf)
    fprintf('\n');
end

for field = reshape(fieldnames(EYE.pupil), 1, [])
    data = EYE.pupil.(field{:});
    lims = cellfun(@(x) parsedatastr(x, data), args.lims);
    badidx = data <= lims(1) | data >= lims(2);
    badidx = badidx & ~isnan(data);
    fprintf('\t\t%s:\t%f%% previously extant data removed\n', field{:}, 100*nnz(badidx)/numel(badidx))
    data(badidx) = nan;
    EYE.pupil.(field{:}) = data;
    EYE.gaze.x(badidx) = nan;
    EYE.gaze.y(badidx) = nan;
end

end
