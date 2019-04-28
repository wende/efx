defmodule EfxExample do
  use Efx

  def read_file() do
    File.read("Wende")
  end

  def read_specific_file(file) do
    File.read(file)
  end

  defmacrop insert_puts() do
    quote do
      IO.puts("sth")
    end
  end

  def read_from_macro() do
    insert_puts()
  end

  eff print(any) :: {&IO.puts/1}
  @spec print(any) :: any
  def print(sth) do
    IO.puts(sth)
  end
end
