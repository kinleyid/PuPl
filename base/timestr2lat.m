
function lats = timestr2lat(EYE, str)

lats = nan(size(str));
str = cellstr(str);
for ii = 1:numel(str)
    lats(ii) = EYE.srate * parsetimestr(str{ii}, EYE.srate);
end

end