# AWS Lambda、CloudWatch イベントを使って既存のEC2インスタンスを任意の時間に起動・停止するスクリプト

既存のEC2インスタンスを任意の時間に起動・停止するLambda関数とそれを呼び出すCloudWatchイベントを作成するCloudFormationテンプレートを作成するrubyスクリプトです。[Humidifier](https://github.com/localytics/humidifier)を使用しています。

# 前提条件

Ruby 2.0

# インストール

以下のコマンドを実行して下さい。

```bash
$ git clone https://github.com/ytabira/time-based-instances
$ cd time-based-instances
$ bundle install
```

# 環境変数

起動停止するEC2インスタンスが複数ある場合は`EC2_INSTANCE_IDS`にカンマ区切りで指定してください。

`TIME_BASED_INSTANCES_STACK_NAME`は既存のCloudFormationスタック名と重複しない名前を指定して下さい。

`EC2_START_SCHEDULE_EXPRESSION`, `EC2_STOP_SCHEDULE_EXPRESSION`はオプションです。指定方法は[ルールのスケジュール式の構文](http://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/events/ScheduledEvents.html)を参照して下さい。指定しなかった場合は起動9:00, 停止19:00で作成されます。

```bash
export AWS_ACCESS_KEY_ID=AKIA***************
export AWS_SECRET_ACCESS_KEY=****************************************
export AWS_REGION=ap-northeast-1
export TIME_BASED_INSTANCES_STACK_NAME=tabira-schedule
export EC2_INSTANCE_IDS="'i-*************','i-*************'"
export EC2_START_SCHEDULE_EXPRESSION="cron(0 0 ? * MON-FRI *)"
export EC2_STOP_SCHEDULE_EXPRESSION="cron(0 10 * * ? *)"
```

# Lambda関数、CloudWatchイベントの作成

以下のコマンドを実行して下さい。

```bash
$ rake time_based_instances:deploy
```

起動・停止時間を変更した場合は以下のコマンドを実行して下さい。

```bash
$ rake time_based_instances:update
```
