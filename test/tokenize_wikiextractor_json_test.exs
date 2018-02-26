defmodule TokenizeWikiextractorJsonTest do
  use ExUnit.Case

  import TokenizeWikiExtractorJson, only: [parse_json: 1]

  test "should parse a file of line delimited json objects" do
    s = File.read!(Path.join(__DIR__, "../test/fixtures/wiki_00"))

    assert 5 == length(TokenizeWikiExtractorJson.parse_json(s))
    assert ["Another", "Fine", "test", "Foo", "bar"] == TokenizeWikiExtractorJson.parse_json(s)
  end


end






