defmodule Localize.Unit.DDL do
  @moduledoc """
  Functions to return SQL DDL commands that support the
  creation and deletion of the `cldr_unit` database
  type and associated aggregate functions.
  """

  @default_db :postgres

  # The application whose priv directory holds the SQL files.
  @app Mix.Project.config()[:app]

  @supported_db_types :code.priv_dir(:localize_units_sql)
                      |> Path.join("SQL")
                      |> File.ls!()
                      |> Enum.map(&String.to_atom/1)

  @doc """
  Returns the SQL string which when executed will
  define the `cldr_unit` and `cldr_unit_with_usage` data types.

  ### Arguments

  * `db_type` is the type of the database for which the SQL
    string should be returned.  Defaults to `:postgres` which
    is currently the only supported database type.

  ### Returns

  * A SQL string that can be executed to create the types.

  ### Examples

      iex> is_binary(Localize.Unit.DDL.create_cldr_unit())
      true

  """
  def create_cldr_unit(db_type \\ @default_db) do
    read_sql_file(db_type, "create_cldr_unit.sql")
  end

  @doc """
  Returns the SQL string which when executed will
  drop the `cldr_unit` and `cldr_unit_with_usage` data types.

  ### Arguments

  * `db_type` is the type of the database for which the SQL
    string should be returned.  Defaults to `:postgres` which
    is currently the only supported database type.

  ### Returns

  * A SQL string that can be executed to drop the types.

  ### Examples

      iex> is_binary(Localize.Unit.DDL.drop_cldr_unit())
      true

  """
  def drop_cldr_unit(db_type \\ @default_db) do
    read_sql_file(db_type, "drop_cldr_unit.sql")
  end

  @doc """
  Returns the SQL string which when executed will
  define aggregate functions for the `cldr_unit`
  and `cldr_unit_with_usage` data types.

  ### Arguments

  * `db_type` is the type of the database for which the SQL
    string should be returned.  Defaults to `:postgres` which
    is currently the only supported database type.

  ### Returns

  * A SQL string that can be executed to define the aggregate functions.

  ### Examples

      iex> is_binary(Localize.Unit.DDL.define_aggregate_functions())
      true

  """
  def define_aggregate_functions(db_type \\ @default_db) do
    read_sql_file(db_type, "define_aggregate_functions.sql")
  end

  @doc """
  Returns the SQL string which when executed will
  drop the aggregate functions for the `cldr_unit`
  and `cldr_unit_with_usage` data types.

  ### Arguments

  * `db_type` is the type of the database for which the SQL
    string should be returned.  Defaults to `:postgres` which
    is currently the only supported database type.

  ### Returns

  * A SQL string that can be executed to drop the aggregate functions.

  ### Examples

      iex> is_binary(Localize.Unit.DDL.drop_aggregate_functions())
      true

  """
  def drop_aggregate_functions(db_type \\ @default_db) do
    read_sql_file(db_type, "drop_aggregate_functions.sql")
  end

  @doc """
  Returns a string that will Ecto `execute` each SQL
  command.

  ### Arguments

  * `sql` is a string of SQL commands that are
    separated by three newlines ("\\n"),
    that is to say two blank lines between commands
    in the file.

  ### Returns

  * A string of Ecto `execute` statements.

  ### Examples

      iex> Localize.Unit.DDL.execute_each("SELECT name FROM customers;\\n\\n\\nSELECT id FROM orders;")
      "execute \\"SELECT name FROM customers;\\"\\nexecute \\"SELECT id FROM orders;\\""

  """
  def execute_each(sql) do
    sql
    |> String.split("\n\n\n")
    |> Enum.map_join("\n", &execute/1)
  end

  @doc """
  Returns a string that will Ecto `execute` a single SQL
  command.

  ### Arguments

  * `sql` is a single SQL command.

  ### Returns

  * A string of an Ecto `execute` statement.

  ### Examples

      iex> Localize.Unit.DDL.execute("SELECT name FROM customers;")
      "execute \\"SELECT name FROM customers;\\""

  """
  def execute(sql) do
    sql = String.trim_trailing(sql, "\n")

    if String.contains?(sql, "\n") do
      "execute \"\"\"\n" <> sql <> "\n\"\"\""
    else
      "execute " <> inspect(sql)
    end
  end

  defp read_sql_file(db_type, file_name) when db_type in @supported_db_types do
    base_dir(db_type)
    |> Path.join(file_name)
    |> File.read!()
  end

  defp read_sql_file(db_type, file_name) do
    raise ArgumentError,
          "Database type #{db_type} does not have a SQL definition " <>
            "file #{inspect(file_name)}"
  end

  defp base_dir(db_type) do
    :code.priv_dir(@app)
    |> Path.join(["SQL", "/#{db_type}"])
  end
end
