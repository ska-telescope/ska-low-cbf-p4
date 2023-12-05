P4 code for SKA Low CBF
=======================
This repository contains the P4 code to deploy the Atomic COTS solution of the SKA Low CBF. This code originates
from the Low CBF network directory and is now independent of the controler of the P4 switch.

## Documentation
[![Documentation Status](https://readthedocs.org/projects/ska-telescope-ska-low-cbf-p4/badge/?version=latest)](https://developer.skao.int/projects/ska-low-cbf-p4/en/latest/?badge=latest)

The documentation for this project can be found in the `docs` folder, or browsed in the SKA development portal:

* [ska-low-cbf-p4 documentation](https://developer.skatelescope.org/projects/ska-low-cbf-p4/en/latest/index.html "SKA Developer Portal: ska-low-cbf-p4 documentation")

## Project Avatar (Repository Icon)
[Network switch icons created by Ranah Pixel Studio - Flaticon](https://www.flaticon.com/free-icons/network-switch "network switch icons")

# Developer’s Guide

* The Makefiles here are inherited from [ska-cicd-makefile](https://gitlab.com/ska-telescope/sdi/ska-cicd-makefile).
  * Refer to docs at that repo, or use make help for details.
  * This link is via a git submodule, so use the --recursive flag when cloning this repository, or run git submodule update --init --recursive afterwards.


# Changelog

### 0.5.4
* decrement TTL and redo IPv4 Checksum for each IPv4 packets

### 0.5.3
* add switchd systemd service scripts and modify 'sde' role tasks to install it
* latest documentation follows SKAO template

### 0.5.2
* yaml file for SDE compatible with 9.13.0

### 0.5.1
* typo in metadata fixed

### 0.5.0
* Updated ansible scripts to SDE 9.13.0
* Updated P4 code to 9.13.0
* SubStation manipulation
* Routing for SDP 
* New ARP routing to support 
* New documentation 


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
