provider "aws" {
  region  = var.region
  profile = "myaws"
}

resource "aws_vpc" "Prod" {
  cidr_block       = "10.0.0.0/20"
  instance_tenancy = "default"
  tags = merge(
    {
      Name = "Prod",
    },
    var.tags
  )
}

################ Private Subnets #####################################################

resource "aws_subnet" "WAS_Subnet1" {
  vpc_id                  = var.Prod
  cidr_block              = var.private_subnet_cidr_blocks[0]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[2]
  tags = merge(
    {
      Name = "WAS_Subnet1",
    },
    var.tags
  )
}

resource "aws_subnet" "WAS_Subnet2" {
  vpc_id                  = var.Prod
  cidr_block              = var.private_subnet_cidr_blocks[1]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[3]
  tags = merge(
    {
      Name = "WAS_Subnet2",
    },
    var.tags
  )
}

resource "aws_subnet" "DB_Subnet1" {
  vpc_id                  = var.Prod
  cidr_block              = var.private_subnet_cidr_blocks[2]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[2]
  tags = merge(
    {
      Name = "DB_Subnet1",
    },
    var.tags
  )
}

resource "aws_subnet" "DB_Subnet2" {
  vpc_id                  = var.Prod
  cidr_block              = var.private_subnet_cidr_blocks[3]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[5]
  tags = merge(
    {
      Name = "DB_Subnet2",
    },
    var.tags
  )
}


################ Public Subnets #####################################################

resource "aws_subnet" "Public_Subnet1" {
  vpc_id                  = var.Prod
  cidr_block              = var.public_subnet_cidr_blocks[0]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[0]
  tags = merge(
    {
      Name = "Public_Subnet1",
    },
    var.tags
  )
}

resource "aws_subnet" "Public_Subnet2" {
  vpc_id                  = var.Prod
  cidr_block              = var.public_subnet_cidr_blocks[1]
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zones[1]
  tags = merge(
    {
      Name = "Public_Subnet2",
    },
    var.tags
  )
}


##############Security Groups #########################################

resource "aws_security_group" "ExportServerAccess" {
  name        = "ExportServerAccess"
  description = "Security Group to access Export Server"
  vpc_id      = var.Prod
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    description = "WAS Subnet1 access to Port 3006 on Export Server"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    description = "WAS Subnet2 access from Port 3005 on Export Server"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    description     = ""
    security_groups = [aws_security_group.BastionHostSG.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    {
      Name = "ExportServerAccess",
    },
    var.tags
  )
}


resource "aws_security_group" "GlobalAcceleratorAccess" {
  name        = "GlobalAccelerator"
  description = "GlobalAccelerator configured SecurityGroup"
  vpc_id      = var.Prod
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    {
      Name           = "GlobalAcceleratorAccess",
      AWSServiceName = "GlobalAccelerator",
    },
    var.tags
  )
}

resource "aws_security_group" "PublicAccess" {
  name        = "PublicAccess"
  description = "Security Group to be used by instances in public subnet"
  vpc_id      = var.Prod
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Allows port 443 from everywhere"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Allows port 80 from everywhere"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Port 80 traffic from public to WAS Subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Port 443 traffic from public to WAS Subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Port 80 traffic from public to WAS Subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Port 443 traffic from public to WAS Subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  tags = merge(
    {
      Name = "PublicAccess",
    },
    var.tags
  )
}


resource "aws_security_group" "ALBAccess" {
  name        = "ALBAccess"
  description = "Security Group to control ALB traffic"
  vpc_id      = var.Prod
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "All traffic allowed on Port 443"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "All traffic allowed on Port 80"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Traffic to Port 443on WAS Subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Traffic to Port 80 on WAS Subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Traffic to Port 443 on WAS Subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Traffic to Port 80 on WAS Subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  tags = merge(
    {
      Name = "ALBAccess",
    },
    var.tags
  )
}


resource "aws_security_group" "BastionHostSG" {
  name        = "BastionHostSG"
  description = "Security Group for Bastion Host"
  vpc_id      = var.Prod
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    {
      Name = "BastionHostAccess",
    },
    var.tags
  )
}

resource "aws_security_group" "DBAccess" {
  name        = "DBAccess"
  description = "Security group to permit DB instance traffic"
  vpc_id      = var.Prod
  ingress {
    from_port   = 3607
    to_port     = 3607
    protocol    = "tcp"
    description = "Incoming traffic from WAS subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  ingress {
    from_port   = 3607
    to_port     = 3607
    protocol    = "tcp"
    description = "Incoming traffic from WAS subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  egress {
    from_port   = 3607
    to_port     = 3607
    protocol    = "tcp"
    description = "Outbound traffic from port 3607 to WAS Subnet1"
    cidr_blocks = [var.private_subnet_cidr_blocks[0]]
  }
  egress {
    from_port   = 3607
    to_port     = 3607
    protocol    = "tcp"
    description = "Outbound traffic from port 3607 to WAS Subnet2"
    cidr_blocks = [var.private_subnet_cidr_blocks[1]]
  }
  tags = merge(
    {
      Name = "DBAccess",
    },
    var.tags
  )
}

