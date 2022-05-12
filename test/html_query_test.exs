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
      <div class="profile admin" id="alice">
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

    test "returns nil if the attr does not exist" do
      @html |> Hq.find("#alice") |> Hq.attr("foo") |> assert_eq(nil)
    end

    test "raises if the first argument is a list or HTML tree" do
      assert_raise RuntimeError,
                   """
                   Expected a single HTML node but got:

                   <div class="profile admin" id="alice">
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
      assert_raise RuntimeError,
                   "Expected a single HTML node but found none",
                   fn -> @html |> Hq.find!("glorp") end
    end

    test "fails if more than 1 element is found" do
      assert_raise RuntimeError,
                   """
                   Expected a single HTML node but got:

                   <p>
                     P1
                   </p>
                   <p>
                     P2
                   </p>


                   """,
                   fn -> @html |> Hq.find!("p") end
    end
  end

  describe "form_fields" do
    test "returns all the form fields as a name -> value map" do
      html = """
      <form test-role="test-form">
        <input type="text" name="person[name]" value="alice">
        <input type="text" name="person[age]" value="100">
        <textarea name="person[about]">Alice is 100</textarea>
      </form>
      """

      html
      |> Hq.find(test_role: "test-form")
      |> Hq.form_fields()
      |> assert_eq(%{name: "alice", age: "100", about: "Alice is 100"})
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

  describe "parse" do
    test "can parse a string" do
      "<div>hi</div>" |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "when given a list, assumes it is an already-parsed floki html tree" do
      [{"div", [], ["hi"]}] |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "when given a threeple, assumes it is a floki element" do
      {"div", [], ["hi"]} |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "can parse any struct that implements String.Chars" do
      %Test.Etc.TestDiv{contents: "hi"} |> Hq.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    defmodule FooStruct do
      defstruct [:foo]
    end

    test "cannot parse structs that don't implement String.Chars" do
      assert_raise RuntimeError,
                   "Expected %HtmlQueryTest.FooStruct{foo: 1} to implement protocol String.Chars",
                   fn ->
                     %FooStruct{foo: 1} |> Hq.parse()
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
      assert_raise RuntimeError,
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
