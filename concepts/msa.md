# Microservice Architecture

- [wikipedia](https://en.wikipedia.org/wiki/Microservices)
- [Microservices](https://martinfowler.com/articles/microservices.html) - James Lewis, Martin Fowler
  - [한국어 번역](http://channy.creation.net/articles/microservices-by-james_lewes-martin_fowler) - 윤석찬(Channy Yun)
- [microservices.io](https://microservices.io/)
  - [Pattern: Microservice Architecture](https://microservices.io/patterns/microservices.html)
- [Microservices architecture on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-microservices/aks-microservices) - Microsoft
- [마이크로서비스 기반 클라우드 아키텍처 구성 모범 사례](https://youtu.be/bOoagOf481I) - 윤석찬 (AWS 테크에반젤리스트)
- [MSA 제대로 이해하기](https://youtu.be/bOoagOf481I) - PaaS-TA
- [Netflix OSS, Spring Cloud 를 활용한 MSA 기초](https://www.youtube.com/playlist?list=PL9mhQYIlKEhdtYdxxZ6hZeb0va2Gm17A5) - SKPlanet T아카데미

> 간단하게 말하면, 마이크로서비스 아키텍처 스타일은 단일 응용 프로그램을 나누어 작은 서비스의 조합으로 구축하는 방법이며, 각 개별 서비스는 자신의 프로세스에서 실행하는 HTTP 기반 API 등으로 가벼운 연결 방식을 사용합니다. 각 서비스는 비지니스 로직의 수행 기능에 맞게 구축 된 완전히 자동화 된 머신에 의한 배포를 통해 이루어 집니다. 각 서비스의 최소한의 중앙 관리 기능은 있지만, 서로 다른 프로그래밍 언어에 의해 개발되고, 다른 데이터 저장 기술이 이용할 수 있습니다.

![monoliths-and-microservices.png](../images/concepts/monoliths-and-microservices.png)
