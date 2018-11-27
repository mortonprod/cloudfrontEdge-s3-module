AWS_PROFILE=personal

.PHONY: test clean

init: env
	echo PROFILE: ${AWS_PROFILE}
	terraform init
		# -backend-config="bucket=wgl-site-terraform-state"
plan: env lambda
	terraform plan

lambda:
	zip -r lambda -X lambda.zip

env: 
	export AWS_PROFILE=personal

