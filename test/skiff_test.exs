defmodule SkiffTest do
  use ExUnit.Case
  doctest Skiff

  test "greets the world" do
    assert Skiff.hello() == :world
  end
end
