# 付録

ここでは、本文中には書けなかった部分についての補足や、各章に書くには長すぎるような具体的な内容を扱います。

## 1章の補足: SMTPクライアントとサーバのやりとりとメールデータの対応

SMTPでは、以下の流れでクライアントとサーバが通信を行う必要があります。クライアントが以下のリクエストを送信し、サーバがレスポンスを行う必要があります。

1. サーバへの接続（25番ポート、587番ポート等）
2. HELO or EHLO
3. MAIL FROM
4. RCPT TO
5. DATA
6. メールの内容
7. `.` （ドットのみで終わる行）
8. QUIT

そして、それぞれのやりとりは、実は、相互にメールに記録されています。1章で取り上げたメールデータを元に、各工程ごとに、通信内容とメールデータを比較してみましょう。

\clearpage

```{caption="再掲: SMTPクライアントとサーバのリクエスト/レスポンス例"}
$ telnet imap.b.test 25
Trying 10.255.2.40...
Connected to imap.b.test.
Escape character is '^]'.
@<color>{gray,220 imap.b.test ESMTP Postfix}
HELO a.test
@<color>{gray,250 imap.b.test}
MAIL FROM: user1@a.test
@<color>{gray,250 2.1.0 Ok}
RCPT TO:   user1@b.test
@<color>{gray,250 2.1.5 Ok}
DATA
@<color>{gray,354 End data with <CR><LF>.<CR><LF>}
Message-ID: <20241113081556.12727@a.test>
Date: Wed, 13 Nov 2024 08:15:56 +0900
From: user1@a.test
To:   user1@b.test
Subject: scenario1-1 (mail from user1@a.test)

Hello user1@b.test!
.
@<color>{gray,250 2.0.0 Ok: queued as 3EE173C0ADC}
QUIT
@<color>{gray,221 2.0.0 Bye}
Connection closed by foreign host.
```

```{caption="再掲: メールサーバに保存されるデータの例"}
@<color>{gray,Return-Path: <user1@a.test>}
@<color>{gray,Received: from a.test (client.a.test [10.255.1.10])}
        @<color>{gray,by imap.b.test (Postfix) with SMTP id CECC4383F6B}
        @<color>{gray,for <user1@imap.b.test>; Sun, 10 Nov 2024 21:59:09 +0900 (JST)}
Message-ID: <20241110215910.10161@a.test>
Date: Sun, 10 Nov 2024 21:59:10 +0900
From: user1@a.test
To:   user1@imap.b.test
Subject: scenario1 (mail from user1@a.test)

Hello user1@imap.b.test!
```

\clearpage

### サーバへの接続（25番ポート、587番ポート等）、HELO or EHLO


```lua
サーバ:      220 imap.b.test ESMTP Postfix
クライアント: HELO a.test
サーバ:      250 imap.b.test
```

HELO で送信した内容が `Received: from` に、レスポンスしているホスト名が `by` に記載されていることがわかります。

```
Received: from a.test (client.a.test [10.255.1.10])
        by imap.b.test (Postfix) with SMTP id CECC4383F6B
```

### MAIL FROM

```
クライアント: MAIL FROM: user1@a.test
サーバ:      250 2.1.0 Ok
```

`MAIL FROM` で送信した内容は `Return-Path` に記録されます。これは、メールの送信がエラーとなった場合にどこに送信するかを示しています。例えば、「MAILER-DAEMON」といった差出人からメールが届くことがありますよね。それはここのReturn-Pathを元に送っています。

```
Return-Path: <user1@a.test>
```

### RCPT TO

```
クライアント: RCPT TO:   user1@imap.b.test
サーバ:      250 2.1.5 Ok
```

`RCPT TO` は、メールサーバ上の実際に届く宛先メールを指定します。DATA上の `To` と別々に用意されている理由は、「Toが自分に設定されたメールをAさんに転送したい」という場合をイメージしてもらうとわかりやすいですね。

```
        for <user1@imap.b.test>; Sun, 10 Nov 2024 21:59:09 +0900 (JST)
```

\clearpage

### DATA

実際のメールデータは以下の部分です。この部分は、SMTP上はそのまま送信されます。また、 `DATA` のやり取りが正常に完了した後、`250 2.0.0 Ok: queued as` のように成功通知を行いますが、この時に id が返答されます。順番が前後しますが、これが、 `Received:`  の後の SMTP id に記録されていることがわかります。

