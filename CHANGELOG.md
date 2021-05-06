# annatar - changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Implement AWS compatibility
- Allow multiple instances for single GCP VPS Zones

## [1.0.0] - 2021-03-04
### Added

- Terraform 
  - Scripts to create a generic Debian server (OS can be changed within the script)
  - Scripts to deploy DNS Managed Zone with custom registries for a given domain
- Ansible playbook to deploy web and mail servers for a given domain; roles include:
  - Postfix
  - Dovecot
  - OpenDKIM
  - Postfixadmin
  - Roundcube
  - Mailjet as relay
  - Nginx webserver
  - Letsencrypt 
  - Pip2 installation
  - Gophish for phishing campaigns
- A playbook file is included to illustrate how to deploy required web or mail servers
