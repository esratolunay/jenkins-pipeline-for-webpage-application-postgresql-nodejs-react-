variable "key_name" {
  default = "usa_key"
}

variable "number" {
  default = 3
}

variable "allow_ports" {
  type = list(number)
  default = [ 22, 3000, 5000, 5432 ]
}
variable "user" {
  default = "esra"
}