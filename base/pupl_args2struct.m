
function args = pupl_args2struct(inputs, defs)

if size(defs, 1) == 1
    defs = reshape(defs, 2, [])';
end

args = [];

for arg_idx = 1:2:numel(inputs)
    args.(inputs{arg_idx}) = inputs{arg_idx + 1};
end

for def_idx = 1:size(defs, 1)
    curr_def_name = defs{def_idx, 1};
    curr_def_val = defs{def_idx, 2};
    if ~isfield(args, curr_def_name)
        args.(curr_def_name) = curr_def_val;
    end
end

end