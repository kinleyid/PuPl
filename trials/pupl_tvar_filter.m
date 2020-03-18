
function idx = pupl_tvar_filter(events, filter)

idx = false(size(events));
for eidx = 1:numel(events)
    if eval(regexprep(filter, '#', 'events(eidx).var.'))
        idx(eidx) = true;
    end
end

end
