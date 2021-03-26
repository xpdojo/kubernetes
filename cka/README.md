# CKA 스터디 가이드

CKA를 취득한다고 해서 Kubernetes를 잘 안다고 할 순 없기 때문에
그저 취득을 목적으로 준비했습니다.

![cka-certificate](../images/cka-certificate.png)

_**2021-02-13 취득**_

## Linux Foundation

- [CKA 공식 안내](https://www.cncf.io/certification/cka/)
- [CKA 공식 지침](https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad)
- 열람 가능한 페이지 (추가탭 1개만 허용)
  - 저는 문서를 빨리 찾을 수 있도록 필요한 문서는 북마크를 해두었습니다.
    - `https://kubernetes.io/docs/`
    - `https://kubernetes.io/ko/docs/`
    - `https://github.com/kubernetes/`
    - `https://kubernetes.io/blog/`
  - 필요한 건 검색 기능을 사용했습니다. (위 도메인에 포함되진 않았지만 지적은 없었습니다: https://kubernetes.io/search/?q=etcd)
- [LF 공식 핸드북](https://docs.linuxfoundation.org/tc-docs/certification/lf-candidate-handbook)
- [CKA(D) 자주 묻는 질문](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)
- [2020년 9월 이후 변경된 부분](https://training.linuxfoundation.org/cka-program-changes-2020/)
  - 도메인별 비중 변경
  - CKA 시험은 66점 이상 합격 (변경 전 74점 이상)
  - 2시간 동안 15-20개 문제 => 후기들을 보면 모두 17문제 (변경 전 3시간 동안 24개 문제)
  - 2021년 2월 기준 k8s v1.20
- 제가 봤던 시험 환경 (감독관마다 다를 수 있습니다)
  - 책상이나 벽에 아무것도 없어야 한다고 하지만 제 방은 책상을 중심으로 사방이 책장입니다. 실제로는 책상 위에만 비어있으면 지적하지 않는 것 같습니다.
  - 중간에 화장실을 가겠다고 했는데 흔쾌히 허락을 받았습니다. 시험을 일시 중지(시간은 흘러감) 해놓고는 천천히 다녀왔습니다.

## 도움이 된 자료

- [Certified Kubernetes Administrator (CKA) with Practice Tests - Udemy](https://www.udemy.com/course/certified-kubernetes-administrator-with-practice-tests/)
  - [GitHub](https://github.com/kodekloudhub/certified-kubernetes-administrator-course)
- [실제 시험중 터미널](https://www.certshero.com/linux-foundation/cka/practice-test)
- [<쿠버네티스 인 액션>](http://www.acornpub.co.kr/book/k8s-in-action-new)
- [kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

### 참고

보기 편하신 걸로 취사선택하시면 됩니다.

- [CKA 팁](https://prashix.medium.com/certified-kubernetes-administrator-cka-notes-and-20-tips-may-2020-692b0df1b1c6)
- [rudimartinsen](https://rudimartinsen.com/cka-resources/)
  - [CKA Study Guide](https://rudimartinsen.com/2020/12/28/cka-study-guide/)
  - [트러블슈팅](https://rudimartinsen.com/2021/01/14/cka-notes-troubleshooting/)
- [scriptcrunch](https://scriptcrunch.com/kubernetes-exam-guide/)
- [CKA(D) 연습 문제](https://medium.com/@sensri108/practice-examples-dumps-tips-for-cka-ckad-certified-kubernetes-administrator-exam-by-cncf-4826233ccc27)
- [CKAD 연습 문제](https://github.com/dgkanatsios/CKAD-exercises)
- [chadmcrowell/CKA-Exercises](https://github.com/chadmcrowell/CKA-Exercises)
- [David-VTUK/CKA-StudyGuide](https://github.com/David-VTUK/CKA-StudyGuide)
- [mgonzalezo/CKA-Preparation](https://github.com/mgonzalezo/CKA-Preparation)
- [Bes0n/CKA](https://github.com/Bes0n/CKA)

## 정리

![cka-test-view](../images/cka-test-view.png)

_시험 환경을 최대한 복원해봤습니다..._

### 기억해두면 좋은 것들

- 시험에는 선언형(declarative)보다 명령형(imperative)에 익숙한 것이 효율적입니다.
- 시작하면 바로 `sudo -i` 명령을 통해 root로 접속합니다.
- [치트 시트](https://kubernetes.io/ko/docs/reference/kubectl/cheatsheet/) 문서를 북마크 해뒀다가 참고합니다.
- 문제마다 풀어야 할 컨텍스트를 명시하고 있습니다. 잊지 말고 컨텍스트를 바꾸세요.
- 평소에 `k`로 alias를 지정하는 것보다 `kubectl`을 사용하셨다면 익숙한 것을 그대로 사용하세요.
- tmux는 이미 설치되어 있습니다.
- `kubectl` 하위 커맨드 중 `create`, `run`, `apply`는 혼동하지 말아야 합니다.
- 관련 내용을 외우고 있지 않아도 문서를 빠르게 찾을 수 있다면 풀 수 있는 문제들입니다.
- 생각보다 [깃헙](https://github.com/kubernetes/website/tree/master/content/ko/examples)에 있는 매니페스트 파일들이 문서보다 도움될 때가 있습니다.
  여기 있는 example 들이 홈페이지 문서에 포함되는 example들이기 때문에 실제 정답이 되기도 합니다.

### Kind를 사용한 클러스터 생성

- [Kind](https://github.com/kubernetes-sigs/kind): 도커 컨테이너를 노드로 할당해서 k8s 클러스터를 생성할 수 있는 도구
- 개인용 PC에서 연습할 때 도움이 되었던 도구입니다.
- 간단하게 클러스터를 생성했다 제거할 수 있습니다.

```bash
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.10.0/kind-$(uname)-amd64"
chmod +x ./kind
mv ./kind /usr/local/bin/kind
```

```bash
kind create cluster
# kind create cluster --image kindest/node:latest
```

```bash
kind delete cluster
```

```bash
kubectl config view
kubectl config current-context
kubectl config set-cluster
kubectl config set-context
```
