import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:intl/intl.dart';

part 'balance.g.dart';

abstract class Balance implements Built<Balance, BalanceBuilder> {
  Balance._();

  factory Balance([updates(BalanceBuilder builder)]) = _$Balance;

  @nullable
  String get title;

  @nullable
  String get uuid;

  @nullable
  int get number;

  @nullable
  String get type;

  @nullable
  String get betType;

  @nullable
  double get balance;

  @nullable
  String get balanceLocalizedString;

  @nullable
  String get created;

  @nullable
  String get expire;

  @nullable
  String get startDate;

  @memoized
  String formatDate(String date) {
    return DateFormat.yMMMd().format(
      DateTime.parse(
        date.substring(0, 10),
      ),
    );
  }

  @memoized
  String formattedDate(String date) {
    return DateFormat('yyy-MM-dd').format(DateTime.parse(date));
  }

  @memoized
  String freebetFormatDate(String date) {
    return DateFormat.MMMMd().format(DateTime.parse(date));
  }

  @memoized
  double expiredProgress() {
    int difference = DateTime.parse(formattedDate(expire)).difference(DateTime.parse(formattedDate(created))).inDays;

    int forToday = DateTime.now().difference(DateTime.parse(formattedDate(created))).inDays;
    if (forToday < 1) {
      forToday = 1;
    }
    final expiredPercent = forToday / difference * 100;
    if (expiredPercent.isNaN) {
      return 0;
    }

    final percentageRemainingTime = 100 - expiredPercent;
    if (percentageRemainingTime >= 50.0) {
      return 100.0;
    } else if (percentageRemainingTime >= 20.0) {
      return 50.0;
    } else {
      return 20.0;
    }
  }

  static Serializer<Balance> get serializer => _$balanceSerializer;
}
