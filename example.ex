defmodule Example do
  @eff {File.{read}}
  def read_file(name) do
    File.read(name)
  end

  @eff {File.{write}}
  def write_file(name) do
    File.write!(name)
  end

  @eff {Random.{eff}}
  def random(from, to) do
    Enum.random(from..to)
  end

  @eff {File.{read, write}, Random.{int}}
  def rewrite_random_line(name) do
    name
    |> read_file()
    |> List.insert_at(random(1, 10), "Wende")
    |> write_file()
  end

  # Infer

  # Error on line: 27 expected effect: {}, actual effect {File.{read, write}, Random.{eff}}
  @eff {}
  def my_fun() do
    rewrite_random_line("somefile.txt")
  end

  # Catch effects
  @eff my_fun2({IO.{write}})
  @spec my_fun2()
  def my_fun2() do
    pure do
      rewrite_random_line("somefile.txt")
    catch
      File.read(name) ->
        IO.inspect("Reading file #{name}")
        "Mocked file"

      File.write(name, _content) ->
        IO.inspect("Writing file #{name}")
        :ok

      Random.int(from, to) ->
        10
    end
  end

  # Continuations
  @eff my_fun3({IO.{write}})
  @spec my_fun3()
  def my_fun3() do
    pure do
      rewrite_random_line("somefile.txt")
    catch
      File.read(name), k ->
        IO.inspect("Reading file #{name}")
        "Mocked file"

      File.write(name, _content), k ->
        IO.inspect("Writing file #{name}")
        :ok

      IO.puts(sth), k ->
        k.()
        IO.puts(sth)
    end
  end
end
