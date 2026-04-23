if Code.ensure_loaded?(Ecto.Type) do
  defmodule Localize.Unit.Ecto.Map.Type do
    @moduledoc """
    Implements the `Ecto.Type` behaviour for `Localize.Unit`, where the
    underlying schema type is a map.

    This is the required option for databases such as MySQL that do not
    support composite types.

    In order to preserve precision, the value is serialized as a string since
    the JSON representation of a numeric value is either an integer or a
    float.

    `Decimal.to_string/1` is not guaranteed to produce a string that will
    round-trip convert back to the identical number. However given enough
    precision in the [Decimal context](https://hexdocs.pm/decimal/Decimal.Context.html#content)
    then round trip conversion should be expected. The default precision in
    the context is 28 digits.

    """

    @behaviour Ecto.Type

    defdelegate cast(unit), to: Localize.Unit.Ecto.Composite.Type

    defdelegate embed_as(term), to: Localize.Unit.Ecto.Composite.Type
    defdelegate equal?(term1, term2), to: Localize.Unit.Ecto.Composite.Type

    def type() do
      :map
    end

    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_binary(value) do
      with {value, ""} <- Decimal.parse(value),
           {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name), usage: usage) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_integer(value) do
      with {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name), usage: usage) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def load(%{"unit" => unit_name, "value" => value}) when is_binary(value) do
      with {value, ""} <- Decimal.parse(value),
           {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name)) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def load(%{"unit" => unit_name, "value" => value}) when is_integer(value) do
      with {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name)) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def dump(%Localize.Unit{name: unit_name, value: value}) do
      {:ok, %{"unit" => to_string(unit_name), "value" => to_string(value)}}
    end

    def dump(_) do
      :error
    end
  end
end
