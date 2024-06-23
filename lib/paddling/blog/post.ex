defmodule Paddling.Blog.Post do
  alias __MODULE__.Rating

  @keys ~w(ratings content)a
  @enforce_keys @keys
  defstruct @keys

  @type t() ::
          %__MODULE__{
            content: binary(),
            ratings: Rating.t()
          }

  @spec parse!(binary()) :: %__MODULE__{}
  def parse!(filename) do
    [_, meta | content] =
      File.read!(filename)
      |> String.split("---")

    parsed_meta = parse_meta!(meta)

    %__MODULE__{
      ratings: parsed_meta |> Map.get("ratings") |> Rating.to_struct!(),
      content: content |> Enum.at(0) |> parse_content!()
    }
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
