output "server_ip" {
  description = ""
  value       = aws_eip.main.public_ip
}