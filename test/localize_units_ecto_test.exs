defmodule Localize.Unit.Ecto.Test do
  use ExUnit.Case

  describe "Localize.Unit.Ecto.Composite.Type specific tests" do
    test "load a tuple with an unknown unit produces an error" do
      assert Localize.Unit.Ecto.Composite.Type.load({"ABC", 100}) == :error
    end

    test "load a tuple produces a Localize.Unit struct" do
      assert Localize.Unit.Ecto.Composite.Type.load({"meter", 100}) ==
               {:ok, Localize.Unit.new!(100, "meter")}
    end

    test "dump a unit struct" do
      assert Localize.Unit.Ecto.Composite.Type.dump(Localize.Unit.new!(100, "meter")) ==
               {:ok, {"meter", 100}}
    end
  end

  describe "Localize.Unit.Ecto.Map.Type specific tests" do
    test "load a json map with a string value produces a Localize.Unit struct" do
      assert Localize.Unit.Ecto.Map.Type.load(%{"unit" => "meter", "value" => "100"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "load a json map with a number value produces a Localize.Unit struct" do
      assert Localize.Unit.Ecto.Map.Type.load(%{"unit" => "meter", "value" => 100}) ==
               {:ok, Localize.Unit.new!(100, "meter")}
    end

    test "load a json map with an unknown unit code produces an error" do
      assert Localize.Unit.Ecto.Map.Type.load(%{"unit" => "AAA", "value" => 100}) == :error
    end

    test "dump a unit struct" do
      assert Localize.Unit.Ecto.Map.Type.dump(Localize.Unit.new!(100, "meter")) ==
               {:ok, %{"value" => "100", "unit" => "meter"}}
    end
  end

  for ecto_type_module <- [Localize.Unit.Ecto.Composite.Type, Localize.Unit.Ecto.Map.Type] do
    test "#{inspect(ecto_type_module)}: dump anything other than a Localize.Unit struct or a 2-tuple is an error" do
      assert unquote(ecto_type_module).dump(100) == :error
    end

    test "#{inspect(ecto_type_module)}: cast a map with the current structure but an empty value" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => ""}) == {:ok, nil}
    end

    test "#{inspect(ecto_type_module)}: cast a unit struct" do
      assert unquote(ecto_type_module).cast(Localize.Unit.new!(100, "meter")) ==
               {:ok, Localize.Unit.new!(100, "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and values" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => "100"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    # A string that is a number followed by more text is no value: it is a
    # cast error, where it raised WithClauseError.
    test "#{inspect(ecto_type_module)}: cast a value with trailing text is an error" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => "12abc"})

      assert message =~ "12abc"
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => 100}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{"unit" => :meter, "value" => "100"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{"unit" => :meter, "value" => 100}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and invalid unit" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{"unit" => "AAA", "value" => 100})

      assert message =~ "AAA"
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and values" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: "100"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: 100}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: 100}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: "100"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and invalid unit" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{unit: "AAA", value: 100})

      assert message =~ "AAA"
    end

    test "#{inspect(ecto_type_module)}: cast anything else is an error" do
      assert unquote(ecto_type_module).cast(:atom) == :error
    end
  end
end
