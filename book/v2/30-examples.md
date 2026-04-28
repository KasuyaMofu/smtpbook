# SPF/DKIM/DMARC のメールログ実例

最後に、これからメールの運用を始める皆様へメールのやりとりやメールデータを見る際の解像度を高めてもらうため、メールデータのサンプルと、それぞれのシーケンス図をいくつか紹介します。


![メール検証環境の構成](30-00-network.png)

```{caption="メールデータのサンプル 色の凡例"}
@<color>{red,SPFに関係する記述}
@<color>{blue,DKIMに関係する記述}
@<color>{teal,DMARCに関係する記述 ※SPFやDKIMと重複する場合、DMARCの色付けを優先します}
```

\clearpage

## SPF

### SPF=pass(no DKIM,DMARC)

![SPF=pass(no DKIM,DMARC)](30-01-SPFpass.png)

```{caption="SPF=pass(no DKIM,DMARC)のメールデータ"}
Return-Path: <user1@@<color>{red,a.test}>
Received: from spf.mx.b.test (spf.mx.b.test [10.255.2.31])
        by imap.b.test (Postfix) with ESMTPS id 11D113C0B40
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:02 +0900 (JST)
Received: from plain.smtp.a.test (plain.smtp.a.test [@<color>{red,10.255.1.20}])
        by spf.mx.b.test (Postfix) with ESMTPS id D2EC43C0B32
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:01 +0900 (JST)
Authentication-Results: spf.mx.b.test;
        @<color>{red,spf=pass (spf.mx.b.test: domain of user1@a.test designates 10.255.1.20 as }
         @<color>{red,→ permitted sender) smtp.mailfrom=user1@a.test}
Received: from a.test (client.a.test [10.255.1.10])
        by plain.smtp.a.test (Postfix) with SMTP id CF7D13C0B2A
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:00 +0900 (JST)
Message-ID: <20241111225901.7568@a.test>
Date: Mon, 11 Nov 2024 22:59:01 +0900
From: user1@a.test
To:   user1@spf.b.test
Subject: scenario2-1 (mail from user1@a.test)

Hello user1@spf.b.test!
```

\clearpage

### SPF=fail(no DKIM,DMARC)

![SPF=fail(no DKIM,DMARC)のシーケンス図](30-02-SPFfail.png)

```{caption="SPF=fail(no DKIM,DMARC)のメールデータ"}
Return-Path: <user1@@<color>{red,a.test}>
Received: from spf.mx.b.test (spf.mx.b.test [10.255.2.31])
        by imap.b.test (Postfix) with ESMTPS id BF87F3C0B45
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:13 +0900 (JST)
Received: from plain.smtp.x.test (plain.smtp.x.test [@<color>{red,10.255.24.20}])
        by spf.mx.b.test (Postfix) with ESMTPS id A73933C0B48
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:13 +0900 (JST)
Authentication-Results: spf.mx.b.test;
        @<color>{red,spf=fail (spf.mx.b.test: domain of user1@a.test does not designate 10.255.24.20 as}
        @<color>{red,→ permitted sender) smtp.mailfrom=user1@a.test}
Received: from a.test (client.a.test [10.255.1.10])
        by plain.smtp.x.test (Postfix) with SMTP id B38B43C0B45
        for <user1@spf.b.test>; Mon, 11 Nov 2024 22:59:12 +0900 (JST)
Message-ID: <20241111225912.28233@a.test>
Date: Mon, 11 Nov 2024 22:59:13 +0900
From: user1@a.test
To:   user1@spf.b.test
Subject: scenario2-2 (mail from user1@a.test)

Hello user1@spf.b.test!
```

\clearpage

## DKIM

### DKIM=pass(no SPF,DMARC)

![DKIM=pass(no SPF,DMARC)のシーケンス図](30-03-DKIMpass.png)

\clearpage

