# terraform-google-network-loadbalancer-L7

이 모듈은 [terraform-google-module-template](https://stash.wemakeprice.com/users/lswoo/repos/terraoform-google-module-template/browse)에 의해서 생성되었습니다. 

The resources/services/activations/deletions that this module will create/trigger are:

- Create a GCS bucket with the provided name

## Usage

모듈의 기본적인 사용법은 다음과 같습니다:

```hcl
module "network_loadbalancer_L7" {
  source  = "terraform-google-modules/network-loadbalancer-L7/google"
  version = "~> 0.1"

  project_id  = "<PROJECT ID>"
  bucket_name = "gcs-test-bucket"
}
```

모듈 사용의 예시는 [examples](./examples/) 디렉토리에 있습니다.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket\_name | The name of the bucket to create | `any` | n/a | yes |
| project\_id | The project ID to deploy to | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_name | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

이 모듈을 사용하기 위해 필요한 사항을 표기합니다.

### Software

아래 dependencies들이 필요합니다:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

이 모듈의 리소스를 배포하기 위해서는 아래 역할이 필요합니다:

- Storage Admin: `roles/storage.admin`

[Project Factory module][project-factory-module] 과
[IAM module][iam-module]로 필요한 역할이 부여된 서비스 어카운트를 배포할 수 있습니다.

### APIs

이 모듈의 리소스가 배포되는 프로젝트는 아래 API가 활성화되어야 합니다:

- Google Cloud Storage JSON API: `storage-api.googleapis.com`

[Project Factory module][project-factory-module]을 이용해 필요한 API를 활성화할 수 있습니다.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Contributing

- 이 모듈에 기여하기를 원한다면 [contribution guidelines](./CONTRIBUTING.md)를 참고 바랍니다.

## Changelog

- [CHANGELOG.md](./CHANGELOG.md)

## TO DO

- [ ]
- [X]
