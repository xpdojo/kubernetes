# Hashicorp Vault

- [Hashicorp Vault](#hashicorp-vault)
  - [참고](#참고)
  - [Architecture](#architecture)
  - [Workflow](#workflow)
    - [Policy-Authorization](#policy-authorization)
  - [Quickstart](#quickstart)

> A tool for secrets management, encryption as a service, and privileged access management

## 참고

- [Injecting Vault Secrets Into Kubernetes Pods via a Sidecar](https://www.hashicorp.com/blog/injecting-vault-secrets-into-kubernetes-pods-via-a-sidecar) - Vault Team
- [hashicorp/vault](https://github.com/hashicorp/vault) - GitHub
- [Docs](https://www.vaultproject.io/docs) - Vault
- [hashicorp Vault 시작 (tutorial)](https://lejewk.github.io/vault-get-started/) - 개발자님 cs 드세요

## Architecture

![vault-architecture.png](../../images/configuration/vault-architecture.png)

*[출처 - A very high level overview of Vault](https://www.vaultproject.io/docs/internals/architecture)*

## Workflow

### Policy-Authorization

![vault-policy-workflow.svg](../../images/configuration/vault-policy-workflow.svg)

![vault-auth-workflow.svg](../../images/configuration/vault-auth-workflow.svg)

*[출처 - Policy-Authorization Workflow](https://www.vaultproject.io/docs/concepts/policies)*

## Quickstart

```bash

```