resource "aws_security_group" "WASAccess" {
  name        = "WASAccess"
  description = "Security Group to be used by Web application servers"
  vpc_id      = var.Prod
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = ""
    cidr_blocks = [var.public_subnet_cidr_blocks[0], var.public_subnet_cidr_blocks[1]]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = ""
    cidr_blocks = [var.public_subnet_cidr_blocks[0], var.public_subnet_cidr_blocks[1]]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = ""
    cidr_blocks = [var.private_subnet_cidr_blocks[0], var.private_subnet_cidr_blocks[1], var.private_subnet_cidr_blocks[2], var.private_subnet_cidr_blocks[3]]
  }
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    description = ""
    cidr_blocks = [var.private_subnet_cidr_blocks[0], var.private_subnet_cidr_blocks[1]]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    description     = ""
    security_groups = [aws_security_group.BastionHostSG.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    {
      Name = "WASAccess",
    },
    var.tags
  )
}

##################### EC2 Instances ########################################

resource "aws_instance" "WAS1" {
  ami                                  = "ami-0980f330b434aed5f"
  instance_type                        = "t2.2xlarge"
  associate_public_ip_address          = false
  availability_zone                    = var.availability_zones[2]
  subnet_id                            = aws_subnet.WAS_Subnet1.id
  iam_instance_profile                 = "SSMAccessRole"
  instance_initiated_shutdown_behavior = "stop"
  private_ip                           = "10.0.3.5"
  tenancy                              = "default"
  vpc_security_group_ids               = [aws_security_group.WASAccess.id]

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = merge(
    {
      Name = "WAS1",
    },
    var.tags
  )
}

resource "aws_instance" "WAS2" {
  ami                                  = "ami-0980f330b434aed5f"
  instance_type                        = "t2.2xlarge"
  associate_public_ip_address          = false
  availability_zone                    = var.availability_zones[3]
  subnet_id                            = aws_subnet.WAS_Subnet2.id
  iam_instance_profile                 = "SSMAccessRole"
  instance_initiated_shutdown_behavior = "stop"
  private_ip                           = "10.0.4.5"
  tenancy                              = "default"
  vpc_security_group_ids               = [aws_security_group.WASAccess.id]

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = merge(
    {
      Name = "WAS2",
    },
    var.tags
  )
}

resource "aws_instance" "ExportServer" {
  ami                                  = "ami-052efd3df9dad4825"
  instance_type                        = "t2.xlarge"
  associate_public_ip_address          = false
  availability_zone                    = var.availability_zones[2]
  subnet_id                            = aws_subnet.WAS_Subnet1.id
  iam_instance_profile                 = "SSMAccessRole"
  instance_initiated_shutdown_behavior = "stop"
  private_ip                           = "10.0.3.30"
  tenancy                              = "default"
  vpc_security_group_ids               = [aws_security_group.ExportServerAccess.id]

  credit_specification {
    cpu_credits = "standard"
  }
  tags = merge(
    {
      Name = "ExportServer",
    },
    var.tags
  )
}

resource "aws_instance" "BastionHost" {
  ami                                  = "ami-052efd3df9dad4825"
  instance_type                        = "t2.micro"
  associate_public_ip_address          = true
  availability_zone                    = var.availability_zones[0]
  subnet_id                            = aws_subnet.Public_Subnet1.id
  iam_instance_profile                 = "SSMAccessRole"
  instance_initiated_shutdown_behavior = "stop"
  tenancy                              = "default"
  vpc_security_group_ids               = [aws_security_group.BastionHostSG.id]

  credit_specification {
    cpu_credits = "standard"
  }
  tags = merge(
    {
      Name = "BastionHost",
    },
    var.tags
  )
}

############Aurora mysql RDS  #####################

resource "aws_rds_cluster" "mysqldb" {
  cluster_identifier                  = "mysqldb"
  availability_zones                  = [var.availability_zones[0], var.availability_zones[2], var.availability_zones[5]]
  backtrack_window                    = 0
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery", ]
  iam_database_authentication_enabled = false
  iops                                = 0
  engine                              = "aurora-mysql"
  engine_version                      = "8.0.mysql_aurora.3.02.0"
  database_name                       = "visualizeroi"
  deletion_protection                 = true
  db_cluster_parameter_group_name     = "default.aurora-mysql8.0"
  master_username                     = "admin"
  port                                = 3607
  storage_encrypted                   = true
  vpc_security_group_ids              = [aws_security_group.DBAccess.id]
}


##################### Aurora RDS AutoScaling Policy  ###################
resource "aws_appautoscaling_target" "mysqlDBautoscaling" {
  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:mysqldb"
  min_capacity       = 1
  max_capacity       = 8
}

