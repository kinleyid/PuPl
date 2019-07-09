function ppns = getmissingppns(EYE, lims)

%   Inputs
% EYE--struct array
%   Outputs
% ppns--cell vector of numerical vectors

ppns = cell(1, numel(EYE));
for dataidx = 1:numel(EYE)
    currlims = timestr2lat(EYE(dataidx), lims);
    currppns = nan(1, numel(EYE(dataidx).epoch));
    for epochidx = 1:numel(currppns)
        abslims = EYE(dataidx).epoch(epochidx).event.latency + currlims;
        abslats = abslims(1):abslims(2);
        amtMissing = 0;
        streams = {'left' 'right'};
        for field = streams
            amtMissing = amtMissing + ...
                nnz(isnan(EYE(dataidx).diam.(field{:})(abslats)));
        end
        currppns(epochidx) = amtMissing / numel(abslats) * numel(streams);
    end
    ppns{dataidx} = currppns;
end

end