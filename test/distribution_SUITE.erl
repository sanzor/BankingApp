-module(distribution_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

% -export([init_per_suite/1,end_per_suite/1,init_per_testcase/2,end_per_testcase/2]).
-export([all/0]).


all()->[
    can_run_one_single_node
].
init_per_suite(Config)->
    [].
end_per_suite(Config)->
    ok.

init_per_testcase(can_run_one_single_node,Config)->
    [{}];
init_per_testcase(_,Config)->
    Config.

end_per_suite()->ok.
