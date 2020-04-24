
function str = pupl_epoch_units(epochs)
% Check consistency of units across epochs, get printable string

epoch_units = {epochs.units};

if numel(epoch_units) > 1
    if isequal(epoch_units{:})
        epoch_units = epoch_units{1};
    else
        epoch_units = {'size' 'inconsistent units'};
    end
else
    epoch_units = epoch_units{1};
end

str = sprintf('Pupil %s (%s, %s',...
    epoch_units{1:3});
if numel(epoch_units) > 3
    str = [str sprintf(', %s', epoch_units{4:end})];
end

str = [str ')'];

end