```{caption="DKIM=pass(no SPF,DMARC)のメールデータ"}
Return-Path: <user1@pass.dkim.a.test>
Received: from dkim.mx.b.test (dkim.mx.b.test [10.255.2.32])
        by imap.b.test (Postfix) with ESMTPS id 5D0923C0B5C
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:30 +0900 (JST)
Received: from dkim.smtp.a.test (dkim.smtp.a.test [10.255.1.21])
        by dkim.mx.b.test (Postfix) with ESMTPS id 2AC753C0B4E
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:30 +0900 (JST)
Authentication-Results: dkim.mx.b.test;
        @<color>{blue,dkim=pass header.d=pass.dkim.a.test header.s=smtpbook header.b=HXOHX5f4}
Received: from pass.dkim.a.test (client.a.test [10.255.1.10])
        by dkim.smtp.a.test (Postfix) with SMTP id 2669F3C0B45
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:29 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=pass.dkim.a.test;}
        @<color>{blue,s=smtpbook; t=1731333570;}
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=0pdj9wqws+KIJQqIWGPQakvN114IPDt1CK4ekSU+NIs=;
        b=HXOHX5f4PMUXvhYONo7sr9GDmcwH8IXk330Y63AA8j+8zydcFC1PPpohjRMDamRvjuVkuV
        98Vr5nA83Jk1Bp0usAWF2jyY68gvsRnczDEINctGmsD54+M7/ET3HHtD3tEMJu2jxvWmmm
        ZyKHgk6NMxYzWjeamCqHFbWQKNKFdhE+sTkW8PfXJMhhwd/id2Si/a20cleERO7BSPWD+2
        dLuwxsjU5iklYWCwyitLBRzN422CGc60SgyPBYZ1bLZlt8I3P5ypC5wpJhKVbKYmtVXFGC
        jtVSWTP15ja3N1ftlqFT94rifbA928h1oCcYBQIgBIDEadL7xqUrvuO30RtwWg==
Message-ID: <20241111225929.22082@pass.dkim.a.test>
Date: Mon, 11 Nov 2024 22:59:29 +0900
From: user1@@<color>{blue,pass.dkim.a.test}
To:   user1@dkim.b.test
Subject: scenario3-1 (mail from user1@pass.dkim.a.test)

Hello user1@dkim.b.test!
```

\clearpage

### DKIM=fail(no SPF,DMARC)

![DKIM=fail(no SPF,DMARC)のシーケンス図](30-04-DKIMfail.png)

\clearpage

```{caption="DKIM=fail(no SPF,DMARC)のメールデータ"}
Return-Path: <user1@fail.dkim.a.test>
Received: from dkim.mx.b.test (dkim.mx.b.test [10.255.2.32])
        by imap.b.test (Postfix) with ESMTPS id E10EC3C0B21
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:43 +0900 (JST)
Received: from dkim.smtp.a.test (dkim.smtp.a.test [10.255.1.21])
        by dkim.mx.b.test (Postfix) with ESMTPS id C879A3C0B66
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:43 +0900 (JST)
Authentication-Results: dkim.mx.b.test;
        @<color>{blue,dkim=fail ("headers rsa verify failed") header.d=fail.dkim.a.test header.s=smtpbook }
        @<color>{blue,→ header.b="UUjtdzq/"}
Received: from fail.dkim.a.test (client.a.test [10.255.1.10])
        by dkim.smtp.a.test (Postfix) with SMTP id B33773C0B21
        for <user1@dkim.b.test>; Mon, 11 Nov 2024 22:59:42 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=fail.dkim.a.test;}
        @<color>{blue,s=smtpbook; t=1731333583;}
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=0pdj9wqws+KIJQqIWGPQakvN114IPDt1CK4ekSU+NIs=;
        b=UUjtdzq/m1EvY948YX5EQnSDvpqi0w0JQgWJMq6hCxuCLpKQkLdMGDB+VfwHsR3cd64lKA
        eeqU5WRt5uX3hsBBwAP3TtmvGFW3T87IoaLi9m9hWGNjN8JQ0KSccqLqbMCj8RGQOgm/Ko
        H8uO2LHznKER9mfdk2bxCsOj35aqISUlcx9E0eRGyH3tAEhYUDR64bq3IORl2/Lf4EO00q
        8FCtw2IrGfDF7VZi8Rh2oKWXadbpF3KQy9LviamqT4kT3pAmdVqH1v9nR3+x9vywnJ7xhb
        azVCkKL+lRnoCz/0oq92PKf1XBrErg7jOotYjZcmfEnk2kew0xE0/KL2+QVYAg==
Message-ID: <20241111225942.24430@fail.dkim.a.test>
Date: Mon, 11 Nov 2024 22:59:43 +0900
From: user1@@<color>{blue,fail.dkim.a.test}
To:   user1@dkim.b.test
Subject: scenario3-2 (mail from user1@fail.dkim.a.test)

Hello user1@dkim.b.test!
```

