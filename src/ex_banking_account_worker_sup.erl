-module(ex_banking_account_worker_sup).
-behaviour(supervisor).

-define(NAME,?MODULE).
-export([init/1,start_link/0,create_account_worker/1]).

start_link()->
    supervisor:start_link({local,?NAME},?MODULE, []).

create_account_worker(User)->
    {ok,Pid}=supervisor:start_child(?NAME,[User]),
    {ok,Pid}.
init(_)->
    Strategy={simple_one_for_one,1,5},
    Flags=[#{
        id=>ex_banking_account_worker,
        start=>{ex_banking_account_worker,start_link,[]},
        restart=>transient,
        shutdown=>3000,
        mod=>[ex_banking_account_worker],
        type=>worker
    }],
    {ok,{Strategy,Flags}}.


