
function pupl_UI_addimporter(varargin)

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
        uimenu(findobj(pupl_globals.UI, 'Tag', tag{:}),...
            'Label', args.label,...
            'Callback', @(h, e)...
                appendtodata(@() pupl_importraw(...
                    'loadfunc', args.loadfunc,...
                    'usebids', usebids,...
                    args.argsto_pupl_importraw{:})));
    end

end