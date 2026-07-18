# sendspin-player (sendspin-go-cli)

The Sendspin Protocol player CLI — connects to a Sendspin server and plays
synchronized multi-room audio. This is a thin binary around the
[`sendspin-go`](https://github.com/Sendspin/sendspin-go) SDK, which implements
the [Sendspin Protocol](https://www.sendspin-audio.com/spec/). Works as a
player for [Music Assistant](https://music-assistant.io/) via its Sendspin
provider.

Looking for the server? See
[`sendspin-go-server`](https://github.com/Sendspin/sendspin-go-server).
Building your own integration (visualizer, DSP, custom output)? Import the
[SDK](https://github.com/Sendspin/sendspin-go) directly.

## Install

Download a release tarball from the
[releases page](https://github.com/Sendspin/sendspin-go-cli/releases), or
build from source:

```bash
./install-deps.sh     # native deps (libopus + ALSA on Linux)
make                  # builds ./sendspin-player
```

`go install github.com/Sendspin/sendspin-go-cli@latest` also works (the
installed binary is named `sendspin-go-cli`).

### Raspberry Pi quickstart

`scripts/quickstart-pi.sh` fetches the latest arm64 release tarball, installs
the systemd unit, and starts the daemon in one step.

## Usage

```bash
./sendspin-player --name "Living Room"                  # mDNS auto-discovery
./sendspin-player --server ws://192.168.1.100:8927 --name "Kitchen"
./sendspin-player --list-audio-devices
./sendspin-player --audio-device "USB Audio Device" --name "Office"
```

Key flags: `--server`, `--name`, `--audio-device`, `--buffer`,
`--static-delay-ms` (fixed hardware latency compensation), `--codec`,
`--max-sample-rate` / `--max-bit-depth` (format caps), `--no-tui`,
`--config`, `--daemon`. Run `./sendspin-player --help` for the full list.

## Configuration

Config precedence: **CLI flags > `SENDSPIN_PLAYER_*` env vars > YAML file >
built-in defaults**. Default config search path: `$SENDSPIN_PLAYER_CONFIG`,
`~/.config/sendspin/player.yaml`, `/etc/sendspin/player.yaml`. An annotated
example lives at `dist/config/player.example.yaml`.

## Run as a daemon

```bash
sudo make install-player-daemon
sudo systemctl enable --now sendspin-player
journalctl -u sendspin-player -f
```

## Development

The wire protocol, codecs, clock sync, and playback scheduling all live in
the [SDK](https://github.com/Sendspin/sendspin-go) — protocol changes belong
there, along with its conformance suite. This repo owns the CLI flags, the
TUI (`internal/ui`), version stamping, and packaging.

Builds use `GOFLAGS=-tags=nolibopusfile` (see the Makefile) so the binary
does not link `libopusfile` at runtime. Pre-commit hooks
(`.pre-commit-config.yaml`) run gofmt, goimports, go-mod-tidy,
golangci-lint, and `go test -race`.

This project follows the
[Open Home Foundation AI Policy](https://github.com/music-assistant/.github/blob/main/AI_POLICY.md).
