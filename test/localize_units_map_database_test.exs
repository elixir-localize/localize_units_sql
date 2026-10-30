defmodule Localize.Unit.Map.Database.Test do
  # The map types are stored as `jsonb`, which Postgrex encodes with `JSON`
  # (Elixir 1.18 and later).
  use Localize.Unit.SQL.RepoCase

  if not Code.ensure_loaded?(JSON), do: @moduletag(:skip)

  test "a unit round-trips through a map column" do
    weight = Localize.Unit.new!(Decimal.new("100.25"), "kilogram")
    length = Localize.Unit.new!(Decimal.new("1.85"), "meter", usage: "person")

    {:ok, %{id: id}} = Repo.insert(%MapProduct{weight: weight, length: length})
    product = Repo.get!(MapProduct, id)

    assert product.weight == weight
    assert product.length == length
  end

  test "the value is stored as a string" do
    {:ok, _product} = Repo.insert(%MapProduct{weight: Localize.Unit.new!(100, "kilogram")})

    assert Repo.query!("SELECT weight FROM map_products").rows ==
             [[%{"unit" => "kilogram", "value" => "100"}]]
  end

  test "a change of usage is written" do
    road = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "road")
    person = Localize.Unit.new!(Decimal.new("3.25"), "meter", usage: "person")

    {:ok, product} = Repo.insert(%MapProduct{length: road})
    {:ok, _product} = product |> Ecto.Changeset.change(length: person) |> Repo.update()

    assert Repo.get!(MapProduct, product.id).length == person
  end
end
