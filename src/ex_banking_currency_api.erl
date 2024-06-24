-module(ex_banking_currency_api).
-export([get_currency/1,add_currency/2,remove_currency/1,update_currency/2]).
%----------------------------------------------------------------------------------
%--------------------Currency API-------------------------------------------------
%----------------------------------------------------------------------------------
get_currency(Currency)->
    ex_banking_currency_server:get_coefficient(Currency).
add_currency(Currency,Coefficient)->
    ex_banking_currency_server:add_currency(Currency, Coefficient).

remove_currency(Currency)->
    ex_banking_currency_server:remove_currency(Currency).

update_currency(Currency,Coefficient)->
    ex_banking_currency_server:update_currency(Currency, Coefficient).