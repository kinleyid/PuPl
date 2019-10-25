
function out = gettrialdata(EYE, trialidx, varargin)

% Here EYE is a single struct, not an array

if isempty(trialidx)
    trialidx = 1:numel(EYE.epoch);
end

if strcmp(varargin{end}, 'both') && ~isfield(getfield(EYE, varargin{1:end-1}), varargin{end})
    % Compute "both" field on the fly
    vec = mergelr(EYE);
else
    vec = getfield(EYE, varargin{:});
end

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