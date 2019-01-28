defmodule Strategies.CoolBlue do
  alias ChromeRemoteInterface.RPC.DOM

  def data(page_pid) do
    page_pid
    |> wait_for_loading()
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

  defp get_node_attr(attrs, name) do
    attrs
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get(name)
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
    |> get_node_attr("title")
  end

  # TODO: DRY
  defp rating(node_id, page_pid) do
    ".review-rating__icons"
    |> fetch_selector(node_id, page_pid)
    |> fetch_node_attrs(page_pid)
    |> get_node_attr("title")
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
      {:chrome_remote_interface, "Page.loadEventFired", %{"method" => "Page.loadEventFired"}} -> page_pid
       ___ -> wait_for_loading(page_pid)
     end
  end

  def pages(_url, []), do: []
  def pages(url, pages_pids) do
    page_pid = List.first(pages_pids)
    ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: url})

    (1..fetch_last_page(page_pid))
    |> Enum.map(fn page_num -> "#{url}?pagina=#{page_num}" end)
  end

  defp fetch_last_page(page_pid) do
    page_pid
    |> wait_for_loading()
    |> fetch_root()
    |> fetch_all(page_pid, ".pagination__item:not(.pagination__item--arrow)")
    |> List.last
    |> fetch_node_html(page_pid)
    |> (&Regex.scan(~r/>(\d*)</, &1)).()
    |> List.flatten
    |> List.last
    |> String.to_integer
  end

  defp fetch_all(root_id, page_pid, selector) do
    case DOM.querySelectorAll(page_pid, %{nodeId: root_id, selector: selector}) do
      {:ok, %{"result" => %{"nodeIds" => ids}}} -> ids
      {:error, __} -> []
    end
  end
end