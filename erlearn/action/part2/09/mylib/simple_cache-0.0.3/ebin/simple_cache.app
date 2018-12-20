{application, simple_cache,
    [
    {description, "A simple caching system"},
    {vsn, "0.0.3"},
    {modules, [
                simple_cache,
                sc_app, 
                sc_sup,
                sc_element_sup,
                sc_store,
                sc_element,
                sc_event,
                sc_event_logger ]},
                
    {registered, [sc_sup]},
    {applications, [kernel, sasl, stdlib, mnesia, resource_discovery]},   % 新依赖项
    {mod, {sc_app, []}}
    ] 
}.

