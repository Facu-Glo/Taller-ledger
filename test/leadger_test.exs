defmodule LeadgerTest do
  use ExUnit.Case
  doctest Leadger

  test "greets the world" do
    assert Leadger.hello() == :world
  end
end
