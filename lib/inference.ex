defmodule Efx.Inference do
  alias Efx.Definition
  alias Efx.EffectSet
  require Logger

  @spec infer(Definition.t(), atom(), atom(), integer()) :: {EffectSet.t(), Definition.t()}
  def infer(definition, mod, fun, arity, stack \\ []) do
    nstack = [{mod, fun, arity} | stack]
    Logger.debug("Infering #{mod}.#{fun}/#{inspect(arity)}")

    definition
    |> Definition.get(mod, fun, arity)
    |> case do
      nil ->
        {EffectSet.new(), definition}

      {:resolved, effect} ->
        {effect, definition}

      {:unresolved, ast} ->
        result =
          ast
          |> find_calls(mod)
          |> Enum.uniq()
          |> Enum.reduce({EffectSet.new(), {:ok, definition}}, fn
            {mod, fun, arity}, {effs, {:ok, defs}} ->
              if {mod, fun, arity} in stack do
                # We've alreayd been here. Carry on
                {effs, {:ok, defs}}
              else
                {effects, definition} = infer(defs, mod, fun, arity, nstack)

                {EffectSet.merge(effs, effects),
                 Definition.set_effects(definition, mod, fun, arity, effects)}
              end
          end)

        with {effs, {:ok, defs}} <- result,
             {:ok, newdefs} <- Definition.set_effects(defs, mod, fun, arity, effs) do
          {effs, newdefs}
        else
          other -> raise "Error infering effects at #{inspect(other)}"
        end
    end
  end

  def find_calls({:__block__, _, [line | lines]}, m) do
    find_calls(line, m) ++ find_calls(lines, m)
  end

  # Dot dynamic call mod.fun(args...)
  def find_calls({{:., _, [{_var, _, Elixir}, _fun]}, _, args}, m) do
    [:dynamic] ++ find_calls(args, m)
  end

  # Dot call on module Mod.fun(args...)
  def find_calls({{:., _, [mod, fun]}, _, args}, m) do
    [{mod, fun, length(args)}] ++ find_calls(args, m)
  end

  # Local or imported call
  def find_calls({fun, meta, args}, mod) do
    case meta[:import] do
      nil -> [{mod, fun, length(args)}] ++ find_calls(args, mod)
      import_module -> [{import_module, fun, length(args)}] ++ find_calls(args, mod)
    end
  end

  def find_calls([h | t], m), do: find_calls(h, m) ++ find_calls(t, m)
  def find_calls([], _), do: []

  def find_calls(x, _) when is_integer(x), do: []

  def find_calls({}, _) do
    []
  end

  def cure(left, effect) do
    :ok
  end
end
