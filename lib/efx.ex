defmodule Efx do
  @moduledoc """
  Documentation for Efx.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Efx.hello()
      :world

  """
  def hello do
    :worldss
  end

  def replace_effects(ast) do
    Macro.prewalk(ast, fn ast ->
      replace_call(ast, {IO, :puts, 1})
    end)
  end

  def replace_call(ast = {{:., _, [module, function]}, _, args}, {mod, fun, arity}) do
    IO.puts("replace call")
    IO.inspect(ast)

    if fun == function && is_module(module, mod) && length(args) == arity do
      quote do
        Efx.eff(unquote(mod), unquote(fun), unquote(args))
      end
    else
      ast
    end
  end

  def replace_call(ast, _) do
    ast
  end

  def is_module({:__aliases__, _, path}, mod) do
    Module.concat(path) == mod |> IO.inspect()
  end

  def eff(mod, fun, args) do
    IO.puts("Calling #{mod} #{fun} #{inspect(args)}")
    apply(mod, fun, args)
  end
end
