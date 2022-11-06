# HtmlQuery

Some simple HTML query functions.
Delegates the hard work to [Floki](https://hex.pm/packages/floki).

```elixir
iex> alias HtmlQuery, as: Hq

iex> html = """
  <form id="profile" test-role="profile">
    <label>Name <input name="name" type="text" value="Fido"> </label>
    <label>Age <input name="age" type="text" value="10"> </label>
    <label>Bio <textarea name="bio">Fido likes long walks and playing fetch.</textarea> </label>
  </form>
</form>
"""

iex> html |> Hq.find!(test_role: "profile")
{"form", [{"id", "profile"}, {"test-role", "profile"}],
 [
   {"label", [], [ "Name ", {"input", [{"name", "name"}, {"type", "text"}, {"value", "Fido"}], []} ]},
   {"label", [], [ "Age ", {"input", [{"name", "age"}, {"type", "text"}, {"value", "10"}], []} ]},
   {"label", [], [ "Bio ", {"textarea", [{"name", "bio"}], ["Fido likes long walks and playing fetch."]} ]}
 ]
}

iex> html |> Hq.all("input[type=text]") |> Enum.map(&Hq.attr(&1, "value"))
["Fido", "10"]

iex> html |> Hq.find(test_role: "profile") |> Hq.form_fields()
%{age: "10", bio: "Fido likes long walks and playing fetch.", name: "Fido"}
```

## API Docs

<https://hexdocs.pm/html_query/HtmlQuery.html>

## Installation

```elixir
def deps do
  [
    {:html_query, "~> 0.3"}
  ]
end
```

