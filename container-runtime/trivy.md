# Trivy

- [Trivy](#trivy)
  - [개념](#개념)
  - [참고](#참고)
  - [Quickstart](#quickstart)
    - [Install](#install)
    - [Usage](#usage)

## 개념

> 컨테이너 이미지, Git 리포지토리 및 파일 시스템을 위한 단순하면서 광범위한 `취약점 스캐너(Vulnerability Scanner)`입니다.
> CI에 적합합니다.

## 참고

- [공식 문서](https://aquasecurity.github.io/trivy/latest/)
- [aquasecurity/trivy GitHub](https://github.com/aquasecurity/trivy)
- [Find Image Vulnerabilities Using GitHub and Aqua Security Trivy Action](https://blog.aquasec.com/github-vulnerability-scanner-trivy) - Simar Singh
- [Using Trivy to Discover Vulnerabilities in VS Code Projects](https://blog.aquasec.com/trivy-open-source-vulnerability-scanner-vs-code) - Simar Singh
- [How to build a CI/CD pipeline for container vulnerability scanning with Trivy and AWS Security Hub](https://aws.amazon.com/blogs/security/how-to-build-ci-cd-pipeline-container-vulnerability-scanning-trivy-and-aws-security-hub/) - AWS

## Quickstart

### [Install](https://aquasecurity.github.io/trivy/latest/installation/)

- macOS

```bash
brew install aquasecurity/trivy/trivy
```

or

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.16.0
```

### Usage

```bash
trivy image registry:2.7.1
# registry:2.7.1 (alpine 3.11.8)
# ==============================
# Total: 6 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 4, CRITICAL: 0)

# +--------------+------------------+----------+-------------------+---------------+---------------------------------------+
# |   LIBRARY    | VULNERABILITY ID | SEVERITY | INSTALLED VERSION | FIXED VERSION |                 TITLE                 |
# +--------------+------------------+----------+-------------------+---------------+---------------------------------------+
# | busybox      | CVE-2021-28831   | HIGH     | 1.31.1-r9         | 1.31.1-r10    | busybox: invalid free or segmentation |
# |              |                  |          |                   |               | fault via malformed gzip data         |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-28831 |
# +--------------+------------------+          +-------------------+---------------+---------------------------------------+
# | libcrypto1.1 | CVE-2021-3450    |          | 1.1.1j-r0         | 1.1.1k-r0     | openssl: CA certificate check         |
# |              |                  |          |                   |               | bypass with X509_V_FLAG_X509_STRICT   |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3450  |
# +              +------------------+----------+                   +               +---------------------------------------+
# |              | CVE-2021-3449    | MEDIUM   |                   |               | openssl: NULL pointer dereference     |
# |              |                  |          |                   |               | in signature_algorithms processing    |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3449  |
# +--------------+------------------+----------+                   +               +---------------------------------------+
# | libssl1.1    | CVE-2021-3450    | HIGH     |                   |               | openssl: CA certificate check         |
# |              |                  |          |                   |               | bypass with X509_V_FLAG_X509_STRICT   |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3450  |
# +              +------------------+----------+                   +               +---------------------------------------+
# |              | CVE-2021-3449    | MEDIUM   |                   |               | openssl: NULL pointer dereference     |
# |              |                  |          |                   |               | in signature_algorithms processing    |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3449  |
# +--------------+------------------+----------+-------------------+---------------+---------------------------------------+
# | ssl_client   | CVE-2021-28831   | HIGH     | 1.31.1-r9         | 1.31.1-r10    | busybox: invalid free or segmentation |
# |              |                  |          |                   |               | fault via malformed gzip data         |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-28831 |
# +--------------+------------------+----------+-------------------+---------------+---------------------------------------+
```

- `.trivyignore`

```bash
# Accept the risk
cat > .trivyignore <<EOF
CVE-2021-28831
EOF
```

```bash
trivy image registry:2.7.1
# registry:2.7.1 (alpine 3.11.8)
# ==============================
# Total: 4 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 2, CRITICAL: 0)

# +--------------+------------------+----------+-------------------+---------------+--------------------------------------+
# |   LIBRARY    | VULNERABILITY ID | SEVERITY | INSTALLED VERSION | FIXED VERSION |                TITLE                 |
# +--------------+------------------+----------+-------------------+---------------+--------------------------------------+
# | libcrypto1.1 | CVE-2021-3450    | HIGH     | 1.1.1j-r0         | 1.1.1k-r0     | openssl: CA certificate check        |
# |              |                  |          |                   |               | bypass with X509_V_FLAG_X509_STRICT  |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3450 |
# +              +------------------+----------+                   +               +--------------------------------------+
# |              | CVE-2021-3449    | MEDIUM   |                   |               | openssl: NULL pointer dereference    |
# |              |                  |          |                   |               | in signature_algorithms processing   |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3449 |
# +--------------+------------------+----------+                   +               +--------------------------------------+
# | libssl1.1    | CVE-2021-3450    | HIGH     |                   |               | openssl: CA certificate check        |
# |              |                  |          |                   |               | bypass with X509_V_FLAG_X509_STRICT  |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3450 |
# +              +------------------+----------+                   +               +--------------------------------------+
# |              | CVE-2021-3449    | MEDIUM   |                   |               | openssl: NULL pointer dereference    |
# |              |                  |          |                   |               | in signature_algorithms processing   |
# |              |                  |          |                   |               | -->avd.aquasec.com/nvd/cve-2021-3449 |
# +--------------+------------------+----------+-------------------+---------------+--------------------------------------+
```
