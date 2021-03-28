# Go 언어로 컨테이너 이미지 빌드하기

> Ahmet Alp Balkan의 [Building container images in Go](https://ahmet.im/blog/building-container-images-in-go/)를 번역한 글입니다.
> 저자의 허락을 받고 번역했습니다.

이 글에서는 도커(Docker)를 사용하지 않고 어떻게 OCI 컨테이너 이미지를 만드는지 설명합니다.
이를 위해 [go-containerregistry](https://github.com/google/go-containerregistry) 모듈을 이용해
프로그래밍해서 레이어 및 이미지 매니페스트를 빌드합니다.
예를 들어 [nginx](https://hub.docker.com/_/nginx) 이미지 위에
정적 웹 사이트 콘텐츠를 추가하여 컨테이너 이미지를 빌드하고
Go 프로그램을 사용하는 [`gcr.io`](https://gcr.io) 같은 레지스트리에 푸시하겠습니다.

순서는 다음과 같습니다.

1. 도커 허브에서 `nginx` 이미지를 가져 옵니다(pull).
2. 기존 `/usr/share/nginx/html` 디렉터리를 삭제하는 새 레이어를 만듭니다.
3. 정적 HTML 콘텐츠과 애셋으로 새 레이어를 만듭니다.
4. 이미지와 태그에 새 레이어를 추가합니다.
5. 새 이미지를 레지스트리로 푸시합니다.

[이 gist](https://gist.github.com/ahmetb/430baa4e8bb0b0f78abb1c34934cd0b6)에서
예제 코드를 찾을 수 있습니다.
그럼 자세히 살펴보겠습니다.

[모듈](https://pkg.go.dev/github.com/google/go-containerregistry)을 다운로드합니다.

```bash
go get -u github.com/google/go-containerregistry
```

이미지 레퍼런스를 가져옵니다.
`crane.Pull` 메서드는 `nginx`라는 레퍼런스를 `index.docker.io/library/nginx:latest`로 바꾼 다음
도커 허브에서 익명 자격 증명(anonymous credentials)을 처리합니다.
그리고 [v1.Image](https://pkg.go.dev/github.com/google/go-containerregistry/pkg/v1#Image)를 반환합니다.
(실제로는 [remote.Image](https://pkg.go.dev/github.com/google/go-containerregistry/pkg/v1/remote#Image))

```go
img, err := crane.Pull("nginx")
if err != nil {
  panic(err)
}
```

이제 [화이트아웃](https://github.com/opencontainers/image-spec/blob/v1.0.1/layer.md#whiteouts) 파일[^1]을
사용하여 nginx 이미지에 딸려 있는 `/usr/share/nginx/html` 디렉터리를 제거하는 레이어를 생성하겠습니다.

[^1]: 화이트아웃 파일(whiteout file)은 경로를 삭제해야 함을 나타내는 특별한 파일명을 가진 빈(empty) 파일입니다.
화이트아웃 파일명은 `.wh.` 접두사와 삭제할 경로로 구성됩니다.

이를 위해 파일명 리스트와 인메모리 바이트 슬라이스로 타르볼(tarball)을 생성할 수 있는 헬퍼 메서드를 사용합니다.
해당 레이어에서 경로를 지우기 위해 tar 파일 내부에 `usr/share/nginx/.wh.html`이라는 파일이 필요합니다.

```go
deleteMap := map[string][]byte{
  "usr/share/nginx/.wh.html": []byte{},
}
deleteLayer, err := crane.Layer(deleteMap)
if err != nil {
  panic(err)
}
```

이제 이 컨테이너 이미지에 추가할 정적 HTML 파일과 에셋이 포함된 디렉토리 트리를 스캔해야 합니다.
다시 `crane.Layer` 메서드를 사용할 수 있지만, 그러려면 모든 파일을 메모리에 올려야 합니다.

여기서는 `tar` 명령어를 사용하여 타르볼을 생성하고 결과를 표준 출력(stdout)에 표시한 다음
[tarball.FromReader](https://pkg.go.dev/github.com/google/go-containerregistry/pkg/v1/tarball#LayerFromReader)로
전달할 수도 있습니다. 명령어는 다음과 같습니다.

```bash
tar -cf- DIR \
    --transform 's,^,usr/share/nginx/,'
    --owner=0 --group=0
```

또는 `tar.Writer`를 사용하여 네이티브한 방식으로 타르볼을 빌드하고
이 [gist](https://gist.github.com/ahmetb/430baa4e8bb0b0f78abb1c34934cd0b6)처럼
인메모리 버퍼에 결과를 기록할 수 있습니다.
여기서는 `filepath.Walk` 메서드를 사용하여 디렉터리 트리의 파일을 스캔하고
tar 아카이브에 디렉터리 및 파일 엔트리를 추가합니다.
간단하게 디렉터리와 일반 파일만 구현했습니다. (symlink 등은 독자에게 예제로 남김)
또한 파일 엔트리에 `usr/share/nginx/html` 접두사를 추가합니다.

그런 다음 이러한 레이어를 새 이미지에 추가합니다.

```go
newImg, err := mutate.AppendLayers(img, deleteLayer, addLayer)
if err != nil {
  panic(err)
}
```

또한 이미지의 진입점(entrypoint)과 전달 인자(arguments)를 변경할 수 있습니다.

그런 다음 이미지에 태그를 지정합니다.

```go
tag, err := name.NewTag("gcr.io/ahmetb-blog/blog:latest")
if err != nil {
  panic(err)
}
```

이 때 로컬 자격 증명 키 체인과 헬퍼를 사용하여 원격 레지스트리에 이미지를 푸시하거나
로컬 도커 데몬에 로드하여 다음을 테스트할 수 있습니다.

```go
// 로컬 테스트를 위해 로컬 도커 엔진에 로드합니다.
if s, err := daemon.Write(tag, newImg); err != nil {
  panic(err)
} else {
  fmt.Println("pushed "+s)
}

// 원격 레지스트리에 푸시합니다.
if err := crane.Push(newImg, tag.String()); err != nil {
  panic(err)
} else {
  fmt.Println(s)
}
```

여기까지입니다.
이 글로 [go-containerregistry](https://github.com/google/go-containerregistry)가
무엇을 해 줄 수 있는지 생각해 볼 수 있는 좋은 연습이었기를 바랍니다.
이 모듈은 매니페스트 수정, 레이어 재배치, 이미지 단순화[^2]를 수행하는
[mutate](https://pkg.go.dev/github.com/google/go-containerregistry/pkg/v1/mutate) 패키지처럼
훨씬 더 많은 기능을 가지고 있습니다.
([ko](https://github.com/google/ko),
[crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md)과
같은 도구가 이 Go 모듈을 사용하여 만들어졌다는 것을 알고 계셨나요?)

[^2]: `docker history` 명령어를 사용하면 도커 이미지의 히스토리(이전 레이어들을 확인할 수 있습니다.
이때 이미지 단순화(flatten images)란 필요한 이미지 정보만 추출해서 히스토리를 제거하고
이미지 크기를 줄이는 작업을 일컫습니다.

꼭 [리포지터리](https://github.com/google/go-containerregistry)를
별표(Star)하고 메인터이너의 트위터
([@jonjohnsonjr](https://twitter.com/jonjonsonjr),
[@ImJasonH](https://twitter.com/imjasonh),
[@mattomata](https://twitter.com/mattomata))를 팔로우해서 커뮤니티에 참여하세요.

> 실행 결과 맛보기 (역자)

```bash
mkdir build-oci-image
cd build-oci-image
curl -O https://gist.githubusercontent.com/ahmetb/430baa4e8bb0b0f78abb1c34934cd0b6/raw/1431150eb52c2ecf81ea469ca685d4be3a30f895/demo.go
go mod init demo
# go: creating new go.mod: module demo
go get
# go: finding module for package github.com/google/go-containerregistry/pkg/crane
# go: finding module for package github.com/google/go-containerregistry/pkg/v1/tarball
# go: finding module for package github.com/google/go-containerregistry/pkg/v1/mutate
# go: finding module for package github.com/google/go-containerregistry/pkg/v1
# go: finding module for package github.com/google/go-containerregistry/pkg/v1/daemon
# go: finding module for package github.com/google/go-containerregistry/pkg/name
# go: found github.com/google/go-containerregistry/pkg/crane in github.com/google/go-containerregistry v0.4.0
# go: found github.com/google/go-containerregistry/pkg/name in github.com/google/go-containerregistry v0.4.0
# go: found github.com/google/go-containerregistry/pkg/v1 in github.com/google/go-containerregistry v0.4.0
# go: found github.com/google/go-containerregistry/pkg/v1/daemon in github.com/google/go-containerregistry v0.4.0
# go: found github.com/google/go-containerregistry/pkg/v1/mutate in github.com/google/go-containerregistry v0.4.0
# go: found github.com/google/go-containerregistry/pkg/v1/tarball in github.com/google/go-containerregistry v0.4.0
sudo -i
docker images
# REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
go run demo.go
# {"status":"Loading layer","progressDetail":{"current":294912,"total":27095142},"progress":"[\u003e                                                  ]  294.9kB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":7077888,"total":27095142},"progress":"[=============\u003e                                     ]  7.078MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":13860864,"total":27095142},"progress":"[=========================\u003e                         ]  13.86MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":19759104,"total":27095142},"progress":"[====================================\u003e              ]  19.76MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":25067520,"total":27095142},"progress":"[==============================================\u003e    ]  25.07MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":26247168,"total":27095142},"progress":"[================================================\u003e  ]  26.25MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":27095142,"total":27095142},"progress":"[==================================================\u003e]   27.1MB/27.1MB","id":"9eb82f04c782"}
# {"status":"Loading layer","progressDetail":{"current":294912,"total":26566376},"progress":"[\u003e                                                  ]  294.9kB/26.57MB","id":"ffd3d6313c9b"}
# {"status":"Loading layer","progressDetail":{"current":8847360,"total":26566376},"progress":"[================\u003e                                  ]  8.847MB/26.57MB","id":"ffd3d6313c9b"}
# {"status":"Loading layer","progressDetail":{"current":16809984,"total":26566376},"progress":"[===============================\u003e                   ]  16.81MB/26.57MB","id":"ffd3d6313c9b"}
# {"status":"Loading layer","progressDetail":{"current":24477696,"total":26566376},"progress":"[==============================================\u003e    ]  24.48MB/26.57MB","id":"ffd3d6313c9b"}
# {"status":"Loading layer","progressDetail":{"current":26566376,"total":26566376},"progress":"[==================================================\u003e]  26.57MB/26.57MB","id":"ffd3d6313c9b"}
# {"status":"Loading layer","progressDetail":{"current":599,"total":599},"progress":"[==================================================\u003e]     599B/599B","id":"9b23c8e1e6f9"}
# {"status":"Loading layer","progressDetail":{"current":599,"total":599},"progress":"[==================================================\u003e]     599B/599B","id":"9b23c8e1e6f9"}
# {"status":"Loading layer","progressDetail":{"current":894,"total":894},"progress":"[==================================================\u003e]     894B/894B","id":"0f804d36244d"}
# {"status":"Loading layer","progressDetail":{"current":894,"total":894},"progress":"[==================================================\u003e]     894B/894B","id":"0f804d36244d"}
# {"status":"Loading layer","progressDetail":{"current":666,"total":666},"progress":"[==================================================\u003e]     666B/666B","id":"9f65d1d4c869"}
# {"status":"Loading layer","progressDetail":{"current":666,"total":666},"progress":"[==================================================\u003e]     666B/666B","id":"9f65d1d4c869"}
# {"status":"Loading layer","progressDetail":{"current":1411,"total":1411},"progress":"[==================================================\u003e]  1.411kB/1.411kB","id":"2acf82036f38"}
# {"status":"Loading layer","progressDetail":{"current":1411,"total":1411},"progress":"[==================================================\u003e]  1.411kB/1.411kB","id":"2acf82036f38"}
# {"status":"Loading layer","progressDetail":{"current":110,"total":110},"progress":"[==================================================\u003e]     110B/110B","id":"c99fc288b954"}
# {"status":"Loading layer","progressDetail":{"current":110,"total":110},"progress":"[==================================================\u003e]     110B/110B","id":"c99fc288b954"}
# {"status":"Loading layer","progressDetail":{"current":39,"total":39},"progress":"[==================================================\u003e]      39B/39B","id":"5f70bf18a086"}
# {"status":"Loading layer","progressDetail":{"current":39,"total":39},"progress":"[==================================================\u003e]      39B/39B","id":"5f70bf18a086"}
# {"stream":"Loaded image: nginx:foo\n"}
docker images
# REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
# nginx               foo                 176899f2ab5f        10 days ago         133MB
```
