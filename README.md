# Chasen for Omarchy

Your [Chasen](https://chasenhq.com) servers in the Omarchy bar.

- **The icon** turns while a deploy runs, on any of your servers. It is in the urgent color when an app is down or a server has an error, normal when there is a warning, and dim when all is well.
- **A click** opens the tree: each server with its alerts, then its apps, each with its state, its version, and the change that runs now.
- **In the tree**, Enter or a click opens the Chasen screen, `r` asks again, and Esc closes. A middle click on the icon opens the screen directly.

## What it needs

- Omarchy Quattro, with its shell.
- The `chasen` CLI, 0.8.6 or newer, logged in to at least one server. Each server needs `chasen-server` 0.8.6 or newer too; it updates itself each night, or run `chasen-server update` on it:

```bash
curl -fsSL https://chasenhq.com/cli | sh
chasen add server root@203.0.113.5
```

The widget runs `chasen overview --json`: every 10 seconds while a deploy runs or the tree is open, and once a minute otherwise. That asks each server that you are logged in to, through your SSH or over HTTPS, and prints one line of JSON. Nothing else runs, and the plugin writes no file.

## Install

```bash
omarchy plugin add https://github.com/karloscodes/omarchy-chasen.git --enable
```

The icon goes to the right side of the bar. To move it, use _Setup > Plugins_ or `omarchy bar put karloscodes.chasen --before omarchy.clock`.

To change how often it asks, set `refreshIntervalSec` (30 to 3600, 60 by default) on its entry in `~/.config/omarchy/shell.json`.

## Remove

```bash
omarchy plugin remove karloscodes.chasen
```

## More

- [Chasen on Omarchy](https://chasenhq.com/docs/omarchy/): the launcher in the menu of apps, and the screen in the colors of your theme.
- [The alerts](https://chasenhq.com/docs/reference/#alerts): what each one means and how to fix it.

## License

[Apache 2.0](LICENSE)
