.PHONY: test

test:
	@echo "Running Muninn test suite..."
	@nvim --headless --cmd "set rtp+=." -c "lua require('muninn.tests.run').run_all()"

# Run a single test module (e.g., make test-module MODULE=runner)
test-module:
	@echo "Running Muninn tests for $(MODULE)..."
	@nvim --headless --cmd "set rtp+=." -c "lua require('muninn.tests.run').run('$(MODULE)')"
