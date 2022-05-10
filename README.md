# minecraft-server

GCP で運用している Minecraft Server を terraform で管理するためのものです。
この Minecraft Server は [takanakahiko-and-98others Discord Server](https://scrapbox.io/takanakahiko-and-98other/takanakahiko-and-98other) で利用されています。

## Features

- preemptible な GCE による Minecraft Server の Hosting
- インスタンスが preempted になった場合に起動するための Google Groups の指定
- インスタンスが preempted になった場合に起動するための Discord Slash Command
- GitHub Actions による Plan / Aplly

## Preparation

### General

- GCP の Project を用意
- terraform の State を管理する bucket を用意する
- `$ terraform -chdir=terraform init`
- `$ terraform -chdir=terraform apply`

### gcf-minecraft-starter

- Discord アプリを適宜用意する
- bot を有効にする
- 権限設定は不要
- minecraft-starter-http function エンドポイントを `INTERACTIONS ENDPOINT URL` として設定
- `https://discord.com/oauth2/authorize?client_id=${client_id}&scope=applications.commands+bot` でインストールする

## Sponsors

<h3 align="center">Special Sponsor(インフラ費用)</h3>
<p align="center">
  <a href="https://github.com/uneco" target="_blank">
    <img width="128px"  src="https://github.com/uneco.png">
  </a>
</p>