```
クライアント: DATA
サーバ:      354 End data with <CR><LF>.<CR><LF>
クライアント: Message-ID: <20241110215910.10161@a.test>
クライアント: Date: Sun, 10 Nov 2024 21:59:10 +0900
クライアント: From: user1@a.test
クライアント: To:   user1@imap.b.test
クライアント: Subject: scenario1 (mail from user1@a.test)
クライアント: 
クライアント: Hello user1@imap.b.test!
クライアント: .
サーバ:      250 2.0.0 Ok: queued as CECC4383F6B
```


```
(省略)
        by imap.b.test (Postfix) with SMTP id CECC4383F6B
(省略)
Message-ID: <20241110215910.10161@a.test>
Date: Sun, 10 Nov 2024 21:59:10 +0900
From: user1@a.test
To:   user1@imap.b.test
Subject: scenario1 (mail from user1@a.test)

Hello user1@imap.b.test!
```

### QUIT

最後に、QUITを実行して接続が終了します。

```
クライアント: QUIT
            Connection closed by foreign host. ※クライアント上のソフトウェアの表示
```


以上のように、クライアントとサーバ間のSMTPのリクエスト/レスポンスの情報を元に、メールサーバが、見えないデータを自動的に追加します。

特に気を付けるべき点は、送信元メールアドレスである `user1@a.test` が2カ所に存在するということです。これらは、「エンベロープFrom」と「ヘッダーFrom」という2つの言葉で分けて呼称されます。

エンベロープFromとは、一般的に、メール送信を行うメールサーバが追加する情報で、 Return-Path に記載されるメールアドレスのことです。

ヘッダーFromとは、DATA コマンドの中で記述されている `From:` から始まる行のメールアドレスのことです。何故ヘッダーFromかというと、これはRFC 5322に定義されている「Internet Message Format」のヘッダー[^90-header-from]であるためです。

[^90-header-from]: RFC 5322 https://www.rfc-editor.org/rfc/rfc5322.html

## 4章の補足: SPFから確認するネットワーク

4章では、SPFレコードを確認した際に、多数のネットワークが存在していました。しかし、これらの情報を全て精査するのはネットワークの領域であり、メールの運用者からすれば直感的ではありません。

```
~ $ dig +noall +ans txt gmail.com       | grep 'v=spf1'
gmail.com.		206	IN	TXT	"v=spf1 redirect=_spf.google.com"

~ $ dig +noall +ans txt _spf.google.com | grep 'v=spf1'
_spf.google.com.	283	IN	TXT	"v=spf1 ip4:74.125.0.0/16 ip4:209.85.128.0/17 ip6:2001:4860:4864
→  ::/56 ip6:2404:6800:4864::/56 ip6:2607:f8b0:4864::/56 ip6:2800:3f0:4864::/56 ip6:2a00:1450:
→  4864::/56 ip6:2c0f:fb50:4864::/56 ~all"
```

SPFレコードで指定されたIPの有効性を確認したい場合、各IPアドレスをWeb上で検索するのが一番早いでしょう。おそらく、AS情報やIPの情報をまとめているサイトが見つかるので、安全性に気をつけた上でアクセスしてください。

もし手動で調べたい場合は、以下のようにwhois[^90-whois]で確認するなどすれば、どの事業者が持っているIPであるかがある程度わかることがあります。

```
~ $ for ip in 74.125.0.0 209.85.128.0 2001:4860:4864:: 2404:6800:4864:: 2607:f8b0:4864::
→  2800:3f0:4864:: 2a00:1450:4864:: 2c0f:fb50:4864:: ; do echo -n "($ip) " ; 
→  whois $ip | grep -i -e netname -e nic-hdl | head -n 1 ; done
(74.125.0.0) NetName:        GOOGLE
(209.85.128.0) NetName:        GOOGLE
(2001:4860:4864::) NetName:        GOOGLE-IPV6
(2404:6800:4864::) netname:        GOOGLE_IPV6_AP-20080930
(2607:f8b0:4864::) NetName:        GOOGLE-IPV6
(2800:3f0:4864::) nic-hdl:     GAS7
(2a00:1450:4864::) netname:        IE-GOOGLE-20091005
(2c0f:fb50:4864::) netname:        google-kenya-inet6num
```

[^90-whois]: 世間的には whois は利用を控える方向に進んでいる印象です https://manual.iij.jp/ct/help/79159429.html

\clearpage
