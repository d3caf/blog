defmodule Paddling.Blog.Post do
  alias __MODULE__.Rating

  @required_keys ~w(content category slug)a
  @enforce_keys @required_keys
  defstruct ~w(metadata)a ++ @required_keys

  @type t() ::
          %__MODULE__{
            content: binary(),
            metadata: map(),
            category: binary(),
            slug: binary()
          }

  @spec parse!(binary()) :: %__MODULE__{}
  def parse!(filename) do
    [_, meta | content] =
      File.read!(filename)
      |> String.split("---")

    parsed_meta = parse_meta!(meta)

    %__MODULE__{
      slug: Path.basename(filename, ".md"),
      category: parsed_meta |> Map.get("category"),
      metadata: parsed_meta |> Map.get("metadata"),
      content: content |> Enum.at(0) |> parse_content!()
    }
    |> IO.inspect()
  end

  defp parse_meta!(meta) do
    meta
    |> String.downcase()
    |> YamlElixir.read_from_string!()
  end

  defp parse_content!(content) do
    content
    |> String.trim("\n")
    |> Earmark.as_html!()
  end

  defmodule Rating do
    @moduledoc """
    Deprecated?
    """
    @keys ~w(scenery difficulty access wildlife uniqueness privacy wpa)a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            scenery: float(),
            difficulty: float(),
            access: float(),
            wildlife: float(),
            uniqueness: float(),
            privacy: float(),
            wpa: float()
          }

    def to_struct!(map) do
      atoms_as_keys =
        for(
          {k, v} <- map,
          into: %{},
          do: {String.to_atom(k), v}
        )

      struct!(__MODULE__, atoms_as_keys)
    end
  end
end
