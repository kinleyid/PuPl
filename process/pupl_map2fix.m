
function out = pupl_map2fix(EYE)

if nargin == 0
    out = @() [];
else
    out = sub_map2fix(EYE);
end

end

function EYE = sub_map2fix(EYE)

i = 1;
isfix = true;
islandidx = [true false(1, EYE.ndata - 1)];
% Identify consecutive fixation points
while true
    if EYE.interstices(i) == 'f'
        isfix = true;
        islandidx(i + 1) = true;
    else
        if isfix
            for fld = {'x' 'y'}
                EYE.gaze.(fld{:})(...
                    islandidx &...
                    ~isnan(EYE.gaze.(fld{:}))) = nanmean_bc(EYE.gaze.(fld{:})(islandidx));
            end
            islandidx(islandidx) = false;
        end
        isfix = false;
    end
    i = i + 1;
    if i == EYE.ndata
        break
    end
end

end