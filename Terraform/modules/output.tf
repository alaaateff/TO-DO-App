output "eks_node_sg_id"{
    value = aws_security_group.eks_nodes_sg.id
}
output "vpc_id"{
    value = aws_vpc.vpc.id
}
output "priv_sub_ids"{
    value = aws_subnet.private-subnet[*].id
}