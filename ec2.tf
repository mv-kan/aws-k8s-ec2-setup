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

resource "aws_instance" "master_node0" {
  ami           = "ami-0b27735385ddf20e8"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.server_key.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "master_node_0"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "resource-name"
  }
  user_data = file("./user_data_master.sh")
  depends_on = [aws_vpc.main, aws_security_group.allow_ssh]
} 