output "postgres_private_ip" {
  value = aws_instance.servers[0].private_ip
}

output "node_public_ip" {
  value = aws_instance.servers[1].public_ip
}

output "react_ip" {
  value = "http://${aws_instance.servers[2].public_ip}:3000"
}