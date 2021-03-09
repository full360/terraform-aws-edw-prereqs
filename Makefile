TERRAFORMMK := $(shell if [ ! -e terraform.mk ]; then \
	wget -N -q https://terraform-modules-full360.s3.amazonaws.com/public/tooling/terraform.mk; fi)

include terraform.mk
