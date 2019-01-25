AWS_PROFILE=personal

.PHONY: test clean

init: env
	echo PROFILE: ${AWS_PROFILE}
	terraform init
		# -backend-config="bucket=wgl-site-terraform-state"
	touch init
plan: init env lambda
	terraform plan

apply: init env lambda
	terraform apply --auto-approve

lambda:
	zip -r lambda -X lambda.zip

env: 
	export AWS_PROFILE=personal
	export AWS_DEFAULT_REGION=eu-east-1

