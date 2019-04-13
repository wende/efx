defmodule EfxExampleTest do
  use ExUnit.Case
  doctest EfxExample

  import Efx

  setup do
    Efx.register_effect(File, :read, 1)
    :ok
  end

  test "Captures effect" do
    result =
      handle do
        EfxExample.read_file()
      catch
        File.read("Wende"), k ->
          IO.puts("Win")
          k.({:ok, "Content"})
      end

    assert result == {:ok, "Content"}
  end
end
