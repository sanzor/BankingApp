%%%-------------------------------------------------------------------
%% @doc ex_banking public API
%% @end
%%%-------------------------------------------------------------------
-module(ex_banking_app).
-behaviour(application).
-export([start/2, stop/1]).


-define(FU(Key,List),proplists:get_value(Key, List)).


%%====================================================================
%% API
%%====================================================================
start({failover,Node},Args)->
    io:format("Failover  ~p",[Node]),
    ex_banking_main_sup:start_link();   
start({takeover,Node},Args)->
    io:format("Takeover from: ~p",[Node]),
    ex_banking_main_sup:start_link();
start(_StartType, _StartArgs)->
    io:format("\nStarting normal\n"),
    {ok,Pid}=ex_banking_main_sup:start_link(),
    {ok,Pid}.
stop(_State) ->
    ok.

    
