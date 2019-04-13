defmodule EfxExampleTest do
  use ExUnit.Case
  doctest EfxExample

  import Efx

  test "Captures simple effect" do
    result =
      handle do
        EfxExample.read_file()
      catch
        File.read("Wende"), k ->
          k.({:ok, "Content"})
      end

    assert result == {:ok, "Content"}
  end

  # TODO: Match arguments on handlers
  @tag :skip
  test "Captures simple effect with args" do
    result =
      handle do
        foo = EfxExample.read_specific_file("Wende")
        bar = EfxExample.read_specific_file("Wende2")
        foo <> bar
      catch
        File.read("Wende"), k ->
          k.("Foo")

        File.read("Wende2"), k ->
          k.("Bar")
      end

    assert result == "FooBar"
  end

  test "Identity effect" do
    result =
      handle do
        EfxExample.read_specific_file("Foo")
      catch
        File.read(eff), k ->
          k.(eff)
      end

    assert result == "Foo"
  end
end
