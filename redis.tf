resource "aws_instance" "redis-instance" {
  ami           = "ami-02c329a4b4aba6a48"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo systemctl enable docker

              sudo docker run --name redis -p 6379:6379 -d redis
              EOF

  tags = {
    Name = "redis-instance"
  }

  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  subnet_id = aws_subnet.private[0].id
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow Redis access"
  vpc_id      = aws_vpc.cluster_vpc.id

  egress {
    from_port     = 0
    to_port       = 0
    protocol      = "-1"
    cidr_blocks   = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_redis_to_ecs" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.redis_sg.id
}