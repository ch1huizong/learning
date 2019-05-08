%%%============================================================
%%%
%%% 框架的主要通用部分
%%% 
%%%============================================================
-module(gws_server).
-behaviour(gen_server).

-export([start_link/3]).

% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-record(state, {lsock, socket, request_line, headers = [],
                body = <<>>, content_remaining = 0,
                callback, user_data, parent}).

%%%============================================================
%%%  API部分
start_link(Callback,LSock, UserArgs) -> 
    gen_server:start_link(?MODULE, [Callback,LSock, UserArgs, self()], []).


%%%============================================================
%%% 回调部分
init([Callback, LSock, UserArgs, Parent]) -> 
    {ok, UserData} = Callback:init(UserArgs),
    State = #state{lsock = LSock, callback = Callback,
                    user_data = UserData, parent = Parent},
    {ok, State, 0}.

handle_call(Msg, _From, State) -> 
    {reply, {ok, Msg}, State}.

handle_cast(_Request, State) -> 
    {noreply, State}.

terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info({http,_Sock, {http_request, _, _, _} = Request}, State) ->
    inet:setopts(State#state.socket, [{active, once}]),
    {noreply, State#state{request_line = Request}};
handle_info({http,_Sock,{http_header, _, Name, _, Value}}, State) ->
    inet:setopts(State#state.socket, [{active, once}]),
    {noreply, header(Name, Value,State)};
handle_info({http, _Sock, http_eoh},
            #state{content_remaining = 0} = State) ->
    {stop, normal, handle_http_request(State)};
handle_info({http, _Sock, http_eoh}, State) ->
    inet:setopts(State#state.socket, [{active, once}, {packet, raw}]), % 设置为raw模式了,接受数据
    {noreply, State};
handle_info({tcp, _Sock, Data}, State) when is_binary(Data) ->
    ContentRem = State#state.content_remaining - byte_size(Data),
    Body = list_to_binary([State#state.body, Data]),
    NewState = State#state{body = Body, content_remaining = ContentRem},
    if 
        ContentRem > 0 ->
            inet:setopts(State#state.socket, [{active, once}]),
            {noreply, NewState};
        true ->
            {stop, normal, handle_http_request(NewState)} % 何时调用？ 与下一个分支顺序？
    end;
handle_info({tcp_closed, _Sock}, State) ->  % 还会调用你吗？
    {stop, normal, State};
handle_info(timeout, #state{lsock = LSock, parent = Parent} = State) ->
    {ok, Socket} = gen_tcp:accept(LSock),
    gws_connection_sup:start_child(Parent),
    inet:setopts(Socket, [{active, once}]),
    {noreply, State#state{socket = Socket}}.


%%%============================================================
%%% 内部函数，解析
header('Content-Length' = Name, Value, State) ->            % 怎么会是字符串？
    ContentLength = list_to_integer(binary_to_list(Value)),
    State#state{ content_remaining = ContentLength,
                headers = [{Name, Value} | State#state.headers]};
header(<<"Expect">> = Name, <<"100-continue">> = Value, State) ->
    gen_tcp:send(State#state.socket, gen_web_server:http_reply(100)),   % 给客户端发继续响应
    State#state{headers = [{Name, Value} | State#state.headers]};
header(Name, Value, State) ->
    State#state{headers = [{Name, Value} | State#state.headers]}.

handle_http_request(#state{ callback     = Callback,
                            request_line = Request,
                            headers      = Headers,
                            body         = Body,
                            user_data    = UserData } = State) ->
    {http_request, Method, _, _} = Request,
    Reply = dispatch(Method, Request, Headers, Body, Callback, UserData),
    gen_tcp:send(State#state.socket, Reply),
    State.

%%%============================================================
%%% 与回调模块对接
dispatch('GET', Request, Headers, _Body, Callback, UserData) ->
    Callback:get(Request, Headers, UserData);
dispatch('DELETE', Request, Headers, _Body, Callback, UserData) ->
    Callback:delete(Request, Headers, UserData);
dispatch('HEAD', Request, Headers, _Body, Callback, UserData) ->
    Callback:head(Request, Headers, UserData);
dispatch('POST', Request, Headers, _Body, Callback, UserData) ->
    Callback:post(Request, Headers, UserData);
dispatch('PUT', Request, Headers, _Body, Callback, UserData) ->
    Callback:put(Request, Headers, UserData);
dispatch('TRACE', Request, Headers, _Body, Callback, UserData) ->
    Callback:trace(Request, Headers, UserData);
dispatch('OPTIONS', Request, Headers, _Body, Callback, UserData) ->
    Callback:options(Request, Headers, UserData);
dispatch(_Other, Request, Headers, _Body, Callback, UserData) ->
    Callback:other_method(Request, Headers, UserData).
