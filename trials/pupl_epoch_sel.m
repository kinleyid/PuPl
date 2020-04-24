
function [idx, eps] = pupl_epoch_sel(EYE, epochs, filter)
% Epoch selector
%
% Inputs:
%   epochs (struct array of epochs)
%   filter (epoch selector)
events = pupl_epoch_get(EYE, epochs, '_ev');
idx = pupl_event_sel(events, filter);

end
