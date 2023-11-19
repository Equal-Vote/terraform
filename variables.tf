variable "ALLOWED_URLS" {
  type    = string
  default = "http://localhost:3000/"
}

variable "DATABASE_URL" {
  type      = string
  sensitive = true
}

variable "DEV_DATABASE" {
  type    = string
  default = "TRUE"
}

variable "KEYCLOAK_PUBLIC_KEY" {
  type    = string
  default = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1pykfFHROSZY8/Q2071vAaplb4uBrj+Ei5uVVYwyhtSuJNKIhpIXukcfAAud/Qq35/a6kZoLCn5DyPZFhuq6nqyen0w9Kwjy91Oc1VR/hRPRPAWdCv5LfsS7/3nuN9O8cUCpkZG16CD92JtmEYNXd6LvFooDa4MNMDk3jOxRRVgFzzbGvq7WUkDySN/9pxsQ2OsmoWNvswIM5LMbyKCyP+F8F10wuOwFcon5PWK8MJ5ob/BDeUqTuyS6TwNst2Ui6Tf2WhC4x7V7+RxSnP5oxjpP4K7cWoCExDcOUY33ZQM7Z9zbs0B0XC9f0Ev9JNKHDhtAyKvg6DrMGlyTyLyLXQIDAQAB"
}

variable "KEYCLOAK_SECRET" {
  type      = string
  sensitive = true
}

# This is also mapped to REACT_APP_KEYCLOAK_URL in main.tf
variable "KEYCLOAK_URL" {
  type    = string
}

variable "S3_ID" {
  type    = string
}

variable "S3_SECRET" {
  type      = string
  sensitive = true
}

variable "SENDGRID_API_KEY" {
  type      = string
  sensitive = true
}

variable "CONTAINER_IMAGE" {
  type    = string
  default = "ghcr.io/equal-vote/star-server:sha-d65f462"
}

variable "PGPASSWORD" {
  type      = string
  sensitive = true
}

variable "REACT_APP_FF_ELECTION_ROLES" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_METHOD_STAR_PR" {
  type    = string
  default = "true"
}

variable "REACT_APP_FF_METHOD_RANKED_ROBIN" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_METHOD_APPROVAL" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_METHOD_RANKED_CHOICE" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_CANDIDATE_DETAILS" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_CANDIDATE_PHOTOS" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_PRECINCTS" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_MULTI_RACE" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_MULTI_WINNER" {
  type    = string
  default = "true"
}

variable "REACT_APP_FF_CUSTOM_REGISTRATION" {
  type    = string
  default = "false"
}

variable "REACT_APP_FF_VOTER_FLAGGING" {
  type    = string
  default = "false"
}
