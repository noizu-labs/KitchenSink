
defmodule Noizu.KitchenSink.Types do
  alias Noizu.KitchenSink.Types, as: T
  @vsn 1.00
  @type nmid :: integer # Mnesia Id
  @type nmaid :: atom # Mnesia Atom/Constant Id
  @type slug :: String.t
  @type unix_epoch :: integer
  @type vsn :: float
  @type url :: String.t
  @type state :: :enabled | :disabled | :deleted | :pending
  @type subject :: tuple
  @type permissions :: :unrestricted | :private | :public | any

  @type day_month_year :: {integer, integer, integer}

  @type entity_identifier :: T.nmid | T.nmaid | tuple
  @type entity_reference :: {:ref, module, T.entity_identifier}
end # end defmodul
