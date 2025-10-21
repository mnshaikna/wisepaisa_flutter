import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart'; // for expression parsing

class CalculatorBottomSheet extends StatefulWidget {
  const CalculatorBottomSheet({super.key});

  @override
  State<CalculatorBottomSheet> createState() => _CalculatorBottomSheetState();
}

class _CalculatorBottomSheetState extends State<CalculatorBottomSheet> {
  String _expression = '';
  String _result = '';

  void _append(String value) {
    setState(() => _expression += value);
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = '';
    });
  }

  void _calculate() {
    try {
      final exp = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      Parser p = Parser();
      Expression expObj = p.parse(exp);
      ContextModel cm = ContextModel();
      double eval = expObj.evaluate(EvaluationType.REAL, cm);
      setState(() => _result = eval.toString());
    } catch (e) {
      setState(() => _result = 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '7',
      '8',
      '9',
      '÷',
      '4',
      '5',
      '6',
      '×',
      '1',
      '2',
      '3',
      '-',
      '0',
      '.',
      '=',
      '+',
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_expression, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              _result,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                final key = buttons[index];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (key == '=') {
                      _calculate();
                    } else {
                      _append(key);
                    }
                  },
                  child: Text(key, style: const TextStyle(fontSize: 20)),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    if (_result.isNotEmpty && _result != 'Error') {
                      Navigator.pop(context, double.tryParse(_result));
                    } else {
                     // Navigator.pop(context);
                    }
                  },
                  child: const Text('Use Result'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
