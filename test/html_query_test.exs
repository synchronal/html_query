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
        <input type="text" name="name" value="alice">
        <input type="number" name="age" value="100">
        <input type="email" name="email" value="">
        <textarea name="about">Alice is 100</textarea>
        <select name="favorite_color"><option>red</option><option selected>blue</option><option>green</option></select>
        <input type="submit" name="save">
      </form>
      """
      |> Hq.find(test_role: "test-form")
      |> Hq.form_fields()
      |> assert_eq(%{name: "alice", age: "100", email: "", about: "Alice is 100", favorite_color: "blue"})
    end

    test "returns empty string for selects with no selection" do
      """
      <form test-role="test-form">
        <select name="favorite_color"><option>red</option><option>blue</option><option>green</option></select>
      </form>
      """
      |> Hq.find(test_role: "test-form")
      |> Hq.form_fields()
      |> assert_eq(%{favorite_color: ""})
    end

    test "excludes inputs with no name" do
      """
      <form test-role="test-form">
        <input type="text" value="alice">
        <input type="number" value="100">
        <input type="email" value="">
        <textarea>Alice is 100</textarea>
        <select><option>red</option><option selected>blue</option><option>green</option></select>
        <input type="submit">
      </form>
      """
      |> Hq.find(test_role: "test-form")
      |> Hq.form_fields()
      |> assert_eq(%{})
    end

    test "returns a nested map when names are in x[y] format" do
      """
      <form>
        <input type="text" name="_csrf" value="_123xyz">
        <input type="text" name="person[name]" value="alice">
        <input type="email" name="auth[email]" value="alice@example.com">
        <input type="password" name="auth[password]" value="password123">
        <textarea name="auth[about]">Alice is 100</textarea>
        <select name="person[favorite_color]"><option selected>red</option><option>blue</option><option>green</option></select>
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{
        _csrf: "_123xyz",
        person: %{name: "alice", favorite_color: "red"},
        auth: %{email: "alice@example.com", password: "password123", about: "Alice is 100"}
      })
    end

    test "converts dashes in fields names to underscores" do
      """
      <form>
        <input type="text" name="full-name" value="Alice Ant">
        <input type="text" name="backup-auth[backup-password]" value="alice123">
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{full_name: "Alice Ant", backup_auth: %{backup_password: "alice123"}})
    end

    test "uses the last value when there are duplicate field names" do
      """
      <form>
        <input type="text" name="name" value="alice">
        <input type="text" name="name" value="billy">
        <input type="text" name="auth[password]" value="alice123">
        <input type="text" name="auth[password]" value="billy123">
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{name: "billy", auth: %{password: "billy123"}})
    end

    test "uses the checked value for radio inputs" do
      """
      <form>
        <input type="radio" name="nested[one_item_checked]" value="a" />
        <input type="radio" name="nested[one_item_checked]" value="b" checked />
        <input type="radio" name="one_item_checked" value="x" checked />
        <input type="radio" name="one_item_checked" value="y" />
        <input type="radio" name="not_checked" value="1" />
        <input type="radio" name="not_checked" value="2" />
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{one_item_checked: "x", not_checked: nil, nested: %{one_item_checked: "b"}})
    end

    test "uses the checked value for checkboxes" do
      """
      <form>
        <input type="checkbox" name="two_items_checked" value="a" />
        <input type="checkbox" name="two_items_checked" value="b" checked />
        <input type="checkbox" name="two_items_checked" value="c" />
        <input type="checkbox" name="two_items_checked" value="d" checked />
        <input type="checkbox" name="nested[not_checked]" value="yes" />
        <input type="checkbox" name="nested[one_item_checked]" value="x" checked />
        <input type="checkbox" name="nested[one_item_checked]" value="y" />
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{two_items_checked: ["b", "d"], nested: %{not_checked: [], one_item_checked: ["x"]}})
    end

    test "handles arrays of checkboxes" do
      """
      <form>
        <input type="checkbox" name="nested[value][]" value="x" checked />
        <input type="checkbox" name="nested[value][]" value="y" />
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{nested: %{value: ["x"]}})
    end

    test "returns `[]` when no checkboxes are checked" do
      """
      <form>
        <input type="checkbox" name="color" value="blue" />
        <input type="checkbox" name="color" value="green" />
        <input type="checkbox" name="color" value="red" />
      </form>
      """
      |> Hq.find("form")
      |> Hq.form_fields()
      |> assert_eq(%{color: []})
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
      |> Hq.table(columns: :all)
      |> assert_eq([
        ["Col 1", "Col 2", "Col 3"],
        ["1,1", "1,2", "1,3"],
        ["2,1", "2,2", "2,3"],
        ["3,1", "3,2", "3,3"]
      ])
    end

    test "can filter certain columns by index" do
      @html
      |> Hq.table(columns: [0, 2])
      |> assert_eq([
        ["Col 1", "Col 3"],
        ["1,1", "1,3"],
        ["2,1", "2,3"],
        ["3,1", "3,3"]
      ])
    end

    test "can filter certain columns by column title" do
      @html
      |> Hq.table(columns: ["Col 3", "Col 1"])
      |> assert_eq([
        ["Col 3", "Col 1"],
        ["1,3", "1,1"],
        ["2,3", "2,1"],
        ["3,3", "3,1"]
      ])
    end

    test "raises when a column does not exist" do
      assert_raise RuntimeError, ~s|Element "Col B" not present in:\n["Col 1", "Col 2", "Col 3"]|, fn ->
        @html
        |> Hq.table(columns: ["Col 1", "Col B"])
      end
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
