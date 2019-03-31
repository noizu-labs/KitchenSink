defmodule Noizu.Support.Cms.V2.Database.MockArticleTable do
  @moduledoc false

  def strategy(mock_strategy \\ __MODULE__.DefaultStrategy, mock_settings \\ %{}) do
    [
      read: fn(key) -> mock_strategy.read(mock_settings, key) end,
      read!: fn(key) -> mock_strategy.read!(mock_settings, key) end,
      write: fn(record) -> mock_strategy.write(mock_settings, record) end,
      write!: fn(record) -> mock_strategy.write!(mock_settings, record) end,
      delete: fn(record) -> mock_strategy.delete(mock_settings, record) end,
      delete!: fn(record) -> mock_strategy.delete!(mock_settings, record) end,
      match: fn(selector) -> mock_strategy.match(mock_settings, selector) end,
      match!: fn(selector) -> mock_strategy.match!(mock_settings, selector) end,
    ]
  end

  defmodule DefaultStrategy do
    @stub %{}
    @table Noizu.Cms.V2.Database.ArticleTable

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
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.write(@table, record.identifier, record)
    end

    def delete(mock_settings, record) do
      delete!(mock_settings, record)
    end

    def delete!(_mock_settings, key) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.delete(@table, key)
    end

    def match(mock_settings, selector) do
      match!(mock_settings, selector)
    end

    def match!(_mock_settings, _selector) do
      %Amnesia.Table.Select{values: [], coerce: @table}
    end
  end
end
