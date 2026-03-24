# tracegeo

Trace the network route to any destination and see where each hop is in the world.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)](#requirements)
[![Bash: 4.0+](https://img.shields.io/badge/bash-4.0%2B-green.svg)](#requirements)
[![Version: 0.2.0](https://img.shields.io/badge/version-0.2.0-orange.svg)](https://github.com/musayann/tracegeo)

## Sample Output

```bash
Tracing route to google.com (172.217.170.206)...

 HOP   IP                   LATENCY       DELTA   LOCATION                 ORG
 ───  ────────────────  ──────────  ──────────   ──────────────────────── ────────────────────
   1  192.168.8.1         0.800 ms           -   (private)                -
   2  41.216.140.1        4.163 ms     +3.0 ms   Kigali, RW               AS37006 Liquid Telecommunication Rwanda Limited
   3  197.155.90.64      18.973 ms     -5.0 ms   Nairobi, KE              AS30844 Liquid Telecommunications Ltd
   4  41.60.138.237      24.070 ms     +5.1 ms   Mombasa, KE              AS30844 Liquid Telecommunications Ltd
   5  192.178.251.145    25.522 ms     +3.9 ms   Mombasa, KE              AS15169 Google LLC
   6  172.217.170.206    26.283 ms     +4.5 ms   Mombasa, KE              AS15169 Google LLC

Done. 6 hops, destination reached.
```

## Features

- Traces the full network path to any IP address or domain name
- Supports both IPv4 and IPv6 traceroutes with `-4`/`-6` flags (auto-detects by default)
- Resolves domain names to IPs via `dig`
- Geolocates each public hop — city, country, and organization — using [ipinfo.io](https://ipinfo.io)
- Displays round-trip latency for each hop with inter-hop delta to pinpoint where latency is added
- Automatically detects and labels private (RFC 1918) IP addresses
- Colored, formatted table output with Unicode box-drawing characters
- Animated spinner during geolocation lookups
- Respects the [`NO_COLOR`](https://no-color.org) environment variable and non-TTY output
- Configurable maximum hops and probes per hop
- Zero configuration — no API keys, no config files
- Single-file, pure Bash — no compilation, no runtime dependencies beyond standard Unix tools

## Requirements

tracegeo runs on any Unix-like system with the following:

| Dependency    | Purpose                    | Typical Package               |
| ------------- | -------------------------- | ----------------------------- |
| `bash` 4.0+   | Script interpreter         | Pre-installed on most systems |
| `traceroute`  | Network route tracing      | `traceroute` / `inetutils`    |
| `traceroute6` | IPv6 route tracing         | Usually included with `traceroute` (macOS built-in) |
| `dig`         | DNS resolution             | `dnsutils` / `bind-utils`     |
| `curl`        | HTTP requests to ipinfo.io | `curl`                        |

Run `make check` to verify all dependencies are present.

## Installation

### From source

```sh
git clone https://github.com/musayann/tracegeo.git
cd tracegeo
make install
```

Installs to `/usr/local/bin` by default. Customize with:

```sh
make install PREFIX=~/.local
```

### Manual

```sh
curl -fsSL https://raw.githubusercontent.com/musayann/tracegeo/main/tracegeo -o tracegeo
chmod +x tracegeo
sudo mv tracegeo /usr/local/bin/
```

### Installing dependencies

**macOS (Homebrew):**

```sh
brew install bind traceroute curl
```

> `curl` is pre-installed on macOS. `bind` provides `dig`. `traceroute` may already be present.

**Debian / Ubuntu:**

```sh
sudo apt install dnsutils traceroute curl
```

**Fedora / RHEL / CentOS:**

```sh
sudo dnf install bind-utils traceroute curl
```

**Arch Linux:**

```sh
sudo pacman -S bind traceroute curl
```

### Verifying dependencies

```sh
make check
```

### Uninstall

```sh
make uninstall
```

## Usage

Trace the route to a domain:

```sh
tracegeo google.com
```

Trace to a raw IP address:

```sh
tracegeo 8.8.8.8
```

Limit to 15 hops:

```sh
tracegeo -m 15 example.com
```

Single probe per hop (faster, less accurate):

```sh
tracegeo -q 1 cloudflare.com
```

Force IPv6:

```sh
tracegeo -6 google.com
```

Trace to a raw IPv6 address:

```sh
tracegeo 2001:4860:4860::8888
```

Disable color output:

```sh
NO_COLOR=1 tracegeo google.com
```

Pipe to a file (color is automatically disabled for non-TTY output):

```sh
tracegeo google.com > trace.txt
```

> `traceroute` may require elevated privileges on some systems. If you see no hops, try `sudo tracegeo google.com`.

## Options

| Flag                 | Description                     | Default |
| -------------------- | ------------------------------- | ------- |
| `-h`, `--help`       | Show help message and exit      |         |
| `-v`, `--version`    | Print version and exit          |         |
| `-4`                 | Force IPv4                      |         |
| `-6`                 | Force IPv6                      |         |
| `-m`, `--max-hops N` | Maximum number of hops to trace | `30`    |
| `-q`, `--queries N`  | Number of probes sent per hop   | `3`     |

## How It Works

tracegeo is a single Bash script that chains standard Unix networking tools with a free geolocation API. The pipeline has four stages:

1. **DNS Resolution** — If the target is a domain name, `dig +short` resolves it to an IP address (A record for IPv4, AAAA for IPv6). The protocol is auto-detected or can be forced with `-4`/`-6`. If resolution fails, the script exits with an error.

2. **Route Tracing** — `traceroute -n` (or `traceroute6 -n` for IPv6) runs with the configured max hops and probes per hop. The `-n` flag skips reverse DNS to keep output fast and parseable. Output is streamed line-by-line through a `while read` loop so results appear incrementally.

3. **Geolocation Lookup** — For each hop that returns a public IP, the script sends a request to `https://ipinfo.io/<ip>` via `curl` with a 3-second timeout. The JSON response is parsed with `grep`/`cut` — no `jq` dependency required. Private IPs (RFC 1918) are labeled `(private)` and skip the API call entirely. Timed-out hops (`* * *`) are displayed as `*`.

4. **Formatted Output** — Results are printed as a column-aligned table using `printf`. Unicode box-drawing characters form the header separator. ANSI color codes are applied for readability but automatically suppressed when `NO_COLOR` is set or stdout is not a terminal.

```
destination ──▶ dig (DNS) ──▶ traceroute ──▶ per-hop curl (ipinfo.io) ──▶ formatted table
```

## Environment Variables

| Variable   | Effect                                                         |
| ---------- | -------------------------------------------------------------- |
| `NO_COLOR` | When set to any non-empty value, disables all ANSI color codes |

Color is also automatically disabled when stdout is not a terminal (e.g., when piping to a file).

## Contributing

Contributions are welcome. Here is how to get started:

### Development setup

1. Fork and clone the repo
2. Run `make check` to verify dependencies
3. The entire tool is a single file: `tracegeo` — edit it directly
4. Test manually: `./tracegeo google.com`

### Guidelines

- Keep it pure Bash — no external interpreters (Python, Perl, etc.)
- Preserve compatibility with Bash 4.0+
- Respect `NO_COLOR` for any new output
- Keep the script self-contained in a single file
- Match the existing code style: 2-space indent, `snake_case` functions, `# ---` section separators

### Submitting changes

1. Create a feature branch
2. Make your changes with clear commit messages
3. Open a pull request describing what and why

## Limitations

- Geolocation accuracy depends on ipinfo.io's free-tier data; some IPs may show approximate locations
- ipinfo.io rate-limits unauthenticated requests (~50k/month); rapid successive traces may be throttled
- `traceroute` may require `sudo` on some Linux configurations
- JSON parsing uses `grep`/`cut` rather than a dedicated parser; unusual API response formatting could theoretically cause misparses

## License

[MIT](LICENSE) — Copyright (c) 2026 Yannick Musafiri

## Credits

- [ipinfo.io](https://ipinfo.io) for the free IP geolocation API
- Built with standard Unix tools: `traceroute`, `dig`, `curl`, and `bash`
