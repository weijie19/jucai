import 'package:flutter/material.dart';

const List<String> selectableIconKeys = [
  // 餐饮
  'restaurant',
  'fastfood',
  'local_cafe',
  // 交通
  'directions_bus',
  'directions_car',
  'local_gas_station',
  'flight',
  // 购物
  'shopping_cart',
  'shopping_bag',
  'checkroom',
  // 居家
  'home',
  'water_drop',
  'bolt',
  'wc',
  // 娱乐运动
  'sports_esports',
  'movie',
  'sports_soccer',
  'fitness_center',
  // 医疗
  'local_hospital',
  'medication',
  // 人情
  'favorite',
  'card_giftcard',
  // 其他生活
  'school',
  'pets',
  'phone_iphone',
  'wifi',
  'brush',
  'spa',
  'child_care',
  // 收入
  'payments',
  'account_balance',
  'trending_up',
  'work',
  'savings',
  'redeem',
  // 兜底
  'more_horiz',
];

IconData iconFor(String key) {
  switch (key) {
    // 餐饮
    case 'restaurant':
      return Icons.restaurant;
    case 'fastfood':
      return Icons.fastfood;
    case 'local_cafe':
      return Icons.local_cafe;
    // 交通
    case 'directions_bus':
      return Icons.directions_bus;
    case 'directions_car':
      return Icons.directions_car;
    case 'local_gas_station':
      return Icons.local_gas_station;
    case 'flight':
      return Icons.flight;
    // 购物
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'checkroom':
      return Icons.checkroom;
    // 居家
    case 'home':
      return Icons.home;
    case 'water_drop':
      return Icons.water_drop;
    case 'bolt':
      return Icons.bolt;
    case 'wc':
      return Icons.wc;
    // 娱乐运动
    case 'sports_esports':
      return Icons.sports_esports;
    case 'movie':
      return Icons.movie;
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'fitness_center':
      return Icons.fitness_center;
    // 医疗
    case 'local_hospital':
      return Icons.local_hospital;
    case 'medication':
      return Icons.medication;
    // 人情
    case 'favorite':
      return Icons.favorite;
    case 'card_giftcard':
      return Icons.card_giftcard;
    // 其他生活
    case 'school':
      return Icons.school;
    case 'pets':
      return Icons.pets;
    case 'phone_iphone':
      return Icons.phone_iphone;
    case 'wifi':
      return Icons.wifi;
    case 'brush':
      return Icons.brush;
    case 'spa':
      return Icons.spa;
    case 'child_care':
      return Icons.child_care;
    // 收入
    case 'payments':
      return Icons.payments;
    case 'account_balance':
      return Icons.account_balance;
    case 'trending_up':
      return Icons.trending_up;
    case 'work':
      return Icons.work;
    case 'savings':
      return Icons.savings;
    case 'redeem':
      return Icons.redeem;
    // 账户
    case 'account_balance_wallet':
      return Icons.account_balance_wallet;
    case 'chat':
      return Icons.chat;
    case 'credit_card':
      return Icons.credit_card;
    // 兜底
    case 'more_horiz':
      return Icons.more_horiz;
    default:
      return Icons.label;
  }
}
