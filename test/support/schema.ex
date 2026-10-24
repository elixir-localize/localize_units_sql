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
