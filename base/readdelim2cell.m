
function [out, header] = readdelim2cell(fullpath, delim, varargin)

if numel(varargin) == 1
    comment = varargin{1};
else
    comment = '#';
end

fid = fopen(fullpath);
% Read header
header = {};
while ~feof(fid)
    endofheader = ftell(fid);
    currline = fgetl(fid);
    if strcmp(currline(1:numel(comment)), comment)
        header(end+1) = {currline(3:end)};
    else
        break
    end
end

eol = sprintf('\n');
d = sprintf(delim);

% Determine number of columns
fseek(fid, endofheader, 'bof');
currline = fgetl(fid);
currline = strrep(currline, eol, d);
currline = stringsplit(currline, delim);
ncols = numel(currline);

% Read raw
fseek(fid, endofheader, 'bof');
out = fread(fid, 'uint8=>char')';
fclose(fid);

out = strrep(out, eol, d); % Get it all as one line, replacing newlines with delimiters
out = stringsplit(out, d); % Get cell array
out(end-mod(numel(out), ncols)+1:end) = []; % Future source of bugs
out = reshape(out, ncols, [])';

end