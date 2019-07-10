
function pupl_exportundownsampled(EYE)

relLats = EYE(1).trialset(1).relLatencies;

bins = struct(...
    'start', sprintf('%ddp', relLats(1)),...
    'width', '0',...
    'step', '1dp',...
    'nbins', numel(relLats));

pupl_exportbinned(EYE, 'bins', bins);

end