resource "aws_appautoscaling_policy" "mysqlDBautoscaling" {
  name               = "mysqlDBautoscaling"
  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:mysqldb"
  policy_type        = "TargetTrackingScaling"


  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    target_value       = 60

    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
  }
}

##### Aurora mysql RDS Cluster Parameter Group ############# (Not imported)

#resource "aws_rds_cluster_parameter_group" "8.0.mysql_aurora.3.02.0" {
#  name        = "rds-cluster-pg"
#  family      = "aurora5.6"
#  description = "RDS default cluster parameter group"

#  parameter {
#    name  = "character_set_server"
#    value = "utf8"
#  }

#  parameter {
#    name  = "character_set_client"
#    value = "utf8"
#  }
#}


##### Internet Gateway #############
resource "aws_internet_gateway" "ProdInfraGW" {
  vpc_id = var.Prod
  tags = merge(
    {
      Name = "ProdInfraGW",
    },
    var.tags
  )
}

####### NAT Gateway ################
resource "aws_nat_gateway" "ValueCoreNatGW" {
  allocation_id = "eipalloc-035be23c97d1d2eca" #Elastic IP assigned by NAT GW
  subnet_id     = aws_subnet.Public_Subnet1.id
  tags = merge(
    {
      Name = "ValueCoreNatGW",
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.ProdInfraGW]
}

### Route Tables #######################
resource "aws_route_table" "Prod_Private" {
  vpc_id = var.Prod

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ValueCoreNatGW.id 
  }
  tags = merge(
    {
      Name = "Prod_Private",
    },
    var.tags
  )
}

resource "aws_route_table" "Prod_Public" {
  vpc_id = var.Prod

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ProdInfraGW.id 
  }
  tags = merge(
    {
      Name = "Prod_Public",
    },
    var.tags
  )
}

###### Route Table Association #################
resource "aws_route_table_association" "Prod_Private_Route_Association_A" {
  subnet_id      = aws_subnet.DB_Subnet1.id
  route_table_id = aws_route_table.Prod_Private.id
}

resource "aws_route_table_association" "Prod_Private_Route_Association_B" {
  subnet_id      = aws_subnet.DB_Subnet2.id
  route_table_id = aws_route_table.Prod_Private.id
}

resource "aws_route_table_association" "Prod_Private_Route_Association_C" {
  subnet_id      = aws_subnet.WAS_Subnet1.id
  route_table_id = aws_route_table.Prod_Private.id
}

resource "aws_route_table_association" "Prod_Private_Route_Association_D" {
  subnet_id      = aws_subnet.WAS_Subnet2.id
  route_table_id = aws_route_table.Prod_Private.id
}


resource "aws_route_table_association" "Prod_Public_Route_Association_A" {
  subnet_id      = aws_subnet.Public_Subnet1.id
  route_table_id = aws_route_table.Prod_Public.id
}

resource "aws_route_table_association" "Prod_Public_Route_Association_B" {
  subnet_id      = aws_subnet.Public_Subnet2.id
  route_table_id = aws_route_table.Prod_Public.id
}

#########ALB Target Group ####################

resource "aws_alb_target_group" "WASInstanceGroup" {
  name                          = "WASInstanceGroup"
  load_balancing_algorithm_type = "round_robin"
  port                          = 443
  protocol_version              = "HTTP1"
  protocol                      = "HTTPS"
  target_type                   = "instance"
  vpc_id                        = var.Prod
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/vr/login"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    enabled         = true
    type            = "lb_cookie"
  }
}

#### ALB #############
resource "aws_alb" "ValucoreALB" {
  name                       = "ValucoreALB"
  internal                   = false
  ip_address_type            = "ipv4"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ALBAccess.id]
  subnets                    = [aws_subnet.WAS_Subnet1.id, aws_subnet.WAS_Subnet2.id]
  enable_deletion_protection = true
  subnet_mapping {
    subnet_id = aws_subnet.WAS_Subnet1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.WAS_Subnet2.id
  }
}

####### ALB Target Group attachment ########## 
resource "aws_lb_target_group_attachment" "WASInstanceGroupA" {
  target_group_arn = aws_alb_target_group.WASInstanceGroup.arn
  target_id        = aws_instance.WAS2.id
  port             = 443
}

resource "aws_lb_target_group_attachment" "WASInstanceGroupB" {
  target_group_arn = aws_alb_target_group.WASInstanceGroup.arn
  target_id        = aws_instance.WAS1.id
  port             = 443
}

####### Adding Listnerers ##############

resource "aws_alb_listener" "valucorelistener" {
  load_balancer_arn = aws_alb.ValucoreALB.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:246415412746:certificate/316c770b-6ad7-4cf9-92a2-554a20576bea"
  default_action {
    target_group_arn = aws_alb_target_group.WASInstanceGroup.id
    type             = "forward"
  }
}

####### ALB Global Accelerator ############
resource "aws_globalaccelerator_accelerator" "ALBValuveCoreAccelerator" {
  name            = "ALBValuveCoreAccelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled = false
  }
}
