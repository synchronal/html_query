# HtmlQuery

Some simple HTML query functions.
Delegates the hard work to [Floki](https://hex.pm/packages/floki).

```elixir
iex> alias HtmlQuery, as: Hq

iex> html = """
<select test-role="breakfast">
  <option value="apple-pie">Apple Pie</option>
  <option value="banana-smoothie" selected>Banana Smoothie</option>
  <option value="cherry-a-la-mode">Cherry à la Mode</option>
</select>
"""

iex> html |> Hq.find(test_role: "breakfast")
{"select", [{"test-role", "breakfast"}],
 [
   {"option", [{"value", "apple-pie"}], ["Apple Pie"]},
   {"option", [{"value", "banana-smoothie"}, {"selected", "selected"}],
    ["Banana Smoothie"]},
   {"option", [{"value", "cherry-a-la-mode"}], ["Cherry à la Mode"]}
 ]
}

iex> html |> Hq.all("[test-role=breakfast] option") |> Enum.map(&Hq.text/1)
["Apple Pie", "Banana Smoothie", "Cherry à la Mode"]

iex> html |> Hq.find!("[test-role=breakfast] option[selected]") |> Hq.attr("value")
"banana-smoothie"
```

## API Docs

<https://hexdocs.pm/html_query>

## Installation

```elixir
def deps do
  [
    {:html_query, "~> 0.1.0"}
  ]
end
```

