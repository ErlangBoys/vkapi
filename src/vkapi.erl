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
    %%Count = nested:get([<<"response">>,<<"count">>], DecodedJson),
    Items = nested:get([<<"response">>,<<"items">>], DecodedJson),
    %%Count, 
    get_all_attachments(<<"photo">>,Items).

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

get_all_attachments(Key,Response) ->
    get_all_attachments(Key,Response,[],[]).
get_all_attachments(_,[],[],Attachments) ->
    Attachments;
get_all_attachments(Key,[H|T],[],Attachments) ->
    PostUrls = case maps:get(<<"attachments">>,H,other_key) of
		   [] ->
		       get_all_attachments(Key,T,[],Attachments);
		   other_key ->
		       get_all_attachments(Key,T,[],Attachments);
		   AttachmentList ->
		       get_post_attachments(Key,AttachmentList)
		   
	       end,
    get_all_attachments(Key,T,[],[PostUrls|Attachments]).


get_post_attachments(Key,AttachmentList) ->
    get_post_attachments(Key,AttachmentList,[]).
get_post_attachments(_,[],PostAttachments) ->
    PostAttachments;
get_post_attachments(Key,[H|T],PostAttachments) ->					     
   case maps:get(<<"photo">>,H,other_key) of
	other_key ->
	    get_post_attachments(Key,T,PostAttachments);
	Params ->
	   MaxResPhoto = get_max_available_photo_res(Params),
	   get_post_attachments(Key,T,[MaxResPhoto|PostAttachments])
    end.
    

get_max_available_photo_res(PhotoParamsMap) ->
    get_max_available_photo_res(<<"photo_2560">>,"NotFound_2560",PhotoParamsMap,<<>>).
get_max_available_photo_res(_,"Found",[],ResultUrl) ->
    ResultUrl;
get_max_available_photo_res(Key,DefaultMessage,PhotoParamsMap,ResultUrl) ->
    case maps:get(Key, PhotoParamsMap, DefaultMessage) of
	"NotFound_2560" ->
	    get_max_available_photo_res(<<"photo_1280">>,"NotFound_1280",PhotoParamsMap,ResultUrl);
	"NotFound_1280" ->
	    get_max_available_photo_res(<<"photo_807">>,"NotFound_807",PhotoParamsMap,ResultUrl);
	"NotFound_807" ->
	    get_max_available_photo_res(<<"photo_604">>,"NotFound_130",PhotoParamsMap,ResultUrl);
	"NotFound_130" ->
	    get_max_available_photo_res(<<"photo_130">>,"NotFound_75",PhotoParamsMap,ResultUrl);
	"NotFound_75" ->
	    get_max_available_photo_res(<<"photo_75">>,"NoImageFound",PhotoParamsMap,ResultUrl);
	"NoImageFound" ->
	    get_max_available_photo_res(<<"photo_2560">>,"NotFound_2560",PhotoParamsMap,ResultUrl);
	Value ->
	    get_max_available_photo_res(Key,"Found",[],Value)
    end.    

