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
  test "With Section: hello.dolly" do
    state = fixture(:foo_biz)
    {:cont, state} =  Binding.extract_token({"#with hello.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "With Section: hello.dolly as | sheep | " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with hello.dolly as | sheep | ", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}

    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}], as: "sheep"}
    assert h.match["sheep"] == %Selector{selector: [:root, {:select, "hello"}, {:key, "dolly"}], as: "sheep"}
    assert t.bind == %{{:select, "hello"} => %{{:key, "dolly"} => %{}}}
  end

  @tag :email
  @tag :dynamic_template
  test "With Section (foo.biz): this.dolly " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{}}}}

  end

  @tag :email
  @tag :dynamic_template
  test "With Section (foo.biz): this.dolly as | sheep | " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with this.dolly as | sheep | ", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}], as: "sheep"}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{}}}}
    assert h.match["sheep"] == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}], as: "sheep"}
  end


  @tag :email
  @tag :dynamic_template
  test "If Section (foo.biz): this.dolly " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}

    [h,t|_] = state.section_stack
    assert h.section == :if
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{}}}}
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})


    # Confirm expected state after with
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{}}}}
    #----

    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    # Confirm expected state after nested with.
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}, {:key, "henry"}], as: "bob"}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{ {:key, "henry"} => %{} }}}}
    #----

    {_, state} = Binding.extract_token({"/with", state}, %{})

    # Confirm expected state after returning to first with
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == %{{:select, "foo"} => %{ {:key, "biz"} => %{{:key, "dolly"} => %{}}}}
    #----

    {_, state} = Binding.extract_token({"/with", state}, %{})

    # Confirm expected state after returning to first if
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
    [h,t|_] = state.section_stack
    assert h.section == :if
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == %{{:select, "foo"} => %{{:key, "biz"} => %{{:key, "dolly"} => %{}}}}
    #----

    {_, state} = Binding.extract_token({"/if", state}, %{})

    # Confirm expected state after returning to root (not selector is still set for this because of fixture construction)
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}]}
    [h|_] = state.section_stack
    assert h.section == :root
    #----

    assert state.outcome == :ok
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting| Unsupported tag - correct close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    {_, state} = Binding.extract_token({"#apple bob.douglas as | bob | ", state}, %{})

    [h,t|_] = state.section_stack

    assert h.section == {:unsupported, "apple"}
    assert h.clause == %Selector{selector: [:root, {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}, {:key, "henry"}, {:key, "douglas"}], as: "bob"}

    {_, state} = Binding.extract_token({"/apple", state}, %{})

    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/if", state}, %{})


    assert state.outcome == :ok
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting| Unsupported tag - no clause - correct close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    {_, state} = Binding.extract_token({"#apple", state}, %{})
    [h,t|_] = state.section_stack
    assert h.section == {:unsupported, "apple"}
    assert h.clause == nil
    {_, state} = Binding.extract_token({"/apple", state}, %{})

    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/if", state}, %{})

    assert state.outcome == :ok
  end



  @tag :email
  @tag :dynamic_template
  test "Section Nesting| Unsupported tag - skipped close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    {_, state} = Binding.extract_token({"#apple", state}, %{})

    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/with", state}, %{})
    {_, state} = Binding.extract_token({"/if", state}, %{})

    assert state.outcome == :ok
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting| Unsupported tag - invalid close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    {_, state} = Binding.extract_token({"#apple", state}, %{})

    {:halt, state} = Binding.extract_token({"/if", state}, %{})
    state.outcome == :error
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting| invalid close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})
    {:halt, state} = Binding.extract_token({"/if", state}, %{})
    state.outcome == :error
  end




  @tag :email
  @tag :dynamic_template
  test "Extract Default Binding" do
    template = """
    {{!bind required.variable.hint}}
    {{! regular comment }}
    {{!-- comment with nested tokens {{#if !condition}} --}}
    {{#if selection}}
      {{apple}}
      {{#with nested}}
         {{this.stuff | ignore}}
         {{#with this.stuff.user_name as | myguy | }}
            {{myguy.first_name | output_pipe}}
         {{/with}}
      {{/with}}
    {{/if}}

    {{ nested.stuff.user_name.last_name }}
    {{#with nested.stuff.user_name as | myguy | }}
       {{myguy.first_name | output_pipe}}
    {{/with}}


    {{#unless selection}}
        {{oh.my}}
    {{else}}
      {{oh.goodness}}
    {{/unless}}

    """
    sut = Binding.extract(template)
    assert sut.outcome == :ok
    assert sut.last_error == nil

    [h|t] = sut.section_stack
    assert h.bind[{:select, "nested"}][{:key, "stuff"}][{:key, "user_name"}][{:key, "first_name"}] == %{}
    assert h.bind[{:select, "nested"}][{:key, "stuff"}][{:key, "user_name"}][{:key, "last_name"}] == %{}
    assert h.bind[{:select, "required"}][{:key, "variable"}][{:key, "hint"}] == %{}
    assert h.bind[{:select, "selection"}] == %{}
    assert length(sut.section_stack) == 1
    assert length(h.children) == 3
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