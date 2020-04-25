function lat = diplat(x, sr)

[~, lat] = min(x);
lat = lat / sr; % in seconds

end