#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.UserSettings.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger
  alias Noizu.UserSettings.Settings
  alias Noizu.UserSettings.Setting

  @context Noizu.ElixirCore.CallingContext.admin()


  @tag :user_settings
  test "Insert Setting (new, root)" do
    sut = %Settings{}
          |> Settings.insert(:foo_setting, :bar, 100)
    expected = %Settings{settings: %{foo_setting: %Setting{setting: :foo_setting, stack: %{[] => [%{value: :bar, weight: 100}]}}}}
    assert sut == expected
  end

  @tag :user_settings
  test "Insert Setting (new, path)" do
    sut = %Settings{}
          |> Settings.insert(:foo_setting, [:nested, :setting, :path], :bar, 100)
    expected = %Settings{settings: %{foo_setting: %Setting{setting: :foo_setting, stack: %{[:nested, :setting, :path] => [%{value: :bar, weight: 100}]}}}}
    assert sut == expected
  end


  @tag :user_settings
  test "Insert Setting (append existing path)" do
    sut = %Settings{}
          |> Settings.insert(:foo_setting, [:nested, :setting, :path], :bar, 100)
          |> Settings.insert(:foo_setting, [:nested, :setting, :path], :boo, 200)
    expected = %Settings{settings: %{foo_setting: %Setting{setting: :foo_setting, stack: %{[:nested, :setting, :path] => [%{value: :bar, weight: 100}, %{value: :boo, weight: 200}]}}}}
    assert sut == expected
  end

  @tag :user_settings
  test "Insert Setting (append new path)" do
    sut = %Settings{}
          |> Settings.insert(:foo_setting, :bar, 100)
          |> Settings.insert(:foo_setting, [:nested, :setting, :path], :boo, 200)
    expected = %Settings{settings: %{foo_setting: %Setting{setting: :foo_setting, stack: %{[] => [%{value: :bar, weight: 100}], [:nested, :setting, :path] => [%{value: :boo, weight: 200}]}}}}
    assert sut == expected
  end


  @tag :user_settings
  test "Effective (when max weight is parent)" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)

    effective = Settings.effective(sut, :foo_setting, [:top, :parent, :parents_parent])
    assert effective == :bop
  end

  @tag :user_settings
  test "effective_for" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)
          |> Settings.insert(:foo_setting, [:alt_parent], :ohmy, 200)
          |> Settings.insert(:foo_setting, [:alt_parent, :alt_parents_parent], :ohmy, 10_000)

    effective = Settings.effective_for(sut, :foo_setting, [[:top, :parent, :parents_parent], [:alt_parent]])
    assert effective == :bop

    effective = Settings.effective_for(sut, :foo_setting, [[:top, :parent, :parents_parent], [:alt_parent, :alt_parents_parent]])
    assert effective == :ohmy
  end

  @tag :user_settings
  @tag :inspect
  test "Inspect (infinity)" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)

    expected = "#Settings<[#Setting(:foo_setting)<%{[] => [%{value: :bibbity, weight: 100}], [:parent, :parents_parent] => [%{value: :booppity, weight: 300}], [:parents_parent] => [%{value: :bop, weight: 400}], [:top, :parent, :parents_parent] => [%{value: :bobbity, weight: 200}]}>, #Setting(:get)<%{[] => [%{value: :schiwfty, weight: 1000}]}>]>"
    actual = "#{inspect sut, limit: :infinity}"
    assert actual == expected
  end

  @tag :user_settings
  @tag :inspect
  test "Inspect (500)" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)

    expected = "#Settings<[#Setting(:foo_setting)<%{[] => %{effective: :bibbity, entries: 1}, [:parent, :parents_parent] => %{effective: :bop, entries: 1}, [:parents_parent] => %{effective: :bop, entries: 1}, [:top, :parent, :parents_parent] => %{effective: :bop, entries: 1}}>, #Setting(:get)<%{[] => %{effective: :schiwfty, entries: 1}}>]>"
    actual = "#{inspect sut, limit: 500}"
    assert actual == expected
  end

  @tag :user_settings
  @tag :inspect
  test "Inspect (100)" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)

    expected = "#Settings<[#Setting(:foo_setting)<%{[] => 1, [:parent, :parents_parent] => 1, [:parents_parent] => 1, [:top, :parent, :parents_parent] => 1}>, #Setting(:get)<%{[] => 1}>]>"
    actual = "#{inspect sut, limit: 100}"
    assert actual == expected
  end

  @tag :user_settings
  @tag :inspect
  test "Inspect (10)" do
    sut = %Settings{}
          |> Settings.insert(:get, :schiwfty, 1000)
          |> Settings.insert(:foo_setting, :bibbity, 100)
          |> Settings.insert(:foo_setting, [:top, :parent, :parents_parent], :bobbity, 200)
          |> Settings.insert(:foo_setting, [:parents_parent], :bop, 400)
          |> Settings.insert(:foo_setting, [:parent, :parents_parent], :booppity, 300)

    expected = "#Settings<[#Setting(:foo_setting)<4>, #Setting(:get)<1>]>"
    actual = "#{inspect sut, limit: 10}"
    assert actual == expected
  end

end