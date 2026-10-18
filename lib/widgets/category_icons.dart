import 'package:flutter/material.dart';

const List<String> selectableIconKeys = [
  'restaurant',
  'directions_bus',
  'shopping_cart',
  'home',
  'sports_esports',
  'local_hospital',
  'favorite',
  'payments',
  'card_giftcard',
  'trending_up',
  'work',
  'more_horiz',
];

IconData iconFor(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'directions_bus':
      return Icons.directions_bus;
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'home':
      return Icons.home;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'favorite':
      return Icons.favorite;
    case 'payments':
      return Icons.payments;
    case 'card_giftcard':
      return Icons.card_giftcard;
    case 'trending_up':
      return Icons.trending_up;
    case 'work':
      return Icons.work;
    case 'more_horiz':
      return Icons.more_horiz;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet;
    case 'chat':
      return Icons.chat;
    case 'credit_card':
      return Icons.credit_card;
    case 'account_balance':
      return Icons.account_balance;
    case 'savings':
      return Icons.savings;
    default:
      return Icons.label;
  }
}
