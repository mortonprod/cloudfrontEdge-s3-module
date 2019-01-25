AWS_PROFILE=personal
STATE_NAME=wgl-site
STATE_REGION=eu-west-2

.PHONY: test clean

init:
	echo PROFILE: ${AWS_PROFILE}
	terraform init -backend-config="bucket=${STATE_NAME}-terraform-state" \
		-backend-config="key=${STATE_NAME}" \
		-backend-config="region=${STATE_REGION}" \
		-backend-config="dynamodb_table=${STATE_NAME}-terraform-state" 
	touch init
plan: init lambda
	terraform plan

apply: init lambda
	terraform apply --auto-approve

lambda:
	zip -r lambda -X lambda.zip

