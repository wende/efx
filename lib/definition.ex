defmodule Efx.Definition do
  use GenServer

  defmodule Module do
    @type t :: %Module{functions: %{optional({name :: atom(), arity :: tuple()}) => Set.t()}}
    defstruct functions: %{}
  end

  defstruct modules: %{}

  def start(), do: GenServer.start(Module, name: __MODULE__)

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def define_effects(module, fun, arity, effects) do
    GenServer.cast(__MODULE__, {:define_effects, module, fun, arity, effects})
  end

  def handle_cast({:define_effects, mod, fun, arity, effects}, _, state) do
    new_state =
      case state.modules[mod] do
        nil ->
          put_in(state.modules[mod], %{{fun, arity} => effects})

        mod ->
          case mod[{fun, arity}] do
            nil ->
              put_in(state.modules[mod][{fun, arity}], effects)

            definition ->
              conflict(definition, effects)
              state
          end
      end

    {:noreply, new_state}
  end

  defp conflict(original, annotation) do
    # TODO do the conflic
  end

  defmacro eff({:::, _, [left, right]}) do
    {name, arity, args} = function_and_args_ast(left)

    effects =
      effects_ast(right)
      |> resolve_free_vars(args)

    define_effects(__CALLER__.module, name, arity, effects)
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
    throw("Incorrect effects definition: #{Macro.to_string(ast)}")
  end

  defp effects_set(effects) do
    # TODO organize effects
    effects
    MapSet.new(effects)
  end

  defp resolve_free_vars(effects, vars) do
    # TODO
  end
end
