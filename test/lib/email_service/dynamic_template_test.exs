#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.DynamicTemplateTest do
  use ExUnit.Case, async: false
  require Logger
  alias  Noizu.EmailService.Email.Binding.Substitution.Dynamic, as: Binding
  alias Binding.Error
  alias Binding.Section
  alias Binding.Selector

  @context Noizu.ElixirCore.CallingContext.admin()

  @default_binding %{
    required: %{
      only_if_selection: %{
        hint: 42
      },
      only_unless_else_selection: %{
        hint: 41
      },
      variable: %{
        hint: 7,
      }
    },
    selection: {:tuple, :clause},
    apple: %{

    },
    snapple: %{
      details: [
        %{width: 8}, %{width: 2, not_bound: 5}, %{width: :tiger}
      ]
    },
    nested: %{
      stuff: %{
        user_name: %{
          "first_name" => "adam",
          "last_name" => "smith",
          :via_alias => :robin,
          scalar_embed: {:this, :will, :copied, :in, :full, :due, :to, :stuff, :output}
        }
      },
      stuff2: %{
        user_name: %{
          "first_name" => "adam",
          "last_name" => "smith",
          :via_alias => :robin,
          scalar_embed: {:this, :will, :store, :as, :true}
        }
      }
    },
    oh: %{
      my: 1,
      goodness: -1
    }
  }

  @template """
  {{!bind required.variable.hint}}
  {{! regular comment }}
  {{!-- comment with nested tokens {{#if !condition}} --}}
  {{#if selection}}
    {{apple}}
    {{#each snapple.details}}
      {{this.width}}
    {{/each}}

    {{!bind required.only_if_selection.hint}}
    {{#with nested}}
       {{this.stuff | ignore}}
       {{#with this.stuff.user_name as | myguy | }}
          {{myguy.first_name | output_pipe}}
          {{myguy.via_alias}}
       {{/with}}
    {{/with}}
  {{else}}
    {{!bind required.only_else_selection.hint}}
  {{/if}}

  {{ nested.stuff2.user_name.last_name }}
  {{#with nested.stuff2.user_name as | myguy | }}
     {{myguy.first_name | output_pipe}}
     {{myguy.unbound_field}}
     {{#if myguy.optional_unbound}} test {{/if}}
     {{#if myguy.scalar_embed }} test2 {{/if}}
  {{/with}}

  {{#unless selection}}
      {{oh.my}}
  {{else}}
    {{!bind required.only_unless_else_selection.hint}}
    {{oh.goodness}}
  {{/unless}}

  """

  @tag :email
  @tag :dynamic_template
  test "Current Selector (root)" do
    selector = fixture(:default)
               |> Binding.current_selector()
    assert selector == %Selector{selector: []}
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
    assert selector_or_error == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
  end


  @tag :email
  @tag :dynamic_template
  test "Extract Selector (root): hello.dolly[@index]" do
    {selector_or_error, _state} = fixture(:default)
                                 |> Binding.extract_selector("!bind hello.dolly[@index]")
    assert selector_or_error == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}, {:at, "@index"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Current Selector (foo.biz)" do
    selector = fixture(:foo_biz)
               |> Binding.current_selector()
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): this" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("this")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): this.dolly" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("this.dolly")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): ." do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector(".")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): ../" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("../")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}]}
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
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz.bop): ../dolly" do
    {selector_or_error, _state} = fixture(:foo_biz_bop)
                                 |> Binding.extract_selector("../dolly")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz.bop): ../dolly | pipe" do
    {selector_or_error, _state} = fixture(:foo_biz_bop)
                                 |> Binding.extract_selector("../dolly | pipe")
    assert selector_or_error == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): hello.dolly" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("!bind hello.dolly")
    assert selector_or_error == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "Extract Selector (foo.biz): hello.dolly[@index]" do
    {selector_or_error, _state} = fixture(:foo_biz)
                                 |> Binding.extract_selector("!bind hello.dolly[@index]")
    assert selector_or_error == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}, {:at, "@index"}]}
  end


  @tag :email
  @tag :dynamic_template
  test "With Section: hello.dolly" do
    state = fixture(:foo_biz)
    {:cont, state} =  Binding.extract_token({"#with hello.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
    [h,_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
  end

  @tag :email
  @tag :dynamic_template
  test "With Section: hello.dolly as | sheep | " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with hello.dolly as | sheep | ", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}

    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
    assert h.match["sheep"] == %Selector{selector: [ {:select, "hello"}, {:key, "dolly"}]}
    assert t.bind == []
  end

  @tag :email
  @tag :dynamic_template
  test "With Section (foo.biz): this.dolly " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []

  end

  @tag :email
  @tag :dynamic_template
  test "With Section (foo.biz): this.dolly as | sheep | " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#with this.dolly as | sheep | ", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []
    assert h.match["sheep"] == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
  end


  @tag :email
  @tag :dynamic_template
  test "If Section (foo.biz): this.dolly " do
    state = fixture(:foo_biz)
    {:cont, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}

    [h,t|_] = state.section_stack
    assert h.section == :if
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})


    # Confirm expected state after with
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []
    #----

    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})

    # Confirm expected state after nested with.
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}, {:key, "henry"}]}
    assert h.match["bob"] == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}, {:key, "henry"}]}
    assert t.bind == []
    #----

    {_, state} = Binding.extract_token({"/with", state}, %{})

    # Confirm expected state after returning to first with
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    [h,t|_] = state.section_stack
    assert h.section == :with
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []
    #----

    {_, state} = Binding.extract_token({"/with", state}, %{})

    # Confirm expected state after returning to first if
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
    [h,t|_] = state.section_stack
    assert h.section == :if
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}]}
    assert t.bind == []
    #----

    {_, state} = Binding.extract_token({"/if", state}, %{})

    # Confirm expected state after returning to root (not selector is still set for this because of fixture construction)
    selector = Binding.current_selector(state)
    assert selector == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}
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

    [h|_] = state.section_stack

    assert h.section == {:unsupported, "apple"}
    assert h.clause == %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "dolly"}, {:key, "henry"}, {:key, "douglas"}]} # , as: "bob"

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
    [h|_] = state.section_stack
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
    assert state.outcome == :ok # error not set at this level of parsing.
    assert state.last_error.error == {:tag_close_mismatch, :if}
  end


  @tag :email
  @tag :dynamic_template
  test "Section Nesting| invalid close" do
    state = fixture(:foo_biz)
    {_, state} = Binding.extract_token({"#if this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.dolly", state}, %{})
    {_, state} = Binding.extract_token({"#with this.henry as | bob | ", state}, %{})
    {:halt, state} = Binding.extract_token({"/if", state}, %{})
    assert state.outcome == :ok # error not set at this level of parsing.
    assert state.last_error.error == {:tag_close_mismatch, :if}
  end




  @tag :email
  @tag :dynamic_template
  test "Extract Default Binding" do
    sut = Binding.extract(@template)
    assert sut.outcome == :ok
    assert sut.last_error == nil

    [h|_] = sut.section_stack

    assert length(h.bind) == 4
    assert Enum.at(h.bind, 0).selector == [ {:select, "nested"}, {:key, "stuff2"}, {:key, "user_name"}, {:key, "last_name"}]
    assert Enum.at(h.bind, 1).selector == [ {:select, "required"}, {:key, "variable"}, {:key, "hint"}]
    assert Enum.at(h.bind, 2).selector == [ {:select, "nested"}, {:key, "stuff2"}, {:key, "user_name"}, {:key, "unbound_field"}]
    assert Enum.at(h.bind, 3).selector == [ {:select, "nested"}, {:key, "stuff2"}, {:key, "user_name"}, {:key, "first_name"}]


    [i|_] = h.children
    i = i.then_clause
    assert Enum.at(i.bind, 0).selector == [ {:select, "required"}, {:key, "only_if_selection"}, {:key, "hint"}]
    assert length(sut.section_stack) == 1
    assert length(h.children) == 4
  end

  @tag :email
  @tag :dynamic_template
  test "Prepare Effective Bindings" do
    sut = Binding.extract(@template)
    assert sut.outcome == :ok
    assert sut.last_error == nil

    # define variable selector
    state = %Noizu.RuleEngine.State.InlineStateManager{}
    options = %{variable_extractor: &Noizu.EmailService.Email.Binding.Substitution.Dynamic.variable_extractor/4}
    state = Noizu.RuleEngine.StateProtocol.put!(state, :bind_space, @default_binding, @context)

    {response, _state} = Noizu.RuleEngine.ScriptProtocol.execute!(sut, state, @context, options)

    alias_test = Enum.filter(response.bind, fn(v) -> v.selector ==  [ {:select, "nested"}, {:key, "stuff"}, {:key, "user_name"}, {:key, "via_alias"}] end)
    assert length(alias_test) == 1

    _output = """
    %Noizu.EmailService.Email.Binding.Dynamic.Effective{
      bind: [Selector(nested.stuff2.user_name.last_name),
       Selector(required.variable.hint),
       Selector(nested.stuff2.user_name.unbound_field),
       Selector(nested.stuff2.user_name.first_name), Selector(selection.(?)),
       Selector(required.only_if_selection.hint), Selector(apple),
       Selector(nested.stuff), Selector(nested.stuff.user_name.via_alias),
       Selector(nested.stuff.user_name.first_name),
       Selector(snapple.details.[n].width), Selector(snapple.details.[n].width),
       Selector(snapple.details.[n].width),
       Selector(nested.stuff2.user_name.optional_unbound.(?)),
       Selector(nested.stuff2.user_name.scalar_embed.(?)), Selector(oh.goodness),
       Selector(required.only_unless_else_selection.hint)],
      bound: %{
        "apple" => %{},
        "nested" => %{
          "stuff" => %{
            user_name: %{
              :scalar_embed => {:this, :will, :copied, :in, :full, :due, :to, :stuff, :output},
              :via_alias => :robin,
              "first_name" => "adam",
              "last_name" => "smith"
            }
          },
          "stuff2" => %{
            "user_name" => %{
              "first_name" => "adam",
              "last_name" => "smith",
              "scalar_embed" => true
            }
          }
        },
        "oh" => %{"goodness" => -1},
        "required" => %{
          "only_if_selection" => %{"hint" => 42},
          "only_unless_else_selection" => %{"hint" => 41},
          "variable" => %{"hint" => 7}
        },
        "selection" => true,
        "snapple" => %{
          "details" => [%{"width" => 8}, %{"width" => 2}, %{"width" => :tiger}]
        }
      },
      meta: %{},
      unbound: %{
        optional: [Selector(nested.stuff2.user_name.optional_unbound.(?))],
        required: [Selector(nested.stuff2.user_name.unbound_field)]
      },
      vsn: 1.0
    }
    """

    assert response.bound["apple"] == %{}
    assert response.bound["nested"]["stuff"].user_name.scalar_embed == {:this, :will, :copied, :in, :full, :due, :to, :stuff, :output}
    assert response.bound["nested"]["stuff"].user_name.via_alias == :robin
    assert response.bound["nested"]["stuff2"]["user_name"]["scalar_embed"] == true  # full contents dropped as they are not referenced by template, just checked for existence.
    assert response.bound["oh"]["goodness"] == -1
    assert response.bound["oh"]["my"] == nil
    assert response.bound["required"]["only_if_selection"]["hint"] == 42
    assert response.bound["required"]["only_else_selection"]["hint"] == nil
    assert response.bound["required"]["only_unless_else_selection"]["hint"] == 41
    assert Enum.at(response.bound["snapple"]["details"], 1)["width"] == 2
    assert Enum.at(response.bound["snapple"]["details"], 1)["not_bound"] == nil
    assert Enum.at(response.bound["snapple"]["details"], 2)["width"] == :tiger

    assert Enum.at(response.unbound.optional, 0).selector == [{:select, "nested"}, {:key, "stuff2"}, {:key, "user_name"}, {:key, "optional_unbound"}, :scalar_value]
    assert Enum.at(response.unbound.required, 0).selector == [{:select, "nested"}, {:key, "stuff2"}, {:key, "user_name"}, {:key, "unbound_field"}]


  end

  def fixture(fixture, options \\ %{})
  def fixture(:default, _options) do
    %Noizu.EmailService.Email.Binding.Substitution.Dynamic{}
  end
  def fixture(:foo_biz, _options) do
    %Noizu.EmailService.Email.Binding.Substitution.Dynamic{
      section_stack: [%Section{current_selector: %Selector{selector: [ {:select, "foo"}, {:key, "biz"}]}}]
    }
  end
  def fixture(:foo_biz_bop, _options) do
    %Noizu.EmailService.Email.Binding.Substitution.Dynamic{
      section_stack: [%Section{current_selector: %Selector{selector: [ {:select, "foo"}, {:key, "biz"}, {:key, "bop"}]}}]
    }
  end

end