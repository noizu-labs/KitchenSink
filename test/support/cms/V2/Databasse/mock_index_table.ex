defmodule Noizu.Support.Cms.V2.Database.MockIndexTable do
  @moduledoc false

  def strategy(mock_strategy \\ __MODULE__.DefaultStrategy, mock_settings \\ %{}) do
    [
      read: fn(key) -> mock_strategy.read(mock_settings, key) end,
      read!: fn(key) -> mock_strategy.read!(mock_settings, key) end,
      write: fn(record) -> mock_strategy.write(mock_settings, record) end,
      write!: fn(record) -> mock_strategy.write!(mock_settings, record) end,
      match: fn(selector) -> mock_strategy.match(mock_settings, selector) end,
      match!: fn(selector) -> mock_strategy.match!(mock_settings, selector) end,
    ]
  end

  defmodule DefaultStrategy do
    @stub %{}
    @table Noizu.Cms.V2.Database.IndexTable

    def read(mock_settings, key) do
      read!(mock_settings, key)
    end

    def read!(_mock_settings, key) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(@table, key, @stub[key])
    end

    def write(mock_settings, record) do
      write!(mock_settings, record)
    end

    def write!(_mock_settings, record) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.write(@table, record.article, record)
    end

    def match(mock_settings, selector) do
      match(mock_settings, selector)
    end

    def match!(_mock_settings, _selector) do
      []
    end
  end
end
