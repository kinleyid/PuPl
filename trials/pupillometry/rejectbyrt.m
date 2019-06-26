
function rejectbyrt(EYE, varargin)

p = inputParser;
addParameter(p, 'lims', [])
parse(p, varargin{:});

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.lims)
    lims = UI_histgetrej(mergefields(EYE, 'epoch', 'event', 'rt'));
    if isempty(lims)
        return
    end
end
callstr = sprintf('''lims'', %s)', all2str(lims));

fprintf('Rejecting epochs...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    data = mergefields(EYE(dataidx), 'epoch', 'event', 'rt');
    currlims = cellfun(@(x) parsedatastr(x, data), lims);
    ninitialrejects = nnz(mergefields(EYE(dataidx), 'epoch', 'reject'));
    for epochidx = 1:numel(EYE(dataidx).epoch)
        curr_rt = EYE(dataidx).epoch(epochidx).event.rt;
        if curr_rt < currlims(1) || curr_rt > currlims(2)
            EYE(dataidx).epoch(epochidx).reject = true;
        end
    end
    ntotalrejects = nnz(mergefields(EYE(dataidx), 'epoch', 'reject'));
    nnewrejects = ntotalrejects - ninitialrejects;
    fprintf('%d new rejections; %d total\n', nnewrejects, ntotalrejects);
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end