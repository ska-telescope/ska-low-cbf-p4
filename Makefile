# CAR_OCI_REGISTRY_HOST and PROJECT are combined to define
# the Docker tag for this project. The definition below inherits the standard
# value for CAR_OCI_REGISTRY_HOST = artefact.skao.int and overwrites
# PROJECT to give a final Docker tag
PROJECT = ska-low-cbf-p4

# Fixed variables
# Timeout for gitlab-runner when run locally
TIMEOUT = 86400

CI_PROJECT_DIR ?= .
CI_PROJECT_PATH_SLUG ?= ska-low-cbf-p4
CI_ENVIRONMENT_SLUG ?= ska-low-cbf-p4

#
# include makefile to pick up the standard Make targets, e.g., 'make build'
# build, 'make push' docker push procedure, etc. The other Make targets
# ('make interactive', 'make test', etc.) are defined in this file.
#
include .make/release.mk
#include .make/k8s.mk
include .make/make.mk
#include .make/python.mk
#include .make/helm.mk
#include .make/oci.mk
include .make/help.mk
include .make/docs.mk

CI_JOB_ID ?= local##pipeline job id

# define private overrides for above variables in here
-include PrivateRules.mak

PROXY_VALUES = \
		--env=http_proxy=${http_proxy} \
		--env=https_proxy=${https_proxy} \
		--env=no_proxy=${no_proxy} \
