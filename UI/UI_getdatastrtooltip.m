
function txt = UI_getdatastrtooltip

shorthands = {
    '`mu' 'mean'
    '`md' 'median'
    '`mn' 'min'
    '`mx' 'max'
    '`sd' 'standard deviation'
    '`vr' 'variance'
    '`iq' 'interquartile range'
    '`madv' 'median absolute deviation'
    'n%' 'nth percentile'
    'f($)' 'function f() applied to data'
}';

txt = sprintf('You can use shorthands for statistical quantities here:\n\n');
txt = [txt sprintf('%s: %s\n', shorthands{:})];

end