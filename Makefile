# Set sane defaults for Make
SHELL = bash
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Set default goal such that `make` runs `make help`
.DEFAULT_GOAL := help

OS = $(shell uname -s)
ifeq ($(OS), Linux)
	OPENER=xdg-open
else
	OPENER=open
endif

.PHONY: all init validate plan apply destroy clean destroy-dryrun rebuild test pre-commit pre-commit-install pre-commit-run

TERRAFORM = docker run --rm --name terraform -v $(CURDIR):/terraform -w /terraform/environments/toozej/ hashicorp/terraform:latest

all: init plan apply

init: ## terraform init
	#terraform init
	$(TERRAFORM) init

validate: ## terraform validate
	#terraform validate
	$(TERRAFORM) validate

plan: ## terraform plan
	#terraform plan -out terraform.tfplan
	$(TERRAFORM) plan -out terraform.tfplan

apply: ## terraform apply
	#terraform apply --auto-approve
	$(TERRAFORM) apply --auto-approve

ssh:
	@if test -f ./id_rsa; then \
		ssh -o StrictHostKeyChecking=no -i ./id_rsa `$(TERRAFORM) output -json username | jq -r '.'`@`$(TERRAFORM) output -json ip | jq -r '.'`; \
	else \
		ssh -o StrictHostKeyChecking=no -i /VMs/.ssh/id_rsa `$(TERRAFORM) output -json username | jq -r '.'`@`$(TERRAFORM) output -json ip | jq -r '.'`; \
	fi

destroy: ## terraform destroy applied resources
	# terraform destroy --auto-approve
	$(TERRAFORM) destroy --auto-approve

clean: destroy ## destroy resources and clean up
	rm -f terraform.tfstate terraform.tfstate.backup

destroy-dryrun: ## dry-run destroy
	# terraform plan -destroy -out terraform.tfplan
	$(TERRAFORM) plan -destroy -out terraform.tfplan

rebuild: destroy apply ## destroy and re-apply

test: ## Run tests
	terrascan init

pre-commit: pre-commit-install pre-commit-run ## Install and run pre-commit hooks

pre-commit-install: ## Install pre-commit hooks and necessary binaries
	command -v pre-commit || sudo dnf install -y pre-commit || sudo apt-get install -y pre-commit
	command -v terraform-docs || cd /tmp && curl -s -L "`curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E "https://.+?-linux-amd64.tar.gz"`" > terraform-docs.tgz && tar xzf terraform-docs.tgz && chmod +x terraform-docs && sudo mv terraform-docs /usr/local/bin/ && rm -rf terraform-docs.tgz && cd -
	command -v tflint || cd /tmp && curl -s -L "`curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip"`" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/local/bin/ && cd -
	command -v tfsec || cd /tmp && curl -s -L "`curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E "https://.+?tfsec_.+?_linux_amd64.tar.gz" | head -n1`" > tfsec.tgz && tar xzf tfsec.tgz && chmod +x tfsec && sudo mv tfsec /usr/local/bin/ && rm tfsec.tgz && cd -
	command -v terrascan || cd /tmp && curl -s -L "`curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?Linux_x86_64.tar.gz"`" > terrascan.tgz && tar xzf terrascan.tgz && chmod +x terrascan && sudo mv terrascan /usr/local/bin/ && rm -rf terrascan.tgz && cd -
	terrascan init
	# install and update pre-commits
	pre-commit install
	pre-commit autoupdate

pre-commit-run: ## Run pre-commit hooks against all files
	pre-commit run --all-files
	# manually run the following checks since their pre-commits aren't working or don't exist

help: ## Display help text
	@grep -E '^[a-zA-Z_-]+ ?:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
