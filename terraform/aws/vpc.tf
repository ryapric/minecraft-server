#################
# Core / Shared #
#################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minecraft"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "main" {
  description = "SG rules for Minecraft server"
  name        = local.name_tag
  vpc_id      = aws_vpc.main.id

  tags = merge(
    { Name = local.name_tag }
  )
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description       = "Allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "ping" {
  type              = "ingress"
  description       = "Allow ICMP ping"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "deployer_ssh" {
  type              = "ingress"
  description       = "Allow deployer SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.my_ip.body)}/32"]
  security_group_id = aws_security_group.main.id
}

# The following Minecraft server port rules are open to the world, but the
# access to the server itself is expected to be gated by login ID
resource "aws_security_group_rule" "bedrock_tcp" {
  type              = "ingress"
  description       = "Allow Minecraft Bedrock clients (TCP)"
  from_port         = 19132
  to_port           = 19132
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "bedrock_udp" {
  type              = "ingress"
  description       = "Allow Minecraft Bedrock clients (UDP)"
  from_port         = 19132
  to_port           = 19132
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "java_tcp" {
  type              = "ingress"
  description       = "Allow Minecraft Java clients (TCP)"
  from_port         = 25565
  to_port           = 25565
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "java_udp" {
  type              = "ingress"
  description       = "Allow Minecraft Java clients (UDP)"
  from_port         = 25565
  to_port           = 25565
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

##########
# Public #
##########
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    { Name = local.name_tag }
  )
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}
