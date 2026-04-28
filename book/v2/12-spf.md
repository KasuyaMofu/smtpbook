# SPF

SPF(Sender Policy Framework)とは、「RFC 7208 Sender Policy Framework (SPF) for Authorizing Use of Domains in Email, Version 1」[^1] に記載されている内容を指します。原文には、具体的なアルゴリズムや概念実装が記載されているなど、とても長い文書となっています。理想的には、全てを理解することが望ましいですが、ここでは、運用上必要な、各種ソフトウェアが示すSPF認証のログと、その後にしなければならないアクションを解説します。

**(3章で学ぶこと)**

- SPFは、見えないデータのエンベロープFromを元に動作を行うこと
- SPFアライメントとは、見えないデータのエンベロープFromと、見えるデータのヘッダーFromのドメインが一致すること
- 所有するドメインのSPFは、なるべく狭く設定しないと悪用される可能性があること


[^1]: https://datatracker.ietf.org/doc/html/rfc7208

\clearpage

## SPFレコード

SPFは、SPFレコードを設定することから全てが始まります。実際にSPFレコードを見てみましょう。SPFレコードは、対象のメールアドレスの @ 以降のドメインに、TXTレコードとして登録され、 `v=spf1` から始まります。例えば、皆さんがよく使われているであろう `@gmail.com` については、 `dig` コマンドを用いて以下のように調べることができます。

```
~ $ dig +noall +ans txt gmail.com       | grep 'v=spf1'
gmail.com.		206	IN	TXT	"v=spf1 redirect=_spf.google.com"

~ $ dig +noall +ans txt _spf.google.com | grep 'v=spf1'
_spf.google.com.	283	IN	TXT	"v=spf1 ip4:74.125.0.0/16 ip4:209.85.128.0/17 ip6:2001:4860:4864
→  ::/56 ip6:2404:6800:4864::/56 ip6:2607:f8b0:4864::/56 ip6:2800:3f0:4864::/56 ip6:2a00:1450:
→  4864::/56 ip6:2c0f:fb50:4864::/56 ~all"
```

SPFレコードの記述の中には、 `~` のような記号を表す限定子(qualifier)、機構(mechanism)、修飾子(Modifier)など[^12-10]の言葉があります。しかし、仕様に関する議論でない限り、それらを区別して呼ぶことは稀でしょう。そのため、本書では「ルール」という言葉で統一します。

[^12-10]: マクロ(Macro)は、今回は取り上げません。もし、 `%{d}` のような記載を見つけた場合は、「SPFマクロ」などで検索し、情報を検索してください。

### ip4, ip6

メールを送信するサーバの接続元IPを指定します。例えば、　`gmail.com`  のSPFレコード冒頭を抜粋すると、「 `gmail.com` は、 74.125.0.0/16のサーバから送信されたれたメールは正規のメールである」と宣言する意味になります。

```
v=spf1 ip4:74.125.0.0/16
```

記述の簡便さから、ネットワークの指定(CIDR, `/24`などの表記のこと)を、自身の利用可能なIPよりも大きく設定してしまう場合があります。例えば、ネットワーク内に `192.0.2.10` と `192.0.2.244` といったIPを持つサーバがあった場合、 `192.0.2.0/24` と記載したくなることでしょう。しかし、これは、 /24 内の全てのサーバ、例えば `192.0.2.127` が、あなたのドメインを正規に利用できるメールサーバとして見なされます。他人がSPF認証を送信できる、つまり、あなたのドメインを利用してスパムを送信できてしまう状態にあるという状況に陥ってしまうため、記述するIPは可能な限り狭めましょう。

また、表記は `ip4` , `ip6` であることに気をつけましょう。 `ip` や `ipvX` ではありません。

### include, redirect

上記の例にある通り、redirectは、他のSPFレコードへリダイレクトするルールです。しかし、実際に目にすることが多いのは include でしょう。例えば、AWSのAmazon SESでカスタムドメインを利用する場合、SPFレコードには以下のように記載することが求められています[^12-aws-spf]。

```
"v=spf1 include:amazonses.com ~all"
```

実際に dig で確認すると、以下のような内容が確認できます。 include は、このように、「あるIPの集合(AWS等)からメールを送信することをSPF上で許可する」という意味合いを持つことが多いです。

```
~ $ dig +noall +ans amazonses.com txt | grep 'v=spf1'
amazonses.com.		834	IN	TXT	"v=spf1 ip4:199.255.192.0/22 ip4:199.127.232.0/22 
→  ip4:54.240.0.0/18 ip4:69.169.224.0/20 ip4:23.249.208.0/20 ip4:23.251.224.0/19 
→  ip4:76.223.176.0/20 ip4:54.240.64.0/18 ip4:76.223.128.0/19 ip4:216.221.160.0/19
→  ip4:206.55.144.0/20 ip4:24.110.64.0/18 -all"
```

`include` と `redirect` は、ルールとしては似ているものなので、一緒として考えていただいて構いません[^12-redirect]。

[^12-aws-spf]: https://docs.aws.amazon.com/ja_jp/ses/latest/dg/mail-from.html#mail-from-set
[^12-redirect]: 経験上、 `redirect` を目にする機会は少なく、エラーとなっていることはさらに少ないはずです。エラー時の参照先に redirect があった場合に仕様を確認する程度で良いと思います

