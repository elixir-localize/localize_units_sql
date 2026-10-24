defmodule Localize.Unit.Ecto.Callbacks.Test do
  # The Ecto.Type callbacks beyond cast/1, load/1 and dump/1 that the
  # schema tests do not reach.
  use ExUnit.Case, async: true

  alias Localize.Unit.Ecto.Composite.Type, as: UnitComposite
  alias Localize.Unit.Ecto.Map.Type, as: UnitMap
  alias Localize.UnitWithUsage.Ecto.Composite.Type, as: UsageComposite
  alias Localize.UnitWithUsage.Ecto.Map.Type, as: UsageMap

  @types [UnitComposite, UnitMap, UsageComposite, UsageMap]

  for type <- @types do
    test "#{inspect(type)}: embeds as itself" do
      assert unquote(type).embed_as(:json) == :self
    end

    test "#{inspect(type)}: units are equal when they compare equal" do
      type = unquote(type)

      assert type.equal?(Localize.Unit.new!(100, "meter"), Localize.Unit.new!(100, "meter"))

      assert type.equal?(
               Localize.Unit.new!(100, "meter"),
               Localize.Unit.new!(10_000, "centimeter")
             )

      refute type.equal?(Localize.Unit.new!(100, "meter"), Localize.Unit.new!(3, "foot"))
    end

    test "#{inspect(type)}: other values are equal when they are the same" do
      assert unquote(type).equal?(nil, nil)
      refute unquote(type).equal?(1, 2)
    end
  end

  describe "the composite types" do
    test "a unit is never blank" do
      refute UnitComposite.blank?(Localize.Unit.new!(100, "meter"))
      refute UsageComposite.blank?(Localize.Unit.new!(100, "meter"))
    end

    test "cast a Decimal value" do
      assert UnitComposite.cast(%{"unit" => "meter", "value" => Decimal.new("2.5")}) ==
               {:ok, Localize.Unit.new!(Decimal.new("2.5"), "meter")}

      assert UsageComposite.cast(%{
               "unit" => "meter",
               "value" => Decimal.new("2.5"),
               "usage" => "person"
             }) ==
               {:ok, Localize.Unit.new!(Decimal.new("2.5"), "meter", usage: "person")}
    end

    test "a nil or empty usage casts as no usage" do
      for usage <- [nil, ""] do
        assert UsageComposite.cast(%{"unit" => "meter", "value" => 2, "usage" => usage}) ==
                 {:ok, Localize.Unit.new!(Decimal.new(2), "meter")}
      end
    end
  end

  describe "the map types" do
    test "are stored as a map" do
      assert UnitMap.type() == :map
      assert UsageMap.type() == :map
    end

    test "Localize.Unit.Ecto.Map.Type loads a map with a usage" do
      assert UnitMap.load(%{"unit" => "meter", "value" => "2", "usage" => "person"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(2), "meter", usage: "person")}

      assert UnitMap.load(%{"unit" => "meter", "value" => 2, "usage" => "person"}) ==
               {:ok, Localize.Unit.new!(2, "meter", usage: "person")}
    end

    test "Localize.UnitWithUsage.Ecto.Map.Type loads a map without a usage" do
      assert UsageMap.load(%{"unit" => "meter", "value" => "2"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(2), "meter")}

      assert UsageMap.load(%{"unit" => "meter", "value" => 2}) ==
               {:ok, Localize.Unit.new!(2, "meter")}
    end

    test "Localize.UnitWithUsage.Ecto.Map.Type loads a nil or empty usage as no usage" do
      assert UsageMap.load(%{"unit" => "meter", "value" => 2, "usage" => nil}) ==
               {:ok, Localize.Unit.new!(2, "meter")}

      assert UsageMap.load(%{"unit" => "meter", "value" => "2", "usage" => ""}) ==
               {:ok, Localize.Unit.new!(Decimal.new(2), "meter")}
    end

    test "a value that is not a number does not load" do
      for type <- [UnitMap, UsageMap] do
        assert type.load(%{"unit" => "meter", "value" => "x"}) == :error
        assert type.load(%{"unit" => "meter", "value" => "x", "usage" => "person"}) == :error
      end
    end
  end
end
