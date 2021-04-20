function EYE = readeyelinkEDF(fullpath)

EYE = [];

global pupl_globals
if pupl_globals.isoctave
    % Attempt to parse with plain Octave code
    EYE = readeyelinkEDF_oct(fullpath);
else
    % Use pre-compiled mex binaries
    EYE = readeyelinkEDF_mex(fullpath);
end

end
