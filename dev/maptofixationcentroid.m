
function EYE = maptofixationcentroid(EYE)

callstr = sprintf('eyeData = %s(eyeData)', mfilename);
for dataidx = 1:numel(EYE)
    i = 1;
    isf = true;
    islandidx = [true false(1, EYE(dataidx).ndata - 1)];
    % Identify consecutive fixation points
    while true
        if EYE(dataidx).datalabel(i) == 'f'
            isf = true;
            islandidx(i + 1) = true;
        else
            if isf
                for fld = {'x' 'y'}
                    EYE(dataidx).gaze.(fld{:})(...
                        islandidx &...
                        ~isnan(EYE(dataidx).gaze.(fld{:}))) = mean(EYE(dataidx).gaze.(fld{:})(islandidx), 'omitnan');
                end
                islandidx(islandidx) = false;
            end
            isf = false;
        end
        i = i + 1;
        if i == EYE(dataidx).ndata
            break
        end
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end

end