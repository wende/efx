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
          IO.inspect(SomeMod.func(1))
          20 + SomeMod.func(10, 10)
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

    test "handle block cures effects" do
      ast =
        quote do
          handle do
            IO.puts("Foo")
            File.read("Name")
          catch
            File.read(name) ->
              IO.inspect("Reading #{name}")
          end
        end
        |> Definition.prepare_ast()

      {effects, env} =
        Definition.new()
        # Assume IO.inspect/1 as effectful
        |> Definition.set_effects(IO, :inspect, 1, EffectSet.new([{IO, :inspect, 1}]))
        ~> Definition.set_effects(IO, :puts, 1, EffectSet.new([{IO, :puts, 1}]))
        ~> Definition.set_effects(File, :read, 1, EffectSet.new([{File, :read, 1}]))
        # Set ast of Mod.fun/1 to body calling itself
        ~> Definition.set_ast(Mod, :fun, 1, ast)
        # Infer the Mod.fun/1
        ~> Efx.Inference.infer(Mod, :fun, 1)

      assert EffectSet.equal?(effects, EffectSet.new([{IO, :inspect, 1}, {IO, :puts, 1}]))
    end

    test "Macros are expanded" do
      ast =
        quote do
          "a" |> IO.puts()
        end
        |> Definition.prepare_ast()

      {effects, env} =
        Definition.new()
        ~> Definition.set_effects(IO, :puts, 1, EffectSet.new([{IO, :puts, 1}]))
        ~> Definition.set_ast(Mod, :fun, 1, ast)
        ~> Efx.Inference.infer(Mod, :fun, 1)

      assert EffectSet.equal?(effects, EffectSet.new([{IO, :puts, 1}]))
    end
  end
end
