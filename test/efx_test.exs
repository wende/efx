defmodule EfxTest do
  alias Efx.Definition
  alias Efx.EffectSet

  import Efx.Macros
  import Efx

  use ExUnit.Case
  doctest Efx

  describe "Effects definitions" do
    test "Defining effect set" do
      effects1 =
        Efx.Definition.effects_ast(
          quote do
            {&Effect.a/1, &Effect.b/2}
          end,
          __ENV__
        )

      effects2 =
        Efx.Definition.effects_ast(
          quote do
            {&Effect.b/2, &Effect.a/1}
          end,
          __ENV__
        )

      assert MapSet.equal?(effects1, effects2)
    end

    test "Clear effect" do
      effects1 =
        quote do
          {&Effect.a/1, &Effect.b/2}
        end
        |> Efx.Definition.effects_ast(__ENV__)
        |> Efx.EffectSet.remove_effect(Effect, :b, 2)

      effects2 =
        quote do
          {&Effect.a/1}
        end
        |> Efx.Definition.effects_ast(__ENV__)

      assert MapSet.equal?(effects1, effects2)
    end

    test "Effects definition" do
      eff =
        Definition.new()
        |> Definition.set_effects(Mod, :fun, 1, EffectSet.new([]))
        ~> Definition.get_effects(Mod, :fun, 1)

      assert eff == MapSet.new([])
    end

    test "Effects conflict" do
      eff =
        Definition.new()
        |> Definition.set_effects(Mod, :fun, 1, EffectSet.new([]))
        ~> Definition.set_effects(Mod, :fun, 1, EffectSet.new([]))

      assert {:ok, _} = eff

      conflict =
        Definition.new()
        |> Definition.set_effects(Mod, :fun, 1, EffectSet.new([{Mod, :fun, 1}]))
        ~> Definition.set_effects(Mod, :fun, 1, EffectSet.new([{Mod, :fun, 2}]))

      assert {:error, _} = conflict
    end

    test "No effect yields nil" do
      assert nil == Definition.new() |> Definition.get_effects(Mod, :fun, 1)
    end
  end
end
