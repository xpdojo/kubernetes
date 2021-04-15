# 컨테이너 네트워크 인터페이스 규격

> [Container Network Interface Specification](https://github.com/containernetworking/cni/blob/spec-v0.4.0/SPEC.md)

- [컨테이너 네트워크 인터페이스 규격](#컨테이너-네트워크-인터페이스-규격)
  - [버전](#버전)
    - [릴리스 버전](#릴리스-버전)
  - [CNI 개요](#cni-개요)
  - [일반적인 고려 사항](#일반적인-고려-사항)
  - [CNI 플러그인](#cni-플러그인)
    - [CNI 플러그인 개요](#cni-플러그인-개요)
    - [Parameters (매개 변수)](#parameters-매개-변수)
    - [Result](#result)
    - [네트워크 구성](#네트워크-구성)
      - [네트워크 구성 예](#네트워크-구성-예)
    - [네트워크 구성 목록](#네트워크-구성-목록)
      - [네트워크 구성 목록 에러 핸들링](#네트워크-구성-목록-에러-핸들링)
      - [네트워크 구성 목록 예](#네트워크-구성-목록-예)
      - [네트워크 구성 목록 런타임 예](#네트워크-구성-목록-런타임-예)
    - [IP 할당](#ip-할당)
      - [IP 주소 관리 (IPAM) 인터페이스](#ip-주소-관리-ipam-인터페이스)
      - [주의](#주의)
    - [잘-알려진 구조](#잘-알려진-구조)
      - [IPs](#ips)
      - [Routes](#routes)
      - [DNS](#dns)
  - [잘-알려진 에러 코드](#잘-알려진-에러-코드)

## 버전

해당 CNI **규격**의 버전은 **0.4.0**입니다.

[이 리포지토리](https://github.com/containernetworking/cni)의 **CNI 라이브러리 및 플러그인 버전과 독립적입니다**.
(예: [릴리스](https://github.com/containernetworking/cni/releases) 버전)

### 릴리스 버전

규격의 릴리스 버전은 Git 태그로 사용할 수 있습니다.

| tag                                                                                  | spec permalink                                                                        | major changes                                             |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| [`spec-v0.4.0`](https://github.com/containernetworking/cni/releases/tag/spec-v0.4.0) | [spec at v0.4.0](https://github.com/containernetworking/cni/blob/spec-v0.4.0/SPEC.md) | Introduce the CHECK command and passing prevResult on DEL |
| [`spec-v0.3.1`](https://github.com/containernetworking/cni/releases/tag/spec-v0.3.1) | [spec at v0.3.1](https://github.com/containernetworking/cni/blob/spec-v0.3.1/SPEC.md) | none (typo fix only)                                      |
| [`spec-v0.3.0`](https://github.com/containernetworking/cni/releases/tag/spec-v0.3.0) | [spec at v0.3.0](https://github.com/containernetworking/cni/blob/spec-v0.3.0/SPEC.md) | rich result type, plugin chaining                         |
| [`spec-v0.2.0`](https://github.com/containernetworking/cni/releases/tag/spec-v0.2.0) | [spec at v0.2.0](https://github.com/containernetworking/cni/blob/spec-v0.2.0/SPEC.md) | VERSION command                                           |
| [`spec-v0.1.0`](https://github.com/containernetworking/cni/releases/tag/spec-v0.1.0) | [spec at v0.1.0](https://github.com/containernetworking/cni/blob/spec-v0.1.0/SPEC.md) | initial version                                           |

_이 태그들이 안정적일 거라고 기대하지 마세요. 향후 특정 커밋이 규격 버전에 기록될 만한지에 대한 결정을 바꿀 수 있습니다._

## CNI 개요

이 문서에서는 리눅스, 컨테이너 네트워크 인터페이스 (_CNI_, _Container Networking Interface_)의 애플리케이션 컨테이너에 대한 일반적인 플러그인 기반 네트워킹 솔루션을 제안합니다.
이것은 [rkt][rkt-github] 네트워킹에 대한 많은 설계 고려 사항을 충족시키는 것을 목표로 한 rkt 네트워킹 제안서에서 파생되었습니다.

본 제안서의 목적상 다음과 같은 두 가지 용어를 매우 구체적으로 정의합니다.

- _컨테이너_ 는 [리눅스 _네트워크 네임스페이스_][namespaces]와 유의어로 간주될 수 있습니다.
  이에 해당하는 장치는 특정 컨테이너 런타임 구현에 따라 달라집니다.
  예를 들어, rkt와 같은 [App Container Spec][appc-github] 구현에서는 각 _파드_ 가 고유한 네트워크 네임스페이스에서 실행됩니다.
  반면 [도커][docker]에는 일반적으로 각각의 개별 도커 컨테이너에 대한 네트워크 네임스페이스가 있습니다.
- _네트워크_ 는 서로 통신할 수 있는 고유하게 주소 지정이 가능한 엔티티 그룹을 말합니다.
  이것은 개별 컨테이너(위에서 지정한 대로), 머신 또는 일부 다른 네트워크 장치(예: 라우터)일 수 있습니다.
  컨테이너는 개념적으로 하나 이상의 네트워크에 _추가_ 하거나 _제거_ 할 수 있습니다.

이 문서는 "런타임"과 "플러그인" 사이의 인터페이스를 지정하는 것을 목표로 합니다.
잘-알려진 특정 필드가 있지만 런타임에서는 플러그인에 추가 정보를 전달하고 싶을 수 있습니다.
이러한 확장은 이 규격에 속하지 않지만 [규약(convention)](https://github.com/containernetworking/cni/blob/spec-v0.4.0/CONVENTIONS.md)으로 문서화됩니다.
"must", "must not", "required", "shall", "shall not", "should", "should not", "recommended", "may", "optional"
이라는 키워드는 [RFC 2119][rfc-2119]([번역][rfs-2119-ko])에 명시된 대로 사용됩니다.

[rkt-github]: https://github.com/coreos/rkt
[namespaces]: http://man7.org/linux/man-pages/man7/namespaces.7.html
[appc-github]: https://github.com/appc/spec
[docker]: https://docker.com
[rfc-2119]: https://www.ietf.org/rfc/rfc2119.txt
[rfs-2119-ko]: https://techhtml.github.io/rfc/RFC2119.html

## 일반적인 고려 사항

- 컨테이너 런타임은 플러그인을 호출하기 전에 컨테이너를 위한 새로운 네트워크 네임스페이스를 생성해야 합니다.
- 그런 다음 런타임은 해당 컨테이너가 속해야 하는 네트워크와 각 네트워크에서 실행되어야 하는 플러그인을 결정해야 합니다.
- 네트워크 구성은 JSON 형식이며 파일로 쉽게 저장할 수 있습니다.
  네트워크 구성에는 플러그인 (유형) 전용 필드뿐만 아니라 `name` 및 `type`과 같은 필수 필드가 포함됩니다.
  네트워크 구성을 통해 필드는 호출 간에 값을 변경할 수 있습니다.
  이를 위해 다양한 정보를 포함해야 하는 선택적 필드 `args`가 있습니다.
- 컨테이너 런타임은 각 네트워크의 플러그인을 순차적으로 실행하여 해당 네트워크에 컨테이너를 추가해야 합니다.
- 컨테이너 라이프사이클이 완료되면 런타임은 플러그인을 (컨테이너를 추가하기 위해 실행된 순서의) 역순으로 실행하여 네트워크에서 컨테이너의 연결을 끊어야 합니다.
- 컨테이너 런타임은 동일한 컨테이너에 대해 병렬 작업을 호출해서는 안 되지만 서로 다른 컨테이너에 대해서는 병렬 작업을 호출할 수 있습니다.
- `ADD`가 항상 `DEL`과 상응하도록 컨테이너 런타임은 하나의 컨테이너에 대한 `ADD` 및 `DEL` 작업을 명령해야 합니다. `DEL`에는 추가 `DEL` 작업이 따를 수 있지만 플러그인은 여러 `DEL`을 허용적으로(permissively) 처리해야 합니다(즉, 플러그인 `DEL`은 멱등이어야 함).
- 컨테이너는 `ContainerID`로 고유하게 식별되어야 합니다. 상태를 저장하는 플러그인은 기본 키 `(network name, CNI_CONTAINERID, CNI_IFNAME)`를 사용하여 이 작업을 수행해야 합니다.
- 런타임은 동일한 `(network name, container id, name of the interface inside the container)`에 대해 `ADD`를 두 번 호출해서는 안 됩니다.
  이는 `ADD` 작업마다 다른 인터페이스 이름으로 수행된 경우에만 지정된 컨테이너 ID를 특정 네트워크에 두 번 이상 추가할 수 있음을 의미합니다.
- 특별히 선택 사항으로 표시되지 않는 한 CNI 구조체의 필드([네트워크 구성](#network-configuration) 및 [CNI 플러그인 결과](#result))는 필수입니다.

## CNI 플러그인

### CNI 플러그인 개요

각 CNI 플러그인은 컨테이너 관리 시스템(예: rkt 또는 Kubernetes)에 의해 호출되는 실행 파일로 구현되어야 합니다.

CNI 플러그인은 컨테이너 네트워크 네임스페이스에 네트워크 인터페이스를 삽입하고(예: veth 쌍의 한쪽 끝) 호스트에서 필요한 모든 변경(예: veth의 다른 쪽 끝을 브리지에 연결)을 수행합니다.
그런 다음 해당 네트워크 인터페이스에 IP를 할당하고 적절한 IPAM 플러그인을 호출하여 IPAM(IP 주소 관리) 섹션과 일치하는 라우트를 설정해야 합니다.

### Parameters (매개 변수)

CNI 플러그인이 지원해야 하는 작업은 다음과 같습니다.

- `ADD`: 네트워크에 컨테이너를 추가합니다.

  - Parameters:
    - **컨테이너 ID**. 런타임에 의해 할당된 컨테이너에 대한 고유한 플레인 텍스트 식별자입니다. 비워둘 수 없습니다.
    - **네트워크 네임스페이스 경로**. 추가할 네트워크 네임스페이스의 경로를 나타냅니다. (예: `/proc/[pid]/ns/net` 또는 `bind-mount/link`)
    - **네트워크 구성**. 컨테이너가 결합할 수 있는 네트워크를 설명하는 JSON 문서입니다. 스키마는 아래에 설명되어 있습니다.
    - **추가 전달 인자**. 이렇게 하면 컨테이너별로 CNI 플러그인을 간단하게 구성할 수 있는 대체 메커니즘이 제공됩니다.
    - **컨테이너 내 인터페이스명**. 컨테이너 내부에 생성된 인터페이스(네트워크 네임스페이스)에 할당하길 원하는 이름입니다. 따라서 인터페이스 이름에 대한 표준 리눅스 제약을 준수해야 합니다.
  - Result:
    - **인터페이스 목록**. 플러그인에 따라 샌드박스(예: 컨테이너 또는 하이퍼바이저) 인터페이스 이름 및/또는 호스트 인터페이스 이름, 각 인터페이스의 하드웨어 주소 및 인터페이스가 있는 경우 샌드박스에 대한 세부 정보가 포함될 수 있습니다.
    - **각 인터페이스에 할당된 IP 구성**. The IPv4 and/or IPv6 addresses, gateways, and routes assigned to sandbox and/or host interfaces.
    - **각 인터페이스에 할당된 IP 구성**. IPv4 및/또는 IPv6 주소, 게이트웨이 및 라우트가 샌드박스 및/또는 호스트 인터페이스에 할당됩니다.
    - **DNS 정보**. 이름 서버, 도메인, 검색 도메인 및 옵션에 대한 DNS 정보를 포함하는 딕셔너리입니다.

- `DEL`: 네트워크에서 컨테이너를 제거합니다.
  - Parameters:
    - **컨테이너 ID**, `Add`와 동일.
    - **네트워크 네임스페이스 경로**, `Add`와 동일.
    - **네트워크 구성**, `Add`와 동일.
    - **추가 전달 인자**, `Add`와 동일.
    - **컨테이너 내 인터페이스명**, `Add`와 동일.
  - All parameters should be the same as those passed to the corresponding add operation.
  - A delete operation should release all resources held by the supplied containerid in the configured network.
  - If there was a known previous `ADD` action for the container, the runtime MUST add a `prevResult` field to the configuration JSON of the plugin (or all plugins in a chain), which MUST be the `Result` of the immediately previous `ADD` action in JSON format ([see below](#network-configuration-list-runtime-examples)). The runtime may wish to use libcni's support for caching `Result`s.
  - When `CNI_NETNS` and/or `prevResult` are not provided, the plugin should clean up as many resources as possible (e.g. releasing IPAM allocations) and return a successful response.
  - If the runtime cached the `Result` of a previous `ADD` response for a given container, it must delete that cached response on a successful `DEL` for that container.

Plugins should generally complete a `DEL` action without error even if some resources are missing. For example, an IPAM plugin should generally release an IP allocation and return success even if the container network namespace no longer exists, unless that network namespace is critical for IPAM management. While DHCP may usually send a 'release' message on the container network interface, since DHCP leases have a lifetime this release action would not be considered critical and no error should be returned. For another example, the `bridge` plugin should delegate the DEL action to the IPAM plugin and clean up its own resources (if present) even if the container network namespace and/or container network interface no longer exist.

- `CHECK`: 컨테이너의 네트워킹이 예상대로 동작하는지 확인합니다.

  - Parameters:
    - **Container ID**, `ADD`와 동일.
    - **네트워크 네임스페이스 경로**, `ADD`와 동일.
    - **네트워크 구성** `ADD`와 동일, 여기에는 선행된 `ADD`의 `Result`를 포함하는 `prevResult` 필드가 있어야 합니다.
    - **추가 전달 인자**, `ADD`와 동일.
    - **컨테이너 내 인터페이스명**, `ADD`와 동일.
  - Result:
    - 플러그인은 아무것도 반환하지 않거나 에러를 반환해야 합니다.
  - The plugin must consult the `prevResult` to determine the expected interfaces and addresses.
  - The plugin must allow for a later chained plugin to have modified networking resources, e.g. routes.
  - The plugin should return an error if a resource included in the CNI Result type (interface, address or route):
    - was created by the plugin, and
    - is listed in `prevResult`, and
    - does not exist, or is in an invalid state.
  - The plugin should return an error if other resources not tracked in the Result type such as the following are missing or are in an invalid state:
    - Firewall rules
    - Traffic shaping controls
    - IP reservations
    - External dependencies such as a daemon required for connectivity
    - etc.
  - The plugin should return an error if it is aware of a condition where the container is generally unreachable.
  - The plugin must handle `CHECK` being called immediately after an `ADD`, and therefore should allow a reasonable convergence delay for any asynchronous resources.
  - The plugin should call `CHECK` on any delegated (e.g. IPAM) plugins and pass any errors on to its caller.
  - A runtime must not call `CHECK` for a container that has not been `ADD`ed, or has been `DEL`eted after its last `ADD`.
  - A runtime must not call `CHECK` if `disableCheck` is set to `true` in the [configuration list](#network-configuration-lists).
  - A runtime must include a `prevResult` field in the network configuration containing the `Result` of the immediately preceding `ADD` for the container. The runtime may wish to use libcni's support for caching `Result`s.
  - A runtime may choose to stop executing `CHECK` for a chain when a plugin returns an error.
  - A runtime may execute `CHECK` from immediately after a successful `ADD`, up until the container is `DEL`eted from the network.
  - A runtime may assume that a failed `CHECK` means the container is permanently in a misconfigured state.

- `VERSION`: 지원 버전

  - Parameters: 없음.
  - Result: 플러그인이 지원하는 CNI 규격 버전에 대한 정보

    ```json
    {
      "cniVersion": "0.4.0", // the version of the CNI spec in use for this output
      "supportedVersions": ["0.1.0", "0.2.0", "0.3.0", "0.3.1", "0.4.0"] // the list of CNI spec versions that this plugin supports
    }
    ```

런타임에서는 호출할 실행 파일의 이름으로 네트워크 유형(아래 [네트워크 구성](#network-configuration) 참조)을 사용해야 합니다.
그런 다음 런타임은 미리 정의된 디렉토리 목록에서 이 실행 파일을 찾아야 합니다(디렉토리 목록은 이 규격에서 규정되지 않음).
찾은 후에는 아래와 같은 환경 변수와 함께 실행 파일을 호출해서 인수를 전달해야 합니다.

- `CNI_COMMAND`: 원하는 작업을 나타냅니다. (`ADD`, `DEL`, `CHECK`, `VERSION`)
- `CNI_CONTAINERID`: 컨테이너 ID
- `CNI_NETNS`: 네트워크 네임스페이스 파일의 경로
- `CNI_IFNAME`: 설정할 인터페이스 이름. 플러그인이 이 인터페이스 이름을 사용할 수 없는 경우 오류를 반환해야 합니다.
- `CNI_ARGS`: 사용자가 호출할 때 전달되는 추가 인자입니다. 영숫자 키-값 쌍은 세미콜론으로 구분됩니다. (예: "FOO=BAR;ABC=123")
- `CNI_PATH`: CNI 플러그인 실행 파일을 탐색할 경로 목록입니다. 경로는 OS별 목록 분리 기호로 구분됩니다. (예: Linux는 ':', Windows는 ';')

JSON 형식의 네트워크 구성은 stdin을 통해 플러그인으로 스트리밍해야 합니다. 즉, 디스크의 특정 파일에 종속되지 않으며 호출 간에 변경되는 정보가 포함될 수 있습니다.

### Result

IPAM 플러그인은 [IP 할당](#ip-할당)에 설명된 대로 요약된 `Result` 구조체를 반환해야 합니다.

Plugins must indicate success with a return code of zero and the following JSON printed to stdout in the case of the ADD command.
The `ips` and `dns` items should be the same output as was returned by the IPAM plugin (see [IP Allocation](#ip-allocation) for details)
except that the plugin should fill in the `interface` indexes appropriately,
which are missing from IPAM plugin output since IPAM plugins should be unaware of interfaces.

```json
{
  "cniVersion": "0.4.0",
  "interfaces": [                                            (this key omitted by IPAM plugins)
    {
      "name": "<name>",
      "mac": "<MAC address>",                            (required if L2 addresses are meaningful)
      "sandbox": "<netns path or hypervisor identifier>" (required for container/hypervisor interfaces, empty/omitted for host interfaces)
    }
  ],
  "ips": [
    {
      "version": "<4-or-6>",
      "address": "<ip-and-prefix-in-CIDR>",
      "gateway": "<ip-address-of-the-gateway>",          (optional)
      "interface": <numeric index into 'interfaces' list>
    },
    ...
  ],
  "routes": [                                                (optional)
    {
      "dst": "<ip-and-prefix-in-cidr>",
      "gw": "<ip-of-next-hop>"                           (optional)
    },
    ...
  ],
  "dns": {                                                   (optional)
    "nameservers": <list-of-nameservers>,                    (optional)
    "domain": <name-of-local-domain>,                        (optional)
    "search": <list-of-additional-search-domains>,           (optional)
    "options": <list-of-options>                             (optional)
  }
}
```

`cniVersion` specifies a [Semantic Version 2.0](https://semver.org) of CNI specification used by the plugin. A plugin may support multiple CNI spec versions (as it reports via the `VERSION` command), here the `cniVersion` returned by the plugin in the result must be consistent with the `cniVersion` specified in [Network Configuration](#network-configuration). If the `cniVersion` in the network configuration is not supported by the plugin, the plugin should return an error code 1 (see [Well-known Error Codes](#well-known-error-codes) for details).

`interfaces` describes specific network interfaces the plugin created.
If the `CNI_IFNAME` variable exists the plugin must use that name for the sandbox/hypervisor interface or return an error if it cannot.

- `mac` (string): the hardware address of the interface.
  If L2 addresses are not meaningful for the plugin then this field is optional.
- `sandbox` (string): container/namespace-based environments should return the full filesystem path to the network namespace of that sandbox.
  Hypervisor/VM-based plugins should return an ID unique to the virtualized sandbox the interface was created in.
  This item must be provided for interfaces created or moved into a sandbox like a network namespace or a hypervisor/VM.

The `ips` field is a list of IP configuration information.
See the [IP well-known structure](#ips) section for more information.

The `routes` field is a list of route configuration information.
See the [Routes well-known structure](#routes) section for more information.

The `dns` field contains a dictionary consisting of common DNS information.
See the [DNS well-known structure](#dns) section for more information.

The specification does not declare how this information must be processed by CNI consumers.
Examples include generating an `/etc/resolv.conf` file to be injected into the container filesystem or running a DNS forwarder on the host.

Errors must be indicated by a non-zero return code and the following JSON being printed to stdout:

```json
{
  "cniVersion": "0.4.0",
  "code": <numeric-error-code>,
  "msg": <short-error-message>,
  "details": <long-error-message> (optional)
}
```

`cniVersion` specifies a [Semantic Version 2.0](https://semver.org) of CNI specification used by the plugin.
Error codes 0-99 are reserved for well-known errors (see [Well-known Error Codes](#well-known-error-codes) section).
Values of 100+ can be freely used for plugin specific errors.

In addition, stderr can be used for unstructured output such as logs.

### 네트워크 구성

The network configuration is described in JSON form. The configuration may be stored on disk or generated from other sources by the container runtime. The following fields are well-known and have the following meaning:

- `cniVersion` (string): [Semantic Version 2.0](https://semver.org) of CNI specification to which this configuration conforms.
- `name` (string): Network name. This should be unique across all containers on the host (or other administrative domain).
- `type` (string): Refers to the filename of the CNI plugin executable.
- `args` (dictionary, optional): Additional arguments provided by the container runtime. For example a dictionary of labels could be passed to CNI plugins by adding them to a labels field under `args`.
- `ipMasq` (boolean, optional): If supported by the plugin, sets up an IP masquerade on the host for this network. This is necessary if the host will act as a gateway to subnets that are not able to route to the IP assigned to the container.
- `ipam` (dictionary, optional): Dictionary with IPAM specific values:
  - `type` (string): Refers to the filename of the IPAM plugin executable.
- `dns` (dictionary, optional): Dictionary with DNS specific values:
  - `nameservers` (list of strings, optional): list of a priority-ordered list of DNS nameservers that this network is aware of. Each entry in the list is a string containing either an IPv4 or an IPv6 address.
  - `domain` (string, optional): the local domain used for short hostname lookups.
  - `search` (list of strings, optional): list of priority ordered search domains for short hostname lookups. Will be preferred over `domain` by most resolvers.
  - `options` (list of strings, optional): list of options that can be passed to the resolver

Plugins may define additional fields that they accept and may generate an error if called with unknown fields. The exception to this is the `args` field may be used to pass arbitrary data which should be ignored by plugins if not understood.

#### 네트워크 구성 예

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "bridge",
  // type (plugin) specific
  "bridge": "cni0",
  "ipam": {
    "type": "host-local",
    // ipam specific
    "subnet": "10.1.0.0/16",
    "gateway": "10.1.0.1"
  },
  "dns": {
    "nameservers": ["10.1.0.1"]
  }
}
```

```json
{
  "cniVersion": "0.4.0",
  "name": "pci",
  "type": "ovs",
  // type (plugin) specific
  "bridge": "ovs0",
  "vxlanID": 42,
  "ipam": {
    "type": "dhcp",
    "routes": [{ "dst": "10.3.0.0/16" }, { "dst": "10.4.0.0/16" }]
  },
  // args may be ignored by plugins
  "args": {
    "labels": {
      "appVersion": "1.0"
    }
  }
}
```

```json
{
  "cniVersion": "0.4.0",
  "name": "wan",
  "type": "macvlan",
  // ipam specific
  "ipam": {
    "type": "dhcp",
    "routes": [{ "dst": "10.0.0.0/8", "gw": "10.0.0.1" }]
  },
  "dns": {
    "nameservers": ["10.0.0.1"]
  }
}
```

### 네트워크 구성 목록

Network configuration lists provide a mechanism to run multiple CNI plugins for a single container in a defined order, passing the result of each plugin to the next plugin.
The list is composed of well-known fields and list of one or more standard CNI network configurations (see above).

The list is described in JSON form, and can be stored on disk or generated from other sources by the container runtime. The following fields are well-known and have the following meaning:

- `cniVersion` (string): [Semantic Version 2.0](https://semver.org) of CNI specification to which this configuration list and all the individual configurations conform.
- `name` (string): Network name. This should be unique across all containers on the host (or other administrative domain).
- `disableCheck` (string): Either `true` or `false`. If `disableCheck` is `true`, runtimes must not call `CHECK` for this network configuration list. This allows an administrator to prevent `CHECK`ing where a combination of plugins is known to return spurious errors.
- `plugins` (list): A list of standard CNI network configuration dictionaries (see above).

When executing a plugin list, the runtime MUST replace the `name` and `cniVersion` fields in each individual network configuration in the list with the `name` and `cniVersion` field of the list itself. This ensures that the name and CNI version is the same for all plugin executions in the list, preventing versioning conflicts between plugins.
The runtime may also pass capability-based keys as a map in the top-level `runtimeConfig` key of the plugin's config JSON if a plugin advertises it supports a specific capability via the `capabilities` key of its network configuration. The key passed in `runtimeConfig` MUST match the name of the specific capability from the `capabilities` key of the plugins network configuration. See CONVENTIONS.md for more information on capabilities and how they are sent to plugins via the `runtimeConfig` key.

For the `ADD` action, the runtime MUST also add a `prevResult` field to the configuration JSON of any plugin after the first one, which MUST be the `Result` of the previous plugin (if any) in JSON format ([see below](#network-configuration-list-runtime-examples)).
For the `CHECK` and `DEL` actions, the runtime MUST (except that it may be omitted for `DEL` if not available) add a `prevResult` field to the configuration JSON of each plugin, which MUST be the `Result` of the immediately previous `ADD` action in JSON format ([see below](#network-configuration-list-runtime-examples)).
For the `ADD` action, plugins SHOULD echo the contents of the `prevResult` field to their stdout to allow subsequent plugins (and the runtime) to receive the result, unless they wish to modify or suppress a previous result.
Plugins are allowed to modify or suppress all or part of a `prevResult`.
However, plugins that support a version of the CNI specification that includes the `prevResult` field MUST handle `prevResult` by either passing it through, modifying it, or suppressing it explicitly.
It is a violation of this specification to be unaware of the `prevResult` field.

The runtime MUST also execute each plugin in the list with the same environment.

For the `DEL` action, the runtime MUST execute the plugins in reverse-order.

#### 네트워크 구성 목록 에러 핸들링

When an error occurs while executing an action on a plugin list (eg, either `ADD` or `DEL`) the runtime MUST stop execution of the list.

If an `ADD` action fails, when the runtime decides to handle the failure it should execute the `DEL` action (in reverse order from the `ADD` as specified above) for all plugins in the list, even if some were not called during the `ADD` action.

#### 네트워크 구성 목록 예

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "plugins": [
    {
      "type": "bridge",
      // type (plugin) specific
      "bridge": "cni0",
      // args may be ignored by plugins
      "args": {
        "labels": {
          "appVersion": "1.0"
        }
      },
      "ipam": {
        "type": "host-local",
        // ipam specific
        "subnet": "10.1.0.0/16",
        "gateway": "10.1.0.1"
      },
      "dns": {
        "nameservers": ["10.1.0.1"]
      }
    },
    {
      "type": "tuning",
      "sysctl": {
        "net.core.somaxconn": "500"
      }
    }
  ]
}
```

#### 네트워크 구성 목록 런타임 예

Given the network configuration list JSON [shown above](#example-network-configuration-lists) the container runtime would perform the following steps for the `ADD` action.
Note that the runtime adds the `cniVersion` and `name` fields from configuration list to the configuration JSON passed to each plugin, to ensure consistent versioning and names for all plugins in the list.

1. first call the `bridge` plugin with the following JSON:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "bridge",
  "bridge": "cni0",
  "args": {
    "labels": {
      "appVersion": "1.0"
    }
  },
  "ipam": {
    "type": "host-local",
    // ipam specific
    "subnet": "10.1.0.0/16",
    "gateway": "10.1.0.1"
  },
  "dns": {
    "nameservers": ["10.1.0.1"]
  }
}
```

2. next call the `tuning` plugin with the following JSON, including the `prevResult` field containing the JSON response from the `bridge` plugin:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "tuning",
  "sysctl": {
    "net.core.somaxconn": "500"
  },
  "prevResult": {
    "ips": [
      {
        "version": "4",
        "address": "10.0.0.5/32",
        "interface": 2
      }
    ],
    "interfaces": [
      {
        "name": "cni0",
        "mac": "00:11:22:33:44:55"
      },
      {
        "name": "veth3243",
        "mac": "55:44:33:22:11:11"
      },
      {
        "name": "eth0",
        "mac": "99:88:77:66:55:44",
        "sandbox": "/var/run/netns/blue"
      }
    ],
    "dns": {
      "nameservers": ["10.1.0.1"]
    }
  }
}
```

Given the same network configuration JSON list, the container runtime would perform the following steps for the `CHECK` action.

1. first call the `bridge` plugin with the following JSON, including the `prevResult` field containing the JSON response from the `ADD` operation:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "bridge",
  "bridge": "cni0",
  "args": {
    "labels" : {
        "appVersion" : "1.0"
    }
  },
  "ipam": {
    "type": "host-local",
    // ipam specific
    "subnet": "10.1.0.0/16",
    "gateway": "10.1.0.1"
  },
  "dns": {
    "nameservers": [ "10.1.0.1" ]
  }
  "prevResult": {
    "ips": [
        {
          "version": "4",
          "address": "10.0.0.5/32",
          "interface": 2
        }
    ],
    "interfaces": [
        {
            "name": "cni0",
            "mac": "00:11:22:33:44:55",
        },
        {
            "name": "veth3243",
            "mac": "55:44:33:22:11:11",
        },
        {
            "name": "eth0",
            "mac": "99:88:77:66:55:44",
            "sandbox": "/var/run/netns/blue",
        }
    ],
    "dns": {
      "nameservers": [ "10.1.0.1" ]
    }
  }
}
```

2. next call the `tuning` plugin with the following JSON, including the `prevResult` field containing the JSON response from the `ADD` operation:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "tuning",
  "sysctl": {
    "net.core.somaxconn": "500"
  },
  "prevResult": {
    "ips": [
      {
        "version": "4",
        "address": "10.0.0.5/32",
        "interface": 2
      }
    ],
    "interfaces": [
      {
        "name": "cni0",
        "mac": "00:11:22:33:44:55"
      },
      {
        "name": "veth3243",
        "mac": "55:44:33:22:11:11"
      },
      {
        "name": "eth0",
        "mac": "99:88:77:66:55:44",
        "sandbox": "/var/run/netns/blue"
      }
    ],
    "dns": {
      "nameservers": ["10.1.0.1"]
    }
  }
}
```

Given the same network configuration JSON list, the container runtime would perform the following steps for the `DEL` action.
Note that plugins are executed in reverse order from the `ADD` and `CHECK` actions.

1. first call the `tuning` plugin with the following JSON, including the `prevResult` field containing the JSON response from the `ADD` action:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "tuning",
  "sysctl": {
    "net.core.somaxconn": "500"
  },
  "prevResult": {
    "ips": [
      {
        "version": "4",
        "address": "10.0.0.5/32",
        "interface": 2
      }
    ],
    "interfaces": [
      {
        "name": "cni0",
        "mac": "00:11:22:33:44:55"
      },
      {
        "name": "veth3243",
        "mac": "55:44:33:22:11:11"
      },
      {
        "name": "eth0",
        "mac": "99:88:77:66:55:44",
        "sandbox": "/var/run/netns/blue"
      }
    ],
    "dns": {
      "nameservers": ["10.1.0.1"]
    }
  }
}
```

2. next call the `bridge` plugin with the following JSON, including the `prevResult` field containing the JSON response from the `ADD` action:

```json
{
  "cniVersion": "0.4.0",
  "name": "dbnet",
  "type": "bridge",
  "bridge": "cni0",
  "args": {
    "labels": {
      "appVersion": "1.0"
    }
  },
  "ipam": {
    "type": "host-local",
    // ipam specific
    "subnet": "10.1.0.0/16",
    "gateway": "10.1.0.1"
  },
  "dns": {
    "nameservers": ["10.1.0.1"]
  },
  "prevResult": {
    "ips": [
      {
        "version": "4",
        "address": "10.0.0.5/32",
        "interface": 2
      }
    ],
    "interfaces": [
      {
        "name": "cni0",
        "mac": "00:11:22:33:44:55"
      },
      {
        "name": "veth3243",
        "mac": "55:44:33:22:11:11"
      },
      {
        "name": "eth0",
        "mac": "99:88:77:66:55:44",
        "sandbox": "/var/run/netns/blue"
      }
    ],
    "dns": {
      "nameservers": ["10.1.0.1"]
    }
  }
}
```

### IP 할당

As part of its operation, a CNI plugin is expected to assign (and maintain) an IP address to the interface and install any necessary routes relevant for that interface. This gives the CNI plugin great flexibility but also places a large burden on it. Many CNI plugins would need to have the same code to support several IP management schemes that users may desire (e.g. dhcp, host-local).

To lessen the burden and make IP management strategy be orthogonal to the type of CNI plugin, we define a second type of plugin -- IP Address Management Plugin (IPAM plugin). It is however the responsibility of the CNI plugin to invoke the IPAM plugin at the proper moment in its execution. The IPAM plugin must determine the interface IP/subnet, Gateway and Routes and return this information to the "main" plugin to apply. The IPAM plugin may obtain the information via a protocol (e.g. dhcp), data stored on a local filesystem, the "ipam" section of the Network Configuration file or a combination of the above.

#### IP 주소 관리 (IPAM) 인터페이스

Like CNI plugins, the IPAM plugins are invoked by running an executable. The executable is searched for in a predefined list of paths, indicated to the CNI plugin via `CNI_PATH`. The IPAM Plugin must receive all the same environment variables that were passed in to the CNI plugin. Just like the CNI plugin, IPAM plugins receive the network configuration via stdin.

Success must be indicated by a zero return code and the following JSON being printed to stdout (in the case of the ADD command):

```json
{
  "cniVersion": "0.4.0",
  "ips": [
      {
          "version": "<4-or-6>",
          "address": "<ip-and-prefix-in-CIDR>",
          "gateway": "<ip-address-of-the-gateway>"  (optional)
      },
      ...
  ],
  "routes": [                                       (optional)
      {
          "dst": "<ip-and-prefix-in-cidr>",
          "gw": "<ip-of-next-hop>"                  (optional)
      },
      ...
  ]
  "dns": {                                          (optional)
    "nameservers": <list-of-nameservers>            (optional)
    "domain": <name-of-local-domain>                (optional)
    "search": <list-of-search-domains>              (optional)
    "options": <list-of-options>                    (optional)
  }
}
```

Note that unlike regular CNI plugins, IPAM plugins should return an abbreviated `Result` structure that does not include the `interfaces` key, since IPAM plugins should be unaware of interfaces configured by their parent plugin except those specifically required for IPAM (eg, like the `dhcp` IPAM plugin).

`cniVersion` specifies a [Semantic Version 2.0](https://semver.org) of CNI specification used by the IPAM plugin. An IPAM plugin may support multiple CNI spec versions (as it reports via the `VERSION` command), here the `cniVersion` returned by the IPAM plugin in the result must be consistent with the `cniVersion` specified in [Network Configuration](#network-configuration). If the `cniVersion` in the network configuration is not supported by the IPAM plugin, the plugin should return an error code 1 (see [Well-known Error Codes](#well-known-error-codes) for details).

The `ips` field is a list of IP configuration information.
See the [IP well-known structure](#ips) section for more information.

The `routes` field is a list of route configuration information.
See the [Routes well-known structure](#routes) section for more information.

The `dns` field contains a dictionary consisting of common DNS information.
See the [DNS well-known structure](#dns) section for more information.

Errors and logs are communicated in the same way as the CNI plugin. See [CNI Plugin Result](#result) section for details.

IPAM plugin examples:

- **host-local**: 지정된 범위 내에서 (동일한 호스트의 다른 컨테이너에서) 사용되지 않은 IP를 선택합니다.
- **dhcp**: DHCP 프로토콜을 사용하여 임대를 받고 유지합니다. DHCP 요청은 생성된 컨테이너 인터페이스를 통해 전송되므로 연결된 네트워크가 브로드캐스트를 지원해야 합니다.

#### 주의

- 라우트가 0 메트릭으로 추가되어야 합니다.
- 기본 라우트는 "0.0.0.0/0"을 통해 지정할 수 있습니다. 다른 네트워크가 이미 기본 라우트를 구성했을 수 있으므로 CNI 플러그인은 기본 라우트 정의를 건너뛰도록 준비해야 합니다.

### 잘-알려진 구조

#### IPs

```json
  "ips": [
    {
      "version": "<4-or-6>",
      "address": "<ip-and-prefix-in-CIDR>",
      "gateway": "<ip-address-of-the-gateway>",           (optional)
      "interface": <numeric index into 'interfaces' list> (not required for IPAM plugins)
    },
    ...
  ]
```

The `ips` field is a list of IP configuration information determined by the plugin. Each item is a dictionary describing of IP configuration for a network interface.
IP configuration for multiple network interfaces and multiple IP configurations for a single interface may be returned as separate items in the `ips` list.
All properties known to the plugin should be provided, even if not strictly required.

- `version` (string): either "4" or "6" and corresponds to the IP version of the addresses in the entry.
  All IP addresses and gateways provided must be valid for the given `version`.
- `address` (string): an IP address in CIDR notation (eg "192.168.1.3/24").
- `gateway` (string): the default gateway for this subnet, if one exists.
  It does not instruct the CNI plugin to add any routes with this gateway: routes to add are specified separately via the `routes` field.
  An example use of this value is for the CNI `bridge` plugin to add this IP address to the Linux bridge to make it a gateway.
- `interface` (uint): the index into the `interfaces` list for a [CNI Plugin Result](#result) indicating which interface this IP configuration should be applied to.
  IPAM plugins should not return this key since they have no information about network interfaces.

#### Routes

```json
  "routes": [
    {
      "dst": "<ip-and-prefix-in-cidr>",
      "gw": "<ip-of-next-hop>"               (optional)
    },
    ...
  ]
```

Each `routes` entry is a dictionary with the following fields. All IP addresses in the `routes` entry must be the same IP version, either 4 or 6.

- `dst` (string): destination subnet specified in CIDR notation.
- `gw` (string): IP of the gateway. If omitted, a default gateway is assumed (as determined by the CNI plugin).

Each `routes` entry must be relevant for the sandbox interface specified by CNI_IFNAME.

#### DNS

```json
  "dns": {
    "nameservers": <list-of-nameservers>,                (optional)
    "domain": <name-of-local-domain>,                    (optional)
    "search": <list-of-additional-search-domains>,       (optional)
    "options": <list-of-options>                         (optional)
  }
```

The `dns` field contains a dictionary consisting of common DNS information.

- `nameservers` (list of strings): list of a priority-ordered list of DNS nameservers that this network is aware of. Each entry in the list is a string containing either an IPv4 or an IPv6 address.
- `domain` (string): the local domain used for short hostname lookups.
- `search` (list of strings): list of priority ordered search domains for short hostname lookups. Will be preferred over `domain` by most resolvers.
- `options` (list of strings): list of options that can be passed to the resolver.
  See [CNI Plugin Result](#result) section for more information.

## 잘-알려진 에러 코드

1부터 99까지의 에러 코드는 여기에 지정된 경우를 제외하고 사용할 수 없습니다.

- `1` - 호환되지 않는 CNI 버전
- `2` - 네트워크 구성에서 지원되지 않는 필드. 에러 메시지에는 지원되지 않는 필드의 키와 값이 포함되어야 합니다.
- `3` - 알 수 없거나 존재하지 않는 컨테이너. 이 에러는 런타임에서 컨테이너 네트워크를 정리할 필요가 없다는 것을 뜻합니다(예: 컨테이너에 `DEL` 작업 호출).
- `11` - 나중에 다시 시도. 플러그인이 정리해야 하는 일시적 상태를 감지한 경우 이 코드를 사용하여 작업을 다시 시도해야 하는 런타임에 알릴 수 있습니다.
