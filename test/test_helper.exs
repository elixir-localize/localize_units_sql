ExUnit.start()

{:ok, _pid} = Localize.Unit.SQL.Repo.start_link()
:ok = Ecto.Adapters.SQL.Sandbox.mode(Localize.Unit.SQL.Repo, :manual)

defmodule Localize.Unit.SQL.RepoCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Localize.Unit.SQL.Repo

  using do
    quote do
      alias Localize.Unit.SQL.Repo

      import Ecto
      import Ecto.Query
      import Localize.Unit.SQL.RepoCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end
