defmodule CliTest do
  use ExUnit.Case
  doctest MassTokenize

  import MassTokenize.CLI, only: [parse_args: 1]

  test "help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help
  end

  test "default parse if only --path is the only switch" do
    assert parse_args(["--path", "some/file"]) == [path: "some/file", wikiextractor_json: false]
  end

  test "sets `:wikiextractor_json` if --wikiextractor-json is passed as switch" do
    assert parse_args(["--path", "some/file", "--wikiextractor-json"]) == [path: "some/file", wikiextractor_json: true]
  end
end






