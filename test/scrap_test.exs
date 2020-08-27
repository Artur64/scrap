defmodule ScrapTest do
  use ExUnit.Case

  test "Scrapping valid url, successful case" do
    url = "www.google.com"
    assert {:ok, %Scrap{}} = Scrap.fetch(url)
  end

  test "Scrapping valid url with resourses count check" do
    url = "www.google.com"
    {:ok, %Scrap{assets: assets, links: links}} = Scrap.fetch(url)

    # Getting "img" and "src" tags independently
    req = Floki.parse_document!(HTTPoison.get!(url).body)
    all_img_tags = Floki.find(req, "img")
    all_src_tags = Floki.find(req, "a")

    assert {Enum.count(all_img_tags), Enum.count(all_src_tags)} ==
             {Enum.count(assets), Enum.count(links)}
  end

  test "Scrapping valid urls with responses count check" do
    urls = ["www.google.com", "linux.org"]
    results = Scrap.fetch(urls)
    assert Enum.count(urls) == Enum.count(results)
  end

  test "Scrapping invalid url" do
    invalid_url = "someinvalidurl"

    assert Scrap.fetch(invalid_url) ==
             {:error,
              "Error, could not perform a request: \"Error, host: \\\"someinvalidurl\\\" couldn't be resolved/doesn't exist/unavailable\""}
  end

  test "Scrapping valid list of urls" do
    urls = ["www.google.com", "giphy.com"]
    results = Scrap.fetch(urls)
    assert [{:ok, _}, {:ok, _}] = results
  end

  test "Scrapping partially valid list of urls" do
    urls = ["www.google.com", "someinvalidurl"]
    results = Scrap.fetch(urls)

    assert [{:ok, _}, {:error, _}] = results
  end

  test "Scrapping invalid list of urls" do
    urls = ["someinvalidurl1", "someinvalidurl2"]
    results = Scrap.fetch(urls)
    assert [{:error, _}, {:error, _}] = results
  end
end
