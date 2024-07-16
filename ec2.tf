resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server_key" {
  key_name   = "server-key"
  public_key = tls_private_key.server_key.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.server_key.private_key_pem
  sensitive = true
}

resource "aws_instance" "master_node_0" {
  ami           = "ami-0b27735385ddf20e8"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.server_key.key_name
  
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.a.id
  tags = {
    Name = "${var.name_prefix}-master_node_0"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "resource-name"
  }
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }
  user_data = file("./user_data_master.sh")
  depends_on = [aws_vpc.main, aws_security_group.allow_ssh, aws_vpc_security_group_ingress_rule.allow_tls_ipv4, aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4]
} 


resource "aws_instance" "worker_node_0" {
  ami           = "ami-0b27735385ddf20e8"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.server_key.key_name
  
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.a.id
  tags = {
    Name = "${var.name_prefix}-worker_node_0"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "resource-name"
  }
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }
  user_data = file("./user_data_worker.sh")
  depends_on = [aws_vpc.main, aws_security_group.allow_ssh, aws_vpc_security_group_ingress_rule.allow_tls_ipv4, aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4]
} 