# minecraft-server

## gcf-minecraft-starter
- `make archive` してから terraform apply する
- `make archive` は package.json が変更されたら zip を作り直す
    * `version` を変更することを想定。`$ touch` してもよい
- Discord アプリは適宜用意する
    * bot を有効にする
    * 権限設定は不要
    * minecraft-starter-http function をデプロイしたあとそのエンドポイントを `INTERACTIONS ENDPOINT URL` として設定
    * `https://discord.com/oauth2/authorize?client_id=${client_id}&scope=applications.commands+bot` でインストールする
