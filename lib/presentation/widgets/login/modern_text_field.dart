import 'package:flutter/material.dart';

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData prefixIcon;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    required this.prefixIcon,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ModernTextFieldState createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    // ignore: deprecated_member_use
                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                    : Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _isFocused = hasFocus;
              });
              if (hasFocus) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              validator: widget.validator,
              decoration: InputDecoration(
                labelText: widget.label,
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? Theme.of(context).primaryColor : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                labelStyle: TextStyle(
                  color: _isFocused ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
