%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% Copyright 2013 Opscode, Inc. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
-module(mini_s3_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("erlcloud/include/erlcloud_aws.hrl").
%-include("../src/erlcloud_aws.hrl").
-include("../src/internal.hrl").

format_s3_uri_test_() ->
    Config = fun(Url, Type) ->
                     %#config{s3_url = Url, bucket_access_type = Type}
                     %#aws_config{s3_url = Url, s3_bucket_access_method = Type}
                     mini_s3:new("", "", Url, Type)
             end,
    Tests = [
             %% hostname
             {"https://my-aws.me.com", vhost, "https://bucket.my-aws.me.com:443"},
             {"https://my-aws.me.com", path,  "https://my-aws.me.com:443/bucket"},

             %% ipv4
             {"https://192.168.12.13", path,  "https://192.168.12.13:443/bucket"},

             %% ipv6
             {"https://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]", path,
              "https://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:443/bucket"},

             %% These tests document current behavior. Using
             %% vhost with an IP address does not make sense,
             %% but leaving as-is for now to avoid adding the
             %% is_it_an_ip_or_a_name code.
             {"https://192.168.12.13", vhost, "https://bucket.192.168.12.13:443"},

             {"https://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]", vhost,
              "https://bucket.[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:443"}
            ],
    [ ?_assertEqual(Expect, mini_s3:format_s3_uri(Config(Url, Type), "bucket"))
      || {Url, Type, Expect} <- Tests ].

%% 2015-01-27 00:00:00 = 1422316800 = ?MIDNIGHT
-define(MIDNIGHT, 1422316800).
-define(DAY, 86400).
-define(HOUR, 3600).

%expiration_time_test_() ->
%    Tests = [
%             %% {TTLSecs, IntervalSecs, MockedTimestamp, ExpectedExpiry}
%             {{3600, 900}, {{2015,1,27},{0,0,0}}  , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,0,10}} , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,1,0}}  , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,1,10}} , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,3,0}}  , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,3,30}} , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,5,0}}  , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,10,0}} , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,14,0}} , (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,14,59}}, (?MIDNIGHT + ?HOUR + 900)},
%             {{3600, 900}, {{2015,1,27},{0,15,0}} , (?MIDNIGHT + ?HOUR + 1800)},
%             {{3600, 900}, {{2015,1,27},{0,15,1}} , (?MIDNIGHT + ?HOUR + 1800)},
%             {{3600, 900}, {{2015,1,27},{0,29,59}}, (?MIDNIGHT + ?HOUR + 1800)},
%             {{3600, 900}, {{2015,1,27},{0,30,0}} , (?MIDNIGHT + ?HOUR + 2700)},
%             {{3600, 900}, {{2015,1,27},{0,44,59}}, (?MIDNIGHT + ?HOUR + 2700)},
%             {{3600, 900}, {{2015,1,27},{0,45,0}} , (?MIDNIGHT + ?HOUR + 3600)},
%             {{3600, 900}, {{2015,1,27},{0,59,59}}, (?MIDNIGHT + ?HOUR + 3600)},
%             {{3600, 900}, {{2015,1,27},{1,0,0}}  , (?MIDNIGHT + ?HOUR + 4500)},
%
%             %% There are 86400 seconds in a day. What happens if the interval is not evenly
%             %% divisible in that time? Take 7m for example. 420 secs goes into a day 205.71
%             %% times which is a remainder of 300 seconds. We should make sure that we
%             %% restart the intervals at midnight, so we don't have day to day drift
%
%             {{3600, 420}, {{2015,1,27},{23,59,0}} , (?MIDNIGHT + ?DAY + ?HOUR)},
%             {{3600, 420}, {{2015,1,28},{0,0,0}}   , (?MIDNIGHT + ?DAY + ?HOUR + 420)},
%
%             %% Let's test the old functionality too
%             {3600, {{2015,1,27},{0,0,0}} , (?MIDNIGHT + ?HOUR)},
%             {3600, {{2015,1,27},{0,0,1}} , (?MIDNIGHT + ?HOUR + 1)},
%             {3600, {{2015,1,27},{0,1,1}} , (?MIDNIGHT + ?HOUR + 61)},
%             {3600, {{2015,1,28},{0,1,1}} , (?MIDNIGHT + ?DAY + ?HOUR + 61)}
%            ],
%
%    TestFun = fun(Arg, MockedTime) ->
%                      meck:new(mini_s3, [unstick, passthrough]),
%                      meck:expect(mini_s3, universaltime, fun() -> MockedTime end),
%                      Expiry = mini_s3:expiration_time(Arg),
%                      meck:unload(mini_s3),
%                      Expiry
%              end,
%    [ ?_assertEqual(Expect, TestFun(Arg, MockedTimestamp))
%      || {Arg, MockedTimestamp, Expect} <- Tests].

