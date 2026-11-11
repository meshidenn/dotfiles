# 通し例：1つの関数が段階1から7まで進む

題材は、このスキルのために作った Python の関数である。出典の例ではない。途中の名前は応答内の「名前の変遷」として扱い、コードには到達した名前だけを書く。

## 題材

```python
def on_upload(file, uploader):
    if file.size > MAX_UPLOAD_BYTES:
        raise UploadTooLarge(file.size)

    rows = []
    rejected = []
    reader = csv.DictReader(io.TextIOWrapper(file.stream, encoding="utf-8"))
    for line_no, record in enumerate(reader, start=2):
        if not record["sku"] or not record["quantity"].isdigit():
            rejected.append(line_no)
            continue
        rows.append((record["sku"], int(record["quantity"]), record["customer_id"]))

    with db.transaction():
        db.executemany(INSERT_ORDER_SQL, rows)

    stock_cache.clear()

    if rejected:
        mailer.send(uploader.email, "取り込めなかった行", render_rejected(rejected))
```

## 段階1：誤解を招く名前

`on_upload` は、呼ばれる時点を表す。何が起きるかを伝えず、DB への書き込みとメールの送信を伏せている。

## 段階2：`applesauce`

本体を理解する前に、名付ける範囲だけを決める。範囲は関数全体とする。

## 段階3：`probably_insert_orders_into_db_and_stuff`

- **確かめた事実：** `db.executemany(INSERT_ORDER_SQL, rows)` で注文を挿入する。
- **未確認：** `rows` の作り方、`stock_cache`、`mailer`。

`handle_order_upload` は嘘ではないが、採用しない。残りの処理もこの名前に含まれているように見えるので、何が未確認かが分からなくなる。

## 段階4：節を1つずつ足す

名前は `probably_` と `_and_stuff` の間の部分だけを示す。

| 反復 | 種類 | 確かめた事実 | 中央の部分 |
| --- | --- | --- | --- |
| 1 | 既知を広げる | `csv.DictReader` で注文の CSV を読む。 | `parse_order_csv_and_insert_orders_into_db` |
| 2 | 既知を広げる | SKU が空の行と、数量が数字でない行を除く。 | `parse_order_csv_and_insert_valid_orders_into_db` |
| 3 | 未知を狭める | `stock_cache` は `clear()` を呼ぶだけで、読み出さない。 | `…_and_clear_stock_cache` |
| 4 | 既知を広げる | 除いた行があれば、行番号をアップロードした人にメールで送る。 | `…_and_email_rejected_line_numbers_to_uploader` |

- **`_and_stuff` を外す：** `file`、`uploader`、`rows`、`rejected`、`db`、`stock_cache`、`mailer` をすべて追った。ほかに影響はない。
- **`probably_` を外す：** 4つの節をそれぞれ確かめるテストが通った。
- **名前に入れないもの：** 冒頭のサイズ検査はガード節である。

到達した名前は次のとおり。

```text
parse_order_csv_and_insert_valid_orders_into_db_and_clear_stock_cache_and_email_rejected_line_numbers_to_uploader
```

依頼が「何をしているかを把握したい」であれば、ここで止める。この名前をコードに入れるかどうかは、ユーザーに確認する。

## 段階5：名前を見て、責務を分ける

本体と呼び出し元は見ない。名前の節だけを見る。

| 節 | 判断 | 構造の変更 |
| --- | --- | --- |
| `parse_order_csv` | 入力の形式の話であり、注文の保存と無関係である。 | `parse_order_csv(file)` として分離し、`rows` と `rejected` を返す。 |
| `clear_stock_cache` | 注文を保存する側の内部事情であり、呼び出し側から隠したい。 | `db` と `stock_cache` を持つ保存役へ、挿入と消去をまとめて移す。 |

変更後の名前は `insert_orders_and_email_rejected_line_numbers_to_uploader` になる。`clear_stock_cache` の節が名前から消えるのは、消去が保存役の内部へ移ったあとである。

これらは構造の変更なので、承認がなければ提案に留める。

## 段階6：呼び出し元を見て、目的を書く

呼び出し元は2つある。

- **アップロード画面：** 取引先の担当者が、注文をまとめて登録する。
- **夜間バッチ：** 取引先のサーバーから取得したファイルを登録する。アップロードした人はいない。

アップロード画面だけを見ると、「注文を一括で登録し、取り込めなかった行を知らせる」が目的に見える。しかし、夜間バッチには知らせる相手がいない。メールでの通知は、共通の目的ではなかった。

段階5に戻り、通知を分離する。

| 名前 | 使う呼び出し元 | 表している目的 |
| --- | --- | --- |
| `import_bulk_orders(rows)` | 両方 | 注文をまとめて登録する。保存先とキャッシュは気にしなくてよい。 |
| `notify_uploader_of_rejected_lines(rejected, uploader)` | アップロード画面 | 登録できなかった行を、担当者が直せるようにする。 |

次の名前は採用しない。

- `post_upload_process`：使う時点を表しており、理由を表していない。
- `OrderImporter.execute`：ソフトウェア工学の用語であり、ドメインの語ではない。

## 段階7：名前の集まりを見て、概念を作る

- `rows` の要素は `(str, int, str)` のタプルである。SKU、数量、顧客という解釈は、変数名と添字の順序だけが支えている。
- 「SKU が空でなく、数量が数字である」という検査が、手入力フォームの処理にもある。
- `rejected` は `int` のリストである。行番号であることは名前だけが示し、理由は持たない。

欠けている概念は「注文明細」と「取り込めなかった行」である。

- `OrderLine`：SKU、数量、顧客を持つ。妥当性は生成時に検査する。
- `RejectedLine`：行番号と理由を持つ。

これにより、数量の上限検査を足す場所は `OrderLine` であると自明になる。

## 名前の変遷

| 段階 | 名前 | 見た場所 |
| --- | --- | --- |
| 1 | `on_upload` | 名前と本体の食い違い |
| 2 | `applesauce` | 範囲のみ |
| 3 | `probably_insert_orders_into_db_and_stuff` | 本体 |
| 4 | `parse_order_csv_and_insert_valid_orders_into_db_and_clear_stock_cache_and_email_rejected_line_numbers_to_uploader` | 本体とデータの流れ |
| 5 | `parse_order_csv`、`insert_orders_and_email_rejected_line_numbers_to_uploader` | 名前のみ |
| 6 | `import_bulk_orders`、`notify_uploader_of_rejected_lines` | 呼び出し元 |
| 7 | `OrderLine`、`RejectedLine` を引数と戻り値の型にする | 名前と型の集まり |
