defmodule Product do
  use Ecto.Schema

  @primary_key false
  schema "products" do
    field(:weight, Localize.Unit.Ecto.Composite.Type)
    field(:length, Localize.UnitWithUsage.Ecto.Composite.Type)
    field(:name, :string)
    timestamps()
  end
end

defmodule MapProduct do
  use Ecto.Schema

  schema "map_products" do
    field(:weight, Localize.Unit.Ecto.Map.Type)
    field(:length, Localize.UnitWithUsage.Ecto.Map.Type)
    timestamps()
  end
end
