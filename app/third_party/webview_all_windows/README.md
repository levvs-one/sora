# Sora's Windows WebView patch

This package is part of [`webview_all`](https://github.com/abandoft/webview_all).

Source: webview_all_windows 1.4.4, MIT, Abandoft. The upstream license remains in `LICENSE`.

The local bridge exposes WebView2's documented DevTools protocol calls and four Network events through its existing method/event channels. Sora sets Accept-Language without replacing the actual browser User-Agent and collects request/response metadata for HAR. Bodies are not fetched; the native Network buffers are disabled. Event registration is idempotent, callbacks hold a weak lifetime marker, and disposal removes every registration before the WebView owner is released.

The Dart additions are `setPreferredLanguages`, `enableNetworkEvents`, `networkEvents` and `callDevToolsProtocolMethod`. The generated Pigeon API is unchanged. Dart formatting is normalized to the project's SDK.

Native Windows CI checks HTTP/JavaScript language, real GET/POST/error responses, repeated opening, page loading and process release. Remove the override when upstream exposes equivalent APIs and lifecycle guarantees.
