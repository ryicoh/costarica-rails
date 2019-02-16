# costarica
LINEグループ上で料理当番を管理するボットです

Google App Engineでデプロイできますよ！！

# デプロイ方法
- Cloud SQLのインスタンスを作成

- LINEのMessaging APIの登録

- cp app-sample.yaml app.yaml

Cloud SQLのインスタンスとLINEのMessaging APIの設定を書く
- vi app.yaml

- $ gcloud app deploy
