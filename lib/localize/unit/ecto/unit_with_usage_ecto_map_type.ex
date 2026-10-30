if Code.ensure_loaded?(Ecto.Type) do
  defmodule Localize.UnitWithUsage.Ecto.Map.Type do
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

    @impl Ecto.Type
    defdelegate cast(unit), to: Localize.UnitWithUsage.Ecto.Composite.Type

    @impl Ecto.Type
    defdelegate embed_as(term), to: Localize.UnitWithUsage.Ecto.Composite.Type
    @impl Ecto.Type
    defdelegate equal?(term1, term2), to: Localize.UnitWithUsage.Ecto.Composite.Type

    @impl Ecto.Type
    def type do
      :map
    end

    @impl Ecto.Type
    def load(%{"unit" => unit_name, "value" => value} = unit) do
      with {:ok, value} <- load_value(value) do
        loaded(new_unit(value, unit_name, Map.get(unit, "usage")))
      end
    end

    def load(_value) do
      :error
    end

    @impl Ecto.Type
    def dump(%Localize.Unit{name: unit_name, value: value, usage: usage}) do
      {:ok,
       %{
         "unit" => to_string(unit_name),
         "value" => to_string(value),
         "usage" => usage && to_string(usage)
       }}
    end

    def dump(_) do
      :error
    end

    # `Ecto.Type.load/1` answers `:error` for a value it cannot load.
    defp loaded({:ok, unit}), do: {:ok, unit}
    defp loaded({:error, _exception}), do: :error

    defp load_value(value) when is_number(value), do: {:ok, value}

    defp load_value(value) when is_binary(value) do
      case Decimal.parse(value) do
        {decimal, ""} -> {:ok, decimal}
        _not_a_number -> :error
      end
    end

    defp load_value(_value), do: :error

    defp new_unit(value, unit_name, usage) when usage in [nil, ""] do
      Localize.Unit.new(value, to_string(unit_name))
    end

    defp new_unit(value, unit_name, usage) do
      Localize.Unit.new(value, to_string(unit_name), usage: to_string(usage))
    end
  end
end
