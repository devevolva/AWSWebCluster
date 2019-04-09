###############################################################################
# 
# VARIABLES
#
###############################################################################

# VPC CIDR BLOCKS
variable "vpc_main_cidr_block" {
    description = "Main VPC CIDR block."
    default     = "192.168.0.0/16"
}

variable "secondary_cidr_blocks" {
    description = "Secondary CIDR blocks for AZ subnets."
    default     = ["192.168.0.0/20","192.168.16.0/20","192.168.32.0/20","192.168.48.0/20","192.168.64.0/20","192.168.80.0/20"]
}



# SERVER PORTS
variable "server_http_port" {
  description = "Server HTTP port."
  default     = 8080
}


# DATASOURCES
data "aws_availability_zones" "all" {}



# R53 "A" RECORD
variable "r53_zone_id" {
    description = "Existing Route53 hosted zone id."
    default     = "Z32HEQVAQX766V"
}

variable "r53_domain_name" {
    description = "Domain name to be hosted by Route53."
    default     = "devevolvacloud.com"
}