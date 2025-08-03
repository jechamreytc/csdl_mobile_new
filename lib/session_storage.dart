import 'dart:html' as html;

class SessionStorage {
  static const String url = "http://localhost/finalhk/api/";

  // static const String url = "http://192.168.1.136/finalhk/api/";

  static void setItem(String key, String value) {
    html.window.localStorage[key] = value;
  }

  static String? getItem(String key) {
    return html.window.localStorage[key];
  }

  static void clear() {
    html.window.localStorage.clear();
  }
}
