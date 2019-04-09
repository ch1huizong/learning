%%% ------------------------------------------------------------
%%% @author ch1huizong ch1huizong@gmail.com 
%%% 
%%% @copyright 2019-3-14 ch1huizong
%%% @doc RPC OVer TCP server.This module defines a server process
%%%     that listens for incoming TCP connections and allows the
%%%     user to execute RPC commands via that TCP stream.
%%% @end
%%% ------------------------------------------------------------

-module(tr_server).

-behaviour(gen_server).

-export([start_link/1, start_link/0, get_count/0, stop/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
        terminate/2, code_change/3]). 

-include_lib("eunit/include/eunit.hrl").
-define(SERVER, ?MODULE).
-define(DEFAULT_PORT, 1055).

-record(state, {port, lsock, request_count=0}).


%%%============================================================
%%% User API
%%%============================================================

%%-------------------------------------------------------------
%% @doc Starts the server.
%%
%% @spec start_link(Port::integer()) -> {ok, Pid}.
%% where 
%%  Pid = pid()
%% @end
%%-------------------------------------------------------------
start_link(Port) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Port],[]).

start_link() ->
    start_link(?DEFAULT_PORT).

%%-------------------------------------------------------------
%% @doc Fetches the number of requests made to this server
%% @spec get_count() -> {ok, Count}
%% where
%%  Count = integer()
%% @end
%%-------------------------------------------------------------
get_count() ->
    gen_server:call(?SERVER, get_count).

%%-------------------------------------------------------------
%% @doc Stops the server.
%% @spec stop() -> ok
%% @end
%%-------------------------------------------------------------
stop() ->
    gen_server:cast(?SERVER, stop).


%%%============================================================
%%% gen_server callbacks
%%%============================================================

init([Port]) ->
    {ok, LSock} = gen_tcp:listen(Port, [{active,true}]),
    {ok, #state{port = Port, lsock = LSock}, 0}.

handle_call(get_count, _From, State) ->
    {reply, {ok, State#state.request_count}, State}.

handle_cast(stop, State) ->
    {stop, normal, State}.

terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info({tcp, Socket, RawData}, State) ->
    do_rpc(Socket, RawData),
    RequestCount = State#state.request_count,
    {noreply, State#state{request_count = RequestCount + 1}}; % 创建新的state

handle_info(timeout, #state{lsock = LSock} = State) ->
    {ok, _Sock} = gen_tcp:accept(LSock),    %% 会一直阻塞与此
    {noreply, State}.


%%%============================================================
%%% Internal functions
%%%============================================================

do_rpc(Socket, RawData) ->
    try
        {M, F, A} = split_out_mfa(RawData),
        Result = apply(M, F, A),
        gen_tcp:send(Socket, io_lib:fwrite("~p~n",[Result]))
    catch 
        _Class:Err ->
            gen_tcp:send(Socket, io_lib:fwrite("~p~n",[Err]))
    end.


split_out_mfa(RawData) ->   % 解析请求
    MFA = re:replace(RawData, "\r\n$", "",[{return, list}]), %% 去除回车换行
    {match, [M, F, A]} =
        re:run(MFA,
            "(.*):(.*)\s*\\((.*)\s*\\)\s*.\s*$",
            [{capture, [1,2,3], list}, ungreedy]),
    {list_to_atom(M), list_to_atom(F), args_to_terms(A)}.


args_to_terms(RawArgs) -> % 解析参数
    {ok, Toks, _Line} = erl_scan:string("[" ++ RawArgs ++ "]. ", 1), % 加一个空格？
    {ok, Args} = erl_parse:parse_term(Toks),
    Args.


%% 测试
start_test() ->
    {ok, _} = tr_server:start_link(1055).
