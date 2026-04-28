# DNSBL

免責事項: 以下に示すブロックリストの中には、商用利用が禁止されているなどの利用規約を持つブロックリストが含まれます。本文書では、メールの送信者として、メールの受信ログ等から報告されたブロックリストの原因を調査する、といった観点での紹介です。メール受信サーバに組み込み恒常的に利用する目的ではなく、ブロックされた原因の情報を参照することにおいては問題ないと考えていますが、責任は負いかねますので、ご自身や団体で必ず各サービスの利用規約をご確認ください。

## 概要

SPF、DKIM、DMARCを乗り越えたあなたは、メールサーバから数百、数千のメール送信を試みたとすれば、いくらかのメールはメール送信に失敗することでしょう。その原因は、世界には多数のブロックリストが存在し、大手のメールプロバイダは、メールの受信時に、メール送信者のIPやメールアドレスのドメインを元にブロックリストの情報を参照し、さらに、メール本文を独自のフィルタで確認し、それぞれの判断によって、メールを受信するか、あるいは拒否するか決定するためです。

ブロックリストは、主にRFC 5782[^20-rfc5728]と呼ばれる形式で情報が提供されます。multirblによると、2026年4月現在304のリストが存在するようです[^20-multirbl]。これらのいずれかのブロックリストを参照しているはずです。

それらのメールを受信するサーバは、送信元IPアドレス、例えば `192.0.2.99`を元に、ブロックリストに問い合わせを行います。具体的には、 `99.2.0.192.list.example.com` のように、オクテットごとに逆順にしたIPのサブドメインについて、ブロックリストにAレコードの問い合わせを行います。この際、`127.0.0.0/8`に属するIPが名前解決された場合は、そのリストに該当すると判断できます。

例えば、後述するSpamhausのテスト接続[^20-spamhaus-test]を用いると、以下のような結果を得ることができます。

```
~ $ dig +noall +ans @a.gns.spamhaus.org test.dbl.spamhaus.org
test.dbl.spamhaus.org.	60	IN	A	127.0.1.2
```

名前解決が失敗(NXDOMAIN)となった場合は、対象のIPアドレスはブロックリストに登録されていないことを示します。

```
~ $ dig @a.gns.spamhaus.org example.com.dbl.spamhaus.org

; <<>> DiG 9.10.6 <<>> @a.gns.spamhaus.org example.com.dbl.spamhaus.org
; (4 servers found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 64690
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 2048
;; QUESTION SECTION:
;example.com.dbl.spamhaus.org.	IN	A
(省略)
```

これらをまとめて実行するのに、前述の multirbl や BlackListChecker[^20-blc] といったサービスが存在します。ただし、こういったサービスに入力された情報がどのように利用されるかが不安な場合は、上記の例のように、手元で名前解決をして確認をしたり、各サービスの公式ページからクエリを行うのが良いでしょう。

[^20-multirbl]: https://multirbl.valli.org/list/
[^20-rfc5728]: https://datatracker.ietf.org/doc/html/rfc5782
[^20-spamhaus-test]: https://www.spamhaus.org/faqs/domain-blocklist/#how-can-i-test-the-dbl
[^20-blc]: https://blacklistchecker.com/check

## 傾向と対策

### 初めてメール配信を行う場合

メール運用を開始してよく聞かれるのは、ウォームアップ[^20-warmup]が失敗することです。メールはレピュテーション（評判）が大事です。突然、大量にメールを送り始めることができずにメールが拒否されるのは、あなたが問題ないメールを送ろうと努力したとしても、それは、外から見た場合にはスパムと見分けがつかないためです。

具体的な方法論はありませんが、参考URLや「メール ウォームアップ方法」などで多数の文献がヒットすると思うので、調べて実施して見ましょう。

### 共有されたIPを利用する場合

SPF/DKIM/DMARCがいずれもPASSの状態で、かつ、あまり大量にはメールを送信していないにもかかわらずメールが送信できない場合、過去に不正なメール利用をすでに行なってしまっている可能性があると考えましょう。

ブロックリストに登録されている場合、不正なメール中継サーバとして利用されているといった、サーバ自身が実際に意図しない不正なメールを送信している場合があります。不正なメールを送信している場合に、後述のブロックリストに登録されている場合があるため、サーバ上のメール送信機構のログや、外部の25番ポート宛のトラフィックを観察しましょう。

サーバが利用するIPが専用IPではなく共用IPである場合は、割り当てられたIPを使っていた以前の利用者が原因である可能性があります。この場合、基本的には自力で対処はできないことが多いです。可能であれば、別のIPが割り当て操作を行いましょう[^20-ip-gacha]。

### 長期間運用中にメール送信がブロックリストによって失敗し始めた場合

メールを送信するのが初めてでもなく、利用中のIPは独占しているにも関わらず、メールのログ上でブロックリストに登録されていることを確認した場合、あなたの運用しているメールサーバや、メールサーバを利用するアプリケーションを契機として、実害のあるメールが送信されている可能性があります。

そういったケースでは、単一のブロックリストではなく、多数のブロックリストに同時に登録されているかもしれません。後述の、それぞれのブロックリストを確認すると良いでしょう。

IPがブロックリストに登録されていない場合は、メール本文中のドメインや文章によってブロックされている可能性もあります。最近、送信するメールの本文が書き変わっていないかを確認しましょう。

以上を踏まえた上で、主要ブロックリストの中でも抑えておくべきサーバや、特別な手続きが必要なブロックリストを紹介します。

[^20-warmup]: 参考 https://learn.microsoft.com/ja-jp/dynamics365/customer-insights/journeys/warmup-process-email-marketing

\clearpage

## 主要なブロックリスト

### Spamhaus

