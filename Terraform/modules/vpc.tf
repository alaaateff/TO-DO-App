resource "aws_vpc" "vpc" {
  cidr_block       = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [aws_vpc.vpc]
    tags = {
    Name = "eks_igw"
  }
}

resource "aws_subnet" "public-subnet" {
  count = var.pub-sub-count
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.pub-sub-cidr, count.index)
  availability_zone = element(var.pub-az, count.index)
  depends_on = [aws_vpc.vpc]
  map_public_ip_on_launch = true
  
  tags = {
  "kubernetes.io/role/elb" = "1"
   Name = "eks__pub_sub_${count.index}"
   "kubernetes.io/cluster/eks-cluster" = "shared"
}
}

resource "aws_subnet" "private-subnet" {
  count = var.priv-sub-count
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.priv-sub-cidr, count.index)
  availability_zone = element(var.priv-az, count.index)
  depends_on = [aws_vpc.vpc]
  tags = {
         "kubernetes.io/role/internal-elb" = "1"
          Name = "eks__priv_sub_${count.index}"
  }
}

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks_pub_rt"
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_route_table_association" "pub-rt-assoc" {
  count = 3 
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.pub-rt.id
  depends_on = [aws_vpc.vpc , aws_subnet.public-subnet]
}

resource "aws_eip" "ngw-eip" {
  domain   = "vpc"
    tags = {
    Name = "eks_eip"
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.ngw-eip.id
  subnet_id     = aws_subnet.public-subnet[0].id
  depends_on = [aws_internet_gateway.igw]
    tags = {
    Name = "eks_nat"
  }
}

resource "aws_route_table" "priv-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat-gw.id
  }
    tags = {
    Name = "eks_priv_rt"
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_route_table_association" "priv-rt-assoc" {
  count = 3 
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.priv-rt.id
  depends_on = [aws_vpc.vpc , aws_subnet.private-subnet]
}

resource "aws_security_group" "eks-cluster-sg" {
  name        = var.eks-sg
  description = "Allow 443 from bastion"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "eks_sg"
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes_sg" {
  name   = "eks-nodes-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description     = "Kubelet from EKS control plane"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks-cluster-sg.id]
  }
  ingress {
   from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_groups = [
    aws_security_group.eks-cluster-sg.id
  ]
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port       = 9443
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks-cluster-sg.id]
  }
  ingress {
  description = "node-to-node communication"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  self        = true
}
}