\clearpage

## DMARC

### DMARC=pass(SPF=pass & SPF aligned, DKIM=pass & DKIM aligned)

SPF

| ヘッダーFrom | user1@pass.dkim.a.test |
| --- | --- |
| Return-Path | user1@pass.dkim.a.test |
| SPFレコード | pass.dkim.a.test "v=spf1 ip4:10.255.1.20/31 -all” |
| 送信元サーバ(IP) | dkim.smtp.a.test(10.255.1.21) |
| 結果 | spf=pass |

DKIM

| ヘッダーFrom | user1@pass.dkim.a.test |
| --- | --- |
| DKIM-Signature d= | d=pass.dkim.a.test |
| 結果 | dkim=pass |

```{caption="DMARC=pass(SPF=pass & SPF aligned, DKIM=pass & DKIM aligned)のメールデータ"}
@<color>{red,Return-Path: <user1@}@<color>{teal,pass.dkim.a.test}@<color>{red,>}
Received: from dmarc.mx.b.test (dmarc.mx.b.test [10.255.2.33])
        by imap.b.test (Postfix) with ESMTPS id 1661E3C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 22:59:59 +0900 (JST)
Received: from dkim.smtp.a.test (dkim.smtp.a.test [@<color>{red,10.255.1.21}])
        by dmarc.mx.b.test (Postfix) with ESMTPS id E2F6D3C0B6A
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 22:59:58 +0900 (JST)
Authentication-Results: dmarc.mx.b.test;
        @<color>{blue,dkim=pass header.d=pass.dkim.a.test header.s=smtpbook header.b=F6rlfsvS;}
        @<color>{red,spf=pass (dmarc.mx.b.test: domain of user1@pass.dkim.a.test designates 10.255.1.21 as}
        @<color>{red,→ permitted sender) smtp.mailfrom=user1@pass.dkim.a.test;}
        @<color>{teal,dmarc=pass (policy=quarantine) header.from=a.test}
Received: from pass.dkim.a.test (client.a.test [10.255.1.10])
        by dkim.smtp.a.test (Postfix) with SMTP id D9ED03C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 22:59:57 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;} @<color>{teal,d=pass.dkim.a.test}@<color>{blue,;}
        @<color>{blue,s=smtpbook; t=1731333598;}
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=4O5lFigIhxLU8If/5QjKchggSnc7Yxld80E41+l39XE=;
        b=F6rlfsvSbuyAeFj5z0P/BpLxYLXbualYDGS0Ufljj4KXmcHfktoSNsMXI8pkBl0iEdzNps
        V2R8TR1xhbp46uJvjV3K10az+F0g5cfcQTo6iqKAxA5oI9fR5YEA7SVGVZT/nMyOYR1yZu
        XgGe8eyfJ373pITFBBH7MjhJqQ/Qfwb1T7e80c3M+ou4NbCGTEc8a//hBOs+iV5dEvZYQQ
        7cu3/fHXE7TTKJi+PyDtvGfoMLrsQaSH3SzGQLOA7V1xDq5etGA8NRL4UQkCNctlkPaDEj
        wDZZxwLM1sB4g4o9B1WtoKSS8uNKK98vLb/4c0n+nhkfTPidw98CMBMWAa1IOw==
Message-ID: <20241111225958.14795@pass.dkim.a.test>
Date: Mon, 11 Nov 2024 22:59:58 +0900
From: user1@@<color>{teal,pass.dkim.a.test}
To:   user1@dmarc.b.test
Subject: scenario4-1 (mail from user1@pass.dkim.a.test)

Hello user1@dmarc.b.test!
```

