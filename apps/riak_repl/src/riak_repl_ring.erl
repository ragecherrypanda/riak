%% Riak EnterpriseDS
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
-module(riak_repl_ring).
-author('Andy Gross <andy@andygross.org>').
-include("riak_repl.hrl").
-export([ensure_config/1,
         get_repl_config/1,
         add_site/2,
         add_listener/2,
         del_site/2,
         del_listener/2,
         get_site/2,
         get_listener/2]).

-include_lib("eunit/include/eunit.hrl").

-spec(ensure_config/1 :: (ring()) -> ring()).
%% @doc Ensure that Ring has replication config entry in the ring metadata dict.
ensure_config(Ring) ->
    case get_repl_config(Ring) of
        undefined ->
            riak_core_ring:update_meta(?MODULE, initial_config(), Ring);
        {ok, _} ->
            Ring
    end.


-spec(get_repl_config/1 :: (ring()) -> {ok, dict()}|undefined).
%% @doc Get the replication config dictionary from Ring.
get_repl_config(Ring) ->
    riak_core_ring:get_meta(?MODULE, Ring).

-spec(add_site/2 :: (ring(), #repl_site{}) -> ring()).
%% @doc Add a replication site to the Ring.
add_site(Ring, Site=#repl_site{name=Name}) ->
    {ok, RC} = get_repl_config(Ring),
    Sites = dict:fetch(sites, RC),
    case lists:keysearch(Name, 2, Sites) of
        false ->
            NewSites = [Site|Sites],
            riak_core_ring:update_meta(
              ?MODULE,
              dict:store(sites, NewSites, RC),
              Ring);
        {value, _} ->
            Ring
    end.

-spec(del_site/2 :: (ring(), repl_sitename()) -> ring()).
%% @doc Delete a replication site from the Ring.
del_site(Ring, SiteName) -> 
    {ok, RC} = get_repl_config(Ring),
    Sites = dict:fetch(sites, RC),
    case lists:keysearch(SiteName, 2, Sites) of
        false ->
            Ring;
        {value, Site} ->
            NewSites = lists:delete(Site, Sites),
            riak_core_ring:update_meta(
              ?MODULE,
              dict:store(sites, NewSites, RC),
              Ring)
    end.

-spec(get_site/2 :: (ring(), repl_sitename()) -> #repl_site{}|undefined).
%% @doc Get a replication site record from the Ring.
get_site(Ring, SiteName) ->
    {ok, RC} = get_repl_config(Ring),
    Sites  = dict:fetch(sites, RC),
    case lists:keysearch(SiteName, 2, Sites) of
        false -> undefined;
        {value, ReplSite} -> ReplSite
    end.

-spec(add_listener/2 :: (ring(), #repl_listener{}) -> ring()).
%% @doc Add a replication listener host/port to the Ring.
add_listener(Ring,Listener) ->
    {ok, RC} = get_repl_config(Ring),
    Listeners = dict:fetch(listeners, RC),
    case lists:member(Listener, Listeners) of
        false ->
            NewListeners = [Listener|Listeners],
            riak_core_ring:update_meta(
              ?MODULE,
              dict:store(sites, NewListeners, RC),
              Ring);
        true ->
            Ring
    end.

-spec(del_listener/2 :: (ring(), repl_addr()) -> ring()).
%% @doc Delete a replication listener host/port from the Ring.
del_listener(Ring,{_IP, _Port}=ListenAddr) -> 
    {ok, RC} = get_repl_config(Ring),
    Listeners = dict:fetch(listeners, RC),
    case lists:keysearch(ListenAddr, 3, Listeners) of
        false ->
            Ring;
        {value, Listener} ->
            NewListeners = lists:delete(Listener, Listeners),
            riak_core_ring:update_meta(
              ?MODULE,
              dict:store(listeners, NewListeners, RC),
              Ring)
    end.
            

-spec(get_listener/2 :: (ring(), repl_addr()) -> #repl_listener{}|undefined).
%% @doc Fetch a replication host/port listener record from the Ring.
get_listener(Ring,{_IP,_Port}=ListenAddr) -> 
    {ok, RC} = get_repl_config(Ring),
    Listeners  = dict:fetch(listeners, RC),
    case lists:keysearch(ListenAddr, 3, Listeners) of
        false -> undefined;
        {value,Listener} -> Listener
    end.

%% helper functions

%% @private
initial_config() ->
    dict:from_list(
      [{local_listeners, []},
       {sites, []}]
      ).
