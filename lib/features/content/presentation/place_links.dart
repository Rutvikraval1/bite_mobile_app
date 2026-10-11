import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/toast_service.dart';
import '../domain/entities/bite_card.dart';

/// External links for a place (phone, maps, reservations, delivery, menu).
/// Everything opens a real app / website — nothing is booked or ordered
/// in-app, so toasts only ever say what is being opened.
abstract final class PlaceLinks {
  /// Digits (and a leading +) of [phone], or null if there is none.
  static String? dialable(String? phone) {
    if (phone == null) return null;
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return cleaned.replaceAll('+', '').length < 3 ? null : cleaned;
  }

  static String _query(BiteCard place) => [
        place.title,
        if ((place.address ?? '').trim().isNotEmpty) place.address!.trim(),
      ].join(' ');

  static Uri mapsSearch(BiteCard place) => Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': _query(place)},
      );

  static Uri directions(BiteCard place) {
    final destination = _query(place);
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return Uri.https('maps.apple.com', '/', {'daddr': destination});
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
  }

  static Uri googleSearch(String q) =>
      Uri.https('www.google.com', '/search', {'q': q});

  static Uri website(BiteCard place) =>
      googleSearch('${_query(place)} official website');

  static Uri menu(BiteCard place) => googleSearch('${_query(place)} menu');

  static Uri openTable(BiteCard place) =>
      Uri.https('www.opentable.com', '/s', {'term': _query(place)});

  static Uri resy(BiteCard place) =>
      googleSearch('${_query(place)} reservations site:resy.com');

  static Uri doorDash(BiteCard place) =>
      Uri.https('www.doordash.com', '/search/store/${place.title}/');

  static Uri uberEats(BiteCard place) =>
      Uri.https('www.ubereats.com', '/search', {'q': place.title});

  static Uri grubhub(BiteCard place) =>
      Uri.https('www.grubhub.com', '/search', {'queryText': place.title});

  /// Opens [uri] outside the app; shows [opening] first and a failure toast
  /// if no app can handle it.
  static Future<bool> open(Uri uri, {String? opening}) async {
    if (opening != null) ToastService.instance.show(opening);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ToastService.instance.show("⚠️ Couldn't open link");
      return ok;
    } catch (e) {
      debugPrint('[place_links] launch failed: $e');
      ToastService.instance.show("⚠️ Couldn't open link");
      return false;
    }
  }

  /// Starts a phone call to the place. Returns false if it has no number.
  static Future<bool> call(BiteCard place) async {
    final number = dialable(place.phone);
    if (number == null) {
      ToastService.instance.show('No phone number listed');
      return false;
    }
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!ok) ToastService.instance.show("⚠️ Calling isn't available here");
      return ok;
    } catch (e) {
      debugPrint('[place_links] call failed: $e');
      ToastService.instance.show("⚠️ Calling isn't available here");
      return false;
    }
  }
}
