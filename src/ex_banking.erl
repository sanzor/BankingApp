-module(ex_banking).
-behaviour(gen_server).

-define(SERVER,?MODULE).
-export([handle_call/3,handle_cast/2,init/1,start_link/0]).
-export([create_user/1,deposit/3,withdraw/3,get_balance/2,send/4]).

%----------------------------------------------------------------------------------
%--------------------Banking  API--------------------------------------------------
%----------------------------------------------------------------------------------
% 


start_link()->
    gen_server:start_link({local,?SERVER}, ?MODULE,[], []).


-spec create_user(User :: string())-> ok | {error, wrong_arguments} | user_already_exists.
create_user(User) when not is_list(User) , not is_atom(User)->{error,wrong_arguments};
create_user(User)->
    gen_server:call(?SERVER, {create_user,User}).
            
           



-spec get_balance(User :: string(), Currency :: string()) 
                  -> {ok, Balance::number()} | {error, wrong_arguments }| 
                        user_does_not_exist | too_many_requests_to_user.
get_balance(User,Currency)->
    gen_server:call(?SERVER, {get_balance,{User,Currency}}).
            



-spec deposit(User :: string(),
              Amount :: number(), 
              Currency :: string())->  {ok, New_balance::number()} |
                                       {error,wrong_arguments} | 
                                       user_does_not_exist | 
                                       too_many_requests_to_user.
deposit(_User,Amount,Currency) when 
                not is_number(Amount) or 
                (is_number(Amount) andalso Amount<0) or
                not (is_atom(Currency) or is_list(Currency))->{error,wrong_arguments};


deposit(User,Amount,Currency)->
    gen_server:call(?SERVER, {deposit,{User,Amount,Currency}}).
           




-spec withdraw( User :: string(), Amount :: number(), Currency :: string()) -> 
                                       {ok, New_balance :: number()} |
                                       {error, wrong_arguments} | 
                                       user_does_not_exist | 
                                       not_enough_money | 
                                       too_many_requests_to_user.
withdraw(_User,Amount,Currency) when 
                            not is_number(Amount) or 
                            not (is_atom(Currency) or is_list(Currency))->{error,wrong_arguments};
                    
withdraw(User,Amount,Currency)->
    gen_server:call(?SERVER, {withdraw,{User,Amount,Currency}}).
           
            


-spec send(From_User :: string(), To_User :: string(), Amount :: number(), Currency :: string()) ->
                                     {ok, From_User_Balance :: number(), To_User_Balance :: number()} |
                                     {error, wrong_arguments} | not_enough_money | sender_does_not_exist | 
                                     receiver_does_not_exist | too_many_requests_to_sender | 
                                     too_many_requests_to_receiver.
send(_From_User,_To_User,Amount,Currency) when 
                not is_number(Amount) or 
                not (is_atom(Currency) or is_list(Currency))->{error,wrong_arguments};
            
send(From_User,To_User,Amount,Currency)->
    gen_server:call(?SERVER, {send,{From_User,To_User,Amount,Currency}}).


%%%
%  Handlers
%%%

init(Args)->
    {ok,{}}.

handle_cast(_Args,State)->
    {noreply,State}.


handle_call({create_user,User},From,State)->
    {ok,Pid}=ex_banking_worker_sup:fetch_worker(),
     Result= ex_banking_worker:fwd_create_user(Pid,From,User),
     gen_server:reply(From,Result),
     {noreply,State};

handle_call({get_balance,{User,Currency}},From,State)->
    {ok,Pid}=ex_banking_worker_sup:fetch_worker(),
    {ok,Balance}= ex_banking_worker:fwd_get_balance(Pid,From,{User,Currency}),
    gen_server:reply(From,{ok,Balance}),
    {noreply,State};


handle_call({deposit,{User,Amount,Currency}},From,State)->
    {ok,Pid}=ex_banking_worker_sup:fetch_worker(),
    {ok,NewBalance}= ex_banking_worker:fwd_deposit(Pid,From,{User,Amount,Currency}),
    gen_server:reply(From,{ok,NewBalance}),
    {noreply,State};

handle_call({withdraw,{User,Amount,Currency}},From,State)->
    {ok,Pid}=ex_banking_worker_sup:fetch_worker(),
    Result=ex_banking_worker:fwd_withdraw(Pid,From,{User,Amount,Currency}),
    gen_server:reply(From,Result),
    {noreply,State};

handle_call({send,{From_User,To_User,Amount,Currency}},From,State)->
    {ok,Pid}=ex_banking_worker_sup:fetch_worker(),
    Result=ex_banking_worker:fwd_send(Pid,From,{From_User,To_User,Amount,Currency}),
    gen_server:reply(From,Result),
    {noreply,State}.
