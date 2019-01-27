defmodule Scraper do
  use Task

  def start_link(links \\ []) do
    Task.start_link(__MODULE__, :scrape, [])
  end

  def scrape() do
    server = ChromeRemoteInterface.Session.new()
    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)
    first_page = pages |> List.first()
    {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(first_page)

    ChromeRemoteInterface.RPC.DOM.enable(page_pid)
    ChromeRemoteInterface.RPC.Page.enable(page_pid)

    ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: "https://www.coolblue.nl/laptops"})
    Strategies.CoolBlue.data(page_pid)
  end
end
