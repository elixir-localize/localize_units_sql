defmodule Localize.Unit.SQL.Test do
  use Localize.Unit.SQL.RepoCase

  test "insert a record with a unit value" do
    m = Localize.Unit.new!(100, "meter")
    Repo.insert(%Product{weight: m})
    assert {:ok, struct} = Repo.insert(%Product{weight: m})
    assert Localize.Unit.compare(m, struct.weight) == :eq
  end

  test "select aggregate function sum on a :cldr_unit type" do
    m = Localize.Unit.new!(100, "meter", usage: "person")
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = select(Product, [o], type(sum(o.weight), o.weight)) |> Repo.one()
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    sum = select(Product, [o], type(sum(o.length), o.length)) |> Repo.one()
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq
    assert sum.usage == "person"
  end

  test "Repo.aggregate function sum on a :cldr_unit type" do
    m = Localize.Unit.new!(100, "meter", usage: "person")
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = Repo.aggregate(Product, :sum, :weight)
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    sum = Repo.aggregate(Product, :sum, :length)
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq
    assert sum.usage == "person"
  end

  test "Exception is raised if trying to sum different units" do
    m = Localize.Unit.new!(100, "meter")
    m2 = Localize.Unit.new!(100, "foot")
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})

    assert_raise Postgrex.Error, fn ->
      Repo.aggregate(Product, :sum, :weight)
    end

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m2})

    assert_raise Postgrex.Error, fn ->
      Repo.aggregate(Product, :sum, :length)
    end
  end

  test "select distinct aggregate function sum on a :cldr_unit type" do
    m = Localize.Unit.new!(100, "meter", usage: "person")
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: Localize.Unit.new!(200, "meter", usage: "person")})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.weight), o.weight))
    sum = query |> Repo.one()
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: Localize.Unit.new!(200, "meter", usage: "person")})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.length), o.length))
    sum = query |> Repo.one()
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq
    assert sum.usage == "person"
  end

  test "select distinct aggregate function sum on a :cldr_unit_with_usage type" do
    m = Localize.Unit.new!(100, "meter")
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: Localize.Unit.new!(200, "meter")})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.length), o.length))
    sum = query |> Repo.one()
    assert Localize.Unit.compare(sum, Localize.Unit.new!(Decimal.new(300), "meter")) == :eq
  end

  test "inserting a unit with a usage" do
    weight = Localize.Unit.new!(200, "meter", usage: "person")
    {:ok, _} = Repo.insert(%Product{length: weight})

    result = select(Product, [o], o.length) |> Repo.one()
    assert result.usage == "person"
  end

  test "filter on a unit type" do
    m = Localize.Unit.new!(100, "meter")
    m2 = Localize.Unit.new!(200, "foot")

    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})

    query =
      from(o in Product,
        where: fragment("unit(weight)") == "meter",
        select: sum(o.weight)
      )

    result = query |> Repo.one()

    assert result == Localize.Unit.new!(Decimal.new(200), "meter")
  end
end
