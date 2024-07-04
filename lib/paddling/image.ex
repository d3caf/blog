defmodule Paddling.Image do
  require Logger
  alias ExAws.S3

  @posts_dir Path.relative_to_cwd("./lib/paddling/posts") |> Path.expand()
  @bucket Application.compile_env!(:paddling, :image_bucket_name)

  def process_all do
    get_all_image_paths()
    |> optimize_images()
    |> upload_images()
    |> replace_paths()
  end

  defp get_all_image_paths do
    (@posts_dir <> "/**/*.{jpeg,png,jpg}") |> Path.wildcard()
  end

  defp optimize_images(paths) do
    Enum.map(paths, &optimize_image/1)
  end

  defp optimize_image(path) do
    suffix = Path.extname(path)

    with {:ok, resized} <- Image.thumbnail(path, "1200x800", resize: :down),
         {:ok, img_without_meta} <- Image.remove_metadata(resized),
         {:ok, img_bin} <- Vix.Vips.Image.write_to_buffer(img_without_meta, suffix <> "[Q=80]") do
      {path, img_bin}
    end
  end

  defp upload_images(path_tuples) when path_tuples == [],
    do: Logger.warning("No images to upload")

  defp upload_images(path_tuples) do
    Enum.map(path_tuples, &upload_image/1)
  end

  defp upload_image({path, bin}) do
    folder = Path.split(path) |> Enum.at(-2)
    filename = Path.basename(path)

    dest = Path.join(folder, filename)

    Logger.info("Uploading #{filename} to #{dest}")
    S3.put_object(@bucket, dest, bin) |> ExAws.request!()
    {path, dest}
  end

  defp replace_paths(paths) do
    Enum.each(paths, &replace_references/1)
  end

  defp replace_references({orig, new}) do
    needle = "./" <> (Path.split(orig) |> Enum.take(-2) |> Path.join())
    posts = Path.wildcard(@posts_dir <> "/**/*.md")

    Enum.each(posts, &update_post(&1, needle, new))
  end

  defp update_post(post, search_string, replace_with) do
    new_dest = image_url_from_path(replace_with)
    Logger.info("Updating image #{search_string} in #{Path.basename(post, ".md")} -> #{new_dest}")

    updated =
      File.read!(post)
      |> String.replace(search_string, new_dest)

    File.write!(post, updated, [:utf8])
  end

  defp image_url_from_path(path) do
    host =
      Application.fetch_env!(:ex_aws, :s3)[:scheme] <>
        Application.fetch_env!(:ex_aws, :s3)[:host]

    path = Path.join(Application.fetch_env!(:paddling, :image_bucket_name), path)

    URI.new!(host <> "/" <> path) |> URI.to_string()
  end
end
