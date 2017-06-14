provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"
  
  tags {
    Name = "${var.name}"
  }  
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id           = "${aws_vpc.main.id}"
  propagating_vgws = []
}


resource "aws_route_table" "private" {
  vpc_id           = "${aws_vpc.main.id}"
  propagating_vgws = []
  count            = "${length(var.azs)}"
}


resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}


resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.natgw.*.id, count.index)}"
  count                  = "${length(var.azs)}"
}

resource "aws_eip" "nateip" {
  vpc           = true
  count         = "${length(var.azs)}"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${element(aws_eip.nateip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  count         = "${length(var.azs)}"
  depends_on = ["aws_internet_gateway.main"]
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.public_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.public_subnets)}"

  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.private_subnets)}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_security_group" "bastion_did" {
    name_prefix = "${aws_vpc.main.id}-"
    description = "Allow all inbound SSH traffic"
    vpc_id = "${aws_vpc.main.id}"
    tags {
        Name = "bastion_did"
    }	
    ingress {
        from_port = 22
        to_port = 22
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

resource "aws_instance" "did" {
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "t2.medium"
  security_groups = ["${aws_security_group.bastion_did.id}"]
  associate_public_ip_address = true
  key_name = "${var.aws_key_name}"
  tags {
        Name = "Bastion"
    }
  subnet_id  = "${aws_subnet.public.0.id}"
}