%s3_uri_test_() ->
%%    Config = #config{
%%               access_key_id = "access_key_id",
%%               secret_access_key = "secret_access_key"
%%               },
%
%    Config = mini_s3:new("access_key_id", "secret_access_key", "http://host.com"),
%
%    RawHeaders = [],
%
%    TestFun = fun({Method, BucketName, Key, Lifetime, MockedTime}) ->
%                      meck:new(mini_s3, [no_link, passthrough]),
%                      meck:expect(mini_s3, universaltime, fun() -> MockedTime end),
%%                      meck:expect(mini_s3, make_signed_url_authorization, fun(_,_,_,_,_) -> {"", <<"k6E/2haoGH5vGU9qDTBRs1qNGKA=">>} end),
%
%                      URL = binary_to_list(mini_s3:s3_url(Method, BucketName, Key, Lifetime, RawHeaders, Config)),
%                      io:format("URL: ~p~n", [URL]),
%                      io:format("History: ~p~n", [meck:history(mini_s3)]),
%                      meck:unload(mini_s3),
%
%                      URL
%              end,
%
%    Tests = [
%             {{'GET', "BUCKET", "KEY", 3600, {{2015,1,27},{0,0,0}}}, "http://s3.amazonaws.com:80/BUCKET/KEY?AWSAccessKeyId=access_key_id&Expires=1422320400&Signature=k6E/2haoGH5vGU9qDTBRs1qNGKA%3D"},
%             {{'GET', "BUCKET2", "KEY2", {3600, 900}, {{2015,1,27},{0,0,0}}}, "http://s3.amazonaws.com:80/BUCKET2/KEY2?AWSAccessKeyId=access_key_id&Expires=1422321300&Signature=k6E/2haoGH5vGU9qDTBRs1qNGKA%3D"}
%            ],
%
%    [ ?_assertEqual(Expect, TestFun(Args)) || {Args, Expect} <- Tests].

% this should be named make_expire_win_test(), but timeout doesn't work unless main_test_()
main_test_() ->
    {timeout, 60,
        fun() ->
                % 10 expiration windows of size 1sec created 1sec apart should be 10 unique windows (i.e. no duplicates)
                Set1 = [{timer:sleep(1000), mini_s3:make_expire_win(0, 1)} || _ <- [1,2,3,4,5,6,7,8,9,0]],
                10   = length(sets:to_list(sets:from_list(Set1))),

                % 100 expiration windows of large size created quickly should be mostly duplicates
                Set2 = [mini_s3:make_expire_win(0, 1000) || _ <- lists:duplicate(100, 0)],
                2   >= length(sets:to_list(sets:from_list(Set2)))
        end
    }.
    
