defmodule Floki.HTMLTreeTest do
  use ExUnit.Case, assync: true

  alias Floki.{HTMLTree, HTMLNode, TextNode}

  defmodule FakeIdsSeeder do
    use GenServer

    @ids ~w(abcd dbca zyzy zizi bada)

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def seed do
      GenServer.call(__MODULE__, :seed)
    end

    ## GenServer API
    def handle_call(:seed, _from, state) do
      ids_length = length(state)
      new_id = Enum.at(@ids, ids_length, "out_of_range")

      {:reply, new_id, [new_id|state]}
    end
  end

  test "parse the tuple tree into html tree" do
    FakeIdsSeeder.start_link
    link_attrs = [{"href", "/home"}]
    html_tuple =
      {"html", [],
       [
         {:comment, "start of the stack"},
         {"a", link_attrs,
          [{"b", [], ["click me"]}]}, {"span", [], []}]}

    assert HTMLTree.parse(html_tuple, FakeIdsSeeder) == %HTMLTree{
     root_id: "abcd",
     tree: %{
       "abcd" => %HTMLNode{type: "html",
                           children_ids: ["zyzy", "dbca"],
                           floki_id: "abcd"},
       "dbca" => %HTMLNode{type: "a",
                           attributes: link_attrs,
                           floki_parent_id: "abcd",
                           children_ids: ["zizi"],
                           floki_id: "dbca"},
       "zyzy" => %HTMLNode{type: "span",
                           floki_parent_id: "abcd",
                           floki_id: "zyzy"},
       "zizi" => %HTMLNode{type: "b",
                           floki_parent_id: "dbca",
                           children_ids: ["bada"],
                           floki_id: "zizi"},
       "bada" => %TextNode{content: "click me",
                           floki_parent_id: "zizi",
                           floki_id: "bada"}
     }
    }
  end
end