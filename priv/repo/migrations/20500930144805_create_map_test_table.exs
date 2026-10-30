defmodule Localize.Unit.SQL.Repo.Migrations.CreateMapProductTable do
  use Ecto.Migration

  def change do
    create table(:map_products) do
      add(:weight, :map)
      add(:length, :map)
      timestamps()
    end
  end
end
