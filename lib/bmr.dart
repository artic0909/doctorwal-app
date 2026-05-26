import 'package:flutter/material.dart';

class BMRCalculatorScreen extends StatefulWidget {
  const BMRCalculatorScreen({super.key});

  @override
  State<BMRCalculatorScreen> createState() => _BMRCalculatorScreenState();
}

class _BMRCalculatorScreenState extends State<BMRCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _gender = 'Male';
  double _activityLevel = 1.2;

  final List<Map<String, dynamic>> _activityOptions = [
    {'label': 'Sedentary (little or no exercise)', 'multiplier': 1.2},
    {'label': 'Lightly active (exercise 1-3 days/week)', 'multiplier': 1.375},
    {'label': 'Moderately active (exercise 3-5 days/week)', 'multiplier': 1.55},
    {'label': 'Active (exercise 6-7 days/week)', 'multiplier': 1.725},
    {'label': 'Very active (hard exercise 6-7 days/week)', 'multiplier': 1.9},
  ];

  double? _bmrResult;
  double? _tdeeResult;

  void _calculateBMR() {
    if (_formKey.currentState!.validate()) {
      double age = double.parse(_ageController.text);
      double height = double.parse(_heightController.text);
      double weight = double.parse(_weightController.text);

      double bmr;
      if (_gender == 'Male') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }

      setState(() {
        _bmrResult = bmr;
        _tdeeResult = bmr * _activityLevel;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        title: const Text('BMR Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Calculate Your Basal Metabolic Rate",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 5),
            const Text(
              "Find out how many calories your body burns at rest.",
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = 'Male'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _gender == 'Male' ? const Color(0xFF0D47A1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF0D47A1).withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.male, color: _gender == 'Male' ? Colors.white : const Color(0xFF0D47A1)),
                                const SizedBox(width: 8),
                                Text("Male", style: TextStyle(color: _gender == 'Male' ? Colors.white : const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = 'Female'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _gender == 'Female' ? const Color(0xFFE53935) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE53935).withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.female, color: _gender == 'Female' ? Colors.white : const Color(0xFFE53935)),
                                const SizedBox(width: 8),
                                Text("Female", style: TextStyle(color: _gender == 'Female' ? Colors.white : const Color(0xFFE53935), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _ageController,
                          label: "Age",
                          suffix: "years",
                          icon: Icons.cake,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInputField(
                          controller: _heightController,
                          label: "Height",
                          suffix: "cm",
                          icon: Icons.height,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _weightController,
                    label: "Weight",
                    suffix: "kg",
                    icon: Icons.monitor_weight_rounded,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withAlpha(51)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        isExpanded: true,
                        value: _activityLevel,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D47A1)),
                        items: _activityOptions.map((option) {
                          return DropdownMenuItem<double>(
                            value: option['multiplier'],
                            child: Text(option['label'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _activityLevel = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _calculateBMR,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      shadowColor: const Color(0xFF0D47A1).withAlpha(100),
                    ),
                    child: const Text("CALCULATE BMR", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_bmrResult != null && _tdeeResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String suffix, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 20),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget _buildResultSection() {
    int bmr = _bmrResult!.round();
    int tdee = _tdeeResult!.round();
    int loss = tdee - 500;
    int gain = tdee + 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(76), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              const Text("Your BMR", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$bmr", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0, left: 5),
                    child: Text("Calories/day", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                child: Text("Maintenance (TDEE): $tdee kcal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text("Action Plan Based on Your Result", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0), // Light orange background for warning/note
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withAlpha(100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.3),
                    children: [
                      TextSpan(text: "Disclaimer: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: "This is a system-generated action plan for general reference. For personalized advice, please consult a "),
                      TextSpan(text: "Dietitian or Nutrition specialist", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: " through our app."),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildActionCard(
          title: "To Maintain Weight",
          calories: "$tdee kcal/day",
          desc: "Consume this amount to stay at your current weight.",
          color: Colors.blue,
          icon: Icons.balance_rounded,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: "To Lose Weight (0.5 kg/week)",
          calories: "$loss kcal/day",
          desc: "A safe, sustainable calorie deficit for weight loss.",
          color: Colors.orange,
          icon: Icons.trending_down_rounded,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: "To Gain Weight (0.5 kg/week)",
          calories: "$gain kcal/day",
          desc: "A safe surplus for muscle building and weight gain.",
          color: Colors.green,
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String calories, required String desc, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 13)),
                const SizedBox(height: 2),
                Text(calories, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
