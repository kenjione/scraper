defmodule Scraper do
  use Task

  def start_link(urls \\ ["https://www.coolblue.nl/laptops"]) do
    server = ChromeRemoteInterface.Session.new()
    pages = open_pages(server)

    page_pids = Enum.reduce(pages, [], fn page, acc ->
      {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(page)
      [page_pid | acc]
    end)

    urls
    |> Enum.each(fn url ->
      parsed = URI.parse(url)
      cond do
        Regex.match?(~r/coolblue\.nl/, parsed.host) -> Strategies.CoolBlue.pages(url)
        true -> []
      end
      |> Enum.chunk_every(5)
      |> Enum.each(&(scrape_chunk(&1, page_pids)))
    end)
  end

  def scrape_chunk(chunk, page_pids) do
    chunk
    |> Enum.with_index
    |> Enum.each(fn {url, index} ->
      page_pid = Enum.at(page_pids, index)
      Task.start_link(__MODULE__, :scrape, [url, page_pid])
    end)
  end

  def scrape(url, page_pid) do
    ChromeRemoteInterface.RPC.DOM.enable(page_pid)
    ChromeRemoteInterface.RPC.Page.enable(page_pid)

    ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: url})
    Strategies.CoolBlue.data(page_pid)
  end

  def open_pages(server) do
    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

    for i <- length(pages)..5, i < 5, do: ChromeRemoteInterface.Session.new_page(server)
    case ChromeRemoteInterface.Session.list_pages(server) do
      {:ok, pages} -> pages
      ____________ -> []
    end
  end
end
