.PHONY: help test sql-lint

help:
	@printf "Available targets:\n"
	@printf "  make test      Run the Python test suite\n"
	@printf "  make sql-lint  Run SQLFluff on Athena verification queries\n"

test:
	uv run python -m pytest -q

sql-lint:
	uv run sqlfluff lint --dialect athena sql/verification