
function selector = pupl_epoch_selector(EYE)

%% Select by timelocking event attributes
sel = pupl_epoch_selUI(EYE, 'Select by timelocking event attributes');
tl_evs = pupl_epoch_get(EYE, [], '_tl');


%% Select by epoch type
unique({all_epochs.name});

end