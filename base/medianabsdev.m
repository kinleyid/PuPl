
function out = medianabsdev(in)

out = nanmedian_bc(abs(in - nanmedian_bc(in)));

end