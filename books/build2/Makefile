# =============================================================================
# Rust and Parinfer Setup
# =============================================================================

CARGO_ENV := $(HOME)/.cargo/env

# Source cargo environment - use this prefix for any cargo commands
# Note: Each make recipe runs in a new shell, so we must source in each command
CARGO := . "$(CARGO_ENV)" 2>/dev/null && 

# Install Rust toolchain if not present
install-rust:
	@if [ ! -f "$(CARGO_ENV)" ]; then \
		echo "Installing Rust toolchain..."; \
		curl https://sh.rustup.rs -sSf | sh -s -- -y; \
		echo ""; \
		echo "Rust installed. To use cargo in this shell, run:"; \
		echo "  source $(CARGO_ENV)"; \
	else \
		echo "Rust already installed at $(CARGO_ENV)"; \
	fi

# Install parinfer-rust CLI (not on crates.io, must use GitHub)
install-parinfer: install-rust
	@$(CARGO) \
	if command -v parinfer-rust >/dev/null 2>&1; then \
		echo "parinfer-rust already installed"; \
	else \
		echo "Installing parinfer-rust from GitHub..."; \
		cargo install --git https://github.com/eraserhd/parinfer-rust; \
	fi

# Test parinfer-rust installation  
test-parinfer:
	@$(CARGO) echo '(def x' | parinfer-rust -m indent
	@$(CARGO) echo '(defun foo (x)' | parinfer-rust -m indent --lisp-block-comments
	@echo "Parinfer tests passed!"

# Run a command with Rust/Cargo environment
# Usage: make cargo-run CMD="cargo --version"
cargo-run:
	@$(CARGO) $(CMD)
