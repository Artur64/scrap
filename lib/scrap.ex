defmodule Scrap do
  @moduledoc """
  Scrapper core module, consists of functions, needed to perform so-called "webscrapping" or just "scrapping"
  """

  @default_template [assets: "img", links: "a"]
  @extraction_template Application.get_env(:scrap, :extraction_template, @default_template)
  @optional_inner_tags [img: "src", a: "href"]

  defstruct Keyword.keys(Application.get_env(:scrap, :extraction_template, @default_template))

  @doc """
  Fetches the given url and returns {:ok. %Scrapper{}} or {:error, "SomeError (if occured)"}
  ## Example
      iex> url = "www.google.com"
      iex> Scrapper.fetch(url)
      {:ok,
          %Scrapper{
           assets: ["http://www.google.com/images/branding/googlelogo/1x/googlelogo_white_background_color_272x92dp.png",
            "http://www.google.com/textinputassistant/tia.png"],
           links: ["http://www.google.com/imghp?hl=en&tab=wi",
            "http://maps.google.com/maps?hl=en&tab=wl",
           ...
           ]
      }}
  """
  def fetch(urls, opts \\ [])

  def fetch(url, opts) when is_binary(url) do
    url
    |> HTTPoison.process_request_url()
    |> try_request()
    |> process(opts)
  end

  @doc """
  Fetches the given list of urls and returns {:ok. %Scrapper{}} and/or {:error, "SomeError (if occured), as the elements of the list"}
  ## Example
      iex> urls = ["www.google.com", "youtube.com"]
      iex> Scrapper.fetch(urls)
      [
       error: "Error, server returned unexpected 301 status code",
       ok: %Scrapper{
        assets: ["http://www.google.com/images/branding/googlelogo/1x/googlelogo_white_background_color_272x92dp.png",
         "http://www.google.com/textinputassistant/tia.png"],
        links: ["http://www.google.com/imghp?hl=en&tab=wi",
         "http://maps.google.com/maps?hl=en&tab=wl",
        ...
        ]}
     ]
  """
  def fetch(urls, opts) when is_list(urls) do
    fetch_urls(urls, opts, [])
  end

  def fetch(data, _) do
    {:error, "Invalid url provided #{inspect(data)}"}
  end

  defp get_attribute(tag), do: Keyword.get(@optional_inner_tags, tag, :no_additional_tag)
  defp fetch_urls([], _opts, acc), do: Enum.reverse(acc)

  defp fetch_urls([url | urls], opts, acc) when is_list(urls) do
    fetch_urls(urls, opts, [fetch(url, opts) | acc])
  end

  defp process_body(body, template, opts) do
    {:ok, parsed_body} = Floki.parse_document(body)
    extract_tag_urls(parsed_body, opts, template, [])
  end

  defp extract_tag_urls(_parsed_body, _opts, [], acc), do: {:ok, struct(__MODULE__, acc)}

  defp extract_tag_urls(
         parsed_body,
         opts,
         [{key, html_tag} | rest],
         acc
       ) do
    extract_tag_urls(parsed_body, opts, rest, [
      {key, get_resources(html_tag, {parsed_body, opts}, get_attribute(String.to_atom(html_tag)))}
      | acc
    ])
  end

  defp try_request(url) do
    case validate_url(url) do
      {:ok, url} -> HTTPoison.get(url, [], follow_redirect: true)
      {:error, _error} = err -> err
    end
  end

  # Multiple clauses of process allows for the options to be handled and passed up to final_process function
  defp process({:ok, %{body: body, request: %{url: requested_url}, status_code: 200}},
         append_origin: true
       ),
       do: process_body(body, @extraction_template, [requested_url])

  # Default case with no options passed
  defp process({:ok, %{body: body, status_code: 200}}, opts),
    do: process_body(body, @extraction_template, opts)

  defp process({:ok, %{status_code: status}}, _opts),
    do: {:error, "Error, server returned unexpected #{inspect(status)} status code"}

  defp process({:error, rsn}, _opts),
    do: {:error, "Error, could not perform a request: #{inspect(rsn)}"}

  defp process(_, _), do: {:error, "Unexpected internal error"}

  defp get_resources(html_tag, {parsed_body, _opts}, :no_additional_tag) do
    Floki.find(parsed_body, html_tag)
  end

  defp get_resources(html_tag, {parsed_body, opts}, attribute) do
    # Final process is when we need to make final clean-ups or changes to the resources
    parsed_body
    |> Floki.find(html_tag)
    |> Floki.attribute(attribute)
    |> Enum.map(fn resource ->
      final_process(resource, opts)
    end)
  end

  defp validate_url(url) do
    case URI.parse(url) do
      %{host: host} ->
        case :inet.gethostbyname(to_charlist(host)) do
          {:ok, _resolved_data} ->
            {:ok, url}

          {:error, _} ->
            {:error,
             "Error, host: #{inspect(host)} couldn't be resolved/doesn't exist/unavailable"}
        end

      _ ->
        {:error, "Invalid url: #{inspect(url)}"}
    end
  end

  # Some websites, like github are "hiding" source path of images, so they will be threated as they are - empty strings
  defp final_process(<<>>, _opts) do
    ""
  end

  defp final_process(link, [requested_url]) do
    case validate_url(link) do
      {:ok, ^link} ->
        link

      {:error, _rsn} ->
        maybe_absolute_path = <<requested_url::binary, link::binary>>

        case validate_url(maybe_absolute_path) do
          {:ok, _valid} -> maybe_absolute_path
          {:error, _} -> link
        end
    end
  end

  # Allows for custom post-processing, by writing own clauses and logics for final processing of resources
  defp final_process(link, _opts) do
    link
  end
end
