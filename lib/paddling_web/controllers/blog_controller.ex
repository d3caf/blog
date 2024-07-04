defmodule PaddlingWeb.BlogController do
  use PaddlingWeb, :controller
  alias Paddling.Blog

  def post(conn, %{"slug" => slug, "year" => _}) do
    assign(conn, :post, Blog.get_post(slug))
    |> render(:post)
  end
end
