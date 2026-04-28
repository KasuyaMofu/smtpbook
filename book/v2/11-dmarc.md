# DMARC

DMARC(Domain-based Message Authentication Reporting and Conformance)の説明は、一般的には、歴史的な流れに沿って、

1. SPF(2006/4)
2. DKIM(2007/5)
3. DMARC(2015/3)

の順で説明するのが妥当のように感じられます。しかし、DMARCの概念は、人の認識からすれば、SPFとDKIMを拡張するような仕様であり、SPF→DKIM→DMARCの順で説明を行うと、DMARCの説明の際に、またSPFとDKIMをおさらいしなければなりません。この流れは非常に煩雑なので、近道をするためにDMARCについての説明を試みます。

DMARCとは何かというのは、RFC 7489[^11-1]に重要な1文があるので、原文を引用します。

[^11-1]: https://datatracker.ietf.org/doc/html/rfc7489

> 2.  Receivers compare the RFC5322.From address in the mail to the SPF and DKIM results, if present, and the DMARC policy in DNS.

DMARCについてはさまざまな解釈があると思いますが、技術的には、「メール本文中の送信元メールアドレスと、SPFやDKIMで得た結果を比較する」ことを行います。これは、1章で解説した「見えるデータ」と「見えないデータ」の一致を比較することに他なりません。このデータ上にあるドメインの一致を「aligned(アライン)」といいます。[^11-aligned]。

[^11-aligned]: HTMLで言う `align="center"` とかのあのアラインです。英語としては整列された、調整された、などの意味があり、本文書内では「一致」として扱います。

**(2章で学ぶこと)**

- `_dmarc.<ドメイン名>` というTXTレコードが存在していれば、DMARCが適用されている
- DMARCは、「見えるデータ」の送信元メールアドレスと「見えないデータ」のドメインを元に、正しいメールかどうかを確認する技術
- DMARCがパスすると、送信元メールアドレスのドメインが指定する正しいメールサーバからメールを受信したことがわかる

\clearpage

## DMARCレコード

DMARCは、 `_dmarc.<ドメイン名>` というドメインにTXTレコードを設定することで、メールを受信するサーバに「DMARCを確認してくださいね」ということを知らせることができます。例えば、以下のような内容です。

```
~ $ dig +noall +ans txt _dmarc.example.com
_dmarc.example.com.	300	IN	TXT	"v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s"

~ $ dig +noall +ans txt _dmarc.gmail.com
_dmarc.gmail.com.	600	IN	TXT	"v=DMARC1; p=none; sp=quarantine; rua=mailto:(※筆者で削除)"
```

今回は、レコード内の詳しい内容には触れません。 `_dmarc.<ドメイン名>` というTXTレコードがあれば、DMARCが適用されていると考えてください。

## DMARCの意味

DMARCは、「見えるデータ」に書かれているヘッダーFromのドメインをベースに、以下の2通りの「見えないデータ」との比較を行います。

- SPFアライメント
- DKIMアライメント

後述するSPFとDKIMも加え、それぞれOKかNGかによって、最大2x2x2x2=16通りが考えられます。世の中には、この16通りか、それに類するそれぞれの場合分けを書いた複雑な条件や表が示されていることが多いです。しかし、そのような複雑な内容は覚える必要はありません。DMARCがパスするのは、以下の2つの条件のどちらかが満たされている場合です。

1. SPFがパスし、SPFアライメントもパスするもの
2. DKIMがパスし、DKIMアライメントもパスするもの

そして、それぞれは、

1. あるドメインのDNSレコードに公開されているIPのメールサーバからメールを受信した
2. あるドメインのDNSレコードで公開されている鍵に対応する、世界で唯一の鍵を持っているサーバが送ったメールを受信した

という意味を持ちます。DMARCがパスすれば、正しいメールサーバがメールを送信したと扱うことができる、という内容となっています。

\clearpage

とは言え、文章では理解が難しいこともあります。あえて表とするならば、以下のような形になるでしょう。

SPF | SPF\
アライメント | DKIM | DKIM\
アライメント | DMARCの結果
:-: | :-: | :-: | :-: | :-: 
o | x | - | - | x
o | o | - | - | o
- | - | o | x | x
- | - | o | o | o

※o = PASS もしくは aligned, x = FAIL もしくは not aligned, - = 考慮しない


以上のことを念頭に、SPFやSPFアライメント、DKIMやDKIMアライメントについて見ていきましょう。

\clearpage
