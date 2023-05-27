library flutter_yandex_smartcaptcha;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_yandex_smartcaptcha/src/web_page_content.dart';

export 'package:flutter_yandex_smartcaptcha/flutter_yandex_smartcaptcha.dart';

/// sitekey — ключ клиентской части.
///
/// languageCaptcha — язык виджета. 'ru' | 'en' | 'be' | 'kk' | 'tt' | 'uk' | 'uz' | 'tr';
/// testMode — включение работы капчи в режиме тестирования. Пользователь всегда будет получать задание. Используйте это свойство только для отладки и тестирования.
/// isWebView — запуск капчи в WebView. Используется для повышения точности оценки пользователей при добавлении капчи в мобильные приложения с помощью WebView.
/// invisible — невидимая капча.
/// shieldPosition — расположение блока с уведомлением об обработке данных.
/// hideShield — скрыть блок с уведомлением об обработке данных.
/// colorBackground — цвет фона

class CaptchaConfig {
  String siteKey;
  bool testMode;
  String languageCaptcha;
  bool invisible;
  bool hideShield;
  bool isWebView;
  String shieldPosition;
  Color? colorBackground;

  CaptchaConfig(
      {required this.siteKey,
      this.testMode = false,
      this.languageCaptcha = 'ru',
      this.invisible = false,
      this.hideShield = false,
      this.isWebView = true,
      this.shieldPosition = 'bottom-right',
      this.colorBackground});
}

class YandexSmartCaptcha extends StatefulWidget {
  final CaptchaConfig captchaConfig;
  final VoidCallback? challengeViewOpenCallback;
  final VoidCallback? challengeViewCloseCallback;
  final VoidCallback? networkErrorCallback;
  final Function(String) tokenResultCallback;
  final bool Function(Uri uriPolicy)? shouldOpenPolicy;

  const YandexSmartCaptcha(
      {required this.captchaConfig,
      required this.tokenResultCallback,
      this.challengeViewCloseCallback,
      this.challengeViewOpenCallback,
      this.networkErrorCallback,
      this.shouldOpenPolicy,
      Key? key})
      : super(key: key);

  @override
  State<YandexSmartCaptcha> createState() => _YandexSmartCaptchaState();
}

class _YandexSmartCaptchaState extends State<YandexSmartCaptcha> {
  late final WebPageCaptchaContent _webPageCaptchaContent;
  late InAppWebViewController webViewController;

  final InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        transparentBackground: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  @override
  void initState() {
    super.initState();
    final CaptchaConfig captchaConfig = widget.captchaConfig;
    _webPageCaptchaContent = WebPageCaptchaContent(
        siteKey: captchaConfig.siteKey,
        testMode: captchaConfig.testMode,
        languageCaptcha: captchaConfig.languageCaptcha,
        invisible: captchaConfig.invisible,
        hideShield: captchaConfig.hideShield,
        isWebView: captchaConfig.isWebView,
        shieldPosition: captchaConfig.shieldPosition);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.captchaConfig.colorBackground != null ? (widget.captchaConfig.colorBackground ?? Colors.transparent) : Colors.transparent,
      child: InAppWebView(
        initialOptions: options,
        initialData: InAppWebViewInitialData(data: _webPageCaptchaContent.yandexSmartCaptchaWebContent),
        androidOnPermissionRequest: (controller, origin, resources) async {
          return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
        },
        shouldOverrideUrlLoading: (controller, shouldOverrideUrlLoadingRequest) async {
          final Uri? url = shouldOverrideUrlLoadingRequest.request.url;

          if (url != null) {
            final bool result = widget.shouldOpenPolicy?.call(url) ?? true;
            return result ? Future.value(NavigationActionPolicy.ALLOW) : Future.value(NavigationActionPolicy.CANCEL);
          } else {
            return Future.value(NavigationActionPolicy.ALLOW);
          }
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint('consoleMessage:${consoleMessage.toString()}');
        },
        onWebViewCreated: (InAppWebViewController controller) {
          webViewController = controller;

          controller.addJavaScriptHandler(
              handlerName: 'tokenHandler',
              callback: (args) {
                widget.tokenResultCallback.call(' ${args.toString()} ');
              });

          controller.addJavaScriptHandler(
              handlerName: 'challengeVisibleEvent',
              callback: (args) {
                widget.challengeViewOpenCallback?.call();
              });

          controller.addJavaScriptHandler(
              handlerName: 'challengeHiddenEvent',
              callback: (args) {
                widget.challengeViewCloseCallback?.call();
              });

          controller.addJavaScriptHandler(
              handlerName: 'networkErrorEvent',
              callback: (args) {
                widget.networkErrorCallback?.call();
              });
        },
      ),
    );
  }
}
