# Chasen for Omarchy

Your [Chasen](https://chasenhq.com) servers in the Omarchy bar.

- **The icon** turns while a deploy runs, on any of your servers. It is in the urgent color when an app is down or a server has an error, normal when there is a warning, and dim when all is well.
- **A click** opens the tree: each server with its alerts, then its apps, each with its state, its version, and the change that runs now.
- **In the tree**, Enter or a click opens the Chasen screen, `r` asks again, and Esc closes. A middle click on the icon opens the screen directly.

## What it needs

- Omarchy Quattro, with its shell.
- The `chasen` CLI, 0.8.8 or newer, logged in to at least one server. Each server needs `chasen-server` 0.8.6 or newer; it updates itself each night, or run `chasen-server update` on it:

```bash
curl -fsSL https://chasenhq.com/cli | sh
chasen add server root@203.0.113.5
```

The widget runs one `chasen overview --watch` for as long as the bar runs. It keeps one connection open to each server that you are logged in to, through your SSH or over HTTPS, so it logs in once, not at each ask. It asks once a minute, every 5 seconds while a deploy runs, and every 10 seconds while the tree is open. Each ask is one call to a server: a `docker ps` and a read of its database. The alerts come at most once a minute. Nothing else runs, and the plugin writes no file.

## Install

```bash
omarchy plugin add https://github.com/karloscodes/omarchy-chasen.git --enable
```

The icon goes to the right side of the bar. To move it, use _Setup > Plugins_ or `omarchy bar put karloscodes.chasen --before omarchy.clock`.

## Remove

```bash
omarchy plugin remove karloscodes.chasen
```

## More

- [Chasen on Omarchy](https://chasenhq.com/docs/omarchy/): the launcher in the menu of apps, and the screen in the colors of your theme.
- [The alerts](https://chasenhq.com/docs/reference/#alerts): what each one means and how to fix it.

## License

[Apache 2.0](LICENSE)
