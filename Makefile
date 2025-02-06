SHELL := /bin/bash

# EC2テストを実行
ec2:
	@echo "=== EC2 パラメータテストを開始 ==="
	@bash ec2_param_test.sh

# VPCテストを実行
vpc:
	@echo "=== VPC パラメータテストを開始 ==="
	@bash test_vpc.sh

# すべてのテストを実行
all: ec2 vpc
	@echo "=== 全てのパラメータテストが完了しました ==="
