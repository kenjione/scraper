defmodule Strategies.CoolBlue do
  alias ChromeRemoteInterface.RPC.DOM

  def data(page_pid) do
    wait_for_loading(page_pid)

    page_pid
    |> fetch_root()
    |> fetch_products(page_pid)
    |> Enum.map(&fetch_props(&1, page_pid))
    |> IO.inspect
  end

  defp fetch_root(page_pid) do
    case DOM.getDocument(page_pid) do
      {:ok, %{"result" => %{"root" => root}}} -> root["nodeId"]
      {:error, __} -> 0
    end
  end

  defp fetch_products(root_id, page_pid) do
    case DOM.querySelectorAll(page_pid, %{nodeId: root_id, selector: ".product"}) do
      {:ok, %{"result" => %{"nodeIds" => ids}}} -> ids
      {:error, __} -> []
    end
  end

  defp fetch_props(id, page_pid) do
    [
      title(id, page_pid),
      rating(id, page_pid),
      price(id, page_pid),
      image(id, page_pid)
    ]
    |> Enum.join(" | ")
  end

  defp fetch_selector(selector, root_id, page_pid) do
    case DOM.querySelector(page_pid, %{nodeId: root_id, selector: selector}) do
      {:ok, %{"result" => %{"nodeId" => node_id}}} -> node_id
      {:error, _} -> 0
    end
  end

  defp fetch_node_attrs(node_id, page_pid) do
    case DOM.getAttributes(page_pid, %{nodeId: node_id}) do
      {:ok, %{"result" => %{"attributes" => attrs }}} -> attrs
      {:error, _} -> %{}
    end
  end

  defp fetch_node_html(node_id, page_pid) do
    case DOM.getOuterHTML(page_pid, %{nodeId: node_id}) do
      {:ok, %{"result" => %{"outerHTML" => html }}} -> html
      {:error, _} -> ""
    end
  end

  defp title(node_id, page_pid) do
    ".product__title"
    |> fetch_selector(node_id, page_pid)
    |> fetch_node_attrs(page_pid)
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("title")
  end

  # TODO: DRY
  defp rating(node_id, page_pid) do
    ".review-rating__icons"
    |> fetch_selector(node_id, page_pid)
    |> fetch_node_attrs(page_pid)
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("title")
  end

  defp price(node_id, page_pid) do
    ".sales-price__current"
    |> fetch_selector(node_id, page_pid)
    |> fetch_node_html(page_pid)
    |> (&Regex.scan(~r/>(\d*\.?\d*),-</, &1)).()
    |> List.flatten
    |> List.last
  end

  defp image(node_id, page_pid) do
    ".product__image"
    |> fetch_selector(node_id, page_pid)
    |> fetch_node_attrs(page_pid)
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("src")
  end

  defp wait_for_loading(page_pid) do
    ChromeRemoteInterface.PageSession.subscribe(page_pid, "Page.loadEventFired")

    receive do
      {:chrome_remote_interface, "Page.loadEventFired", %{"method" => "Page.loadEventFired"}} -> :ok
       ___ -> wait_for_loading(page_pid)
     end
  end

  def pages(url) do
    [
      # "https://www.coolblue.nl/laptops?pagina=1",
      "https://www.coolblue.nl/mobiele-telefoons",
      # "https://www.coolblue.nl/laptops?pagina=2",
      # "https://www.coolblue.nl/laptops?pagina=3",
      # "https://www.coolblue.nl/laptops?pagina=4",
      # "https://www.coolblue.nl/laptops?pagina=5"
    ]
  end
end