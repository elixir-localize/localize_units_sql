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

    def type do
      :map
    end

    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_binary(value) do
      case Decimal.parse(value) do
        {decimal, ""} -> loaded(Localize.Unit.new(decimal, to_string(unit_name), usage: usage))
        _not_a_number -> :error
      end
    end

    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_integer(value) do
      loaded(Localize.Unit.new(value, to_string(unit_name), usage: usage))
    end

    def load(%{"unit" => unit_name, "value" => value}) when is_binary(value) do
      case Decimal.parse(value) do
        {decimal, ""} -> loaded(Localize.Unit.new(decimal, to_string(unit_name)))
        _not_a_number -> :error
      end
    end

    def load(%{"unit" => unit_name, "value" => value}) when is_integer(value) do
      loaded(Localize.Unit.new(value, to_string(unit_name)))
    end

    def dump(%Localize.Unit{name: unit_name, value: value}) do
      {:ok, %{"unit" => to_string(unit_name), "value" => to_string(value)}}
    end

    def dump(_) do
      :error
    end

    # `Ecto.Type.load/1` answers `:error` for a value it cannot load.
    defp loaded({:ok, unit}), do: {:ok, unit}
    defp loaded({:error, _exception}), do: :error
  end
end
