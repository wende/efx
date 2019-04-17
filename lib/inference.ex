defmodule Efx.Inference do
  defmacro eff({:::, _, [left, right]}) do
    {name, arity, args} = function_and_args_ast(left)

    effects =
      effects_ast(right)
      |> resolve_free_vars(args)

    Efx.Definition.define_effects(__CALLER__.module, name, arity, effects)
  end

  defp function_and_args_ast({name, _, args}) do
    {name, length(args), args}
  end

  # Two effects
  defp effects_ast({effect1, effect2}) do
    effects_set([effect1, effect2])
  end

  # 1, 3 or more effects
  defp effects_ast({:{}, _, args}) do
    effects_set(args)
  end

  defp effects_ast(ast) do
    throw("Incorrect effects definition\n #{Macro.to_string(ast)}")
  end

  defp effects_set(effects) do
    # TODO
  end

  defp resolve_free_vars(effects, vars) do
    # TODO
  end
end
