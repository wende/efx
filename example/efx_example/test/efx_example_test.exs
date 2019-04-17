defmodule EfxExampleTest do
  use ExUnit.Case
  doctest EfxExample

  import Efx
  import ExUnit.CaptureIO

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
        |> IO.inspect()
      catch
        File.read(eff), k ->
          k.(eff)
          10
      end

    assert result == "Foo"
  end

  test "No continuations" do
    result =
      handle do
        EfxExample.read_specific_file("Foo")
      catch
        File.read(eff), k ->
          10
      end

    assert result == "Foo"
  end

  test "Reverse effects using continuations" do
    assert capture_io(fn ->
             handle do
               EfxExample.print("1")
               EfxExample.print("2")
               EfxExample.print("3")
             catch
               IO.puts(text), k ->
                 k.(:ok)
                 IO.puts(text)
             end
           end) =~ "3\n2\n1\n"
  end
end
