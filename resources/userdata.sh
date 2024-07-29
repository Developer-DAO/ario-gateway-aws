#!/bin/bash
set -x

apt-get update
apt-get install -y \
  curl \
  docker-compose \
  kitty-terminfo \
  nfs-common \
  python3-pip \
  ruby-full
pip install awscli

# Format and attach EBS
mkfs -t ext4 -L ar-io-data /dev/sda1
echo "/dev/sda1 /data ext4 defaults 0 2" >> /etc/fstab
mkdir /data
mount /data
mkdir /data/sqlite
mkdir /data/tmp

# Mount the EFS cache filesystem
echo "${fs_id}.efs.${region}.amazonaws.com:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
mkdir /efs
mount /efs
mkdir -p /efs/data/chunks
mkdir -p /efs/data/contiguous
mkdir -p /efs/data/headers
mkdir -p /efs/wallets

# Copy in the latest DB snapshot
backup_dir="/efs/backups"
newest_backup=$(find $backup_dir -name "*.db" -type f | xargs ls -t | head -n 1)
instance_id=$(echo $newest_backup | awk -F '/' '{print $(NF-3)}')
copy_from_dir="$backup_dir/$instance_id/sqlite/before-install"
cp $copy_from_dir/*.db /data/sqlite/

# Download and install the CodeDeploy agent
curl -O https://aws-codedeploy-${region}.s3.amazonaws.com/latest/install
chmod +x ./install
./install auto
 
# Download and install the CloudWatch agent for Ubuntu
curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure the CloudWatch agent
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_root": true,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "ImageId": "\$${aws:ImageId}",
      "InstanceId": "\$${aws:InstanceId}",
      "InstanceType": "\$${aws:InstanceType}"
    },
    "aggregation_dimensions": [
      [
        "InstanceId",
        "InstanceType"
      ]
    ]
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/syslog"
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/auth.log"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/cloud-init-output.log"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/cloud-init.log"
          },
          {
            "file_path": "/var/log/dmesg",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/dmesg"
          },
          {
            "file_path": "/var/log/kernel.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/kernel.log"
          },
          {
            "file_path": "/var/log/aws/code-deploy-agent/codedeploy-agent.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/codedeploy-agent.log"
          }
        ]
      }
    }
  }
}
EOF
systemctl restart amazon-cloudwatch-agent

# Get the region from the metadata service
export AWS_DEFAULT_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)

# Download Release 15
mkdir -p /opt/ar-io-node
curl -o /opt/ar-io-node/docker-compose.yaml \
-L https://gist.githubusercontent.com/kay-is/4282773a7ee0bf16cdf34794829daa7f/raw/a5cd4b33c07efa4ff048e6c81f0bd2ae99633b46/docker-compose.yaml

# Download the .env file from SSM
aws ssm get-parameter \
  --name /ar-io-nodes/env \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text > /opt/ar-io-node/.env

# Download the observer wallet key from SSM
export observer_wallet=$(cat /opt/ar-io-node/.env | grep OBSERVER_WALLET | cut -d '=' -f2)
aws ssm get-parameter \
  --name /ar-io-nodes/observer-key \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text > "/efs/wallets/$${observer_wallet}.json"

# Add the EC2 instance ID to the .env file
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
echo "INSTANCE_ID=$INSTANCE_ID" >> /opt/ar-io-node/.env

# User the AWS logs driver for Docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-region": "${region}",
    "awslogs-group": "${log_group_name}",
    "tag": "{{ with split .ImageName \":\" }}{{join . \"_\"}}{{end}}-{{.ID}}"
  }
}
EOF
systemctl restart docker

# Write systemd service file
cat <<EOF > /etc/systemd/system/ar-io-node.service
[Unit]
Description=ar-io-node
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/opt/ar-io-node
Restart=always
RestartSec=10s
ExecStart=/usr/bin/docker-compose -f /opt/ar-io-node/docker-compose.yaml up
ExecStop=/usr/bin/docker-compose -f /opt/ar-io-node/docker-compose.yaml down
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

# Enable and start gateway service
systemctl daemon-reload
systemctl enable ar-io-node
systemctl start ar-io-node
