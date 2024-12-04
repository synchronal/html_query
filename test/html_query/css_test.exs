defmodule HtmlQuery.CssTest do
  # @related [subject](/lib/html_query/css.ex)

  use Test.SimpleCase, async: true

  doctest HtmlQuery.Css

  describe "selector" do
    test "returns strings unchanged" do
      HtmlQuery.Css.selector("p[id=abc]")
      |> assert_eq("p[id=abc]")
    end

    test "stringifies atoms" do
      HtmlQuery.Css.selector(:div)
      |> assert_eq("div")
    end

    test "creates attribute selectors for each item in a keyword list" do
      HtmlQuery.Css.selector(id: "blue", class: "color")
      |> assert_eq("[id='blue'][class='color']")

      HtmlQuery.Css.selector(p: [id: "blue", class: "color"])
      |> assert_eq("p[id='blue'][class='color']")
    end

    test "combines non-keyword lists with a descendant combinator (a space)" do
      HtmlQuery.Css.selector([[id: "blue", class: "color"], [id: "red", class: "color"]])
      |> assert_eq("[id='blue'][class='color'] [id='red'][class='color']")

      HtmlQuery.Css.selector([[p: [id: "blue", class: "color"]], div: [id: "red", class: "color"]])
      |> assert_eq("p[id='blue'][class='color'] div[id='red'][class='color']")
    end

    test "converts underscores to dashes in attribute names" do
      HtmlQuery.Css.selector(test_role: "glorp")
      |> assert_eq("[test-role='glorp']")
    end

    test "when value is 'true', includes only the key; when 'false', do not render it at all" do
      HtmlQuery.Css.selector(id: "blue", data_favorite: true, role: false)
      |> assert_eq("[id='blue'][data-favorite]")
    end

    test "all together now" do
      HtmlQuery.Css.selector([
        [p: [id: "blue", data_favorite: true]],
        :div,
        [class: "class", test_role: "role"]
      ])
      |> assert_eq("p[id='blue'][data-favorite] div [class='class'][test-role='role']")
    end
  end
end
