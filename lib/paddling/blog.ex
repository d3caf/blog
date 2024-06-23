defmodule Paddling.Blog do
  alias Paddling.Blog.Post
  require Logger

  post_paths =
    "lib/paddling/posts/**/*.md" |> Path.wildcard() |> Enum.sort()

  Logger.info("Found #{Enum.count(post_paths)} posts")
  Logger.info("Latest post: #{Enum.at(post_paths, 0) |> Path.basename("md")}")

  posts =
    for post_path <- post_paths do
      @external_resource Path.relative_to_cwd(post_path)

      Post.parse!(post_path)
    end

  @posts posts

  def list_posts(), do: @posts
end
