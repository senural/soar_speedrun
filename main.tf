provider "aws" {
	shared_config_files 		= ["~/.aws/config"]
	shared_credentials_files 	= ["~/.aws/credentials"]
}

resource "aws_vpc" "splunk_es_vpc" {
  	cidr_block 		= "10.0.0.0/16"
  	instance_tenancy 	= "default"
  	tags = {
  		Name = "splunk_vpc"
  	}
}

resource "aws_security_group" "splunk_es_sg" {
 	name 		= "splunk_es_allow"
 	vpc_id 		= aws_vpc.splunk_es_vpc.id

 	ingress {
  		description 	= "ui_access"
  		from_port 	= 443
  		to_port 	= 443
 	 	protocol 	= "tcp"
  		cidr_blocks 	= ["0.0.0.0/0"]
 	}

 	ingress {
  		description 	= "ssh_access"
  		from_port 	= 22
  		to_port 	= 22
  		protocol 	= "tcp"
  		cidr_bilocks 	= ["0.0.0.0/0"]
 	}

 	egress {
  		from_port 	= 0
  		to_port 	= 0
  		protocol 	= "-1"
  		cidr_blocks 	= ["0.0.0.0/0"]
 	}

 	tags = {
  		Name = "splunk_es_allow"
 	}
}

resource "aws_subnet" "splunk_es_sn_pub" {
	vpc_id     		= aws_vpc.splunk_es_vpc.id
	cidr_block 		= "10.0.1.0/24"
	map_public_ip_on_launch	= "true"
	tags = {
    		Name = "splunk_es_sn_pub"
  	}
}

resource "aws_subnet" "splunk_es_sn_pri" {
        vpc_id     		= aws_vpc.splunk_es_vpc.id
        cidr_block 		= "10.0.2.0/24"
        tags = {
                Name = "splunk_es_sn_pri"
        }
}

resource "aws_internet_gateway" "splunk_es_igw" {
  	vpc_id 			= aws_vpc.splunk_es_vpc.id
  	tags = {
    		Name = "splunk_es_igw"
  }
}

resource "aws_instance" "test_instance" {
	ami 		= "ami-03f65b8614a860c29"
	instance_type 	= "t2.small"
}
