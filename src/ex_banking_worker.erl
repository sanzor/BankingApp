-module(ex_banking_worker).
-behaviour(gen_server).
-include("records.hrl").
-export([create_user/2,get_balance/2,deposit/2,withdraw/2,send/2]).
-export([fwd_create_user/3,fwd_get_balance/3,fwd_deposit/3,fwd_withdraw/3,fwd_send/3]).
-export([handle_call/3,handle_cast/2,init/1,start_link/0]).

-define(NAME,?MODULE).
-record(state,{
   counter_Ref
}).

%%%%  Call API %%%%%%%%%%%%%%%%%
start_link()->
    {ok,Pid}=gen_server:start_link(?NAME, [],[]),
    {ok,Pid}.

init(CounterRef)->
    {ok,#state{counter_Ref=CounterRef}}.



%%
% Sync API
%%
create_user(Pid,User)->
    gen_server:call(Pid,{create_user,User}).
get_balance(Pid,{User,Currency})->
    gen_server:call(Pid,{Currency,{get_balance,User}}).
deposit(Pid,{User,Amount,Currency})->
    gen_server:call(Pid,{Currency,{deposit,{User,Amount}}}).
withdraw(Pid,{User,Amount,Currency})->
    gen_server:call(Pid,{Currency,{withdraw,{User,Amount}}}).
send(Pid,{From_User,To_User,Amount,Currency})->
    gen_server:call(Pid,{Currency,{send,{From_User,To_User,Amount}}}).


%%
% Proxy API
%%
-spec fwd_create_user(Pid::pid(),SendTo::pid(),User::string())->any().
fwd_create_user(Pid,SendTo,User)->
    gen_server:cast(Pid,{SendTo,{create_user,User}}).

-spec fwd_get_balance(Pid::pid(),SendTo::pid(),{User::string(),Currency::string()})->any().
fwd_get_balance(Pid,SendTo,{User,Currency})->
    gen_server:cast(Pid,{SendTo,{Currency,{get_balance,User}}}).



fwd_deposit(Pid,SendTo,{User,Amount,Currency})->
    gen_server:cast(Pid,{SendTo,{Currency,{deposit,{User,Amount}}}}).
fwd_withdraw(Pid,SendTo,{User,Amount,Currency})->
    gen_server:cast(Pid,{SendTo,{Currency,{withdraw,{User,Amount}}}}).
fwd_send(Pid,SendTo,{From_User,To_User,Amount,Currency})->
    gen_server:cast(Pid,{SendTo,{Currency,{send,{From_User,To_User,Amount}}}}).

%%% Handlers %%%%%%


%%
% cast handlers
%%

-spec handle_cast({SendTo::pid(),{create_user,UserId::string()}},State::term())->StateResult::term(). 
handle_cast({SendTo,{create_user,UserId}}, State)->
    ok=do_create_user(UserId, State),
    gen_server:reply(SendTo,ok),
    {stop,normal,State};

handle_cast({SendTo,{Currency,Request}},State)->
    {ok,Coefficient}=can_get_coefficient(Currency, State),
     do_cast(Coefficient,SendTo,Request,State).

do_cast(Coefficient,SendTo,{get_balance,UserId},State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:get_balance(User#user.pid) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    gen_server:reply(SendTo, Reply),
    {noreply,stop,State};

do_cast(Coefficient,SendTo,{deposit,{UserId,Amount}},State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:deposit(User#user.pid,Amount*Coefficient) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    gen_server:reply(SendTo, Reply),
    {noreply,stop,State};

do_cast(Coefficient,SendTo,{withdraw,{UserId,Amount}},State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:withdraw(User#user.pid,Amount*Coefficient) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    gen_server:reply(SendTo, Reply),
    {noreply,stop,State};
    
do_cast(Coefficient,SendTo,{send,{From_User_Id,To_User_Id,Amount}},State)->
    {ok,From_User,To_User}=get_sender_and_receiver(From_User_Id, To_User_Id, State),
    {ok,From_User_Balance,To_User_Balance}=handle_send(From_User#user.pid, To_User#user.pid, Amount*Coefficient, State),
    Reply={ok,From_User_Balance/Coefficient,To_User_Balance/Coefficient},
    gen_server:reply(SendTo, Reply),
    {stop,normal,State}.
        

%%
%  Call handlers
%%


handle_call({create_user,UserId}, _From, State)->
    ok=do_create_user(UserId, State),
    {stop,normal,ok,State};

handle_call({Currency,Request},From,State)->
    {ok,Coefficient}=can_get_coefficient(Currency, State),
     do_call(Coefficient,Request,From,State).



do_call(Coefficient,{get_balance,UserId},_From,State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:get_balance(User#user.pid) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    {reply,Reply,State};
        

do_call(Coefficient,{deposit,{UserId,Amount}},_From,State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:deposit(User#user.pid,Amount*Coefficient) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    {reply,Reply,State};

    
do_call(Coefficient,{withdraw,{UserId,Amount}},_From,State)->
    {ok,User}=get_user(UserId,State),
    Reply=case ex_banking_account:withdraw(User#user.pid,Amount*Coefficient) of
            {ok,BalanceInBaseCurrency}->{ok,BalanceInBaseCurrency/Coefficient};
             Error -> Error
          end,
    {reply,Reply,State};

do_call(Coefficient,{send,{From_User_Id,To_User_Id,Amount}},_From,State)->
    {ok,From_User,To_User}=get_sender_and_receiver(From_User_Id, To_User_Id, State),
    {ok,From_User_Balance,To_User_Balance}=handle_send(From_User#user.pid, To_User#user.pid, Amount*Coefficient, State),
    {stop,normal,{ok,From_User_Balance/Coefficient,To_User_Balance/Coefficient},State}.



can_get_coefficient(Currency,State)->
    case ex_banking_currency_server:get_coefficient(Currency) of
        {ok,Coefficient} -> {ok, Coefficient};
        _ -> throw({stop,normal,{error,wrong_arguments,Currency},State})
    end.
get_user(UserId,State)->
    case ex_banking_account_map:get_user(UserId) of
        {ok,User}-> {ok,User};
         user_does_not_exist  -> throw({stop,normal,user_does_not_exist,State})
    end. 
get_sender_and_receiver(From_Uid,To_Uid,State)->
    From_User=ex_banking_account_map:get_user(From_Uid),
    To_User=ex_banking_account_map:get_user(To_Uid),
    handle_sender_receiver_identity(From_User,To_User,State).


handle_sender_receiver_identity(user_does_not_exist,_,State)->throw({stop,normal,sender_does_not_exist,State});
handle_sender_receiver_identity(_,user_does_not_exist,State)->throw({stop,normal,receiver_does_not_exist,State});
handle_sender_receiver_identity({ok,From},{ok,To},_)->{ok,From,To}.

handle_send(From_User_Pid,To_User_Pid,Amount,State)->
    WithdrawResult=ex_banking_account:withdraw(From_User_Pid, Amount),
    handle_withdraw_result(WithdrawResult,To_User_Pid,Amount,State).

handle_withdraw_result(too_many_requests_to_user,_,_,State)->throw({stop,normal,too_many_requests_to_sender,State});
handle_withdraw_result(not_enough_money,_,_,State)->throw({stop,normal,not_enough_money,State});

handle_withdraw_result({ok,From_NewBalanceInBaseCurrency},To_Pid,Amount,State)->
    case ex_banking_account:deposit(To_Pid, Amount) of
        {ok,To_NewBalanceInBaseCurrency} -> {ok,From_NewBalanceInBaseCurrency,To_NewBalanceInBaseCurrency};
        too_many_requests_to_user -> throw({stop,normal,too_many_requests_to_receiver,State})
    end.

do_create_user(UserId,State)->
    {ok,Pid}=ex_banking_account_sup:create_account(UserId),
    Ref=erlang:monitor(process, Pid),
    case ex_banking_account_map:create_user(UserId, Pid, Ref) of
       account_already_exists-> throw({stop,normal,user_already_exists,State});
       ok ->ok
    end.