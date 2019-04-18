defmodule EfxExampleTest do
  use ExUnit.Case
  doctest EfxExample

  import Efx

  test "Captures simple effect" do
    result =
      handle do
        EfxExample.read_file()
      catch
        File.read("Wende") ->
          {:ok, "Content"}
      end

    assert result == {:ok, "Content"}
  end

  test "Captures simple effect with args" do
    result =
      handle do
        foo = EfxExample.read_specific_file("Wende")
        bar = EfxExample.read_specific_file("Wende2")
        baz = EfxExample.read_specific_file("Baz")

        foo <> bar <> baz
      catch
        File.read("Wende") ->
          "Foo"

        File.read("Wende2") ->
          "Bar"

        File.read(anything) ->
          anything
      end

    assert result == "FooBarBaz"
  end

  test "Identity effect" do
    result =
      handle do
        EfxExample.read_specific_file("Foo")
        |> IO.inspect()
      catch
        File.read(eff) ->
          eff
      end

    assert result == "Foo"
  end
end
