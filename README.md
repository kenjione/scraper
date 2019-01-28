# Scraper

**This is a simple product scraper which scrapes a list of given product URLs. It scrapes 5 pages concurrently, grabbing data and writing that to stdout.**

# HowTo

Make sure you run Google Chrome in headless mode

```
$ open -a Google\ Chrome --args --headless --disable-gpu --remote-debugging-port=9222
```

After that you can use the scraper.

```elixir
$ iex -S mix
iex(1)> Scraper.start_link(["https://www.coolblue.nl/laptops", "https://www.coolblue.nl/mobiele-telefoons"])

...
"Sony Xperia XZ2 Premium Zilver | 4.5 van 5 sterren uit 17 reviews | 675 | https://image.coolblue.nl/max/270x220/products/1088137",
"Apple iPhone SE 32GB Goud | 4.5 van 5 sterren uit 2547 reviews | 358 | https://image.coolblue.nl/max/270x220/products/503512",
"Apple iPhone 8 64GB RED | 4.5 van 5 sterren uit 572 reviews | 598 | https://image.coolblue.nl/max/270x220/products/1033426",
"Asus Zenfone 4 Groen | 5 van 5 sterren uit 5 reviews | 324 | https://image.coolblue.nl/max/270x220/products/894045",
...
```


```elixir
iex(2)> Scraper.start_link()
...
"General Mobile GM6 Zwart | 4.5 van 5 sterren uit 28 reviews | 166 | https://image.coolblue.nl/max/270x220/products/809498",
"Apple iPhone 7 32 GB Zwart T-Mobile | 4.5 van 5 sterren uit 357 reviews | 614 | https://image.coolblue.nl/max/270x220/products/566727",
"Lenovo Moto Z Zwart | 4.5 van 5 sterren uit 16 reviews | 429 | https://image.coolblue.nl/max/270x220/products/528491",
...
```

