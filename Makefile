# CAR_OCI_REGISTRY_HOST and PROJECT are combined to define
# the Docker tag for this project. The definition below inherits the standard
# value for CAR_OCI_REGISTRY_HOST = artefact.skao.int and overwrites
# PROJECT to give a final Docker tag
PROJECT = ska-low-cbf-p4

# KUBE_NAMESPACE defines the Kubernetes Namespace that will be deployed to
# using Helm.  If this does not already exist it will be created
KUBE_NAMESPACE ?= ska-low-cbf-p4

# Kube app defaults to project name, but we use "ska-low-cbf"
# (to facilitate integration testing in the ska-low-cbf repo)
KUBE_APP = ska-low-cbf

# RELEASE_NAME is the release that all Kubernetes resources will be labelled
# with
RELEASE_NAME ?= test

# UMBRELLA_CHART_PATH Path of the umbrella chart to work with
HELM_CHART ?= test-parent
UMBRELLA_CHART_PATH ?= charts/$(HELM_CHART)/

# Fixed variables
# Timeout for gitlab-runner when run locally
TIMEOUT = 86400
# Helm version
HELM_VERSION = v3.3.1
# kubectl version
KUBERNETES_VERSION = v1.19.2

CI_PROJECT_DIR ?= .

KUBE_CONFIG_BASE64 ?=  ## base64 encoded kubectl credentials for KUBECONFIG
KUBECONFIG ?= /etc/deploy/config ## KUBECONFIG location

XAUTHORITY ?= $(HOME)/.Xauthority
THIS_HOST := $(shell ip a 2> /dev/null | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n1)
DISPLAY ?= $(THIS_HOST):0
JIVE ?= false# Enable jive
TARANTA ?= false# Enable Taranta
MINIKUBE ?= true ## Minikube or not
EXPOSE_All_DS ?= true ## Expose All Tango Services to the external network (enable Loadbalancer service)

CI_PROJECT_PATH_SLUG ?= ska-low-cbf-p4
CI_ENVIRONMENT_SLUG ?= ska-low-cbf-p4

#
# include makefile to pick up the standard Make targets, e.g., 'make build'
# build, 'make push' docker push procedure, etc. The other Make targets
# ('make interactive', 'make test', etc.) are defined in this file.
#
include .make/release.mk
include .make/k8s.mk
include .make/make.mk
include .make/python.mk
include .make/helm.mk
include .make/oci.mk
include .make/help.mk
include .make/docs.mk

# Chart for testing
K8S_CHART = test-parent
K8S_CHARTS = $(K8S_CHART)

CI_JOB_ID ?= local##pipeline job id
TANGO_HOST ?= tango-databaseds:10000## TANGO_HOST connection to the Tango DS
TANGO_SERVER_PORT ?= 45450## TANGO_SERVER_PORT - fixed listening port for local server
K8S_TEST_RUNNER = test-runner-$(CI_JOB_ID)##name of the pod running the k8s-test

# define private overrides for above variables in here
-include PrivateRules.mak

# Single image in root of project
OCI_IMAGES = ska-low-cbf-p4

ITANGO_ENABLED ?= false## ITango enabled in ska-tango-base

COUNT ?= 1

PYTHON_VARS_AFTER_PYTEST = -m 'not (post_deployment or bfrt)' --forked --disable-pytest-warnings --count=$(COUNT)

ifeq ($(strip $(firstword $(MAKECMDGOALS))),k8s-test)
# need to set the PYTHONPATH as bcc is in a strange place
PYTHON_VARS_BEFORE_PYTEST = PYTHONPATH=/app/src:/usr/local/lib/python3/site-packages TANGO_HOST=$(TANGO_HOST)
PYTHON_VARS_AFTER_PYTEST := -m 'post_deployment' --disable-pytest-warnings \
	--count=1 --timeout=300 --forked --true-context
endif

HELM_CHARTS_TO_PUBLISH = ska-low-cbf-p4
HELM_CHARTS ?= $(HELM_CHARTS_TO_PUBLISH)

PYTHON_BUILD_TYPE = non_tag_setup

