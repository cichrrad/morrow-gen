.DEFAULT_GOAL := help

# --- Setup ---

install: ## Install Ruby dependencies (Bundle)
	@echo "Installing gems..."
	@bundle install

setup: install ## Full setup (currently alias for install)
	@echo "Setup complete. You can now run 'make run_cli' or 'make run_webui'."

# --- Application Runners ---

run_cli: ## Run the interactive CLI Character Generator
	@ruby bin/cliMorrowGen.rb

run_webui: ## Start the Sinatra Web Server (localhost:4567)
	@ruby web_app.rb

# --- Testing / Dev ---

test: ## Run tests
	@bundle exec rspec

clean: ## Clean up temporary files
	@rm -f *.gem
	@echo "Cleaned up."

# --- Helper ---

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'