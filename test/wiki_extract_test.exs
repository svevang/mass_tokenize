defmodule WikiExtractTest do
  use ExUnit.Case
  doctest WikiExtract

  test "greets the world" do
    assert WikiExtract.hello() == :world
  end
end
