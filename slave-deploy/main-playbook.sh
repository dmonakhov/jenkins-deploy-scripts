#!/bin/sh -e

ansible-playbook $@ post-install.yaml
ansible-playbook $@ main.yaml
