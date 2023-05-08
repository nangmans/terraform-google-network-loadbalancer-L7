/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
####
# 새 프로젝트를 생성하는 대신 기존 프로젝트 환경에 테스트를 진행하기 위해 setup/~.tf 파일은 주석처리함, 추후 새 프로젝트에 테스트해야할시 주석 해제
####
# output "project_id" {
#   value = module.project.project_id
# }

# output "sa_key" {
#   value     = google_service_account_key.int_test.private_key
#   sensitive = true
# }
