# Contributing

이 프로젝트에 대한 모든 컨트리뷰트는 환영합니다. 이 문서에는 컨트리뷰트를 위한 몇 가지 가이드라인들이 기재되어 있습니다.

## Code Reviews

프로젝트 멤버를 포함한 수정 사항들은 코드 리뷰를 거쳐야 합니다. Bitbucket Pull request 기능을 이용하여 코드 리뷰를 신청할 수 있습니다.

## Development

개발 시스템에는 다음과 같은 Dependency들이 필요합니다:

- [Docker Engine][docker-engine]
- [Google Cloud SDK][google-cloud-sdk]
- [make]

### Generating Documentation for Inputs and Outputs

루트 모듈, 서브모듈, example 모듈에 존재하는 README의 Inputs과 Outputs 테이블은 각 모듈에 존재하는 `variables`과 `outputs`에 의해 자동으로 생성됩니다. 모듈 인터페이스가 변경되면 테이블을 갱신해야 변경사항을 반영합니다.
#### 실행

 `make generate_docs` 명령어를 실행해 새 Inputs과 Outputs 테이블을 생성합니다.

### Integration Testing

통합 테스트는 루트 모듈, 서브모듈, example 모듈의 기능을 확인하기 위해 시행합니다. 추가, 변경, 수정사항들은 이 테스트를 거쳐야만 합니다.

통합 테스트는 [Kitchen][kitchen],
[Kitchen-Terraform][kitchen-terraform], [InSpec][inspec]과 같은 도구를 사용할 수 있습니다. 이 도구들은 편의를 위해 Docker 이미지로 패키징되어 있습니다.

이 테스트를 사용하는 일반적인 방법은 [example 모듈](./examples/)의 기능을 확인하는 것입니다. 그럼으로써 루트모듈, 서브모듈, example 모듈이 모두 기능적으로 올바르게 동작한다는 것을 보장할 수 있습니다. 

#### Test Environment
모듈을 테스트하는 가장 쉬운 방법은 독립 된 테스트 프로젝트를 이용하는 것입니다.이러한 프로젝트를 위한 Setup은 [test/setup](./test/setup/) 디렉토리에서 찾을 수 있습니다.

이 Setup을 사용하기 위해, 아래 역할이 부여된 Service account가 필요합니다.(폴더 혹은 조직 수준):
- Project Creator
- Project Billing Manager

Service account가 속한 프로젝트는 아래 API들이 활성화되어 있어야 합니다.(Setup은 Service account 프로젝트에 어떠한 리소스도 생성하지 않습니다):
- Cloud Resource Manager
- Cloud Billing
- Service Usage
- Identity and Access Management (IAM)

다음과 같이 환경 변수에 Service account credential을 Export합니다:

```
export SERVICE_ACCOUNT_JSON=$(< credentials.json)
```

다음과 같은 몇 가지 환경 변수도 Export합니다:
```
export TF_VAR_org_id="your_org_id"
export TF_VAR_folder_id="your_folder_id"
export TF_VAR_billing_account="your_billing_account_id"
```

위 과정이 완료되었다면, Docker를 이용하여 테스트 프로젝트를 준비할 수 있습니다:
```
make docker_test_prepare
```

#### Noninteractive Execution

`make docker_test_integration` 명령어로 준비된 테스트 프로젝트를 이용하여, 상호작용 없이, 모든 example module을 테스트합니다.

#### Interactive Execution

1. `make docker_run` 명령어로 interactive mode의 테스트 Docker 컨테이너를 실행합니다.

2. `kitchen_do create <EXAMPLE_NAME>` 명렁어로 example 모듈을 위한 작업 디렉토리를 시작합니다.

3. `kitchen_do converge <EXAMPLE_NAME>` 명령어로 example 모듈을 적용합니다.
   
4. `kitchen_do verify <EXAMPLE_NAME>` 명령어로 example 모듈을 테스트합니다.

5. `kitchen_do destroy <EXAMPLE_NAME>` 명령어로 example 모듈 state를 제거합니다.

### Linting and Formatting

이 레포지토리의 대부분의 파일들은 코드 퀄리티를 유지하기 위해 Lint 및 formatting이 가능합니다.

#### Execution

`make docker_test_lint` 명령어를 실행합니다.

[docker-engine]: https://www.docker.com/products/docker-engine
[flake8]: http://flake8.pycqa.org/en/latest/
[gofmt]: https://golang.org/cmd/gofmt/
[google-cloud-sdk]: https://cloud.google.com/sdk/install
[hadolint]: https://github.com/hadolint/hadolint
[inspec]: https://inspec.io/
[kitchen-terraform]: https://github.com/newcontext-oss/kitchen-terraform
[kitchen]: https://kitchen.ci/
[make]: https://en.wikipedia.org/wiki/Make_(software)
[shellcheck]: https://www.shellcheck.net/
[terraform-docs]: https://github.com/segmentio/terraform-docs
[terraform]: https://terraform.io/