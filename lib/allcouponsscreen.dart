import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/all_coupons_model.dart'; // Import your model

class AllCouponsScreen extends StatefulWidget {
  const AllCouponsScreen({super.key});

  @override
  State<AllCouponsScreen> createState() => _AllCouponsScreenState();
}

class _AllCouponsScreenState extends State<AllCouponsScreen> {
  bool _isLoading = true;
  List<AllCouponsModel> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons(); // Fetch the coupons when the screen initializes
  }

  Future<void> _fetchCoupons() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/all-coupons'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list =
            data['coupons']; // Assuming 'coupons' is the key in the response

        setState(() {
          _coupons = list.map((e) => AllCouponsModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching coupons: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'All Coupons',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[900],
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _coupons.length,
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Discount Coupon',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '₹${coupon.couponAmount}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'JIO JI BHARKA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coupon Code: ${coupon.couponCode}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valid from: ${coupon.couponStartDate} To: ${coupon.couponEndDate}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
