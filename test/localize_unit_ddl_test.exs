defmodule Localize.Unit.DDL.Test do
  use ExUnit.Case, async: true

  alias Localize.Unit.DDL

  doctest Localize.Unit.DDL

  describe "the Postgres SQL files" do
    test "every file reads as SQL, one command per paragraph" do
      for sql <- [
            DDL.create_cldr_unit(),
            DDL.drop_cldr_unit(),
            DDL.define_aggregate_functions(),
            DDL.drop_aggregate_functions()
          ] do
        assert is_binary(sql)
        assert sql =~ ~r/\b(CREATE|DROP)\b/
      end
    end

    test "create_cldr_unit/1 defines both composite types" do
      sql = DDL.create_cldr_unit()

      assert sql =~ "CREATE TYPE public.cldr_unit AS"
      assert sql =~ "CREATE TYPE public.cldr_unit_with_usage AS"
    end
  end

  describe "execute/1" do
    test "a command on several lines is executed as a heredoc" do
      assert DDL.execute("SELECT 1\nFROM t;\n") == ~s|execute """\nSELECT 1\nFROM t;\n"""|
    end
  end

  describe "a database type with no SQL files" do
    test "raises ArgumentError naming the type and the file" do
      assert_raise ArgumentError,
                   ~s|Database type mysql does not have a SQL definition file "create_cldr_unit.sql"|,
                   fn -> DDL.create_cldr_unit(:mysql) end
    end
  end
end
