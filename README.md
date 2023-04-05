P4 code for SKA Low CBF
=================

[![Documentation Status](https://readthedocs.org/projects/ska-telescope-ska-low-cbf-p4/badge/?version=latest)](https://developer.skao.int/projects/ska-low-cbf-p4/en/latest/?badge=latest)

This repository contains the P4 code to deploy the Atomic COTS solution of the SKA Low CBF. This code originates
from the Low CBF network directory and is now independent of the controler of the P4 switch. 

# Developer’s Guide

* The Makefiles here are inherited from [ska-cicd-makefile](https://gitlab.com/ska-telescope/sdi/ska-cicd-makefile).
  * Refer to docs at that repo, or use make help for details.
  * This link is via a git submodule, so use the --recursive flag when cloning this repository, or run git submodule update --init --recursive afterwards.


# Changelog

### 0.4.7
* Updated ansible scripts to SDE 9.11.2
* Updated P4 code to 9.11.2
* Deactivation of advanced telemetry for a while because of changes in SDE 9.11.2
* Code for tofino 2

### 0.4.6
* Updated ansible scripts to SDE 9.9
* Updated P4 code to 9.9

### 0.4.4
* Ansible scripts to install necessary software on the P4 switch

### 0.4.3
* Starting from the same version as in SKA LOW net repository.
