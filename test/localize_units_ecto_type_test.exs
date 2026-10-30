defmodule Localize.Unit.Ecto.Callbacks.Test do
  # The Ecto.Type callbacks beyond cast/1, load/1 and dump/1 that the
  # schema tests do not reach.
  use ExUnit.Case, async: true

  alias Localize.Unit.Ecto.Composite.Type, as: UnitComposite
  alias Localize.Unit.Ecto.Map.Type, as: UnitMap
  alias Localize.UnitWithUsage.Ecto.Composite.Type, as: UsageComposite
  alias Localize.UnitWithUsage.Ecto.Map.Type, as: UsageMap

  @types [UnitComposite, UnitMap, UsageComposite, UsageMap]

  doctest Localize.Unit.Ecto.Composite.Type
  doctest Localize.UnitWithUsage.Ecto.Composite.Type

  for type <- @types do
    test "#{inspect(type)}: embeds as itself" do
      assert unquote(type).embed_as(:json) == :self
    end

    test "#{inspect(type)}: units are equal when they have the same name and value" do
      type = unquote(type)

      assert type.equal?(Localize.Unit.new!(100, "meter"), Localize.Unit.new!(100, "meter"))

      assert type.equal?(
               Localize.Unit.new!(100, "meter"),
               Localize.Unit.new!(Decimal.new("100.0"), "meter")
             )

      assert type.equal?(
               Localize.Unit.new!(2.5, "meter"),
               Localize.Unit.new!(Decimal.new("2.50"), "meter")
             )
    end

    test "#{inspect(type)}: the same quantity in another unit is a change" do
      type = unquote(type)

      refute type.equal?(
               Localize.Unit.new!(100, "meter"),
               Localize.Unit.new!(10_000, "centimeter")
             )

      refute type.equal?(Localize.Unit.new!(100, "meter"), Localize.Unit.new!(3, "foot"))
    end

    test "#{inspect(type)}: values are compared exactly, not as floats" do
      refute unquote(type).equal?(
               Localize.Unit.new!(Decimal.new("0.1"), "meter"),
               Localize.Unit.new!(Decimal.new("0.1000000000000000000001"), "meter")
             )
    end

    test "#{inspect(type)}: casts a float value" do
      assert unquote(type).cast(%{"unit" => "meter", "value" => 1.5}) ==
               {:ok, Localize.Unit.new!(Decimal.new("1.5"), "meter")}

      assert unquote(type).cast(%{unit: "meter", value: 1.5}) ==
               {:ok, Localize.Unit.new!(Decimal.new("1.5"), "meter")}
    end

    test "#{inspect(type)}: other values are equal when they are the same" do
      assert unquote(type).equal?(nil, nil)
      refute unquote(type).equal?(1, 2)
    end
  end

  describe "usage in equal?/2" do
    test "a change of usage is a change for the types that store it" do
      road = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "road")
      person = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "person")
      plain = Localize.Unit.new!(Decimal.new("3.25"), "meter")

      for type <- [UsageComposite, UsageMap] do
        refute type.equal?(road, person)
        refute type.equal?(road, plain)
        assert type.equal?(road, road)
      end
    end

    test "usage is ignored by the types that do not store it" do
      road = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "road")
      person = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "person")

      for type <- [UnitComposite, UnitMap] do
        assert type.equal?(road, person)
      end
    end

    test "a changeset records a change of usage" do
      road = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "road")
      person = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "person")

      changeset = Ecto.Changeset.change(%Product{length: road}, length: person)
      assert changeset.changes == %{length: person}

      changeset =
        Ecto.Changeset.cast(
          %Product{length: road},
          %{"length" => %{"unit" => "meter", "value" => "3.25", "usage" => "person"}},
          [:length]
        )

      assert changeset.changes == %{length: person}
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

    test "the usage may be left out of a string-keyed map" do
      assert UsageComposite.cast(%{"unit" => "meter", "value" => "1"}) ==
               {:ok, Localize.Unit.new!(Decimal.new(1), "meter")}

      assert UsageMap.cast(%{"unit" => "meter", "value" => 2}) ==
               {:ok, Localize.Unit.new!(Decimal.new(2), "meter")}
    end

    test "a value of the wrong shape does not load" do
      assert UnitComposite.load({"meter", 1, "person"}) == :error
      assert UsageComposite.load({"meter", 1}) == :error
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
        assert type.load(%{"unit" => "meter", "value" => nil}) == :error
        assert type.load(%{"unit" => "meter"}) == :error
        assert type.load("meter") == :error
      end
    end

    test "a float value loads" do
      for type <- [UnitMap, UsageMap] do
        assert type.load(%{"unit" => "meter", "value" => 1.5}) ==
                 {:ok, Localize.Unit.new!(1.5, "meter")}
      end
    end

    test "Localize.Unit.Ecto.Map.Type loads an empty usage as no usage" do
      assert UnitMap.load(%{"unit" => "meter", "value" => "2", "usage" => ""}) ==
               {:ok, Localize.Unit.new!(Decimal.new(2), "meter")}
    end
  end
end