\clearpage

![DMARC=pass(SPF=pass & SPF aligned, DKIM=pass & DKIM aligned)のシーケンス図](30-05-DMARC1.png)

\clearpage

### DMARC=pass(SPF=pass & SPF aligned, DKIM=fail)

SPF

| ヘッダーFrom | user1@fail.dkim.a.test |
| --- | --- |
| Return-Path | user1@fail.dkim.a.test |
| SPFレコード | "v=spf1 ip4:10.255.1.20/31 -all” |
| 送信元サーバ(IP) | dkim.smtp.a.test(10.255.1.21) |
| 結果 | spf=pass |

DKIM

| ヘッダーFrom | user1@fail.dkim.a.test |
| --- | --- |
| DKIM-Signature d= | d=fail.dkim.a.test |
| 結果 | dkim=fail("headers rsa verify failed") |

```{caption="DMARC=pass(SPF=pass & SPF aligned, DKIM=fail)のメールデータ"}
@<color>{red,Return-Path: <user1@}@<color>{teal,fail.dkim.a.test}@<color>{red,>}
Received: from dmarc.mx.b.test (dmarc.mx.b.test [10.255.2.33])
        by imap.b.test (Postfix) with ESMTPS id 30B583C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:14 +0900 (JST)
Received: from dkim.smtp.a.test (dkim.smtp.a.test [@<color>{red,10.255.1.21}])
        by dmarc.mx.b.test (Postfix) with ESMTPS id 191733C0B74
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:14 +0900 (JST)
Authentication-Results: dmarc.mx.b.test;
        @<color>{blue,dkim=fail ("headers rsa verify failed") header.d=fail.dkim.a.test }
        @<color>{blue,→ header.s=smtpbook header.b=khuhmNBv;}
        @<color>{red,spf=pass (dmarc.mx.b.test: domain of user1@fail.dkim.a.test designates 10.255.1.21 as }
        @<color>{red,→        permitted sender) smtp.mailfrom=user1@fail.dkim.a.test;}
        @<color>{teal,dmarc=pass (policy=quarantine) header.from=a.test}
Received: from fail.dkim.a.test (client.a.test [10.255.1.10])
        by dkim.smtp.a.test (Postfix) with SMTP id 1CD2F3C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:13 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;} @<color>{teal,d=fail.dkim.a.test;}
        @<color>{blue,s=smtpbook; t=1731333614;}
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=4O5lFigIhxLU8If/5QjKchggSnc7Yxld80E41+l39XE=;
        b=khuhmNBvrxEVcu4nhcxLYATWnZ73vXz8tchytQ07ndRxzJRAHWyXw3GF36CyMbzGgH73O3
        zp78BhglJpMtTBtu4EgPO5dX1QIWfC8iBI7z3wzlqehzzJTY4cSTxryXq90iNph84Tr0Q6
        5wpsuuSIVjjQFwLNbYiAnRfQbetaolI1ho9Ld/26YNwfgpZ9ydh0ZqE3z5YuiXYjuD/DHh
        ZChdTDsiecA4b5Igben330RQuwVBiquXTcb1TKO1ppqWJGYJtCgxWaKSNYlSfD3EH/9XKz
        nhANLbVJdRcJridVYP6CKYqXymLk8GsNqUS7ofM/+2LS2B+VuItdCTbhlcpXZA==
Message-ID: <20241111230013.28558@fail.dkim.a.test>
Date: Mon, 11 Nov 2024 23:00:13 +0900
From: user1@@<color>{teal,fail.dkim.a.test}
To:   user1@dmarc.b.test
Subject: scenario4-2 (mail from user1@fail.dkim.a.test)

Hello user1@dmarc.b.test!
```

![DMARC=pass(SPF=pass & SPF aligned, DKIM=fail)のシーケンス図](30-06-DMARC2.png)

