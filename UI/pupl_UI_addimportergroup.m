
function pupl_UI_addimportergroup(varargin)

global pupl_globals
if isgraphics(pupl_globals.UI)
    
    args = pupl_args2struct(varargin, {
        'loadfunc' []
        'label' 'Mystery format'
        'type' 'eye' % For convenience
        'argstoself' {} % Also for convenience
        'argsto_pupl_importraw' {}
    });
    args.argsto_pupl_importraw = [args.argsto_pupl_importraw {'type' args.type}];
    if ~isempty(args.argstoself)
        args.argsto_pupl_importraw = [args.argsto_pupl_importraw {'args' args.argstoself}];
    end
    switch args.type
        case 'eye'
            tags = {'importEyeDataMenu' 'BIDSimportEyeDataMenu'};
        case 'event'
            tags = {'importEventLogsMenu' 'BIDSimportEventLogsMenu'};
    end

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
                            'loadfunc', args.loadfunc,...
                            'bids', usebids,...
                            args.argsto_pupl_importraw{:})));
            case 'event'
                uimenu(findobj(pupl_globals.UI, 'Tag', tag{:}),...
                    'Label', args.label,...
                    'Callback', @(h, e)...
                        updateactivedata(@() pupl_import(...
                            'eyedata', getactivedata,...
                            'loadfunc', args.loadfunc,...
                            'bids', usebids,...
                            args.argsto_pupl_importraw{:})));
        end
    end

end