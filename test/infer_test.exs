defmodule InferTest do
  alias Efx.Definition
  import Definition

  alias Efx.EffectSet
  import Efx.Macros
  use ExUnit.Case
  doctest Efx

  describe "Inference" do
    test "Effects are contagious" do
      ast =
        quote do
          IO.inspect(Mod.func(1))
          20 + Mod.func(10, 10)
        end
        |> Definition.prepare_ast()

      {effects, env} =
        Definition.new()
        |> Definition.set_effects(IO, :inspect, 1, EffectSet.new([{IO, :inspect, 1}]))
        ~> Definition.set_ast(Mod, :fun, 1, ast)
        ~> Efx.Inference.infer(Mod, :fun, 1)

      assert effects == EffectSet.new([{IO, :inspect, 1}])
    end

    test "Recursive effects resolve" do
      ast =
        quote do
          20 + Mod.fun(10) + IO.inspect(10)
        end
        |> Definition.prepare_ast()

      {effects, env} =
        Definition.new()
        # Assume IO.inspect/1 as effectful
        |> Definition.set_effects(IO, :inspect, 1, EffectSet.new([{IO, :inspect, 1}]))
        # Set ast of Mod.fun/1 to body calling itself
        ~> Definition.set_ast(Mod, :fun, 1, ast)
        # Infer the Mod.fun/1
        ~> Efx.Inference.infer(Mod, :fun, 1)

      assert effects == EffectSet.new([{IO, :inspect, 1}])
    end

    test "No effect yields nil" do
      assert nil == Definition.new() |> Definition.get_effects(Mod, :fun, 1)
    end
  end
end
