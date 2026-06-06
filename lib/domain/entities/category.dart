import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TransactionCategory {
  food('Food', Icons.restaurant_rounded, AppColors.foodColor),
  travel('Travel', Icons.flight_rounded, AppColors.travelColor),
  taxi('Taxi/Cab', Icons.directions_car_rounded, AppColors.travelColor),
  delivery('Delivery', Icons.shopping_bag_rounded, AppColors.shoppingColor),
  shopping('Shopping', Icons.shopping_basket_rounded, AppColors.shoppingColor),
  bills('Bills', Icons.receipt_long_rounded, AppColors.billsColor),
  entertainment('Entertainment', Icons.movie_rounded, AppColors.entertainmentColor),
  health('Health', Icons.favorite_rounded, AppColors.healthColor),
  finance('Finance', Icons.trending_up_rounded, AppColors.shoppingColor),
  transfer('Transfer', Icons.swap_horiz_rounded, AppColors.otherColor),
  other('Other', Icons.more_horiz_rounded, AppColors.otherColor);

  final String label;
  final IconData icon;
  final Color color;

  const TransactionCategory(this.label, this.icon, this.color);
}

