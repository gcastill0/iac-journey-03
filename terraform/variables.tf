variable "vpc_id" {
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Default tags used to determine the identity and meta-data 
for the deployment. 
**** **** **** **** **** **** **** **** **** **** **** ****/

variable "tags" {
  type = map(any)

  default = {
    Organization = "Happy Bird"
    Keep         = "True"
    Owner        = "Gilberto"
    Region       = "US-EAST-1"
    Purpose      = "York University Lecture"
    TTL          = "168"
    Terraform    = "true"
  }
}