\clearpage

### DMARC=pass(SPF=fail, DKIM=pass & DKIM aligned)

SPF

| Return-Path | user1@pass.dkim.a.test |
| --- | --- |
| SPFレコード | pass.dkim.a.test "v=spf1 ip4:10.255.1.20/31 -all” |
| 送信元サーバ(IP) | dkim.smtp.x.test(10.255.24.21) ※SPF範囲外 |
| 結果 | spf=fail |

DKIM

| ヘッダーFrom | user1@pass.dkim.a.test |
| --- | --- |
| DKIM-Signature d= | d=pass.dkim.a.test |
| 結果 | dkim=pass |

DMARC

| ヘッダーFrom | user1@pass.dkim.a.test |
| --- | --- |
| Return-Path | user1@pass.dkim.a.test ※送信元IPがSPF範囲外 |
| DKIM-Signature d= | d=pass.dkim.a.test |
| 結果 | dmarc=pass |

```{caption="DMARC=pass(SPF=fail, DKIM=pass & DKIM aligned)のメールデータ"}
@<color>{red,Return-Path: <user1@}@<color>{teal,pass.dkim.a.test}@<color>{red,>}
Received: from dmarc.mx.b.test (dmarc.mx.b.test [10.255.2.33])
        by imap.b.test (Postfix) with ESMTPS id 02C013C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:35 +0900 (JST)
Received: from dkim.smtp.x.test (dkim.smtp.x.test [10.255.24.21])
        by dmarc.mx.b.test (Postfix) with ESMTPS id DCEFF3C0B78
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:34 +0900 (JST)
Authentication-Results: dmarc.mx.b.test;
        @<color>{blue,dkim=pass header.d=pass.dkim.a.test header.s=smtpbook header.b=ORWUqDxY;}
        @<color>{red,spf=fail (dmarc.mx.b.test: domain of user1@pass.dkim.a.test }
        @<color>{red,→ does not designate 10.255.24.21 as}
        @<color>{red,→ permitted sender) smtp.mailfrom=user1@pass.dkim.a.test;}
        @<color>{teal,dmarc=pass (policy=quarantine) header.from=a.test}
Received: from pass.dkim.a.test (client.a.test [10.255.1.10])
        by dkim.smtp.x.test (Postfix) with SMTP id D91FF3C0B21
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:33 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;} @<color>{teal,d=pass.dkim.a.test}@<color>{blue,;}
        s=smtpbook; t=1731333634;
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=4O5lFigIhxLU8If/5QjKchggSnc7Yxld80E41+l39XE=;
        b=ORWUqDxY5+og4uOLWr6o5egYETOMrISUccxcCLayflr1uSCgel7BsOpSDEM87J+Sx5nUYc
        nhC6L2wTZIV/C6AgcKRYilcT9j5UmHnFyEYNRIrn4gPBYz4jXH2ee9CTGlCmK4WMXDAi6l
        bzvmSRs8PIjBmO7uY02HJQPdgIYIejhyPSzozcirbpBicTOOI4DPbfRW2uAN1UYpXFles8
        T2wj38IM99Ie40F1kEt7MEz9CYjaQk9/p9mRTr8EkZXdjkOqeOfrljPPtKUmgBsLczIp3z
        aAAX9wkgax0qyCkGIaNpvUHaGwtQiz0M9CuwYuP+ZqmfAhQvXAS2MTU/Hyb1Mw==
Message-ID: <20241111230034.7867@pass.dkim.a.test>
Date: Mon, 11 Nov 2024 23:00:34 +0900
From: user1@@<color>{teal,pass.dkim.a.test}
To:   user1@dmarc.b.test
Subject: scenario4-3 (mail from user1@pass.dkim.a.test)

Hello user1@dmarc.b.test!
```

![DMARC=pass(SPF=fail, DKIM=pass & DKIM aligned)のシーケンス図](30-07-DMARC3.png)

\clearpage

### DMARC=fail(SPF=pass & SPF not aligned, DKIM=pass & DKIM not aligned)

