function out = pupl_load(fullpath)

tmp = load(fullpath, '-mat');
% curr should be a structure with 1 field
fn = fieldnames(tmp);
out = tmp.(fn{:});

end