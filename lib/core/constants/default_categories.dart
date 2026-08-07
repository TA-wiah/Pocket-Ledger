import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

const _uuid = Uuid();

List<CategoryModel> buildDefaultCategories() {
  return [
    _income('Sales', Icons.point_of_sale, Colors.green),
    _income('Salary', Icons.payments, Colors.teal),
    _income('Investment', Icons.trending_up, Colors.blue),
    _income('Loan Received', Icons.call_received, Colors.indigo),
    _expense('Food', Icons.restaurant, Colors.orange),
    _expense('Transport', Icons.directions_car, Colors.brown),
    _expense('Rent', Icons.home, Colors.purple),
    _expense('Utilities', Icons.bolt, Colors.amber),
    _expense('Shopping', Icons.shopping_bag, Colors.pink),
    _expense('Business', Icons.business_center, Colors.blueGrey),
    _expense('Maintenance', Icons.build, Colors.deepOrange),
    _expense('Entertainment', Icons.movie, Colors.deepPurple),
    _expense('Medical', Icons.local_hospital, Colors.red),
    _expense('Education', Icons.school, Colors.cyan),
    _expense('Purchase', Icons.shopping_cart, Colors.lightBlue),
    _expense('Loan Given', Icons.call_made, Colors.indigoAccent),
    _income('Other', Icons.more_horiz, Colors.grey),
    _expense('Other', Icons.more_horiz, Colors.grey),
  ];
}

CategoryModel _income(String name, IconData icon, Color color) => CategoryModel(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
      applicableType: TransactionType.income,
    );

CategoryModel _expense(String name, IconData icon, Color color) => CategoryModel(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
      applicableType: TransactionType.expense,
    );
