defmodule HtmlQuery.QueryError do
  @moduledoc """
  An exception raised when unable to find an HTML element.
  """
  defexception [:message]
end
