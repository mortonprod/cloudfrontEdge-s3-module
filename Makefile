AWS_PROFILE=personal

.PHONY: test clean

init: env
	echo PROFILE: ${AWS_PROFILE}
	terraform init
		# -backend-config="bucket=wgl-site-terraform-state"
plan: env lambda
	terraform plan

apply: env lambda
	terraform apply
	aws s3  cp  ./website/index.html s3://wgl-site/index.html

lambda:
	zip -r lambda -X lambda.zip

env: 
	export AWS_PROFILE=personal
	export AWS_DEFAULT_REGION=eu-east-1

