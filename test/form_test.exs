defmodule HtmlQuery.FormTest do
  # @related [subject](lib/form.ex)

  use Test.SimpleCase, async: true

  describe "input_tags" do
    @tag :skip
    test "returns all form inputs as a keyword list" do
      """
      <form>
        <input type="text" name="name" value="alice">
        <input type="number" name="age" value="100" disabled>
        <input type="email" name="email" value="">
        <textarea name="about">Alice is 100</textarea>
        <select name="favorite_color">
          <option value="r">red</option><option value="b" selected>blue</option><option value="g">green</option>
        </select>
        <input type="submit" name="save">
      </form>
      """
      |> HtmlQuery.Form.input_tags()
      |> assert_eq(
        input: %{name: "name", type: "text", value: "alice"},
        input: %{disabled: true, name: "age", type: "number", value: "100"},
        input: %{name: "email", type: "email", value: ""},
        textarea: %{content: "Alice is 100", name: "about"},
        select: %{
          name: "favorite_color",
          options: [
            %{content: "red", value: "r"},
            %{content: "blue", selected: true, value: "b"},
            %{content: "green", value: "g"}
          ]
        },
        input: %{name: "save", type: "submit"}
      )
    end
  end
end
