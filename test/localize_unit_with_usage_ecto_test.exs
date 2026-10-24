defmodule Localize.UnitWithUsage.Ecto.Test do
  use ExUnit.Case

  describe "Localize.UnitWithUsage.Ecto.Composite.Type specific tests" do
    test "load a tuple with an unknown unit produces an error" do
      assert Localize.UnitWithUsage.Ecto.Composite.Type.load({"ABC", 100, "default"}) == :error
    end

    test "load a tuple produces a Localize.Unit struct" do
      assert Localize.UnitWithUsage.Ecto.Composite.Type.load({"meter", 100, "default"}) ==
               {:ok, Localize.Unit.new!(100, "meter", usage: "default")}
    end

    test "dump a unit struct" do
      assert Localize.UnitWithUsage.Ecto.Composite.Type.dump(
               Localize.Unit.new!(100, "meter", usage: "default")
             ) ==
               {:ok, {"meter", 100, "default"}}
    end

    test "dump a unit struct with nil usage" do
      assert Localize.UnitWithUsage.Ecto.Composite.Type.dump(Localize.Unit.new!(100, "meter")) ==
               {:ok, {"meter", 100, nil}}
    end
  end

  describe "Localize.UnitWithUsage.Ecto.Map.Type specific tests" do
    test "load a json map with a string value produces a Localize.Unit struct" do
      assert Localize.UnitWithUsage.Ecto.Map.Type.load(%{
               "unit" => "meter",
               "value" => "100",
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "load a json map with a number value produces a Localize.Unit struct" do
      assert Localize.UnitWithUsage.Ecto.Map.Type.load(%{
               "unit" => "meter",
               "value" => 100,
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(100, "meter", usage: "default")}
    end

    test "load a json map with an unknown unit code produces an error" do
      assert Localize.UnitWithUsage.Ecto.Map.Type.load(%{
               "unit" => "AAA",
               "value" => 100,
               "usage" => "default"
             }) == :error
    end

    test "dump a unit struct" do
      assert Localize.UnitWithUsage.Ecto.Map.Type.dump(
               Localize.Unit.new!(100, "meter", usage: "default")
             ) ==
               {:ok, %{"value" => "100", "unit" => "meter", "usage" => "default"}}
    end
  end

  for ecto_type_module <- [
        Localize.UnitWithUsage.Ecto.Composite.Type,
        Localize.UnitWithUsage.Ecto.Map.Type
      ] do
    test "#{inspect(ecto_type_module)}: dump anything other than a Localize.Unit struct or a tuple is an error" do
      assert unquote(ecto_type_module).dump(100) == :error
    end

    test "#{inspect(ecto_type_module)}: cast a map with the current structure but an empty value" do
      assert unquote(ecto_type_module).cast(%{
               "unit" => "meter",
               "value" => "",
               "usage" => "default"
             }) == {:ok, nil}
    end

    test "#{inspect(ecto_type_module)}: cast a unit struct" do
      assert unquote(ecto_type_module).cast(Localize.Unit.new!(100, "meter")) ==
               {:ok, Localize.Unit.new!(100, "meter")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and values" do
      assert unquote(ecto_type_module).cast(%{
               "unit" => "meter",
               "value" => "100",
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    # A string that is a number followed by more text is no value: it is a
    # cast error, where it raised WithClauseError.
    test "#{inspect(ecto_type_module)}: cast a value with trailing text is an error" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{
                 "unit" => "meter",
                 "value" => "12abc",
                 "usage" => "default"
               })

      assert message =~ "12abc"
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{
               "unit" => "meter",
               "value" => 100,
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{
               "unit" => :meter,
               "value" => "100",
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{
               "unit" => :meter,
               "value" => 100,
               "usage" => "default"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and invalid unit" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{
                 "unit" => "AAA",
                 "value" => 100,
                 "usage" => "default"
               })

      assert message =~ "AAA"
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and values" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: "100", usage: "default"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: 100, usage: "default"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: 100, usage: "default"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: "100", usage: "default"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(100), "meter", usage: "default")}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and invalid unit" do
      assert {:error, [message: message]} =
               unquote(ecto_type_module).cast(%{unit: "AAA", value: 100, usage: "default"})

      assert message =~ "AAA"
    end

    test "#{inspect(ecto_type_module)}: cast anything else is an error" do
      assert unquote(ecto_type_module).cast(:atom) == :error
    end
  end
end
