if Code.ensure_loaded?(Ecto.Type) do
  defmodule Localize.UnitWithUsage.Ecto.Composite.Type do
    @moduledoc """
    Implements the `Ecto.Type` behaviour for a user-defined Postgres composite
    type called `:cldr_unit_with_usage`.

    This is the preferred option for Postgres databases since the serialized
    unit value is stored as a decimal number and the unit usage is preserved
    across the round trip.

    """

    @behaviour Ecto.Type

    alias Localize.Unit.Ecto.Composite.Type, as: UnitType

    @impl Ecto.Type
    def type do
      :cldr_unit_with_usage
    end

    @doc """
    Returns whether a unit is blank, which it never is.

    ### Arguments

    * `unit` is any term.

    ### Returns

    * `false`.

    ### Examples

        iex> Localize.UnitWithUsage.Ecto.Composite.Type.blank?(Localize.Unit.new!(1, "meter"))
        false

    """
    def blank?(_unit) do
      false
    end

    @impl Ecto.Type
    def load({unit_name, unit_value, unit_usage}) when unit_usage in [nil, ""] do
      loaded(Localize.Unit.new(unit_value, to_string(unit_name)))
    end

    def load({unit_name, unit_value, unit_usage}) do
      loaded(Localize.Unit.new(unit_value, to_string(unit_name), usage: to_string(unit_usage)))
    end

    def load(_value) do
      :error
    end

    @impl Ecto.Type
    def dump(%Localize.Unit{} = unit) do
      {:ok, {to_string(unit.name), unit.value, unit.usage && to_string(unit.usage)}}
    end

    def dump(_) do
      :error
    end

    @dialyzer {:nowarn_function, {:cast, 1}}

    @impl Ecto.Type
    def cast(%Localize.Unit{} = unit) do
      {:ok, unit}
    end

    def cast(%{"unit" => _, "value" => ""}) do
      {:ok, nil}
    end

    def cast(%{"unit" => unit_name, "value" => value, "usage" => usage})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_number(value) do
      value
      |> UnitType.to_decimal()
      |> cast_unit(unit_name, usage)
    end

    def cast(%{"unit" => unit_name, "value" => value, "usage" => usage})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_binary(value) do
      case Decimal.parse(value) do
        {decimal, ""} -> cast_unit(decimal, unit_name, usage)
        _not_a_number -> {:error, message: "Couldn't parse value #{inspect(value)}"}
      end
    end

    def cast(%{"unit" => unit_name, "value" => %Decimal{} = value, "usage" => usage})
        when is_binary(unit_name) or is_atom(unit_name) do
      cast_unit(value, unit_name, usage)
    end

    # The usage is optional, as it is in the atom-keyed form below.
    def cast(%{"unit" => _unit_name, "value" => _value} = unit)
        when not is_map_key(unit, "usage") do
      cast(Map.put(unit, "usage", nil))
    end

    def cast(%{unit: unit_name, value: value} = unit) do
      cast(%{"unit" => unit_name, "value" => value, "usage" => Map.get(unit, :usage)})
    end

    def cast(_unit) do
      :error
    end

    @impl Ecto.Type
    def embed_as(_format), do: :self

    # Two units are equal when they would be stored the same: the same unit
    # name, the same value and the same usage.
    @impl Ecto.Type
    def equal?(%Localize.Unit{} = term1, %Localize.Unit{} = term2) do
      UnitType.equal?(term1, term2) and to_usage(term1.usage) == to_usage(term2.usage)
    end

    def equal?(term1, term2), do: term1 == term2

    # `Ecto.Type.load/1` answers `:error` for a value it cannot load, and
    # `cast/1` an error with a message.
    defp loaded({:ok, unit}), do: {:ok, unit}
    defp loaded({:error, _exception}), do: :error

    defp cast_unit(value, unit_name, usage) do
      case Localize.Unit.new(value, to_string(unit_name), usage: to_usage(usage)) do
        {:ok, unit} -> {:ok, unit}
        {:error, exception} -> {:error, message: Exception.message(exception)}
      end
    end

    defp to_usage(nil), do: nil
    defp to_usage(""), do: nil
    defp to_usage(usage), do: to_string(usage)
  end
end
