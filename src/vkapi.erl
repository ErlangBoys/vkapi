-module(vkapi).
-author('Romaniuk Vadim <romaniuk.cv@gmail.com>').
-include("includes/vkapi.hrl").

-export([request/2]).
-export([get_all/2]).
%% wall.get response https://pastebin.com/rpKTjP8Z

-spec request(atom(),list()) ->list(). 
request(Method, Params) ->
    BinParams = from_proplist_to_binProplist(Params),
    URL = hackney_url:make_url(?VK_API_URL,
			       list_to_binary(Method),
			       BinParams ++ [{<<"access_token">>, ?VK_ACCESS_TOKEN},
					     {<<"v">>, ?VK_API_VERSION}]),
    {ok, _ResultCode, _Result, ClientRef} = hackney:request(get, URL),
    decode_json(ClientRef).	    

get_all(Method,Params) ->
    BinParams = from_proplist_to_binProplist(Params),
    URL = hackney_url:make_url(?VK_API_URL,
			       list_to_binary(Method),
			       BinParams ++ [{<<"access_token">>, ?VK_ACCESS_TOKEN},
					     {<<"v">>, ?VK_API_VERSION}]),
    {ok, _ResultCode, _Result, ClientRef} = hackney:request(get, URL),
    decode_json(ClientRef).	    



%%====================================================%%
%% Internal Functions
%%====================================================%%

-spec decode_json(integer()) ->list().
decode_json(ClientRef) ->
    case hackney:body(ClientRef,infinity) of
	{ok, BinaryResponse} ->
	    case jsone:try_decode(BinaryResponse) of
		{ok, DecodedJsonList, _BinNextValue} ->
		    DecodedJsonList; %% maps
		{error, Reason} ->
		    %% there was some other error, e.g. server is not available
		    {error, Reason}
	    end;
	{error, {closed, BinResp}} ->
	    {error,{closed, BinResp}};
	{error, Reason} ->
	    %% there was some other error, e.g. server is not available
	    {error, Reason}
    end.

-spec from_proplist_to_binProplist(list(tuple())) -> list(tuple()).
from_proplist_to_binProplist(Params) ->
    from_proplist_to_binProplist(Params,[]).
from_proplist_to_binProplist([],BinProplist) ->
    BinProplist;
from_proplist_to_binProplist([H|T],BinProplist) ->
    {K,V} = H,
    from_proplist_to_binProplist(T, [{list_to_binary(K),list_to_binary(V)}|BinProplist]).
