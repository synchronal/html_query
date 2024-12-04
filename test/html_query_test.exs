defmodule HtmlQueryTest do
  # @related [subject](/lib/html_query.ex)

  use Test.SimpleCase, async: true

  alias HtmlQuery, as: Hq

  doctest HtmlQuery

  describe "all" do
    test "finds all matching elements, and returns them as a list of HTML trees" do
      html = """
      <div>
        <p>P1</p>
        <p>P2<p>P2 A</p><p>P2 B</p></p>
        <p>P3</p>
      </div>
      """

      html
      |> Hq.all("p")
      |> assert_eq([
        {"p", [], ["P1"]},
        {"p", [], ["P2", {"p", [], ["P2 A"]}, {"p", [], ["P2 B"]}]},
        {"p", [], ["P2 A"]},
        {"p", [], ["P2 B"]},
        {"p", [], ["P3"]}
      ])

      html
      |> Hq.all("glorp")
      |> assert_eq([])
    end

    test "returns empty list when nothing is found" do
      assert Hq.all("<div><p>hi</p></div>", "img") == []
    end

    test "accepts queries as strings or keyword lists" do
      html = """
      <div>
        <p id="p1" class="para">P1</p>
        <p id="p2" class="para">P2</p>
      </div>
      """

      html
      |> Hq.all("#p2.para")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])

      html
      |> Hq.all("[id=p2][class=para]")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])

      html
      |> Hq.all(id: "p2", class: "para")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])
    end

    test "raises when given nil" do
      assert_raise HtmlQuery.QueryError,
                   """
                   HtmlQuery.all expected to have been given HTML

                   HTML: nil

                   Selector: [data-role='thing']
                   """,
                   fn -> Hq.all(nil, data_role: "thing") end
    end
  end

  describe "attr" do
    @html """
    <div class="profile-list" id="profiles">
      <div class="profile admin" id="alice" test-role="admin-profile">
        <div class="name">Alice</div>
      </div>
      <div class="profile" id="billy">
        <div class="name">Billy</div>
      </div>
    </div>
    """

    test "returns the value of an attr from the outermost element of an HTML node" do
      @html |> Hq.find("#alice") |> Hq.attr("class") |> assert_eq("profile admin")
    end

    test "when attr is an atom, underscores are converted to dashes" do
      @html |> Hq.find("#alice") |> Hq.attr(:test_role) |> assert_eq("admin-profile")
    end

    test "returns nil if the attr does not exist" do
      @html |> Hq.find("#alice") |> Hq.attr("foo") |> assert_eq(nil)
    end

    test "raises if the first argument is a list or HTML tree" do
      assert_raise HtmlQuery.QueryError,
                   """
                   Expected a single HTML node but got:

                   <div class="profile admin" id="alice" test-role="admin-profile">
                     <div class="name">
                       Alice
                     </div>
                   </div>
                   <div class="profile" id="billy">
                     <div class="name">
                       Billy
                     </div>
                   </div>

                   Consider using Enum.map(html, &HtmlQuery.attr(&1, "id"))
                   """,
                   fn -> @html |> Hq.all(".profile") |> Hq.attr("id") end
    end
  end

  describe "find" do
    test "finds the first matching element, and returns it as an HTML node" do
      html = """
      <div>
        <p>P1</p>
        <p>P2</p>
        <p>P3</p>
      </div>
      """

      html |> Hq.find("p") |> assert_eq({"p", [], ["P1"]})
      html |> Hq.find("glorp") |> assert_eq(nil)
    end

    test "raises when given nil" do
      assert_raise HtmlQuery.QueryError,
                   """
                   HtmlQuery.find expected to have been given HTML

                   HTML: nil

                   Selector: [data-role='thing']
                   """,
                   fn -> Hq.find(nil, data_role: "thing") end
    end
  end

  describe "find!" do
    @html """
    <p>P1</p>
    <p>P2</p>
    <div>DIV</div>
    """

    test "finds first matching element and returns it as an HTML node" do
      @html |> Hq.find!("div") |> assert_eq({"div", [], ["DIV"]})
    end

    test "fails if no element is found" do
      assert_raise HtmlQuery.QueryError,
                   """
                   Expected a single HTML node but found none

                   Selector: glorp
                   """,
                   fn -> @html |> Hq.find!("glorp") end
    end

    test "fails if more than 1 element is found" do
      assert_raise HtmlQuery.QueryError,
                   """
                   Expected a single HTML node but got:

                   <p>
                     P1
                   </p>
                   <p>
                     P2
                   </p>

                   Selector: p
                   """,
                   fn -> @html |> Hq.find!("p") end
    end
  end

  describe "form_fields" do
    test "returns selects, textareas, and inputs that have a `value` attr as a name -> value map" do
      """
      <form test-role="test-form">
        <input type="text" name="name" value="alice" />
        <input type="number" name="age" value="100" />
        <input type="email" name="email" value="" />
        <input type="hidden" name="alive" value="false" />
        <input type="checkbox" name="alive" checked value="true" />
        <textarea name="about">Alice is 100</textarea>
        <select name="favorite_color"><option>red</option><option selected>blue</option><option>green</option></select>
        <input type="submit" name="save" />
      </form>
      """
      |> Hq.find(test_role: "test-form")
      |> Hq.form_fields()
      |> assert_eq(%{name: "alice", age: "100", email: "", alive: true, about: "Alice is 100", favorite_color: "blue"})
    end
  end

  describe "meta_tags" do
    test "returns the meta tags" do
      html = """
      <html lang="en">
        <head>
          <meta charset="utf-8"/>
          <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <meta charset="UTF-8" content="ZRgfTSIXKWoqAW8qYAoqFDMIEhNTBnZO-wWymfn2aM6RWXmVUBGi4r3c" csrf-param="_csrf_token" method-param="_method" name="csrf-token"/>

          <title>Title</title>
          <link phx-track-static="phx-track-static" rel="stylesheet" href="/css/app.css"/>
          <script defer="defer" phx-track-static="phx-track-static" type="text/javascript" src="/js/app.js"></script>
        </head>
        <body>body</body>
      </html>
      """

      expected = [
        %{"charset" => "utf-8"},
        %{"content" => "IE=edge", "http-equiv" => "X-UA-Compatible"},
        %{"content" => "width=device-width, initial-scale=1.0", "name" => "viewport"},
        %{
          "charset" => "UTF-8",
          "content" => "ZRgfTSIXKWoqAW8qYAoqFDMIEhNTBnZO-wWymfn2aM6RWXmVUBGi4r3c",
          "csrf-param" => "_csrf_token",
          "method-param" => "_method",
          "name" => "csrf-token"
        }
      ]

      html |> Hq.meta_tags() |> assert_eq(expected, ignore_order: true)
    end
  end

  describe "normalize" do
    test "normalizes an html string" do
      """
      <div>
        <span    id   = "foo"> value</span>
        </div>
      """
      |> Hq.normalize()
      |> assert_eq(~s|<div><span id="foo"> value</span></div>|)
    end

    test "accepts a Floki HTML tree (for flexibility)" do
      [{"div", [], [{"span", [{"id", "foo"}], [" value"]}]}]
      |> Hq.normalize()
      |> assert_eq(~s|<div><span id="foo"> value</span></div>|)
    end

    test "accepts a Floki HTML node (for flexibility)" do
      {"div", [], [{"span", [{"id", "foo"}], [" value"]}]}
      |> Hq.normalize()
      |> assert_eq(~s|<div><span id="foo"> value</span></div>|)
    end
  end

  describe "parse and parse_doc" do
    test "`parse` can parse a string" do
      "<div>hi</div>" |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "`parse_doc` can parse a string" do
      "<html><body>hi</body></html>" |> Hq.parse_doc() |> assert_eq([{"html", [], [{"body", [], ["hi"]}]}])
    end

    test "when given a list, `parse` assumes it is an already-parsed floki html tree" do
      [{"div", [], ["hi"]}] |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "when given a list, `parse_doc` assumes it is an already-parsed floki html tree" do
      [{"html", [], [{"body", [], ["hi"]}]}] |> Hq.parse_doc() |> assert_eq([{"html", [], [{"body", [], ["hi"]}]}])
    end

    test "when given a threeple, `parse` assumes it is a floki element" do
      {"div", [], ["hi"]} |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "`parse` can parse any struct that implements String.Chars" do
      %Test.Etc.TestDiv{contents: "hi"} |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "`parse_doc` can parse any struct that implements String.Chars" do
      %Test.Etc.TestDiv{contents: "hi"} |> Hq.parse_doc() |> assert_eq([{"div", [], ["hi"]}])
    end

    defmodule FooStruct do
      defstruct [:foo]
    end

    test "`parse` cannot parse structs that don't implement String.Chars" do
      assert_raise RuntimeError,
                   "Expected %HtmlQueryTest.FooStruct{foo: 1} to implement protocol String.Chars",
                   fn ->
                     %FooStruct{foo: 1} |> Hq.parse()
                   end
    end

    test "`parse_doc` cannot parse structs that don't implement String.Chars" do
      assert_raise RuntimeError,
                   "Expected %HtmlQueryTest.FooStruct{foo: 1} to implement protocol String.Chars",
                   fn ->
                     %FooStruct{foo: 1} |> Hq.parse_doc()
                   end
    end
  end

  describe "pretty" do
    test "pretty-prints HTML" do
      """
      <div    id="foo"><p>some paragraph
      </p>
           <span>span!   </span>
           </div>
      """
      |> Hq.pretty()
      |> assert_eq("""
      <div id="foo">
        <p>
          some paragraph
        </p>
        <span>
          span!
        </span>
      </div>
      """)
    end

    test "accepts a Floki HTML tree (for flexibility)" do
      [{"div", [], [{"span", [{"id", "foo"}], [" value"]}]}]
      |> Hq.pretty()
      |> assert_eq(~s"""
      <div>
        <span id="foo">
          value
        </span>
      </div>
      """)
    end

    test "accepts a Floki HTML node (for flexibility)" do
      {"div", [], [{"span", [{"id", "foo"}], [" value"]}]}
      |> Hq.pretty()
      |> assert_eq(~s"""
      <div>
        <span id="foo">
          value
        </span>
      </div>
      """)
    end
  end

  describe "reject" do
    test "returns the given html after removing nodes that match the selector" do
      """
      <table>
        <tr id="row-1"> <td> 1 </td> </tr>
        <tr id="row-2"> <td> 2 </td> </tr>
        <tr id="row-3"> <td> 3 </td> </tr>
      </table>
      """
      |> Hq.reject(id: "row-2")
      |> Hq.pretty()
      |> assert_eq(
        """
        <table>
          <tr id="row-1"> <td> 1 </td> </tr>
          <tr id="row-3"> <td> 3 </td> </tr>
        </table>
        """,
        whitespace: :squish
      )
    end
  end

  describe "table" do
    @html """
    <table>
      <thead>
        <tr><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr>
      </thead>
      <tbody>
        <tr><td>1,1</td><td>1,2</td><td>1,3</td></tr>
        <tr><td>2,1</td><td>2,2</td><td>2,3</td></tr>
        <tr><td>3,1</td><td>3,2</td><td>3,3</td></tr>
      </tbody>
    </table>
    """

    test "extracts the cells from the table, returning all columns by default" do
      @html
      |> Hq.table()
      |> assert_eq([
        ["Col 1", "Col 2", "Col 3"],
        ["1,1", "1,2", "1,3"],
        ["2,1", "2,2", "2,3"],
        ["3,1", "3,2", "3,3"]
      ])
    end

    test "`:all` columns can be requested explicitly" do
      @html
      |> Hq.table(only: :all)
      |> assert_eq([
        ["Col 1", "Col 2", "Col 3"],
        ["1,1", "1,2", "1,3"],
        ["2,1", "2,2", "2,3"],
        ["3,1", "3,2", "3,3"]
      ])
    end

    test "can filter certain columns by index via `only: [...]`" do
      @html
      |> Hq.table(only: [0, 2])
      |> assert_eq([
        ["Col 1", "Col 3"],
        ["1,1", "1,3"],
        ["2,1", "2,3"],
        ["3,1", "3,3"]
      ])
    end

    test "can reject certain columns by index via `except: [...]`" do
      @html
      |> Hq.table(except: [0, 2])
      |> assert_eq([
        ["Col 2"],
        ["1,2"],
        ["2,2"],
        ["3,2"]
      ])
    end

    test "can filter certain columns by column title via `only: [...]`" do
      @html
      |> Hq.table(only: ["Col 3", "Col 1"])
      |> assert_eq([
        ["Col 3", "Col 1"],
        ["1,3", "1,1"],
        ["2,3", "2,1"],
        ["3,3", "3,1"]
      ])
    end

    test "can reject certain columns by column title via `except: [...]`" do
      @html
      |> Hq.table(except: ["Col 1", "Col 3"])
      |> assert_eq([
        ["Col 2"],
        ["1,2"],
        ["2,2"],
        ["3,2"]
      ])
    end

    test "can combine `only` and `except`" do
      @html
      |> Hq.table(only: ["Col 1", "Col 3"], except: ["Col 3"])
      |> assert_eq([
        ["Col 1"],
        ["1,1"],
        ["2,1"],
        ["3,1"]
      ])
    end

    test "raises when a column does not exist" do
      assert_raise RuntimeError, ~s|Element "Col B" not present in:\n["Col 1", "Col 2", "Col 3"]|, fn ->
        @html
        |> Hq.table(only: ["Col 1", "Col B"])
      end
    end

    test "can optionally not return the header row" do
      @html
      |> Hq.table(only: ["Col 3", "Col 1"], headers: false)
      |> assert_eq([
        ["1,3", "1,1"],
        ["2,3", "2,1"],
        ["3,3", "3,1"]
      ])
    end

    test "can optionally return the table as a list of maps" do
      @html
      |> Hq.table(as: :maps)
      |> assert_eq([
        %{"Col 1" => "1,1", "Col 2" => "1,2", "Col 3" => "1,3"},
        %{"Col 1" => "2,1", "Col 2" => "2,2", "Col 3" => "2,3"},
        %{"Col 1" => "3,1", "Col 2" => "3,2", "Col 3" => "3,3"}
      ])
    end

    test "when returning a list of maps, can filter by column index or title" do
      @html
      |> Hq.table(as: :maps, only: [0, 2])
      |> assert_eq([
        %{"Col 1" => "1,1", "Col 3" => "1,3"},
        %{"Col 1" => "2,1", "Col 3" => "2,3"},
        %{"Col 1" => "3,1", "Col 3" => "3,3"}
      ])

      @html
      |> Hq.table(as: :maps, only: ["Col 3", "Col 1"])
      |> assert_eq([
        %{"Col 1" => "1,1", "Col 3" => "1,3"},
        %{"Col 1" => "2,1", "Col 3" => "2,3"},
        %{"Col 1" => "3,1", "Col 3" => "3,3"}
      ])
    end

    test "extracts input value when a column _only_ contains a single form field" do
      """
      <table>
        <thead>
          <tr><th>Col 1</th><th>Col 2</th></tr>
        </thead>
        <tbody>
          <tr><td>1</td><td><input type="checkbox" name="value" disabled checked value="true"></td></tr>
          <tr><td>2</td><td><input type="checkbox" name="value" disabled value="true"></td></tr>
          <tr><td>2.1</td><td><input type="hidden" name="value" value="false"><input type="checkbox" name="value" disabled value="true"></td></tr>
          <tr><td>3</td><td><input type="text" name="value" readonly value="some value"></td></tr>
          <tr><td>4</td><td><select name="value" disabled><option value="first"><option selected value="second"></select></td></tr>
          <tr><td>5</td><td><input name="first" disabled value="first"><input name="second" disabled value="second"></td></tr>
        </tbody>
      </table>
      """
      |> Hq.table(as: :maps)
      |> assert_eq([
        %{"Col 1" => "1", "Col 2" => "true"},
        %{"Col 1" => "2", "Col 2" => ""},
        %{"Col 1" => "2.1", "Col 2" => "false"},
        %{"Col 1" => "3", "Col 2" => "some value"},
        %{"Col 1" => "4", "Col 2" => "second"},
        %{"Col 1" => "5", "Col 2" => ""}
      ])
    end
  end

  describe "text" do
    @html """
    <div>
      <p>P1</p>
      <p>P2 <span>a span</span></p>
      <p>P3</p>
    </div>
    """

    test "returns the text value of the HTML node" do
      @html |> Hq.find("div") |> Hq.text() |> assert_eq("P1 P2  a span P3")
    end

    test "requires the use of `Enum.map` to get a list" do
      @html |> Hq.all("p") |> Enum.map(&Hq.text/1) |> assert_eq(["P1", "P2  a span", "P3"])
    end

    test "raises if a list or HTML tree is passed in" do
      assert_raise HtmlQuery.QueryError,
                   """
                   Expected a single HTML node but got:

                   <p>
                     P1
                   </p>
                   <p>
                     P2
                     <span>
                       a span
                     </span>
                   </p>
                   <p>
                     P3
                   </p>

                   Consider using Enum.map(html, &HtmlQuery.text/1)
                   """,
                   fn -> @html |> Hq.all("p") |> Hq.text() end
    end
  end
end
