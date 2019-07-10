function ppns = getmissingppns(EYE, lims)

%   Inputs
% EYE--struct array
%   Outputs
% ppns--cell vector of numerical vectors

ppns = cell(1, numel(EYE));
for dataidx = 1:numel(EYE)
    if strcmp(lims, 'none')
        currlims = [];
    else
        currlims = timestr2lat(EYE(dataidx), lims);
    end
    currppns = nan(1, numel(EYE(dataidx).epoch));
    for epochidx = 1:numel(EYE(dataidx).epoch)
        if isempty(currlims)
            abslats = unfold(EYE(dataidx).epoch(epochidx).abslims);
        else
            abslims = EYE(dataidx).epoch(epochidx).event.latency + currlims;
            abslats = unfold(abslims);
        end
        amtMissing = 0;
        streams = {'left' 'right' 'both'};
        for field = streams
            amtMissing = amtMissing + ...
                nnz(isnan(EYE(dataidx).diam.(field{:})(abslats)));
        end
        currppns(epochidx) = amtMissing / numel(abslats) / numel(streams);
    end
    ppns{dataidx} = currppns;
end

end