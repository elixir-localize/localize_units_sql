import Config

# Connection settings follow the libpq environment variables, so CI (a
# service container with a password) and local development both work.
config :localize_units_sql, Localize.Unit.SQL.Repo,
  username: System.get_env("PGUSER", "kip"),
  password: System.get_env("PGPASSWORD"),
  database: "money_dev",
  hostname: System.get_env("PGHOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :localize_units_sql,
  ecto_repos: [Localize.Unit.SQL.Repo]

config :localize,
  default_locale: :en,
  allow_runtime_locale_download: true

config :postgrex, :json_library, :json

config :logger, level: :error
