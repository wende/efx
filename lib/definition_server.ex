defmodule Efx.Definition.Server do
  use GenServer

  alias Efx.Definition

  def start() do
    IO.puts("Starting Efx server #{inspect(self)}")
    {:ok, pid} = GenServer.start(__MODULE__, name: __MODULE__)
    :global.register_name(__MODULE__, pid)
    {:ok, pid}
  end

  def start_or_get() do
    :global.whereis_name(__MODULE__)
    |> case do
      :undefined ->
        {:ok, pid} = start()
        pid

      pid when is_pid(pid) ->
        pid
    end
  end

  @spec init(any()) :: {:ok, Definition.t()}
  @impl true
  def init(_) do
    {:ok, %Definition{}}
  end

  @impl true
  def terminate(_, _state) do
    IO.puts("DYING")
  end

  @spec define_effects(any(), any(), any(), any()) :: :ok
  def define_effects(module, fun, arity, effects) do
    GenServer.cast(start_or_get(), {:define_effects, module, fun, arity, effects})
  end

  def define_ast(module, fun, arity, ast) do
    GenServer.cast(start_or_get(), {:define_ast, module, fun, arity, ast})
  end

  @spec infer(atom(), atom(), any()) :: any()
  def infer(module, fun, arity) do
    GenServer.call(start_or_get(), {:infer, module, fun, arity})
  end

  @impl true
  def handle_cast({:define_effects, mod, fun, arity, effects}, state) do
    {:ok, new_state} = state |> Definition.set_effects(mod, fun, arity, effects)

    {:noreply, new_state}
  end

  def handle_cast({:define_ast, mod, fun, arity, ast}, state) do
    {:ok, new_state} = state |> Definition.set_ast(mod, fun, arity, ast)

    {:noreply, new_state}
  end

  @impl true
  @spec handle_call({:infer, atom(), atom(), integer}, {pid(), any()}, Definition.t()) ::
          {:reply, EffectSet.t(), Definition.t()}
  def handle_call({:infer, mod, fun, arity}, _, state) do
    state
    |> Definition.get_effects(mod, fun, arity)
    |> IO.inspect(label: "Infering: ")
    |> case do
      nil ->
        {effects, new_state} = Efx.Inference.infer(state, mod, fun, arity)

        {:reply, effects, new_state}

      effects ->
        {:reply, effects, state}
    end
  end
end
