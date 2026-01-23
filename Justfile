# Default command when 'just' is run without arguments
default:
  @just --list

# basedpyright
pyright:
  uv run basedpyright .

# ruff
ruff:
  uv run ruff check .
