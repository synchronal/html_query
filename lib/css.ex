defmodule HtmlQuery.Css do
  # @related [test](/test/css_test.exs)

  @moduledoc """
  Constructs CSS selectors via Elixir data structures. See `selector/1` for details.
  """

  @typedoc "See docs for `selector/1` for more details."
  @type selector() :: binary() | atom() | keyword() | list()

  @doc ~S"""
  Accepts a string, atom, keyword list, or list, and returns a CSS string.

  ## String syntax

  When given a string, returns the string. This is useful when you don't know if a selector is already a string.

  ```elixir
  iex> HtmlQuery.Css.selector(".profile[test-role='new-members']")
  ".profile[test-role='new-members']"
  ```

  ## Atom syntax

  When given an atom, converts the atom to a string, without converting underscores to dashes.

  ```elixir
  iex> HtmlQuery.Css.selector(:p)
  "p"
  ```

  ## Keyword list syntax

  _The keyword list syntax is intentionally limited; complex selectors are more
  easily written as strings._

  The keyword list syntax makes it a bit eaiser to write simple selectors or selectors that use variables:
  e.g.:

  ```elixir
  HtmlQuery.Css.selector(test_role: "new-members")
  HtmlQuery.Css.selector(id: some_variable)
  ```

  Keys are expected to be atoms and will be dasherized (`foo_bar` -> `foo-bar`).
  Values are expected to be strings or another keyword list.

  A key/value pair will be converted to an attribute selector:
  ```elixir
  iex> HtmlQuery.Css.selector(test_role: "new-members")
  "[test-role='new-members']"
  ```

  A keyword list will be converted to a list of attribute selectors:

  ```elixir
  iex> HtmlQuery.Css.selector(class: "profile", test_role: "new-members")
  "[class='profile'][test-role='new-members']"
  ```

  (Note that the CSS selector `.profile` expands to `[class~='profile']` which is not equivalent to
  `[class='profile']`. The keyword list syntax will not generate `~=` selectors so you should use a
  string selector such as `".profile[test-role='new-members']"` instead if you want `~=` semantics. See the
  [CSS spec](https://www.w3.org/TR/CSS21/selector.html#attribute-selectors) for details.)

  When the value is a keyword list, the key is converted to an element selector:

  ```elixir
  iex> HtmlQuery.Css.selector(p: [class: "profile", test_role: "new-members"])
  "p[class='profile'][test-role='new-members']"
  ```

  ## List syntax

  _The list syntax is intentionally limited; complex selectors are more
  easily written as strings._

  When the value is a list (vs a keyword list), atoms are converted to element selectors and
  keyword lists are converted as described above.

  ```elixir
  iex> HtmlQuery.Css.selector([[p: [class: "profile", test_role: "new-members"]], :div, [class: "tag"]])
  "p[class='profile'][test-role='new-members'] div [class='tag']"
  ```
  """
  @spec selector(selector()) :: binary()
  def selector(input) when is_binary(input), do: input
  def selector(input) when is_atom(input), do: input |> to_string() |> selector()
  def selector(input) when is_list(input), do: reduce(input) |> Moar.String.squish()

  defp reduce(input, result \\ "")
  defp reduce([head | tail], result), do: result <> reduce(head) <> reduce(tail)
  defp reduce({k, v}, result) when is_atom(k), do: reduce({k |> to_string() |> Moar.String.dasherize(), v}, result)
  defp reduce({k, v}, result) when is_list(v), do: "#{result} #{k}#{reduce(v)}"
  defp reduce({_k, false}, result), do: result
  defp reduce({k, true}, result), do: "#{result}[#{k}]"
  defp reduce({k, v}, result), do: "#{result}[#{k}='#{v}']"
  defp reduce(term, result), do: "#{result} #{term} "
end
