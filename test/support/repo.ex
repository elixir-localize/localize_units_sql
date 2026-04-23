defmodule Localize.Unit.SQL.Repo do
  use Ecto.Repo,
    otp_app: :localize_units_sql,
    adapter: Ecto.Adapters.Postgres
end