世界一有名なブロックリストです。このリストにIPが登録されていると、主要なメールサーバではメール受信を拒否するか迷惑メールとして扱われることでしょう。エラーメッセージにSpamhausと入っている場合、メールを受信したサーバは、ZEN Blocklist[^20-zen] (`zen.spamhaus.org`)などを参照し、拒否を行なっていることになります。そのため、SpamhausのReputation Checker[^20-spamhaus-rc]にて、メールを送信した元のIPで確認を行いましょう。主に、以下の4つのいずれかにリスティングされていることでしょう。IPをチェックしたページ上にどのリストに登録されているかが示され、どのようなメールを送信したために登録されたかと対処方法が書かれているため、しっかり読んで対処しましょう。

- Spamhaus Blocklist (SBL)
- Combined Spam Sources blocklist (CSS)
- Exploits Blocklist (XBL)
- Policy Blocklist(PBL)

この中でも特筆すべきはPolicy Blocklist(PBL)です。メール送信の質を改善したとしても、このブロックリストは解除されません。Spamhausへ、IP管理者によるマニュアルの対応が必要です。このブロックリストは、Spamhausが「メールを送信するはずのない、インターネットの利用者などのエンドユーザ用のIP」と判断したものです。PBLのページ[^20-spamhaus-pbl]に詳細は記載されていますが、おおまかに、以下の2つの方針をとらないといけません。

1. 共有の単一IPを利用している場合: Spamhausに解除申請を行う。解除の有効期間は最大1年間で、制限されるたびに申請を行う必要がある
2. あなたが /24 以上のネットワークを所有している場合: 案内[^20-spamhaus-for-isp]に従い、ISPポータルからPBLの解除申請を行う

ここでは、特に 1. について伝えます。

[^20-zen]: https://www.spamhaus.org/blocklists/zen-blocklist/
[^20-spamhaus-rc]: https://check.spamhaus.org/
[^20-spamhaus-pbl]: https://www.spamhaus.org/blocklists/policy-blocklist/
[^20-spamhaus-for-isp]: https://www.spamhaus.org/faqs/policy-blocklist-pbl/#who-is-eligible-for-an-isp-pbl-account
[^20-ip-gacha]: いわゆるIPガチャです。いいIPに巡り合うまで頑張りましょう。

\clearpage

もしあなたがPBLに該当している場合、以下のような表示が確認できます。「I am running my own mail server」にチェックを入れ、Next Stepsに進みましょう。

![Spamhaus PBLの入力フォーム例(1)](20-PBL-example-1.png){ width=80% }

\clearpage

次のフォームで、名前とメールアドレスを入力してください。本人認証用のメールが程なく届きますので、クリックしたら完了[^20-idcf]です。

![Spamhaus PBLの入力フォーム例(2)](20-PBL-example-2.png){ width=80% }

[^20-idcf]: IDC Frontierのページによると、申請時に理由を書く場合があるので、指示に従って、なぜPBLの解除が必要であるのか英語で記載しましょう。 https://faq.idcf.jp/faq/show/283?site_domain=default

### Proofpoint

`icloud.com` が採用しているフィルタです。RFC 5782形式の公開情報を提供していないため、 https://www.proofpoint.com/us/ipcheck にアクセスして確認を行いましょう。Spamhausの理由ごとにブロックリストが用意されているのと異なり、Proofpointではブロックの理由を確認することができません[^20-attacker]。


[^20-attacker]: 「ブロックの理由につきましては、攻撃者も同じように質問してきますので理由をお伝えすることはできませんので、ご了承ください。」 https://www.proofpoint.com/jp/support-services/ip-blocked-faq

## レピュテーション

ブロックリストを運営する会社が、独自に、何らかの方法でメールを送信するサーバや、メール送信に使用されるドメインを評価し、メール送信者を許すか許さないか、という判断をしているものを紹介しました。

しかし、大多数のユーザには問題ないが、ごく一部のユーザがコンピュータウィルスに掛かってしまったなどで、短期間で大量のスパムを送ってしまった場合、全てのメール送信を停止してしまうのは平等ではありません。実際には、評価には、「このIPはメールを送信していいかも」から「このIPは送信したらまずいかも」といったグラデーションがあります。そのグラデーションをレピュテーション(評判)といい、いくつかの会社が提供しています。

週に1回など定期的に見ることで、運営しているメールサーバの外部からの評価の参考にすると良いでしょう。短期間に悪化している場合、何か対処が必要な状況が発生しているはずです。

### Cisco Talos

ネットワーク機器でも有名なCiscoが買収したTalosが提供する情報[^20-talos]です。大手であることから信頼できるソースとして扱って良いと考えています。ネットワーク単位でもまとめて見られてとても便利です。

### Senderscore

現Validity社が提供する、 `score.senderscore.com` というDNSBL形式で問い合わせができるレピュテーションの提供サービスです。私の知る限りは相当昔からあり、さまざまなサイトでもレピュテーションの情報源として信頼できるソースとして評価されています[^20-senderscore-source1]。

以下のような問い合わせを行うことで、Aレコードの4オクテット目によって、0〜100のスコアを知ることができます。単一IPに対しての許可ボリュームは10000req/30日[^20-senderscore]だったりと、利用規約を十分に確認の上、利用してください。

```
~ $ dig +noall +ans @nsb00.rpdns.net 70.63.31.50.score.senderscore.com
70.63.31.50.score.senderscore.com. 10 IN A	127.0.4.94
```

[^20-talos]: https://talosintelligence.com/reputation_center/email_rep
[^20-senderscore-source1]: https://sendgrid.kke.co.jp/blog/?p=2827 , https://help.salesforce.com/s/articleView?id=000381531&type=1 など
[^20-senderscore]: https://knowledge.validity.com/s/articles/Accessing-Validity-reputation-data-through-DNS?language=en_US
