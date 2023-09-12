variable "worker_count" {
  default = 3
}

variable "controller_ip" {
  description = "IP address of the controller instance"
  default = "10.0.1.50"
}

variable "worker1_ip" {
  description = "IP address of the worker1 instance"
  default = "10.0.1.51"
}

variable "worker2_ip" {
  description = "IP address of the worker2 instance"
  default = "10.0.1.52"
}