PYTHON_SWITCHES_FOR_FLAKE8=--ignore=F401,W503 --exit-zero

ifneq ($(CI_REGISTRY),)
K8S_TEST_TANGO_IMAGE = --set ska-low-cbf-p4.cbfnet.image.tag=$(VERSION)-dev.c$(CI_COMMIT_SHORT_SHA) \
	--set ska-low-cbf-p4.cbfnet.image.registry=$(CI_REGISTRY)/ska-telescope/low-cbf/ska-low-cbf-p4
K8S_TEST_IMAGE_TO_TEST=$(CI_REGISTRY)/ska-telescope/low-cbf/ska-low-cbf-p4/ska-low-cbf-p4:$(VERSION)-dev.c$(CI_COMMIT_SHORT_SHA)
else
K8S_TEST_TANGO_IMAGE = --set ska-low-cbf-p4.cbfnet.image.tag=$(VERSION)
K8S_TEST_IMAGE_TO_TEST = artefact.skao.int/ska-low-cbf:$(VERSION)
endif

TARANTA_PARAMS = --set ska-taranta.enabled=$(TARANTA) \
				 --set ska-taranta-auth.enabled=$(TARANTA) \
				 --set ska-dashboard-repo.enabled=$(TARANTA)

ifneq ($(MINIKUBE),)
ifneq ($(MINIKUBE),true)
TARANTA_PARAMS = --set ska-taranta.enabled=$(TARANTA) \
				 --set ska-taranta-auth.enabled=false \
				 --set ska-dashboard-repo.enabled=false
endif
endif

K8S_CHART_PARAMS = --set global.minikube=$(MINIKUBE) \
	--set global.exposeAllDS=$(EXPOSE_All_DS) \
	--set global.tango_host=$(TANGO_HOST) \
	--set global.cluster_domain=$(CLUSTER_DOMAIN) \
	--set global.device_server_port=$(TANGO_SERVER_PORT) \
	--set ska-tango-base.display=$(DISPLAY) \
	--set ska-tango-base.xauthority=$(XAUTHORITY) \
	--set ska-tango-base.jive.enabled=$(JIVE) \
	--set ska-tango-base.itango.enabled=$(ITANGO_ENABLED) \
	$(TARANTA_PARAMS) \
	${K8S_TEST_TANGO_IMAGE} \

PROXY_VALUES = \
		--env=http_proxy=${http_proxy} \
		--env=https_proxy=${https_proxy} \
		--env=no_proxy=${no_proxy} \

# override python.mk python-pre-test target
python-pre-test:
	@echo "python-pre-test: running with: $(PYTHON_VARS_BEFORE_PYTEST) $(PYTHON_RUNNER) pytest $(PYTHON_VARS_AFTER_PYTEST) \
	 --cov=src --cov-report=term-missing --cov-report xml:build/reports/code-coverage.xml --junitxml=build/reports/unit-tests.xml $(PYTHON_TEST_FILE)"

k8s-pre-test: python-pre-test

k8s-pre-template-chart: k8s-pre-install-chart

requirements: ## Install Dependencies
	poetry install

pipeline_unit_test: ## Run simulation mode unit tests in a docker container as in the gitlab pipeline
	@docker run --volume="$$(pwd):/home/tango/ska-low-cbf-p4" \
		--env PYTHONPATH=src:src/ska_low_cbf_p4 --env FILE=$(FILE) -it $(ITANGO_DOCKER_IMAGE) \
		sh -c "cd /home/tango/ska-low-cbf-p4 && make requirements && make python-test"

start_pogo: ## start the pogo application in a docker container; be sure to have the DISPLAY and XAUTHORITY variable not empty.
	docker run --network host --user $(shell id -u):$(shell id -g) --volume="$(PWD):/home/tango/ska-low-cbf-p4" --volume="$(HOME)/.Xauthority:/home/tango/.Xauthority:rw" --env="DISPLAY=$(DISPLAY)" $(CAR_OCI_REGISTRY_HOST)/ska-tango-images-tango-pogo:9.6.35

.PHONY: pipeline_unit_test requirements
