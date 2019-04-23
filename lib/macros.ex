defmodule Efx.Macros do
  defmacro left ~> right do
    quote do
      case unquote(left) do
        {:error, e} = e -> e
        {:ok, r} -> r |> unquote(right)
      end
    end
  end

  def with_default({:ok, ok}, _), do: ok
  def with_default({:error, _}, default), do: default
end
