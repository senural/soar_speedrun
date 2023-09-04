provider "aws" {
	shared_config_files 		= ["~/.aws/config"]
	shared_credentials_files 	= ["~/.aws/credentials"]
}

resource "aws_vpc" "soar_vpc" {
  	cidr_block 		= "10.0.0.0/16"
  	instance_tenancy 	= "default"
  	tags = {
  		Name = "soar_vpc"
  	}
}

resource "tls_private_key" "soar_pri_key" {
	algorithm 	= "RSA"
}

resource "aws_key_pair" "soar_key_pair" {
	key_name 	= "soar_key_pair"
 	public_key 	= tls_private_key.soar_pri_key.public_key_openssh
 	depends_on = [
  		tls_private_key.soar_pri_key
 	]
}

resource "local_file" "soar_key_pem" {
	content 	= tls_private_key.soar_pri_key.private_key_pem
 	filename 	= "soar_key_pem.pem"
 	file_permission	="0400"
 	depends_on = [
  		tls_private_key.soar_pri_key
 	]
}

resource "aws_security_group" "soar_sg" {
 	name 		= "soar_allow"
 	vpc_id 		= aws_vpc.soar_vpc.id

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
  		Name = "soar_allow"
 	}
}

resource "aws_subnet" "soar_sn_pub" {
	vpc_id     		= aws_vpc.soar_vpc.id
	cidr_block 		= "10.0.1.0/24"
	map_public_ip_on_launch	= "true"
	tags = {
    		Name = "soar_sn_pub"
  	}
}

resource "aws_subnet" "soar_sn_pri" {
        vpc_id     		= aws_vpc.soar_vpc.id
        cidr_block 		= "10.0.2.0/24"
        tags = {
                Name = "soar_sn_pri"
        }
}

resource "aws_internet_gateway" "soar_igw" {
  	vpc_id 			= aws_vpc.soar_vpc.id
  	tags = {
    		Name = "soar_igw"
  }
}

resource "aws_route_table" "soar_rt" {
	vpc_id                  = aws_vpc.soar_vpc.id
	route {
  		cidr_block 	= "0.0.0.0/0"
		gateway_id 	= aws_internet_gateway.soar_igw.id 
	}
	tags = {
  		Name = "soar_rt"
 	}
}

resource "aws_route_table_association" "soar_rt_pub_asoc" {
	subnet_id 		= aws_subnet.soar_sn_pub.id 
	route_table_id 		= aws_route_table.soar_rt.id
}

resource "aws_route_table_association" "soar_rt_pri_asoc" {
	subnet_id 		= aws_subnet.soar_sn_pri.id
        route_table_id 		= aws_route_table.soar_rt.id
}

resource "aws_instance" "soar_ec2" {
	ami 			= "ami-014b69f69e708f2a9"
	instance_type 		= "m5.xlarge"
	key_name 		= aws_key_pair.soar_key_pair.key_name
	vpc_security_group_ids	= [ aws_security_group.soar_sg.id ]
	subnet_id		= aws_subnet.soar_sn_pub.id
	tags = {
		Name = "soar_ec2"
	}
}
