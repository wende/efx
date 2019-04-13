defmodule Efx do
  defstruct handlers: %{}, continuations: %{}

  @base_effects [
    {File, :read, 1}
  ]

  @spec register_effect(any(), any(), any()) :: :ok
  def register_effect(mod, fun, arity) do
    start()
    Agent.update(Efx, fn state -> Map.put(state, {mod, fun, arity}, true) end)
  end

  def start() do
    case :ets.info(Efx) do
      :undefined ->
        Agent.start(
          fn -> @base_effects |> Enum.map(fn a -> {a, true} end) |> Enum.into(%{}) end,
          name: Efx
        )

        :ok

      _ ->
        :ok
    end
  end

  def replace_effects(ast) do
    start()

    Macro.prewalk(ast, fn
      ast = {{:., _, [_module, _function]}, _, _args} ->
        replace_call(ast)

      ast ->
        ast
    end)
  end

  def replace_call(ast = {{:., _, [mod_ast, fun]}, _, args}) do
    mod = replace_module(mod_ast)

    case Agent.get(Efx, fn state -> state[{mod, fun, length(args)}] end) do
      nil ->
        ast

      true ->
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

  def eff(mod, fun, args) do
    IO.puts("Calling #{mod} #{fun} #{inspect(args)} at #{Efx}")

    efx = Efx.get()

    efx
    |> Map.get(:handlers)
    |> Map.get({mod, fun, length(args)})
    |> case do
      nil ->
        IO.puts("Not found")
        apply(mod, fun, args)

      [{ref, handler} | rest] ->
        IO.inspect({ref, handler})
        Process.put(Efx, put_in(efx.handlers[{mod, fun, args}], rest))

        handler.(args, fn result ->
          Efx.put_continuation(ref, result)
        end)
    end
  end

  defmacro handle(do: code, catch: cases) do
    handlers =
      for {:->, _, [[left, k], body]} <- cases do
        {mod, fun, args} = tuplify_call(left, __CALLER__)

        quote do
          ref = Kernel.make_ref()

          fn [unquote_splicing(args)], unquote(k) ->
            unquote(body)

            case Efx.get_continuation(ref) do
              nil -> throw(:efx_no_cont)
              result -> result
            end
          end
          |> Efx.put_handler({unquote(mod), unquote(fun), unquote(length(args))}, ref)
        end
      end

    quote do
      unquote(handlers)
      unquote(code)
    end
  end

  def put_handler(handler, modfunarity, ref) do
    Efx.get()
    |> update_in(
      [Access.key(:handlers), modfunarity],
      fn handlers -> [{ref, handler} | handlers] end
    )
    |> Efx.put()
  end

  def put_continuation(ref, result) do
    efx = Process.get(Efx, %Efx{})
    new_efx = put_in(efx.continuations[ref], result)
    Process.put(Efx, new_efx)
  end

  def get_continuation(ref) do
    Efx.get().continuations[ref]
  end

  def get() do
    Process.get(unquote(Efx), %Efx{})
  end

  def put(efx) do
    Process.put(unquote(Efx), efx)
  end

  defp tuplify_call({{:., _, [mod, fun]}, _, args}, caller) do
    {Macro.expand(mod, caller), fun, args}
  end

  defp tuplify_call({:{}, _, [mod, fun, args]}, _) do
    {mod, fun, args}
  end
end
