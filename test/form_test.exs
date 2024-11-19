defmodule HtmlQuery.FormTest do
  # @related [subject](lib/form.ex)
  use Test.SimpleCase, async: true
  alias HtmlQuery, as: Hq

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

  test "returns value of selects with value attributes" do
    """
    <form test-role="test-form">
      <select name="favorite_color"><option>red</option><option value="blue">Blue</option><option selected value="green">Green</option></select>
    </form>
    """
    |> Hq.find(test_role: "test-form")
    |> Hq.form_fields()
    |> assert_eq(%{favorite_color: "green"})
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

  test "uses the last checked value for checkboxes with multiples" do
    """
    <form>
      <input type="checkbox" name="two_items_checked" value="a" />
      <input type="checkbox" name="two_items_checked" value="b" checked />
      <input type="checkbox" name="two_items_checked" value="c" />
      <input type="checkbox" name="two_items_checked" value="d" checked />
      <input type="checkbox" name="nested[not_checked]" value="yes" />
      <input type="checkbox" name="nested[one_item_checked]" value="x" checked />
      <input type="checkbox" name="nested[one_item_checked]" value="y" />
      <input type="checkbox" name="nested[two_items_checked]" value="x" checked />
      <input type="checkbox" name="nested[two_items_checked]" value="y" />
      <input type="checkbox" name="nested[two_items_checked]" value="z" checked />
    </form>
    """
    |> Hq.find("form")
    |> Hq.form_fields()
    |> assert_eq(%{two_items_checked: "d", nested: %{one_item_checked: "x", not_checked: nil, two_items_checked: "z"}})
  end

  test "uses hidden inputs paired with checkboxes, only when unchecked" do
    """
    <form>
      <input type="hidden" name="unchecked_default" value="a" />
      <input type="checkbox" name="unchecked_default" value="b" />
      <input type="hidden" name="unchecked_boolean" value="false" />
      <input type="checkbox" name="unchecked_boolean" value="true" />
      <input type="hidden" name="checked_boolean" value="false" />
      <input type="checkbox" name="checked_boolean" checked value="true" />
      <input type="checkbox" name="nested[checked]" checked value="y" />
      <input type="hidden" name="nested[unchecked]" value="no" />
      <input type="checkbox" name="nested[unchecked]" value="yes" />
      <input type="hidden" name="nested[checked]" value="x" />
      <input type="checkbox" name="nested[checked]" checked value="y" />
    </form>
    """
    |> Hq.find("form")
    |> Hq.form_fields()
    |> assert_eq(%{
      unchecked_default: "a",
      checked_boolean: true,
      unchecked_boolean: false,
      nested: %{unchecked: "no", checked: "y"}
    })
  end

  test "handles arrays of checkboxes" do
    """
    <form>
      <input type="checkbox" name="nested[value][]" value="x" checked />
      <input type="checkbox" name="nested[value][]" value="y" />
      <input type="checkbox" name="nested[value][]" value="z" checked />
    </form>
    """
    |> Hq.find("form")
    |> Hq.form_fields()
    |> assert_eq(%{nested: %{value: ["x", "z"]}})
  end

  test "returns `[]` when no checkboxes are checked" do
    """
    <form>
      <input type="checkbox" name="color[]" value="blue" />
      <input type="checkbox" name="color[]" value="green" />
      <input type="checkbox" name="color[]" value="red" />
    </form>
    """
    |> Hq.find("form")
    |> Hq.form_fields()
    |> assert_eq(%{color: []})
  end
end
