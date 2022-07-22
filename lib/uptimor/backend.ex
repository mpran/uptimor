defmodule Uptimor.Backend do
  @moduledoc "Behaviour for uptimor backend"

  @callback get_all! :: [map(), ...]
end
