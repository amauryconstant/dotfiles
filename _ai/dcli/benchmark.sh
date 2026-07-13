#!/usr/bin/env bash
# Performance comparison between bash and Rust implementations

set -euo pipefail

BASH_SCRIPT="./dcli"
RUST_BINARY="./target/release/dcli-rs"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== dcli Performance Benchmark ===${NC}"
echo ""

# Check if Rust binary exists
if [ ! -f "$RUST_BINARY" ]; then
    echo -e "${YELLOW}Rust binary not found. Building...${NC}"
    source "$HOME/.cargo/env"
    cargo build --release
fi

echo -e "${BLUE}Warming up...${NC}"
"$BASH_SCRIPT" status > /dev/null 2>&1 || true
"$RUST_BINARY" status > /dev/null 2>&1 || true

echo ""

# Benchmark function
benchmark() {
    local name="$1"
    local bash_cmd="$2"
    local rust_cmd="$3"
    local iterations=5

    echo -e "${BLUE}Testing: $name${NC}"

    # Bash version
    local bash_total=0
    for i in $(seq 1 $iterations); do
        local start=$(date +%s%N)
        eval "$bash_cmd" > /dev/null 2>&1
        local end=$(date +%s%N)
        local elapsed=$((($end - $start) / 1000000))
        bash_total=$(($bash_total + $elapsed))
    done
    local bash_avg=$(($bash_total / $iterations))

    # Rust version
    local rust_total=0
    for i in $(seq 1 $iterations); do
        local start=$(date +%s%N)
        eval "$rust_cmd" > /dev/null 2>&1
        local end=$(date +%s%N)
        local elapsed=$((($end - $start) / 1000000))
        rust_total=$(($rust_total + $elapsed))
    done
    local rust_avg=$(($rust_total / $iterations))

    # Calculate speedup
    local speedup=$(awk "BEGIN {printf \"%.1f\", $bash_avg / $rust_avg}")

    echo "  Bash:  ${bash_avg}ms"
    echo "  Rust:  ${rust_avg}ms"
    echo -e "  ${GREEN}Speedup: ${speedup}x${NC}"
    echo ""
}

# Run benchmarks
benchmark "status command" "$BASH_SCRIPT status" "$RUST_BINARY status"
benchmark "module list" "$BASH_SCRIPT module list" "$RUST_BINARY module list"

echo -e "${GREEN}Benchmark complete!${NC}"
echo ""
echo "Note: Times shown are averages over 5 runs."
echo "Speedup will be greater with more modules and packages."
