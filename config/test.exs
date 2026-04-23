import Config

config :localize_units_sql, Localize.Unit.SQL.Repo,
    username: "kip",
    database: "money_dev",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox

config :localize_units_sql,
  ecto_repos: [Localize.Unit.SQL.Repo]

config :localize,
  default_locale: :en,
  allow_runtime_locale_download: true

config :postgrex, :json_library, :json

config :logger, level: :error
