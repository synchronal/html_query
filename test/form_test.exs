defmodule HtmlQuery.FormTest do
  # @related [subject](lib/form.ex)

  use Test.SimpleCase, async: true

  describe "input_tags" do
    test "returns all form inputs as a keyword list" do
      """
      <form>
        <input type="text" name="name" value="alice" test-id="name-input">
        <input type="number" name="age" value="100" disabled>
        <input type="email" name="email" value="" class="required-field">
        <textarea name="about">Alice is 100</textarea>
        <select name="favorite_color">
          <option value="r">red</option><option value="b" selected>blue</option><option value="g">green</option>
        </select>
        <input type="submit" name="save">
      </form>
      """
      |> HtmlQuery.Form.input_tags()
      |> assert_eq(
        input: %{"name" => "name", "test-id" => "name-input", "type" => "text", "value" => "alice"},
        input: %{"disabled" => "disabled", "name" => "age", "type" => "number", "value" => "100"},
        input: %{"class" => "required-field", "name" => "email", "type" => "email", "value" => ""},
        textarea: %{"@content" => "Alice is 100", "name" => "about"},
        select: %{
          "name" => "favorite_color",
          "options" => [
            option: %{"@content" => "red", "value" => "r"},
            option: %{"@content" => "blue", "selected" => "selected", "value" => "b"},
            option: %{"@content" => "green", "value" => "g"}
          ]
        },
        input: %{"name" => "save", "type" => "submit"}
      )
    end
  end

  describe "form_data" do
    test "handles inputs of any type" do
      """
      <form>
        <input type="text" name="text-input" value="text-input">
        <input type="email" name="email-input" value="email@example.com">
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        text_input: "text-input",
        email_input: "email@example.com"
      })
    end

    test "handles empty input field values" do
      """
      <form>
        <input type="text" name="text-input-without-value">
        <input type="text" name="text-input-with-empty-value" value="">
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        text_input_without_value: nil,
        text_input_with_empty_value: ""
      })
    end

    test "ignores inputs with no name" do
      """
      <form>
        <input type="text" name="text-input" value="value-for-input-with-name">
        <input type="text" value="value-for-input-with-no-name">
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        text_input: "value-for-input-with-name"
      })
    end

    test "ignores disabled fields but not readonly fields" do
      """
      <form>
        <input type="text" name="readonly-input" value="value-for-readonly-input" readonly>
        <input type="text" name="disabled-input" value="value-for-disabled-input" disabled>
        <input type="text" name="disabled-input-2" value="value-for-disabled-input-2" DISABLED>
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        readonly_input: "value-for-readonly-input"
      })
    end

    test "ignores unchecked checkboxes and radios" do
      """
      <form>
        <input type="checkbox" name="checked-checkbox" value="true" checked>
        <input type="checkbox" name="unchecked-checkbox" value="true">
        <input type="radio" name="radio-1" value="radio-1-a">
        <input type="radio" name="radio-1" value="radio-1-b" checked>
        <input type="radio" name="radio-1" value="radio-1-c">
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        checked_checkbox: "true",
        radio_1: "radio-1-b"
      })
    end

    test "handles textareas" do
      """
      <form>
        <textarea name="textarea">textarea</textarea>
        <textarea name="empty-textarea">  </textarea>
        <textarea name="readonly-textarea" readonly>readonly textarea</textarea>
        <textarea name="disabled-textarea" disabled>disabled textarea</textarea>
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        textarea: "textarea",
        readonly_textarea: "readonly textarea"
      })
    end

    test "handles selects" do
      """
      <form>
        <select name="select">
          <option>select-first</option>
          <option selected>select-second</option>
        </select>
        <select name="select-with-nothing-selected">
          <option>select-first</option>
          <option>select-second</option>
        </select>
        <select name="select-with-no-options">
        </select>
        <select name="select-disabled" disabled>
          <option>select-first</option>
          <option selected>select-second</option>
        </select>
        <select name="select-with-selected-disabled-option">
          <option>select-first</option>
          <option disabled selected>select-second</option>
        </select>
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        select: "select-second",
        select_with_nothing_selected: nil,
        select_with_no_options: nil,
        select_with_selected_disabled_option: nil
      })
    end

    test "handles multi-selects" do
      """
      <form>
        <select name="multi-select" multiple>
          <option>multi-select-first</option>
          <option selected>multi-select-second</option>
          <option>multi-select-third</option>
          <option selected>multi-select-fourth</option>
        </select>
        <select name="multi-select-with-no-options" multiple>
        </select>
        <select name="multi-select-with-nothing-selected" multiple>
          <option>multi-select-first</option>
          <option>multi-select-second</option>
        </select>
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        multi_select: ["multi-select-second", "multi-select-fourth"],
        multi_select_with_no_options: [],
        multi_select_with_nothing_selected: []
      })
    end

    test "select option values fall back to content if `value` attr does not exist" do
      """
      <form>
        <select name="select-with-value-in-attr">
          <option selected value="value in attr">value in content</option>
        </select>
        <select name="select-with-value-in-content">
          <option selected>value in content</option>
        </select>
        <select name="multi-select" multiple>
          <option selected value="value in attr 1">value in content 1</option>
          <option selected>value in content 2</option>
        </select>
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        select_with_value_in_attr: "value in attr",
        select_with_value_in_content: "value in content",
        multi_select: ["value in attr 1", "value in content 2"]
      })
    end

    test "turns composite name into nested maps" do
      """
      <form>
        <input type="hidden" name="form-id" value="abc123">
        <input type="radio" name="account[active]" value="yes" checked>
        <input type="radio" name="account[active]" value="no">
        <input type="text" name="account[person][name]" value="Alice">
        <input type="email" name="account[person][email]" value="alice@example.com">
      </form>
      """
      |> HtmlQuery.Form.form_data()
      |> assert_eq(%{
        form_id: "abc123",
        account: %{
          active: "yes",
          person: %{
            name: "Alice",
            email: "alice@example.com"
          }
        }
      })
    end
  end

  describe "expand_composite_key" do
    test "returns a 1-item list when the input when not a composite key" do
      assert HtmlQuery.Form.expand_composite_key("a") == ["a"]
    end

    test "returns a list keys when a composite key" do
      assert HtmlQuery.Form.expand_composite_key("a[b]") == ["a", "b"]
      assert HtmlQuery.Form.expand_composite_key("a[b][c]") == ["a", "b", "c"]
      assert HtmlQuery.Form.expand_composite_key("a[b][c][d]") == ["a", "b", "c", "d"]
    end
  end

  describe "expand_composite_keys" do
    test "handles non-composite keys" do
      assert HtmlQuery.Form.expand_composite_keys(%{"a" => "1"}) == %{"a" => "1"}
      assert HtmlQuery.Form.expand_composite_keys(%{"a" => "1", "b" => "2"}) == %{"a" => "1", "b" => "2"}
    end

    test "handles composite keys" do
      assert HtmlQuery.Form.expand_composite_keys(%{"a[b]" => "1"}) == %{"a" => %{"b" => "1"}}

      assert HtmlQuery.Form.expand_composite_keys(%{
               "a[b]" => "1",
               "c[d]" => "2"
             }) == %{
               "a" => %{"b" => "1"},
               "c" => %{"d" => "2"}
             }
    end

    test "handles nested composite keys" do
      assert HtmlQuery.Form.expand_composite_keys(%{"a[b][c]" => "1"}) == %{"a" => %{"b" => %{"c" => "1"}}}

      assert HtmlQuery.Form.expand_composite_keys(%{
               "a[b]" => "1",
               "a[c][d]" => "2",
               "a[c][e]" => "3"
             }) == %{
               "a" => %{
                 "b" => "1",
                 "c" => %{
                   "d" => "2",
                   "e" => "3"
                 }
               }
             }
    end

    test "fails when a scalar and a map are both specified for the same key" do
      assert_raise BadMapError, fn -> HtmlQuery.Form.expand_composite_keys(%{"a[b]" => "1", "a[b][c]" => "2"}) end
    end
  end
end
