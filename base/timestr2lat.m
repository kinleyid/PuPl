
function lats = timestr2lat(EYE, str)

str = cellstr(str);
lats = nan(size(str));
str = cellstr(str);
for ii = 1:numel(str)
    lats(ii) = round(EYE.srate * parsetimestr(str{ii}, EYE.srate));
end

end