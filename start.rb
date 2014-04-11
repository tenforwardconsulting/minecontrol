require 'aws'

ec2 = AWS.ec2 #=> AWS::EC2
ec2.client #=> AWS::EC2::Client

ec2.instances['minecraft']
