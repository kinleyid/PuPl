
function idx = pupl_epoch_sel(EYE, epochs, filter)

events = pupl_epoch_get(EYE, epochs, '_ev');
idx = pupl_event_sel(events, filter);

end
