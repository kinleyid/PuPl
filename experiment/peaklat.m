function lat = peaklat(x, sr)

[~, lat] = max(x);
lat = lat / sr; % in seconds

end