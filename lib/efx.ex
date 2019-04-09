defmodule Efx do
  defstruct captured_effects: %{}

  @effects %{
    {IO, :puts, 1} => [STD.WRITE]
  }

  def replace_effects(ast) do
    Macro.prewalk(ast, fn
      ast = {{:., _, [_module, _function]}, _, _args} ->
        replace_call(ast)

      ast ->
        ast
    end)
  end

  def replace_call(ast = {{:., _, [mod_ast, fun]}, _, args}) do
    mod = replace_module(mod_ast)

    case Map.get(@effects, {mod, fun, length(args)}) |> IO.inspect() do
      nil ->
        ast

      [_ | _] ->
        quote do
          Efx.eff(unquote(mod), unquote(fun), unquote(args))
        end
    end
  end

  def replace_call(ast) do
    ast
  end

  def replace_module({:__aliases__, _, path}) do
    Module.concat(path)
  end

  def eff(effect, {mod, fun, args}) do
    IO.puts("Calling #{mod} #{fun} #{inspect(args)}")

    efx =
      Efx
      |> Process.get(%Efx{})

    efx
    |> Map.get(:captured_effects)
    |> Map.get(effect)
    |> case do
      nil ->
        apply(mod, fun, args)

      [pid | rest] ->
        IO.puts("Capturing #{mod} #{fun} #{inspect(args)}")

        if Process.alive?(pid) do
          send(pid, {Kernel.self(), effect, args})
        else
          Process.put(:captured_effects, %Efx{
            efx
            | captured_effects: %{efx.captured_effects | effect: rest}
          })

          eff(effect, {mod, fun, args})
        end
    end
  end

  defmacro handle(code, do: ast) do
    quote do
    end
  end
end