最後に、SPFは a.test でパスし、DKIMは y.test でパスしているが、ヘッダーFromは x.test であるため、どちらとも aligned とならずにDMARCがフェイルする例です。

SPF

| Return-Path | user1@a.test |
| --- | --- |
| SPFレコード | a.test "v=spf1 ip4:10.255.1.20/31 -all” |
| 送信元サーバ(IP) | dkim.smtp.a.test(10.255.1.21) |
| 結果 | spf=pass |

DKIM

| ヘッダーFrom | user1@x.test |
| --- | --- |
| DKIM-Signature d= | d=y.test |
| 結果 | dkim=pass |

DMARC

| ヘッダーFrom | user1@x.test |
| --- | --- |
| Return-Path | user1@a.test ※ドメインが相違|
| DKIM-Signature d= | d=y.test ※ドメインが相違|
| 結果 | dmarc=fail |

```{caption="DMARC=fail(SPF=pass & SPF not aligned, DKIM=pass & DKIM not aligned)のメールデータ"}
@<color>{red,Return-Path: <user1@}@<color>{teal,a.test}@<color>{red,>}
Received: from dmarc.mx.b.test (dmarc.mx.b.test [10.255.2.33])
        by imap.b.test (Postfix) with ESMTPS id 91AF63C0B20
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:53 +0900 (JST)
Received: from dkim.smtp.a.test (dkim.smtp.a.test [10.255.1.21])
        by dmarc.mx.b.test (Postfix) with ESMTPS id 765833C0B85
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:53 +0900 (JST)
Authentication-Results: dmarc.mx.b.test;
        @<color>{blue,dkim=pass header.d=y.test header.s=smtpbook header.b=uOhxNxzm;}
        @<color>{red,spf=pass (dmarc.mx.b.test: domain of user1@a.test designates 10.255.1.21 as}
        @<color>{red,→ permitted sender) smtp.mailfrom=user1@a.test;}
        @<color>{teal,dmarc=fail reason="SPF not aligned (relaxed), DKIM not aligned (relaxed)" }
        @<color>{teal,→ header.from=x.test (policy=reject)}
Received: from x.test (client.a.test [10.255.1.10])
        by dkim.smtp.a.test (Postfix) with SMTP id 789F43C0B20
        for <user1@dmarc.b.test>; Mon, 11 Nov 2024 23:00:52 +0900 (JST)
@<color>{blue,DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;} @<color>{teal,d=y.test}@color{blue,; s=smtpbook;}
        t=1731333653;
        h=from:from:reply-to:subject:subject:date:date:message-id:message-id:
         to:to:cc; bh=4O5lFigIhxLU8If/5QjKchggSnc7Yxld80E41+l39XE=;
        b=uOhxNxzmXzrlirTgBELshntqF6xKNgypuq7LAH0Us9K6PVH+H4HpKrjuvkAapKR9MotwMm
        x0SaeitVbawxpftxQi1KC5YaMOjUOepe+boPZ29mHTpVctncYrENxILvPE3gC588G6DAjz
        LUNfS2jdwQvNuntR53DOGy17Vk/EVPWfnsL7DtF9MrZo6c3l4wRi74pG6b8uSEnjPCQ9Ca
        2SBx2JmJpHnGd1dcSIl+aj8lMxDwVaa8saxjciHp81JFfVOV/vzz9ZlPtTwLdfV++i9lNS
        oacORDyKix5XWPeNkA2UkLeCm6NT5PJfbw3QTqwM9T3jh3ic5+pxMYgYkl8NGw==
Message-ID: <20241111230052.26219@x.test>
Date: Mon, 11 Nov 2024 23:00:52 +0900
From: user1@@<color>{teal,x.test}
To:   user1@dmarc.b.test
Subject: scenario4-4 (mail from user1@x.test)

Hello user1@dmarc.b.test!
```

![DMARC=fail(SPF=pass & SPF not aligned, DKIM=pass & DKIM not aligned)のシーケンス図](30-08-DMARC4.png)

