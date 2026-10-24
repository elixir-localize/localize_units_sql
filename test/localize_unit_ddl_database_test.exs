defmodule Localize.Unit.DDL.Database.Test do
  # The SQL runs against the test database inside the sandbox transaction,
  # which rolls it back. Dropping a function locks it, so these tests run
  # apart from the ones that query the aggregates.
  use Localize.Unit.SQL.RepoCase, async: false

  alias Localize.Unit.DDL

  @functions_sql "SELECT proname FROM pg_proc WHERE proname LIKE '%state_function' ORDER BY proname"

  test "the aggregate functions are defined by their migration" do
    assert state_functions() == ["unit_state_function", "unit_with_usage_state_function"]
  end

  test "drop_aggregate_functions/0 drops every function the aggregates use" do
    for command <- commands(DDL.drop_aggregate_functions()), do: Repo.query!(command)

    assert state_functions() == []
  end

  test "define_aggregate_functions/0 defines them again after a drop" do
    for command <- commands(DDL.drop_aggregate_functions()), do: Repo.query!(command)
    for command <- commands(DDL.define_aggregate_functions()), do: Repo.query!(command)

    assert state_functions() == ["unit_state_function", "unit_with_usage_state_function"]
  end

  defp state_functions do
    @functions_sql |> Repo.query!() |> Map.fetch!(:rows) |> List.flatten()
  end

  # The commands of a SQL file, which separates them with two blank lines.
  defp commands(sql) do
    sql
    |> String.split("\n\n\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