### all

SPFの最後には `~all` か `-all` がついているか確認しましょう。`~` や `-` が全角や特殊なUTFの文字になっていないかの確認と、手前に半角スペースが存在するか、それだけの確認で構いません。

all は、具体的には全てのIPに該当するというルールです。つまり、最後に書くことで、今まで挙げた ip4 や include 等以外の全てのIPに該当するルールを適用します。そこに `~` や `-` がついていることから、「今まで揚げたルールに該当しない全てのIPは、疑わしく判定するか、拒否してほしい」という意味合いになります。

## SPFとSPFアライメント

ここまではSPFについてお伝えしました。それでは、以下のメールデータ例を元に、DMARCのSPFアライメントとは何かをみていきましょう。

SPFやDKIM、DMARCのそれぞれの調査結果は、すべて、「Authentication-Results」というヘッダにまとめて書き込まれます。ここではSPFとSPFアライメントに注目したいので、SPFとDMARCの結果を見て見ましょう。

③の部分では、「エンベロープFromのドメインである a.test は 10.255.1.20 を許可するIPとして指定している」という結果とともに、spf=passしたことがわかります。この結果から、 a.test のTXTレコードに、例えば「ip4:10.255.1.20」と書かれていたと推測ができます。

④の部分では、「ヘッダーFromはa.testであり、ポリシーは quarantine だった」という結果とともにdmarc=passしたことがわかります。この結果では、エンベロープFromとヘッダーFromが一致していることを示します。

さらっと書いてしまいましたが、SPFのアライメントとは、「ヘッダFromのドメインがエンベロープFromのドメインと一致すること」です。1章でも触れた通り、ヘッダFromは見えるデータであり、エンベロープFromは見えないデータです。DMARCがパスしないメールを全て捨て、SPFアライメントがパスし、DMARCをパスするメールだけが受信されていると仮定すれば、見えるデータしかわからないメールクライアントでも、ドメインは正しいIPから送られてきたという確証が得られ、安心してメールを開くことができるというわけです。

```
@<color>{red,Return-Path: <user1@a.test>}                            @<color>{red,③エンベロープFrom(Return-Path)}
Received: from dmarc.mx.b.test (dmarc.mx.b.test [10.255.2.33])
	by imap.b.test (Postfix) with ESMTP id 53B5C204D150
	for <user1@dmarc.b.test>; Mon, 20 Apr 2026 10:30:10 +0900 (JST)
Received: from plain.smtp.a.test (plain.smtp.a.test [10.255.1.20])
	by dmarc.mx.b.test (Postfix) with ESMTP id 43423204D15B
	for <user1@dmarc.b.test>; Mon, 20 Apr 2026 10:30:10 +0900 (JST)
Authentication-Results: dmarc.mx.b.test;
	dkim=none;
	@<color>{red,dmarc=pass} (policy=quarantine) @<color>{red,header.from=a.test};                @<color>{red,②DMARC認証結果}
	@<color>{red,spf=pass} (dmarc.mx.b.test: domain of user1@a.test designates 10.255.1.20
	→  as permitted sender) smtp.mailfrom=user1@a.test                @<color>{red,①SPF認証結果}
                                                                      
Received: from a.test (a.test [10.255.1.10])
	by plain.smtp.a.test (Postfix) with SMTP id 4ACFC204D150
	for <user1@dmarc.b.test>; Mon, 20 Apr 2026 10:30:09 +0900 (JST)
Message-ID: <20260420103009.9002@a.test>
Date: Mon, 20 Apr 2026 10:30:09 +0900
@<color>{red,From: user1@a.test}                                       @<color>{red,④ヘッダーFrom（RFC5322.From）}
To:   user1@dmarc.b.test
Subject: scenario2-3 (mail from user1@a.test)

Hello user1@dmarc.b.test!ß
```

## SPFのトラブルシューティング例

受信できるメールの例を見たので、今度は逆に考えて見ましょう。あなたはメールの運用者で、ユーザにメールが届かなかった場合はどのように考えるべきかを検討しましょう。

SPFをパスしない、もしくはDMARCがパスしなかったメールがある場合、①〜④に対して、具体的には被疑は以下のようになるでしょう。尚、SPFやDMARCは、メールを受信する外部のサーバの名前解決状況にも依存するため、自分では解決できない場合もあります。そのような事象を避けるためには、SPFレコードの新規公開や変更を行う場合は、まずは、TTLを短くして設定・検証を行いましょう。

- ③エンベロープFromが想定した内容でない場合は、メールを送信するサーバ(postfix等)の送信元メールアドレスを確認します
- ④ヘッダFromが想定した内容でない場合は、メールを送信するアプリケーション等の送信元メールアドレスを確認します
- ①SPFの認証結果が想定した内容でない場合は、ドメインに設定されたSPFレコードが誤っているか、存在しません
- ②DMARCの認証結果が想定した内容でない場合は、 `_dmarc.<ドメイン名>` が名前解決できるか確認します。名前解決ができる場合、①〜③が正しければ、それは想定外の事態になります。エラーを起こすサーバとは別のドメインのメール受信者にメールを送信し、DMARCの認証結果を確認します。結果、パスする場合は、パスしないサーバのDMARCの名前解決状況に問題があるため、メール受信者のサーバ管理者に問い合わせを行いましょう

