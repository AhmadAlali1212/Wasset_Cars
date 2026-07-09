// services/subscription_service.dart
import 'dart:convert';

import 'package:mators_car/models/subscription_model.dart';
import 'package:mators_car/models/transaction_model.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  Future<Map<String, dynamic>> subscribe(int planId, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('https://api.example.com/subscribe'),
      body: {
        'plan_id': planId.toString(),
        'payment_method': paymentMethod,
      },
    );

    if (response.statusCode == 200) {
      return {
        'subscription': Subscription.fromJson(json.decode(response.body)['subscription']),
        'transaction': Transaction.fromJson(json.decode(response.body)['transaction']),
        'new_balance': json.decode(response.body)['new_balance'],
      };
    } else {
      throw Exception('Failed to subscribe');
    }
  }

  Future<double> chargeWallet(double amount) async {
    final response = await http.post(
      Uri.parse('https://api.example.com/wallet/charge'),
      body: {'amount': amount.toString()},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['new_balance'];
    } else {
      throw Exception('Failed to charge wallet');
    }
  }
}