defmodule Efx.Macros do
  defmacro left ~> right do
    quote do
      case unquote(left) do
        {:error, e} = e -> e
        {:ok, exp} -> exp |> unquote(right)
        other -> other |> unquote(right)
      end
    end
  end

  def with_default({:ok, ok}, _), do: ok
  def with_default({:error, _}, default), do: default
end
