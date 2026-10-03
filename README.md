# Chasen for Omarchy

The alerts of your [Chasen](https://chasenhq.com) servers in the Omarchy bar: an app that is down, a late backup, a full disk, SSH that still takes passwords. A click opens the screen of your servers.

The icon is dim when all is well, normal when a server has a warning, and in the urgent color when something is wrong. Its tooltip lists the alerts, server by server.

## What it needs

- Omarchy Quattro, with its shell.
- The `chasen` CLI, 0.8.4 or newer, logged in to at least one server:

```bash
curl -fsSL https://chasenhq.com/cli | sh
chasen add server root@203.0.113.5
```

The widget runs `chasen alerts --waybar` once a minute. That asks each server that you are logged in to, through your SSH or over HTTPS, and prints one line of JSON. Nothing else runs, and the plugin writes no file.

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
