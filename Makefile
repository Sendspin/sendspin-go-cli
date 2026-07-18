# ABOUTME: Build automation for the Sendspin Protocol player CLI
# ABOUTME: Provides targets for building, testing, and daemon install

.PHONY: all build player test test-verbose test-coverage lint clean \
	install-player-daemon uninstall-player-daemon help

# Version from git tag or default
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS := -X github.com/Sendspin/sendspin-go-cli/internal/version.Version=$(VERSION)

# Build with -tags=nolibopusfile so gopkg.in/hraban/opus.v2 doesn't link
# libopusfile. The SDK never calls the opus.Stream API (the only consumer
# of the opusfile parts). Override if you need opusfile: make BUILDTAGS= test
BUILDTAGS ?= nolibopusfile
export GOFLAGS = -tags=$(BUILDTAGS)

all: build

build: player

player:
	@echo "Building sendspin-player..."
	go build -ldflags "$(LDFLAGS)" -o sendspin-player .

test:
	@echo "Running tests..."
	go test ./...

test-verbose:
	@echo "Running tests (verbose)..."
	go test -v ./...

test-coverage:
	@echo "Running tests with coverage..."
	go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

lint:
	@echo "Running golangci-lint..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed. Install: https://golangci-lint.run/usage/install/" && exit 1)
	golangci-lint run --timeout=5m

clean:
	rm -f sendspin-player sendspin-player.exe coverage.out coverage.html

# Install the sendspin-player systemd daemon (run as root)
install-player-daemon: player
	@echo "Installing sendspin-player daemon..."
	install -m 755 sendspin-player /usr/local/bin/sendspin-player
	install -m 644 dist/systemd/sendspin-player.service /etc/systemd/system/sendspin-player.service
	@if [ ! -f /etc/default/sendspin-player ]; then \
		install -m 644 dist/systemd/sendspin-player.env /etc/default/sendspin-player; \
		echo "Created /etc/default/sendspin-player — edit this file to configure."; \
	else \
		echo "/etc/default/sendspin-player already exists, not overwriting."; \
	fi
	@if [ ! -f /etc/sendspin/player.yaml ]; then \
		install -d -m 755 /etc/sendspin; \
		install -m 644 dist/config/player.example.yaml /etc/sendspin/player.yaml; \
		echo "Created /etc/sendspin/player.yaml — edit this file to configure."; \
	else \
		echo "/etc/sendspin/player.yaml already exists, not overwriting."; \
	fi
	systemctl daemon-reload
	@echo "Enable and start with: sudo systemctl enable --now sendspin-player"

uninstall-player-daemon:
	@echo "Removing sendspin-player daemon..."
	-systemctl stop sendspin-player 2>/dev/null
	-systemctl disable sendspin-player 2>/dev/null
	rm -f /etc/systemd/system/sendspin-player.service
	rm -f /usr/local/bin/sendspin-player
	systemctl daemon-reload

help:
	@echo "Targets: player (default), test, test-coverage, lint, clean, install-player-daemon, uninstall-player-daemon"
