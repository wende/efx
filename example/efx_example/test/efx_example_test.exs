defmodule EfxExampleTest do
  use ExUnit.Case
  doctest EfxExample

  test "greets the world" do
    assert EfxExample.hello() == :world
  end
end
