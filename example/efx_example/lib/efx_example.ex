defmodule EfxExample do
  def read_file() do
    File.read("Wende")
  end

  def read_specific_file(file) do
    File.read(file)
  end
end
