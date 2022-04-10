
function pupl_UI_addimporter(varargin)

global pupl_globals
if isgraphics(pupl_globals.UI)
    
    args = pupl_args2struct(varargin, {
        'label' ''
        'type' 'eye' % For convenience
    });
    switch args.type
        case 'eye'
            tags = {'pupl:import-eye' 'pupl:bids-import-event'};
        case 'event'
            tags = {'pupl:import-event' 'pupl:bids-import-event'};
    end
    
    args_to_pupl_import = rmfield(args, 'label');
    args_to_pupl_import = pupl_struct2args(args_to_pupl_import);
    
    for tag = tags
        if strcontains(tag{:}, 'BIDS')
            usebids = true;
        else
            usebids = false;
        end
        switch args.type
            case 'eye'
                uimenu(findobj(pupl_globals.UI, 'Tag', tag{:}),...
                    'Label', args.label,...
                    'Callback', @(h, e)...
                        appendtodata(@() pupl_import(...
                            args_to_pupl_import{:},...
                            'bids', usebids),...
                            'import data'));
            case 'event'
                uimenu(findobj(pupl_globals.UI, 'Tag', tag{:}),...
                    'Label', args.label,...
                    'Callback', @(h, e)...
                        updateactivedata(@() pupl_import(...
                            args_to_pupl_import{:},...
                            'eyedata', getactivedata,...
                            'bids', usebids),...
                            'import event logs'));
        end
    end

end