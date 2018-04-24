%%%-------------------------------------------------------------------
%% @doc vkapi public API
%% @end
%%%-------------------------------------------------------------------

-module(vkapi_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    vkapi_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================