defmodule Strategies.CoolBlue do
  alias ChromeRemoteInterface.RPC.DOM

  def data(page_pid) do
    rootId = fetch_root_node(page_pid)

    {:ok, %{"result" => %{"nodeIds" => ids}}} =
      DOM.querySelectorAll(page_pid, %{nodeId: rootId, selector: ".product"})

    Enum.map(ids, fn id ->
      Enum.join([title(page_pid, id), rating(page_pid, id), price(page_pid, id), image(page_pid, id)], " | ")
    end)
    |> IO.inspect
  end

  def title(page_pid, root_id) do
    {:ok, %{"result" => %{"nodeId" => nodeId}}} =
      DOM.querySelector(page_pid, %{nodeId: root_id, selector: ".product__title"})

    {:ok, %{"result" => %{"attributes" => attrs }}} =
      DOM.getAttributes(page_pid, %{nodeId: nodeId})

    attrs
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("title")
  end

  # TODO: DRY
  def rating(page_pid, root_id) do
    {:ok, %{"result" => %{"nodeId" => nodeId}}} =
      DOM.querySelector(page_pid, %{nodeId: root_id, selector: ".review-rating__icons"})

    {:ok, %{"result" => %{"attributes" => attrs }}} =
      DOM.getAttributes(page_pid, %{nodeId: nodeId})

    attrs
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("title")
  end

  def price(page_pid, root_id) do
    {:ok, %{"result" => %{"nodeId" => nodeId}}} =
      DOM.querySelector(page_pid, %{nodeId: root_id, selector: ".sales-price__current"})

    {:ok, %{"result" => %{"outerHTML" => html }}} =
      DOM.getOuterHTML(page_pid, %{nodeId: nodeId})

    Regex.scan(~r/>(\d*\.?\d*),-</, html)
    |> List.flatten
    |> List.last
  end

  def image(page_pid, root_id) do
    {:ok, %{"result" => %{"nodeId" => nodeId}}} =
      DOM.querySelector(page_pid, %{nodeId: root_id, selector: ".product__image"})

    {:ok, %{"result" => %{"attributes" => attrs }}} =
      DOM.getAttributes(page_pid, %{nodeId: nodeId})

    attrs
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
    |> Map.get("src")
  end

  def fetch_root_node(page_pid, len \\ 0) do
    {:ok, %{"result" => %{"root" => root}}} = DOM.getDocument(page_pid)
    {:ok, %{"result" => %{"outerHTML" => html}}} = DOM.getOuterHTML(page_pid, %{nodeId: root["nodeId"]})

    new_len = String.length(html)

    if new_len == len do
      root["nodeId"]
    else
      fetch_root_node(page_pid, new_len)
    end
  end

  def pages(url) do
    [
      "https://www.coolblue.nl/laptops?pagina=1",
      "https://www.coolblue.nl/laptops?pagina=2",
      "https://www.coolblue.nl/laptops?pagina=3",
      "https://www.coolblue.nl/laptops?pagina=4",
      "https://www.coolblue.nl/laptops?pagina=5"
    ]
  end
end