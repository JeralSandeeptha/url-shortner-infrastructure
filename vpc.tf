#######################
# VPC Resource #
#######################
# Create VPC Resource
resource "aws_vpc" "url_shortner_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "URL_Shortner_VPC"
  }
}

##################
# Create Subnets #
################## 
# 1AZ
# Create public and private subnets in 1st availability zone
resource "aws_subnet" "url_shortner_public_subnet_01" {
  vpc_id                  = aws_vpc.url_shortner_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name                                 = "URL_Shortner_Public_Subnet_01"
    "kubernetes.io/cluster/url-shortner" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }
}
resource "aws_subnet" "url_shortner_private_subnet_01" {
  vpc_id            = aws_vpc.url_shortner_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                                 = "URL_Shortner_Private_Subnet_01"
    "kubernetes.io/cluster/url-shortner" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}

# 2AZ
# Create public and private subnets in 2nd availability zone
resource "aws_subnet" "url_shortner_public_subnet_02" {
  vpc_id                  = aws_vpc.url_shortner_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name                                 = "URL_Shortner_Public_Subnet_02"
    "kubernetes.io/cluster/url-shortner" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }
}
resource "aws_subnet" "url_shortner_private_subnet_02" {
  vpc_id            = aws_vpc.url_shortner_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                                 = "URL_Shortner_Private_Subnet_02"
    "kubernetes.io/cluster/url-shortner" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}

####################
# Internet Gateway #
####################
# Create Internet Gateway
resource "aws_internet_gateway" "url_shortner_igw" {
  vpc_id = aws_vpc.url_shortner_vpc.id

  tags = {
    Name = "URL_Shortner_Internet_Gateway"
  }
}

################################
# Elastic IPs for NAT Gateways #
################################
resource "aws_eip" "nat_eip_01" {
  domain = "vpc"
}
resource "aws_eip" "nat_eip_02" {
  domain = "vpc"
}

################
# NAT Gateways #
################
# Create NAT Gateways
resource "aws_nat_gateway" "url_shortner_ngw_01" {
  allocation_id = aws_eip.nat_eip_01.id
  subnet_id     = aws_subnet.url_shortner_public_subnet_01.id

  tags = {
    Name = "URL_Shortner_Internet_Gateway_01"
  }

  depends_on = [aws_internet_gateway.url_shortner_igw]
}
resource "aws_nat_gateway" "url_shortner_ngw_02" {
  allocation_id = aws_eip.nat_eip_02.id
  subnet_id     = aws_subnet.url_shortner_public_subnet_02.id

  tags = {
    Name = "URL_Shortner_Internet_Gateway_02"
  }

  depends_on = [aws_internet_gateway.url_shortner_igw]
}

################
# Route Tables #
################
# Create Route Table for 2 public subnets
resource "aws_route_table" "url_shortner_public_rt" {
  vpc_id = aws_vpc.url_shortner_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.url_shortner_igw.id
  }

  tags = {
    Name = "URL_Shortner_Public_Route_Table"
  }
}

# Create Route Table for 1st private subnet
resource "aws_route_table" "url_shortner_private_rt_01" {
  vpc_id = aws_vpc.url_shortner_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.url_shortner_ngw_01.id
  }

  tags = {
    Name = "URL_Shortner_Private_Route_Table_01"
  }
}
# Create Route Table for 2nd private subnet
resource "aws_route_table" "url_shortner_private_rt_02" {
  vpc_id = aws_vpc.url_shortner_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.url_shortner_ngw_02.id
  }

  tags = {
    Name = "URL_Shortner_Private_Route_Table_02"
  }
}

############################
# Route Table Associations #
############################

# Connect public route table to public subnet 01
resource "aws_route_table_association" "url_shortner_public_rta_01" {
  subnet_id      = aws_subnet.url_shortner_public_subnet_01.id
  route_table_id = aws_route_table.url_shortner_public_rt.id
}
# Connect public route table to public subnet 02
resource "aws_route_table_association" "url_shortner_public_rta_02" {
  subnet_id      = aws_subnet.url_shortner_public_subnet_02.id
  route_table_id = aws_route_table.url_shortner_public_rt.id
}

# Connect private route table to public subnet 01
resource "aws_route_table_association" "url_shortner_private_rta_01" {
  subnet_id      = aws_subnet.url_shortner_private_subnet_01.id
  route_table_id = aws_route_table.url_shortner_private_rt_01.id
}
# Connect private route table to public subnet 02
resource "aws_route_table_association" "url_shortner_private_rta_02" {
  subnet_id      = aws_subnet.url_shortner_private_subnet_02.id
  route_table_id = aws_route_table.url_shortner_private_rt_02.id
}