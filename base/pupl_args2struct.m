
function args = pupl_args2struct(inputs, defs)

for argidx = 1:size(defs, 1)
    argname = defs{argidx, 1};
    found = strcmpi(argname, inputs);
    if ~any(found)
        val = defs{argidx, 2};
    else
        val = inputs{find(found) + 1};
    end
    args.(argname) = val;
end

end