new_test() ->
    % scheme://host:port
    Config0 = mini_s3:new("key", "secret", "http://host:80"),
    "http://" = Config0#aws_config.s3_scheme,
    "host"    = Config0#aws_config.s3_host,
    80        = Config0#aws_config.s3_port,

    Config1 = mini_s3:new("key", "secret", "https://host:80"),
    "https://" = Config1#aws_config.s3_scheme,
    "host"    = Config1#aws_config.s3_host,
    80 =  Config1#aws_config.s3_port,

    Config2 = mini_s3:new("key", "secret", "http://host:443"),
    "http://" = Config2#aws_config.s3_scheme,
    "host"    = Config2#aws_config.s3_host,
    443 = Config2#aws_config.s3_port,

    Config3 = mini_s3:new("key", "secret", "https://host:443"),
    "https://" = Config3#aws_config.s3_scheme,
    "host"    = Config3#aws_config.s3_host,
    443 = Config3#aws_config.s3_port, 

    Config4 = mini_s3:new("key", "secret", "https://host:23"),
    "https://" = Config4#aws_config.s3_scheme,
    "host"    = Config4#aws_config.s3_host,
    23 =  Config4#aws_config.s3_port,

    Config5 = mini_s3:new("key", "secret", "http://host:23"),
    "http://" = Config5#aws_config.s3_scheme,
    "host"    = Config5#aws_config.s3_host,
    23 = Config5#aws_config.s3_port,

    Config00 = mini_s3:new("key", "secret", "http://[1234:1234:1234:1234:1234:1234:1234:1234]:80"),
    "http://" = Config00#aws_config.s3_scheme,
    "[1234:1234:1234:1234:1234:1234:1234:1234]" = Config00#aws_config.s3_host,
    80 = Config00#aws_config.s3_port,


    % scheme://host
    Config6 = mini_s3:new("key", "secret", "https://host"),
    "https://" = Config6#aws_config.s3_scheme,
    "host"    = Config6#aws_config.s3_host,
    443 = Config6#aws_config.s3_port,

    Config7 = mini_s3:new("key", "secret", "http://host"),
    "http://" = Config7#aws_config.s3_scheme,
    "host"    = Config7#aws_config.s3_host,
    80 = Config7#aws_config.s3_port,

    Config11 = mini_s3:new("key", "secret", "http://[1234:1234:1234:1234:1234:1234:1234:1234]"),
    "http://" = Config11#aws_config.s3_scheme,
    "[1234:1234:1234:1234:1234:1234:1234:1234]" = Config11#aws_config.s3_host,
    80 = Config11#aws_config.s3_port,


    % host:port
    Config8 = mini_s3:new("key", "secret", "host:80"),
    "http://" = Config8#aws_config.s3_scheme,
    "host"    = Config8#aws_config.s3_host,
    80 = Config8#aws_config.s3_port,

    Config9 = mini_s3:new("key", "secret", "host:443"),
    "https://" = Config9#aws_config.s3_scheme,
    "host"    = Config9#aws_config.s3_host,
    443 = Config9#aws_config.s3_port,

    ConfigA = mini_s3:new("key", "secret", "host:23"),
    "https://" = ConfigA#aws_config.s3_scheme,
    "host"    = ConfigA#aws_config.s3_host,
    23 = ConfigA#aws_config.s3_port,

    Config88 = mini_s3:new("key", "secret", "[1234:1234:1234:1234:1234:1234:1234:1234]:80"),
    "http://" = Config88#aws_config.s3_scheme,
    "[1234:1234:1234:1234:1234:1234:1234:1234]" = Config88#aws_config.s3_host,
    80 = Config88#aws_config.s3_port,


    % host
    ConfigB = mini_s3:new("key", "secret", "host"),
    "https://" = ConfigB#aws_config.s3_scheme,
    "host"    = ConfigB#aws_config.s3_host,
    443 = ConfigB#aws_config.s3_port,

    ConfigBB = mini_s3:new("key", "secret", "[1234:1234:1234:1234:1234:1234:1234:1234]"),
    "https://" = ConfigBB#aws_config.s3_scheme,
    "[1234:1234:1234:1234:1234:1234:1234:1234]" = ConfigBB#aws_config.s3_host,
    443 = ConfigBB#aws_config.s3_port.


% toggle port on host header (add port or remove it)
get_host_toggleport_test() ->
    Config0 = mini_s3:new("", "", "host"),
    "host:443" = mini_s3:get_host_toggleport("host", Config0),
    Config1 = mini_s3:new("", "", "host:123"),
    "host" = mini_s3:get_host_toggleport("host:123", Config1),
    Config2 = mini_s3:new("", "", "http://host"),
    "http://host:80" = mini_s3:get_host_toggleport("http://host", Config2),
    Config3 = mini_s3:new("", "", "http://host:123"),
    "http://host" = mini_s3:get_host_toggleport("http://host:123", Config3),
    Config4 = mini_s3:new("", "", "https://host:123"),
    "https://host" = mini_s3:get_host_toggleport("https://host:123", Config4).

% construct url from config
get_url_test() ->
    Config0 = mini_s3:new("", "", "http://1.2.3.4"),
    "http://1.2.3.4"      = mini_s3:get_url_noport(Config0),
    "http://1.2.3.4:80"   = mini_s3:get_url_port(  Config0),
    Config1 = mini_s3:new("", "", "https://1.2.3.4"),
    "https://1.2.3.4"     = mini_s3:get_url_noport(Config1),
    "https://1.2.3.4:443" = mini_s3:get_url_port(  Config1),
    Config2 = mini_s3:new("", "", "http://1.2.3.4:443"),
    "http://1.2.3.4"      = mini_s3:get_url_noport(Config2),
    "http://1.2.3.4:443"  = mini_s3:get_url_port(  Config2),
    Config3 = mini_s3:new("", "", "https://1.2.3.4:80"),
    "https://1.2.3.4"     = mini_s3:get_url_noport(Config3),
    "https://1.2.3.4:80"  = mini_s3:get_url_port(  Config3).
