# Сторонние компоненты

Что Sora ставит вместе с собой. Движки скачиваются с выпусков их авторов и
сверяются по SHA-256 из [`packaging/engines/engines.lock`](packaging/engines/engines.lock);
Sora их не изменяет.

## Движки

| Компонент | Версия | Где | Лицензия | Исходный код |
| --- | --- | --- | --- | --- |
| sing-box-lx (на базе sing-box 1.14.3) | 1.14.3-lx.14 | Linux, Windows | GPL-3.0-or-later с условием автора о названии | https://github.com/Leadaxe/sing-box-lx/tree/v1.14.3-lx.14 |
| Xray-core | 26.3.27 | Linux, Windows | MPL-2.0 | https://github.com/XTLS/Xray-core/tree/v26.3.27 |
| mihomo | 1.19.32 | Linux, Windows (сборка compatible) | GPL-3.0 | https://github.com/MetaCubeX/mihomo/tree/v1.19.32 |
| zapret (tpws, nfqws) | 72.1 | Linux | MIT, © bol-van | [`third_party/zapret`](third_party/zapret) |

## Приложение

| Компонент | Версия | Лицензия |
| --- | --- | --- |
| Flutter и Dart | 3.47.6 | BSD-3-Clause |
| Inter | 4.1 | SIL Open Font License 1.1 |
| Country Flags (Hampus Nilsson) | svg-country-flags 1.2.10 | Public Domain |
| grpc | 5.1.0 | Apache-2.0 |
| retry | 3.1.2 | Apache-2.0 |
| cupertino_icons | 2.0.0 | MIT |
| protobuf, fixnum, http2, intl, ffi | 6.1.0, 1.1.1, 2.3.1, 0.20.3, 2.2.0 | BSD-3-Clause |
| shared_preferences, file_selector, url_launcher | 2.5.6, 1.1.0, 6.3.3 | BSD-3-Clause |
| win32 | 6.4.0 | BSD-3-Clause |
| tray_manager, window_manager, nativeapi | 0.7.0, 0.5.2, 0.3.0 | MIT |
| flutter_local_notifications | 22.3.1 | BSD-3-Clause |
| app_links | 7.2.2 | Apache-2.0 |
| webview_all, webview_all_linux, webview_all_windows | 1.4.4 | MIT, © 2021-2026 Abandoft |
| dbus | 0.7.15 | MPL-2.0 |

## Служба

| Компонент | Лицензия |
| --- | --- |
| gRPC, protobuf для Go | Apache-2.0, BSD-3-Clause |
| golang.org/x/sys | BSD-3-Clause |
| go-winio | MIT |
| tailscale/wf | BSD-3-Clause |
| gopacket/gopacket 1.7.4 | BSD-3-Clause |

Тексты лицензий: GPL-3.0 в файле `LICENSE`, Inter в `Inter-LICENSE.txt`, zapret в `zapret-LICENSE.txt` пакета `sora-core`. Лицензии остальных компонентов лежат в их исходном коде по ссылкам выше и на pub.dev.

## WebView All

Исходный код: https://github.com/abandoft/webview_all/tree/1.4.4

Linux- и Windows-плагины сохранены в `app/third_party` с правками жизненного цикла,
выбранного языка и сбора метаданных запросов. Происхождение и объём правок описаны
в их `README.md`.

Copyright 2021-2026 [Abandoft](https://github.com/abandoft)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## gopacket

Источник: https://github.com/gopacket/gopacket/tree/v1.7.4

Copyright (c) 2012 Google, Inc. All rights reserved.
Copyright (c) 2009-2011 Andreas Krennmair. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
   * Neither the name of Andreas Krennmair, Google, nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Noto Sans

Арабский, бенгальский, деванагари, тайский, армянский и грузинский шрифты включены без изменений. CJK 2.004 сокращён до символов интерфейса и переименован в Sora CJK; остальные символы используют шрифты системы.

- Arabic: Version 2.013; ttfautohint (v1.8.4.16-eb64); Copyright 2022 The Noto Project Authors (https://github.com/notofonts/arabic)
- Bengali: Version 3.011; ttfautohint (v1.8.4.16-eb64); Copyright 2025 The Noto Project Authors (https://github.com/notofonts/bengali)
- Devanagari: Version 2.007; ttfautohint (v1.8.4.16-eb64); Copyright 2022 The Noto Project Authors (https://github.com/notofonts/devanagari)
- Thai: Version 2.002; ttfautohint (v1.8.4.7-5d5b); Copyright 2022 The Noto Project Authors (https://github.com/notofonts/thai)
- Armenian: Version 2.008; ttfautohint (v1.8.4.7-5d5b); Copyright 2022 The Noto Project Authors (https://github.com/notofonts/armenian)
- Georgian: Version 2.005; ttfautohint (v1.8.4.7-5d5b); Copyright 2022 The Noto Project Authors (https://github.com/notofonts/georgian)
- CJK SC: 2.004, subset for interface; © 2014-2021 Adobe (http://www.adobe.com/).

This Font Software is licensed under the SIL Open Font License,
Version 1.1.

This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font
creation efforts of academic and linguistic communities, and to
provide a free and open framework in which fonts may be shared and
improved in partnership with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply to
any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software
components as distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to,
deleting, or substituting -- in part or in whole -- any of the
components of the Original Version, by changing formats or by porting
the Font Software to a new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed,
modify, redistribute, and sell modified and unmodified copies of the
Font Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components, in
Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the
corresponding Copyright Holder. This restriction only applies to the
primary font name as presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created using
the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
