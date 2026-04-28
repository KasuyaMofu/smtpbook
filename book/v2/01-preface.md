# はじめに

近年、日本では、Google社が「メール送信者のガイドライン（旧称: 一括送信ガイドライン）[^01-1]」発表してからというもの、2024年1月には神奈川県の高校出願システムにおけるメール送信の事件[^01-2]などが発生し、メールが届かないことへの実害が広く知られるようになりました。また、メール管理者やISPだけでなく、様々な人々がメールへ関心を寄せることとなりました。

[^01-1]: https://support.google.com/a/answer/81126?hl=ja
[^01-2]: https://www.itmedia.co.jp/news/articles/2402/09/news114.html

そんな世界の状況において、メールの送信したい場合にまず考えることは、「いかにしてメール配信サーバやメール送受信サーバを自分で運用をしないか」ということは、メールを管理する立場の方であれば、同意いただけるかと思います。明確な理由がない限り、高度なメールの知識を持ったエンジニアが運用しているであろう、メール送信のSaaSを利用することをオススメします。

それでも、どうしても、自前でメール送信を行わなければならない、またはメールの運用を行わなければならない、つまり、**SMTPを取り扱わないといけない方**に向けて、この本は書かれています。

\clearpage

## 本書で扱うこと、扱わないこと

この本では、メール送信サーバを運用する管理者のために、以下の内容について取り扱います。メール通信の内容と、メールサーバに保管されたメールの実データを用いながら、以下の事柄について解説を行い、**メール運用に関するトラブルシューティングに、最低限必要な知識を学ぶこと**を目的とします。

- SMTP(Simple Mail Transfer Protocol)
- SPF(Sender Policy Framework)
- DKIM(DomainKeys Identified Mail)
- DMARC(Domain-based Message Authentication Reporting and Conformance)
- DNSBL(Blacklists and Whitelists)[^10-DNSBL]

本書では、以下の内容については取り扱いません。[^10-request]

- DMARC Feedback / DMARCレポート
- RFC 8617: ARC(Authenticated Received Chain)[^10-arc]
- BIMI[^10-bimi]
- DKIM2[^10-dkim2]
- RFC 8058: Signaling One-Click Functionality for List Email Headers[^10-oneclick]
- (メール送信における)ウォームアップ
- メールの本文等の情報を使用したフィルタリング

特に、ARCについては 2025年12月に、「Concluding the ARC Experiment」[^10-ARC]という文書が提案されています。現在導入されているサーバや、新規に導入するサーバ対しての仕様見直しに影響が出るかは不明ですが、必要であれば一読ください。

[^10-DNSBL]: RFC 5782 に基づく表記であり、 White や Black に差別的な意図は含まれません。本書では、特に断りがない場合、「ブロック(block)」や「ブロックリスト(block list)」として表記を行います。
[^10-request]: 検証を行うためのメールボリュームが足りず、メールプロバイダの協力が必要です。要望があれば、理論部分の解説のみ追加するかもしれません。
[^10-arc]: https://datatracker.ietf.org/doc/html/rfc8617
[^10-bimi]: https://datatracker.ietf.org/doc/html/draft-brand-indicators-for-message-identification
[^10-dkim2]: https://datatracker.ietf.org/doc/html/draft-ietf-dkim-dkim2-spec-01.html
[^10-oneclick]: List-Unsubscribeヘッダのこと。 https://datatracker.ietf.org/doc/html/rfc8058
[^10-ARC]: https://datatracker.ietf.org/doc/html/draft-adams-arc-experiment-conclusion-01.html

\clearpage

## 本書のPoCと利用したソフトウェアについて

この文書に含まれるメールの例は、以下のURLのリポジトリの成果物を用いています。 `docker compose` が実行できる環境であれば、誰もが検証可能です。 動作の際には、いくらかの注意事項がありますので、リポジトリのREADME等をご確認ください。

[https://github.com/KasuyaMofu/smtpbook](https://github.com/KasuyaMofu/smtpbook)

本書で使用している主要なソフトウェアのバージョンは以下の通りです。

- macOS Sequoia 15.7.5
- Docker Desktop 4.68.0

尚、コンテナ上では、以下のソフトウェア、および動作に必要な付随するソフトウェアを導入しています。 

- Postfix
- Dovecot
- Rspamd
- PowerDNS

また、以前の版では、以下のソフトウェアを使用していましたが、廃止しました。()内は使用していた版です。

- Unbound(v1)

## レイアウトについて

この本は見開き表示に最適化されています。ブラウザやPDFビューワで閲覧する場合は、2ページ表示に切り替えてご覧ください。

## 参考文献

本書を作成するにあたって、参照した文献は以下のURLに記載しております。

[https://github.com/KasuyaMofu/smtpbook/blob/main/book/reference.md](https://github.com/KasuyaMofu/smtpbook/blob/main/book/reference.md)

## 免責事項

本書に記載された内容は、情報の提供のみを目的としています。本書を用いた開発、製作、運用は、必ずご自身の責任と判断によって行ってください。本書の情報による開発、製作、運用等の結果について、著者はいかなる責任も負いません。
