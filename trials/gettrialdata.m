
function out = gettrialdata(EYE, trialidx, varargin)

if isempty(trialidx)
    trialidx = 1:numel(EYE.epoch);
end

vec = getfield(EYE, varargin{:});

out = cell(1, nnz(trialidx));
for ii = 1:numel(trialidx)
    currtrial = EYE.epoch(trialidx(ii));
    out{ii} = vec(unfold(currtrial.abslims));
    if isfield(currtrial, 'baseline')
        out{ii} = currtrial.baseline.func(out{ii}, vec(unfold(currtrial.baseline.abslims)));
    end
end

if numel(out) == 1
    out = out{:};
end

end