defmodule Scraper do
  use Task

  # def start_link(urls \\ ["https://www.coolblue.nl/laptops"]) do
  def start_link(urls \\ ["https://www.coolblue.nl/mobiele-telefoons"]) do
    fetch_pages_pids
    |> iterate(urls)
  end

  defp iterate(pages_pids, urls) do
    urls
    |> Enum.each(fn url ->
      find_strategy(url)
      |> scrape_with_strategy(url, pages_pids)
    end)
  end

  defp find_strategy(url) do
    parsed = URI.parse(url)
    cond do
      Regex.match?(~r/coolblue\.nl/, parsed.host) -> Strategies.CoolBlue
      true -> :error
    end
  end

  defp scrape_with_strategy(strategy, url, pages_pids) do
    strategy.pages(url, pages_pids)
    |> Enum.chunk_every(5)
    |> Enum.each(&(scrape_chunk(strategy, &1, pages_pids)))
  end

  defp fetch_pages_pids do
    ChromeRemoteInterface.Session.new
    |> open_pages
    |> Enum.map(&start_session/1)
    |> Enum.reject(&is_nil/1)
  end

  defp start_session(page) do
    case ChromeRemoteInterface.PageSession.start_link(page) do
      {:ok, page_pid} ->
        ChromeRemoteInterface.RPC.DOM.enable(page_pid)
        ChromeRemoteInterface.RPC.Page.enable(page_pid)
        page_pid
      _______________ -> nil
    end
  end

  defp scrape_chunk(strategy, chunk, pages_pids) do
    chunk
    |> Enum.with_index
    |> Enum.map(fn {url, index} ->
      page_pid = Enum.at(pages_pids, index)
      Task.async(__MODULE__, :scrape, [url, strategy, page_pid])
    end)
    |> Enum.map(&Task.await/1)
  end

  def scrape(url, strategy, page_pid) do
    ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: url})
    strategy.data(page_pid)
  end

  defp open_pages(server) do
    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)
    for i <- length(pages)..5, i < 5, do: ChromeRemoteInterface.Session.new_page(server)
    case ChromeRemoteInterface.Session.list_pages(server) do
      {:ok, pages} -> pages
      ____________ -> []
    end
  end
end
