-module(ex_banking_account).
-behaviour(gen_server).
-export([init/1,start_link/1]).
-export([handle_call/3,handle_info/2,handle_cast/2]).
-export([deposit/2,withdraw/2,get_balance/1]).

-record(state,{
    id,
    balance=0
}).
-define(NAME,?MODULE).
-define(MAX_REQUESTS,10).
%%%--------------------------------- API 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_link(UserId)->
    gen_server:start_link(?NAME,[UserId], []).

init([UserId])->
    {ok,#state{id=UserId,balance=0}}.

deposit(Pid,Amount)->
    gen_server:call(Pid,{deposit,Amount}).

withdraw(Pid,Amount)->
    gen_server:call(Pid, {withdraw,Amount}).

get_balance(Pid)->
    gen_server:call(Pid, get_balance).


%%%% Handlers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 
%%% 
handle_cast(_Message,State)->
    {noreply,State}.
handle_info(_Message,State)->
    {noreply,State}.

handle_call(Request,_From,State)->
    ok=check_capacity(State),
    Result=do_handle_call(Request, _From, State),
    Result.
    

do_handle_call(get_balance,_From,State)->
    timer:sleep(1000),
    {reply,{ok,State#state.balance},State};

do_handle_call({deposit,Amount},_From,State)->
    NewBalance=State#state.balance+Amount,
    {reply,{ok,NewBalance},State#state{balance=NewBalance}};
  
do_handle_call({withdraw,Amount},_From,State) when State#state.balance<Amount ->
    {reply,not_enough_money,State};

do_handle_call({withdraw,Amount},_From,State)->
    NewBalance=State#state.balance-Amount,
    {reply,{ok,NewBalance},State#state{balance=NewBalance}}.

    
check_capacity(State)->
    [{_,Size}]=process_info(self(),[message_queue_len]),
    case Size > ?MAX_REQUESTS of
        true ->  throw({reply,too_many_requests_to_user,State});
        false -> ok
    end.






