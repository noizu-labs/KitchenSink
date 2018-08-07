#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SmartToken.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger

  @context Noizu.ElixirCore.CallingContext.admin()
  @conn_stub %{remote_ip: {127, 0, 0, 1}}

  @tag :smart_token
  test "Account Verification Create & Redeem" do
    user = %Noizu.KitchenSink.Support.UserEntity{name: "SmartToken Account Verification Test"}
           |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    user_ref = Noizu.KitchenSink.Support.UserEntity.ref(user)
    bindings = %{recipient: user_ref}
    smart_token = Noizu.SmartToken.TokenRepo.account_verification_token(%{})
                  |> Noizu.SmartToken.TokenRepo.bind!(bindings, @context, %{})
    encoded_link = Noizu.SmartToken.TokenEntity.encoded_key(smart_token)

    assert smart_token.access_history.count == 0
    assert smart_token.context == user_ref
    assert smart_token.extended_info[:single_use] == true
    assert smart_token.resource == user_ref
    assert smart_token.scope == {:account_info, :verification}
    assert smart_token.state == :enabled
    assert smart_token.type == :account_verification
    assert smart_token.permissions == :unrestricted


    {attempt, token} = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == :ok
    assert token.resource == user_ref
  end

  @tag :smart_token
  test "Account Verification - Max Attempts Exceeded - Single Use" do
    user = %Noizu.KitchenSink.Support.UserEntity{name: "SmartToken Account Verification Test"}
           |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    user_ref = Noizu.KitchenSink.Support.UserEntity.ref(user)
    bindings = %{recipient: user_ref}
    smart_token = Noizu.SmartToken.TokenRepo.account_verification_token(%{})
                  |> Noizu.SmartToken.TokenRepo.bind!(bindings, @context, %{})
    encoded_link = Noizu.SmartToken.TokenEntity.encoded_key(smart_token)

    Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    attempt = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == {:error, :invalid}
  end

  @tag :smart_token
  test "Account Verification - Max Attempts Exceeded - Multi Use" do
    user = %Noizu.KitchenSink.Support.UserEntity{name: "SmartToken Account Verification Test"}
           |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    user_ref = Noizu.KitchenSink.Support.UserEntity.ref(user)
    bindings = %{recipient: user_ref}
    options = %{extended_info: %{multi_use: true, limit: 3}}
    smart_token = Noizu.SmartToken.TokenRepo.account_verification_token(options)
                  |> Noizu.SmartToken.TokenRepo.bind!(bindings, @context, %{})
    encoded_link = Noizu.SmartToken.TokenEntity.encoded_key(smart_token)

    {attempt, _token} = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == :ok
    {attempt, _token} = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == :ok
    {attempt, _token} = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == :ok
    attempt = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == {:error, :invalid}
  end

  @tag :smart_token
  test "Account Verification - Expired" do
    user = %Noizu.KitchenSink.Support.UserEntity{name: "SmartToken Account Verification Test"}
           |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    user_ref = Noizu.KitchenSink.Support.UserEntity.ref(user)
    bindings = %{recipient: user_ref}
    options = %{extended_info: %{multi_use: true, limit: 3}}
    smart_token = Noizu.SmartToken.TokenRepo.account_verification_token(options)
                  |> Noizu.SmartToken.TokenRepo.bind!(bindings, @context, %{})
    encoded_link = Noizu.SmartToken.TokenEntity.encoded_key(smart_token)

    {attempt, _token} = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context)
    assert attempt == :ok

    past_expiration = DateTime.utc_now() |> Timex.shift(days: 5)
    options = %{current_time: past_expiration}
    attempt = Noizu.SmartToken.TokenRepo.authorize!(encoded_link, @conn_stub, @context, options)
    assert attempt == {:error, :invalid}
  end

end