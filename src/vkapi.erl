-module(vkapi).
-author('Romaniuk Vadim <romaniuk.cv@gmail.com>').
-include("includes/vkapi.hrl").

-export([request/2]).
-export([get_all_wall_photos/1]).
-export([get_all_album_photos/1]).
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

get_all_wall_photos(DecodedJson) ->
    Count = nested:get([<<"response">>,<<"count">>], DecodedJson),
    Items = nested:get([<<"response">>,<<"items">>], DecodedJson),
    Count, 
    loop_over_items_to_get_urls(Items).
get_all_album_photos(DecodedJson) ->
    DecodedJson.

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

 loop_over_items_to_get_urls(List) ->
    loop_over_items_to_get_urls(<<"photo_2560">>,"NotFound_2560",List,[]).

loop_over_items_to_get_urls(_,_,[],Result) ->
    Result;

loop_over_items_to_get_urls(Key,DefaultMessage,[H|T],Result) ->
    PhotoParams = case nested:get([<<"attachments">>,<<"photo">>],H,other_key) of
		      {Params} -> Params;
		      other_key ->
			  loop_over_items_to_get_urls(Key,DefaultMessage,T,Result)
		  end,
										
	case maps:get(Key, PhotoParams, DefaultMessage) of
	    "NotFound_2560" ->
		loop_over_items_to_get_urls(<<"photo_1280">>,"NotFound_1280",H,Result);
	    "NotFound_1280" ->
		loop_over_items_to_get_urls(<<"photo_807">>,"NotFound_807",H,Result);
	    "NotFound_807" ->
		loop_over_items_to_get_urls(<<"photo_604">>,"NotFound_130",H,Result);
	    "NotFound_130" ->
		loop_over_items_to_get_urls(<<"photo_130">>,"NotFound_75",H,Result);
	    "NotFound_75" ->
		loop_over_items_to_get_urls(<<"photo_75">>,"NoImageFound",H,Result);
	    "NoImageFound" ->
		loop_over_items_to_get_urls(<<"photo_2560">>,"NotFound_2560",T,Result);
	    Value ->
		loop_over_items_to_get_urls(Key,"NotFound_2560",T,[Value|Result])
	end.                    
