defmodule EfxTest do
  use ExUnit.Case
  doctest Efx

  test "greets the world" do
    assert Efx.hello() == :world
  end
end
