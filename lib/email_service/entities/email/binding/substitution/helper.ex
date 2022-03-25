#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Substitution.Helper do

  def prepare_effective_binding(a, _state, _context, _options) do
    a
  end

  def merge_effective_binding(a,b, state, context, options) do
    Enum.reduce(b || %{}, a || %{}, fn({k,v},acc) ->
      update_in(acc, [k], fn(p) ->
        p && merge_effective_binding(p, v, state, context, options) || v
      end)
    end)
  end
end