#!/bin/bash

# ====== CSVファイルの初期化 ======
CSV_FILE="ec2_test_results.csv"
echo "Instance ID,Parameter,Expected Value,Actual Value,Result" > "$CSV_FILE"

# ====== EC2インスタンスIDの取得 ======
read -p "テスト対象のEC2インスタンスIDを入力してください（スペース区切りで複数可）: " -a INSTANCE_IDS

# ====== インスタンスの存在確認 ======
VALID_INSTANCE_IDS=()
for INSTANCE_ID in "${INSTANCE_IDS[@]}"; do
    INSTANCE_CHECK=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null)
    
    if [[ -z "$INSTANCE_CHECK" ]]; then
        echo "エラー: インスタンスID $INSTANCE_ID は存在しません。"
    else
        VALID_INSTANCE_IDS+=("$INSTANCE_ID")
    fi
done

# ====== 有効なインスタンスが1つもない場合、スクリプトを終了 ======
if [[ ${#VALID_INSTANCE_IDS[@]} -eq 0 ]]; then
    echo "エラー: 有効なインスタンスが見つかりませんでした。スクリプトを終了します。"
    exit 1
fi

# ====== チェック対象のパラメータ一覧 ======
PARAMETERS=("instance_type" "ami" "private_ip" "subnet_id" "vpc_security_group_ids" "key_name" "iam_instance_profile")

for INSTANCE_ID in "${VALID_INSTANCE_IDS[@]}"; do
    echo ">> テスト対象インスタンス: $INSTANCE_ID"
    ACTUAL_DATA=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" | jq '.Reservations[].Instances[0]')

    for PARAM in "${PARAMETERS[@]}"; do
        read -p "期待する $PARAM の値を入力してください: " EXPECTED_VALUE

        case "$PARAM" in
            "vpc_security_group_ids")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.SecurityGroups[].GroupId' | sort | tr '\n' ',' | sed 's/,$//')
                ;;
            "instance_type")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.InstanceType')
                ;;
            "ami")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.ImageId')
                ;;
            "private_ip")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.PrivateIpAddress')
                ;;
            "subnet_id")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.SubnetId')
                ;;
            "key_name")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.KeyName // "N/A"')
                ;;
            "iam_instance_profile")
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r '.IamInstanceProfile.Arn // "N/A"')
                ;;
            *)
                ACTUAL_VALUE=$(echo "$ACTUAL_DATA" | jq -r ".$PARAM")
                ;;
        esac

        if [ "$EXPECTED_VALUE" == "$ACTUAL_VALUE" ]; then
            RESULT="OK"
            echo "[$RESULT] $PARAM (Expected: $EXPECTED_VALUE, Actual: $ACTUAL_VALUE)"
        else
            RESULT="NG"
            echo "[$RESULT] $PARAM (Expected: $EXPECTED_VALUE, Actual: $ACTUAL_VALUE)"
        fi

        echo "$INSTANCE_ID,$PARAM,$EXPECTED_VALUE,$ACTUAL_VALUE,$RESULT" >> "$CSV_FILE"
    done

    echo "-----------------------------------------"
done

echo "テスト結果を $CSV_FILE に出力しました"
