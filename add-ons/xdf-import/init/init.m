function init

pupl_UI_addimporter(...
    'loadfunc', @readxdf,...
    'label', 'From &XDF (.xdf)')

if isempty(which('load_xdf_innerloop'))
    fprintf('compiling load_xdf_innerloop from source...')
    mex('load_xdf_innerloop.c')  
end

end