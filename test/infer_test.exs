defmodule InferTest do
  alias Efx.Definition
  import Definition

  alias Efx.EffectSet
  import Efx.Macros
  use ExUnit.Case
  doctest Efx

  describe "Inference" do
    test "Effects conflict" do
      ast =
        quote do
          IO.inspect(Mod.func(1))
          20 + Mod.func(10, 10)
        end
        |> Definition.prepare_ast()

      result =
        Definition.new()
        |> Definition.set_effects(IO, :inspect, 1, EffectSet.new([{IO, :inspect, 1}]))
        ~> Definition.set_ast(Mod, :fun, 1, ast)
        ~> Efx.Inference.infer(Mod, :fun, 1)

      assert result == []
    end

    test "No effect yields nil" do
      assert nil == Definition.new() |> Definition.get_effects(Mod, :fun, 1)
    end
  end
end
