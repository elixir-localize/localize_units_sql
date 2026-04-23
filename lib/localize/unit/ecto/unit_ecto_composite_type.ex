if Code.ensure_loaded?(Ecto.Type) do
  defmodule Localize.Unit.Ecto.Composite.Type do
    @moduledoc """
    Implements the `Ecto.Type` behaviour for a user-defined Postgres composite
    type called `:cldr_unit`.

    This is the preferred option for Postgres databases since the serialized
    unit value is stored as a decimal number.

    """

    @behaviour Ecto.Type

    def type do
      :cldr_unit
    end

    def blank?(_) do
      false
    end

    def load({unit_name, unit_value}) do
      with {:ok, unit} <- Localize.Unit.new(unit_value, to_string(unit_name)) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def dump(%Localize.Unit{} = unit) do
      {:ok, {to_string(unit.name), unit.value}}
    end

    def dump(_) do
      :error
    end

    @dialyzer {:nowarn_function, {:cast, 1}}

    def cast(%Localize.Unit{} = unit) do
      {:ok, unit}
    end

    def cast(%{"unit" => _, "value" => ""}) do
      {:ok, nil}
    end

    def cast(%{"unit" => unit_name, "value" => value})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_number(value) do
      with decimal_value <- Decimal.new(value),
           {:ok, unit} <- Localize.Unit.new(decimal_value, to_string(unit_name)) do
        {:ok, unit}
      else
        :error -> {:error, message: "Couldn't cast value #{inspect(value)}"}
        {:error, exception} -> {:error, message: Exception.message(exception)}
      end
    end

    def cast(%{"unit" => unit_name, "value" => value})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_binary(value) do
      with {value, ""} <- Decimal.parse(value),
           {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name)) do
        {:ok, unit}
      else
        {:error, exception} -> {:error, message: Exception.message(exception)}
        :error -> {:error, message: "Couldn't parse value #{inspect(value)}"}
      end
    end

    def cast(%{"unit" => unit_name, "value" => %Decimal{} = value})
        when is_binary(unit_name) or is_atom(unit_name) do
      with {:ok, unit} <- Localize.Unit.new(value, to_string(unit_name)) do
        {:ok, unit}
      else
        {:error, exception} -> {:error, message: Exception.message(exception)}
        :error -> {:error, message: "Couldn't cast value #{inspect(value)}"}
      end
    end

    def cast(%{unit: unit_name, value: value}) do
      cast(%{"unit" => unit_name, "value" => value})
    end

    def cast(_unit) do
      :error
    end

    def embed_as(_), do: :self

    def equal?(%Localize.Unit{} = term1, %Localize.Unit{} = term2) do
      case Localize.Unit.compare(term1, term2) do
        :eq -> true
        _ -> false
      end
    end

    def equal?(term1, term2), do: term1 == term2
  end
end
