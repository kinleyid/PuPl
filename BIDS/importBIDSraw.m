
function out = importBIDSraw(rawpath, loadfunc, fmt, attachbids)

out = struct([]);

contents = dir(rawpath);
if any(strcmp({contents.name}, 'raw'))
    rawpath = fullfile(rawpath, contents(strcmp({contents.name}, 'raw')).name);
end

fprintf('Parsing BIDS folder...');
parsed = parseBIDS(rawpath, fmt);
fprintf('done');

for dataidx = 1:numel(parsed)
    fprintf('\n\tLoading %s...', parsed(dataidx).full);
    currdata = loadfunc(parsed(dataidx).full);
    currdata.src = parsed(dataidx).full;
    currdata.name = parsed(dataidx).head;
    if attachbids
        currdata.BIDS = parsed(dataidx).info;
    end
    out = cat(2, out, currdata);
end
fprintf('\nDone\n');

end