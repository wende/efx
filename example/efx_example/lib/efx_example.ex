defmodule EfxExample do
  use Efx

  def read_file() do
    File.read("Wende")
  end

  def read_specific_file(file) do
    File.read(file)
  end

  eff print(any) :: {&IO.puts/1}
  @spec print(any) :: any
  def print(sth) do
    IO.puts(sth)
  end
end
