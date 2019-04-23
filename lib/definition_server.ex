defmodule Efx.Definition.Server do
  use GenServer

  alias Efx.Definition

  def start(), do: GenServer.start(Module, name: __MODULE__)

  def init(_) do
    {:ok, %Definition{}}
  end

  def define_effects(module, fun, arity, effects) do
    GenServer.cast(__MODULE__, {:define_effects, module, fun, arity, effects})
  end

  def handle_cast({:define_effects, mod, fun, arity, effects}, _, state) do
    new_state = state |> Definition.set_effect(mod, fun, arity, effects)

    {:noreply, new_state}
  end
end
