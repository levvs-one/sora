# Sora's Linux WebView patch

Source: [webview_all_linux 1.4.4](https://pub.dev/packages/webview_all_linux/versions/1.4.4), MIT, [Abandoft](https://github.com/abandoft/webview_all). The upstream license is preserved in `LICENSE`.

The local changes forward WebKit process termination, disconnect callbacks before releasing their owner, and await native disposal once. Sora can release a crashed browser and retry after a completed page load.

`setPreferredLanguages` uses `webkit_web_context_set_preferred_languages`, covering HTTP Accept-Language, navigator.language and JavaScript locale. `networkEvents` forwards completed resource metadata for HAR: URL, method, response status, headers and observed resource duration. It does not fetch or retain response bodies. Resource signals use the WebView as their weak owner; native disposal and the Dart subscription both stop delivery.

Remove this override when upstream provides equivalent lifecycle, language and metadata support. Native language/HAR and repeated-open tests run in a hidden X11 session; app tests cover ownership, cancellation and retries.
