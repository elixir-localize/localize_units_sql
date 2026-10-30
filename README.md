# Introduction to Localize Units SQL

[![Hex pm](http://img.shields.io/hexpm/v/localize_units_sql.svg?style=flat)](https://hex.pm/packages/localize_units_sql)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/elixir-localize/localize_units_sql/blob/v2.1.0/LICENSE.md)

`localize_units_sql` implements a set of functions to store and retrieve data structured as a `Localize.Unit.t()` type that represents a unit of measure and a value. See [localize](https://hex.pm/packages/localize) for details of using `Localize.Unit`. Note that `localize_units_sql` depends on `localize`.

## Prerequisites

* `localize_units_sql` is supported on Elixir 1.17 and later only.

> #### Migrating from `ex_cldr_units_sql` {: .info}
>
> From version 2.0, the package has been renamed from `ex_cldr_units_sql` to `localize_units_sql`. The `Cldr.Unit.*` modules are now `Localize.Unit.*` (for example `Cldr.Unit.Ecto.Composite.Type` becomes `Localize.Unit.Ecto.Composite.Type`). Replace the `ex_cldr` family of dependencies with the unified [localize](https://hex.pm/packages/localize) package and remove any `MyApp.Cldr` backend module. Configure locales through `config :localize`. The Postgres composite type names (`cldr_unit`, `cldr_unit_with_usage`) are unchanged, so existing databases do not require a schema migration.

> #### Postgrex JSON library {: .info}
>
> `localize_units_sql` no longer declares `jason` as a dependency. Postgrex defaults to `Jason` for encoding `json`/`jsonb` columns, so configure your preferred JSON library explicitly, for example `config :postgrex, :json_library, JSON` (requires Elixir 1.18+). Postgrex captures this setting at compile time, so after changing it run `mix deps.compile postgrex --force` once.

> #### Make sure the Ecto type and the database type match! {: .warning}
>
> It's important that each Ecto type is matched with its database type in the migration: `Localize.Unit.Ecto.Composite.Type` with `:cldr_unit`, `Localize.UnitWithUsage.Ecto.Composite.Type` with `:cldr_unit_with_usage`, and `Localize.Unit.Ecto.Map.Type` or `Localize.UnitWithUsage.Ecto.Map.Type` with `:map`.

## Serializing to a Postgres database with Ecto

`localize_units_sql` provides custom Ecto data types and two custom Postgres data types to provide serialization of `Localize.Unit.t()` types without losing precision whilst also maintaining the integrity of the `{unit, value}` relationship. To serialize and retrieve unit types from a database the following steps should be followed:

1. First generate the migration to create the custom type:

```bash
mix units.gen.postgres.cldr_units_migration
* creating priv/repo/migrations
* creating priv/repo/migrations/20161007234652_add_cldr_unit_type_to_postgres.exs
```

2. Then migrate the database:

```bash
mix ecto.migrate
09:56:49.567 [info] == Running 20161007234652 MyApp.Repo.Migrations.AddCldrUnitTypeToPostgres.up/0

09:56:49.570 [info] execute "CREATE TYPE public.cldr_unit AS (unit varchar, value numeric);"

09:56:49.574 [info] execute "CREATE TYPE public.cldr_unit_with_usage AS (unit varchar, value numeric, usage varchar);"

09:56:49.576 [info] == Migrated 20161007234652 in 0.0s
```

3. Create your database migration with the new type (don't forget to `mix ecto.migrate` as well):

```elixir
defmodule Localize.Unit.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :weight, :cldr_unit
      add :length, :cldr_unit_with_usage
      timestamps()
    end
  end
end
```

4. Create your schema using the `Localize.Unit.Ecto.Composite.Type` ecto type:

```elixir
defmodule Product do
  use Ecto.Schema

  schema "products" do
    field :weight, Localize.Unit.Ecto.Composite.Type
    field :length, Localize.UnitWithUsage.Ecto.Composite.Type

    timestamps()
  end
end
```

5. Insert into the database:

```elixir
iex> Repo.insert %Product{weight: Localize.Unit.new!(Decimal.new(100), "kilogram")}
```

6. Retrieve from the database:

```elixir
iex> Repo.all Product
```

## Serializing to a MySQL (or other non-Postgres) database with Ecto

Since MySQL does not support composite types, the `:map` type is used which in MySQL is implemented as a `JSON` column. The unit name and amount are serialized into this column.

```elixir
defmodule Localize.Unit.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :weight_map, :map
      add :length_map, :map
      timestamps()
    end
  end
end
```

Create your schema using the `Localize.Unit.Ecto.Map.Type` ecto type:

```elixir
defmodule Product do
  use Ecto.Schema

  schema "products" do
    field :weight_map, Localize.Unit.Ecto.Map.Type
    field :length_map, Localize.UnitWithUsage.Ecto.Map.Type

    timestamps()
  end
end
```

Insert into the database:

```elixir
iex> Repo.insert %Product{weight_map: Localize.Unit.new!(100, "kilogram")}
```

Retrieve from the database:

```elixir
iex> Repo.all Product
```

### Notes

1. In order to preserve precision of the decimal amount, the amount part of the `Localize.Unit.t()` struct is serialized as a string. This is done because JSON serializes numeric values as either `integer` or `float`, neither of which would preserve precision of a decimal value.

2. The precision of the serialized string value is affected by the setting of `Decimal.get_context/0`. The default is 28 digits which should cater for your requirements.

3. Serializing the amount as a string means that SQL query arithmetic and equality operators will not work as expected. You may find that `CAST`ing the string value will restore some of that functionality. For example:

```sql
CAST(JSON_EXTRACT(amount_map, '$.value') AS DECIMAL(20, 8)) AS amount;
```

## Postgres Database functions

Since the datatype used to store `Localize.Unit` in Postgres is a composite type (called `:cldr_unit`), the standard aggregation functions like `sum` and `average` are not supported and the `order_by` clause doesn't perform as expected. `localize_units_sql` provides mechanisms to provide these functions.

### Aggregate functions: sum()

`localize_units_sql` provides a migration generator which, when migrated to the database with `mix ecto.migrate`, supports performing `sum()` aggregation on `:cldr_unit` types. The steps are:

1. Generate the migration by executing `mix units.gen.postgres.aggregate_functions`

2. Migrate the database by executing `mix ecto.migrate`

3. Formulate an Ecto query to use the aggregate function `sum()`

```elixir
iex> q = Ecto.Query.select(Product, [p], type(sum(p.weight), p.weight))
iex> Repo.all(q)
```

The function `Repo.aggregate/3` can also be used. However at least [ecto version 3.2.4](https://hex.pm/packages/ecto/3.2.4) is required for this to work correctly for custom ecto types such as `:cldr_unit`.

```elixir
iex> Repo.aggregate(Product, :sum, :weight)
```

**Note** that to preserve the integrity of `Localize.Unit` it is not permissible to aggregate units that have different unit types. If you attempt to aggregate units with different unit types the query will abort and an exception will be raised:

```
** (Postgrex.Error) ERROR 22033 (invalid_sql_json_subscript) Incompatible units. Expected all unit names to be kilogram

    hint: Please ensure all columns have the same unit type
```

### Order_by with cldr_unit type

Since `:cldr_unit` is a composite type, the default `order_by` results may surprise since the ordering is based upon the type structure, not the unit value. Postgres defines a means to access the components of a composite type and therefore sorting can be done in a more predictable fashion. For example:

```elixir
# In this example we are decomposing the composite column called
# `weight` and using the sub-field `value` to perform the ordering.
iex> q = from p in Product, select: p.weight, order_by: fragment("value(weight)")
iex> Repo.all(q)
```

**Note** that the results may still be unexpected. The example above shows the correct ascending ordering by `value(weight)` however the ordering is not unit aware and therefore mixed units will return a largely meaningless order.

## Installation

`localize_units_sql` can be installed by adding `localize_units_sql` to your list of dependencies in `mix.exs` and then executing `mix deps.get`.

```elixir
def deps do
  [
    {:localize_units_sql, "~> 2.1"},
    ...
  ]
end
```
