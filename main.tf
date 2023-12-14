provider "aws" {
  access_key = "AKIA2KHQRYDVL7JFY5PD"
  secret_key = "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"
  region     = "ap-south-1"  
}

variable "privatekey" {                                        #pem file is defined by a variable-privatekey
  default = "my-keypair.pem"
}

resource "aws_security_group" "allow-ssh-and-8080" {
  name        = "allow-ssh-and-8080"
  description = "Allow SSH and port 8080 inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  
  }
}
                                
resource "aws_instance" "web" {
  ami           = "ami-0d92749d46e71c34c"
  instance_type = "t2.micro"
  key_name = "my-keypair"
  security_groups = ["allow-ssh-and-8080"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup python -m SimpleHTTPServer 8080 &
              EOF

  tags = {
    Name = "project-3"
}

  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} >> /root/Terraform_Ansible_cicd/host"
}

   provisioner "remote-exec" {                                   #The remote-exec provisioner invokes a script on a remote resource after it is created. 
  inline = [                                                    #inline is a list of command strings.
    "echo 'build ssh connection' "                              #echo- to print the given statement
  ]
}

  connection {                                                  #include a connection block so that Terraform knows how to communicate with the server. 
   host = self.public_ip                                        #The address of the resource to connect to.
   type = "ssh"                                                 #The connection type that should be used.
   user = "ec2-user"                                            #The user that we should use for the connection.
   private_key = file("/root/Terraform_Ansible_cicd/my-keypair.pem")
}

  provisioner "local-exec" {
     command = "ansible-playbook -i '${aws_instance.web.public_ip},' --private-key ${var.privatekey} playbook.yml"
  }   
}                                                            
