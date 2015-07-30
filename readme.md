# necromancer
## Automated Web Site Health Check for "the Dead"

---

## What is this

検証用URL一覧をもとに全ページに対しリクエストを発行、HTTPステータス・ロード時間を取得します。また、一定時間経って応答のないページについてはリクエストを打ち切ります。

## Install

* `Open3`関数を使っているためUNIX系システムでのみ動作します。
* parallel Gem が必要です。
    * `gem install parallel`

## Files

* necromancer.rb

　　json形式で与えられたURLをクロールし、ステータスコードとかかった時間をlogにjson形式で出力します。
　　`--help`でオプションの一覧が出ます。

* url*.json

　　necromancer.rb に入力するURLの一覧です。json形式であればファイル名に縛りはありません。

* /logs/

　　necromancer.rb がlogを出力する場所です。

## Usage

[TODO]