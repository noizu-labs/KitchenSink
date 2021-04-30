#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.DynamicTemplateTest do
  use ExUnit.Case, async: false
  require Logger
  alias  Noizu.EmailService.Email.Binding.Dynamic, as: Binding
  alias Binding.Error
  alias Binding.Section
  alias Binding.Selector

  #@context Noizu.ElixirCore.CallingContext.admin()

  @tag :email
  @tag :dynamic_template
  test "Current Selector (root)" do
    selector = fixture(:default)
               |> Binding.current_selector()
    assert selector == %Selector{selector: [:root]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): this" do
    {selector_or_error, state} = fixture(:default)
                                 |> Binding.extract_selector("this")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:extract_clause, :this, :invalid}}, state.last_error)
  end


  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): this.dolly" do
    {selector_or_error, state} = fixture(:default)
                                 |> Binding.extract_selector("this.dolly")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:extract_clause, :this, :invalid}}, state.last_error)
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): ." do
    {selector_or_error, state} = fixture(:default)
                                 |> Binding.extract_selector(".")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:extract_clause, :this, :invalid}}, state.last_error)
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): ../" do
    {selector_or_error, state} = fixture(:default)
                                 |> Binding.extract_selector("../")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:select_parent, :already_root}}, state.last_error)
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): ../../" do
    {selector_or_error, state} = fixture(:default)
                                 |> Binding.extract_selector("../../")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:select_parent, :already_root}}, state.last_error)
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): hello.dolly" do
    {selector_or_error, _state} = fixture(:default)
                                 |> Binding.extract_selector("!bind hello.dolly")
    assert selector_or_error == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}]}
  end


  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): hello.dolly[@index]" do
    {selector_or_error, _state} = fixture(:default)
                                 |> Binding.extract_selector("!bind hello.dolly[@index]")
    assert selector_or_error == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}, {:at, "@index"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Current Selector (foo.biz)" do
    selector = fixture(:foo_biz)
               |> Binding.current_selector()
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): this" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("this")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): this.dolly" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("this.dolly")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): ." do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector(".")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): ../" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("../")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): ../../" do
    {selector_or_error, state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("../../")
    assert selector_or_error == :error
    assert Kernel.match?(%Error{error: {:select_parent, :already_top}}, state.last_error)
  end


  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz.bop): ../../" do
    {selector_or_error, _state} = fixture(:foo_biz_bop)
                                 |> Binding.extract_selector("../../")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz.bop): ../dolly" do
    {selector_or_error, _state} = fixture(:foo_biz_bop)
                                 |> Binding.extract_selector("../dolly")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz.bop): ../dolly | pipe" do
    {selector_or_error, _state} = fixture(:foo_biz_bop)
                                 |> Binding.extract_selector("../dolly | pipe")
    assert selector_or_error == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): hello.dolly" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("!bind hello.dolly")
    assert selector_or_error == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): hello.dolly[@index]" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("!bind hello.dolly[@index]")
    assert selector_or_error == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}, {:at, "@index"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Default Binding" do
    template = """
    {{#if selection}}
      {{apple}}
      {{#with nested}}
         {{this.stuff | ignore}}
      {{/with}}
    {{/if}}

    """
    sut = Binding.extract(template)
    assert sut.outcome == :ok
    assert sut.last_error == nil

    # The finalize step needs to be written to collapse down all of the required bindings and any conditional hooks (although we can just require everything referenced).
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Default Binding - With Error" do
    _sut = fixture(:default)
  end

  def fixture(fixture, options \\ %{})
  def fixture(:default, _options) do
    %Noizu.EmailService.Email.Binding.Dynamic{}
  end
  def fixture(:foo_biz, _options) do
    %Noizu.EmailService.Email.Binding.Dynamic{
      section_stack: [%Section{current_selector: %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}}]
    }
  end
  def fixture(:foo_biz_bop, _options) do
    %Noizu.EmailService.Email.Binding.Dynamic{
      section_stack: [%Section{current_selector: %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "bop"}]}}]
    }
  end

end