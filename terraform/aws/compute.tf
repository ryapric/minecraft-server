resource "aws_spot_instance_request" "main" {
  # Persist request
  instance_interruption_behavior = "stop"
  spot_type                      = "persistent"
  wait_for_fulfillment           = true

  ami                    = data.aws_ami.latest.id
  iam_instance_profile   = aws_iam_instance_profile.main.name
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public.id
  # user_data              = file("../../scripts/init.sh")
  vpc_security_group_ids = [aws_security_group.main.id]

  # To prevent unexpected shutdown of t3-family Spot instances 
  credit_specification {
    cpu_credits = "standard"
  }

  tags = merge(
    { Name = local.name_tag }
  )

  # Need this to apply tags to actual instances, since this resource can't do
  # that itself
  provisioner "local-exec" {
    command = <<-SCRIPT
      aws ec2 create-tags \
        --resources ${self.spot_instance_id} \
        --tags \
          Key=Name,Value=${local.name_tag} \
          Key=spot_request_id,Value=${self.id}
    SCRIPT
  }

  # Now provision the instance with local Minecraft files & the init script
  # Yeah yeah, I know I know, don't use Terraform provisioners, blah blah blah
  provisioner "file" {
    source = "../../bedrock-server-cfg" # a directory
    destination = "/tmp"
  }

  provisioner "file" {
    source = "../../scripts/init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    
  }
}

resource "aws_key_pair" "main" {
  key_name   = local.name_tag
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "main" {
  vpc = true

  tags = merge(
    { Name = local.name_tag }
  )
}

resource "aws_eip_association" "main" {
  allocation_id = aws_eip.main.id
  instance_id   = aws_spot_instance_request.main.spot_instance_id
}
