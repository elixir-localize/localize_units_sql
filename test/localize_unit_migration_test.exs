defmodule Localize.Unit.Migration.Test do
  # A generator writes the migration into the repo's migrations directory,
  # relative to the project. Each test points the repo's `:priv` at a
  # directory of its own under `_build/`, which is never committed, and
  # removes it afterwards. The repo's configuration is shared, so the
  # tests run one at a time.
  use ExUnit.Case, async: false

  alias Localize.Unit.DDL
  alias Localize.Unit.Migration
  alias Mix.Tasks.Units.Gen.Postgres.AggregateFunctions
  alias Mix.Tasks.Units.Gen.Postgres.CldrUnitsMigration

  @repo Localize.Unit.SQL.Repo
  @repo_args ["-r", "Localize.Unit.SQL.Repo"]

  setup do
    config = Application.get_env(:localize_units_sql, @repo)
    priv = "_build/generated_migrations_#{System.unique_integer([:positive])}"
    Application.put_env(:localize_units_sql, @repo, Keyword.put(config, :priv, priv))
    Mix.shell(Mix.Shell.Process)

    on_exit(fn ->
      Application.put_env(:localize_units_sql, @repo, config)
      Mix.shell(Mix.Shell.IO)
      File.rm_rf!(priv)
    end)

    {:ok, directory: priv}
  end

  describe "Localize.Unit.Migration" do
    test "migrations_path/1 is the repo's migrations directory" do
      assert Migration.migrations_path(@repo) ==
               Ecto.Migrator.migrations_path(@repo)
    end

    test "format_string!/1 formats Elixir source" do
      assert IO.iodata_to_binary(Migration.format_string!("def  f, do:  1")) ==
               "def f, do: 1"
    end
  end

  describe "mix units.gen.postgres.cldr_units_migration" do
    test "writes a migration that creates and drops the composite types", %{directory: directory} do
      content = generate(CldrUnitsMigration, directory, "add_cldr_unit_type_to_postgres")

      assert content =~ "defmodule Localize.Unit.SQL.Repo.Migrations.AddCldrUnitTypeToPostgres do"
      assert executed(content, :up) == commands(DDL.create_cldr_unit())
      assert executed(content, :down) == commands(DDL.drop_cldr_unit())
    end
  end

  describe "mix units.gen.postgres.aggregate_functions" do
    test "writes a migration that defines and drops the aggregates", %{directory: directory} do
      content =
        generate(AggregateFunctions, directory, "add_postgres_cldr_unit_aggregate_functions")

      assert content =~
               "defmodule Localize.Unit.SQL.Repo.Migrations.AddPostgresCldrUnitAggregateFunctions do"

      assert executed(content, :up) == commands(DDL.define_aggregate_functions())
      assert executed(content, :down) == commands(DDL.drop_aggregate_functions())
    end
  end

  # Runs a generator and returns the one migration it wrote in `directory`.
  defp generate(task, directory, name) do
    task.run(@repo_args)

    assert [file] = Path.wildcard(Path.join(directory, "migrations/*_#{name}.exs"))
    File.read!(file)
  end

  # The SQL each `execute` in a migration function runs, in order. The
  # generator formats the migration, so it is read as code, not as text.
  defp executed(content, function) do
    {:ok, ast} = Code.string_to_quoted(content)

    {_ast, body} =
      Macro.prewalk(ast, nil, fn
        {:def, _, [{^function, _, _}, [do: body]]} = node, nil -> {node, body}
        node, found -> {node, found}
      end)

    {_body, statements} =
      Macro.prewalk(body, [], fn
        {:execute, _, [sql]} = node, found when is_binary(sql) ->
          {node, [String.trim(sql) | found]}

        node, found ->
          {node, found}
      end)

    Enum.reverse(statements)
  end

  # The commands of a SQL file, which separates them with two blank lines.
  defp commands(sql) do
    sql
    |> String.split("\n\n\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
