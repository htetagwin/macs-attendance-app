import 'package:flutter/material.dart';
import 'package:simple_attendance_app/services/auth_service.dart';
import 'package:simple_attendance_app/constants.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth < 600 ? 24.0 : screenWidth < 1200 ? 28.0 : 32.0;
    final double labelFontSize = screenWidth < 600 ? 16.0 : screenWidth < 1200 ? 18.0 : 20.0;
    final double buttonFontSize = screenWidth < 600 ? 14.0 : screenWidth < 1200 ? 16.0 : 18.0;
    final double padding = screenWidth < 600 ? 12.0 : screenWidth < 1200 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: primaryBlack,
        elevation: 0,
        title: Text(
          'Sign In',
          style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: titleFontSize),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.person, color: accentGold, size: screenWidth < 600 ? 24.0 : 28.0),
            label: Text(
              'Register',
              style: TextStyle(color: accentGold, fontSize: buttonFontSize),
            ),
            onPressed: () => widget.toggleView(),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding * 2),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: padding),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Email',
                  labelText: 'Email',
                  labelStyle: TextStyle(color: primaryBlack, fontSize: labelFontSize),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryBlack, width: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: accentGold, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => email = val.trim()),
              ),
              SizedBox(height: padding),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Password',
                  labelText: 'Password',
                  labelStyle: TextStyle(color: primaryBlack, fontSize: labelFontSize),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryBlack, width: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: accentGold, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                onChanged: (val) => setState(() => password = val),
              ),
              SizedBox(height: padding),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGold,
                    foregroundColor: primaryBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    elevation: 2.0,
                    padding: EdgeInsets.symmetric(horizontal: padding * 2, vertical: padding),
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      final result = await _auth.signInWithEmailAndPassword(email, password);
                      if (result == null) {
                        setState(() {
                          error = 'Invalid email or password';
                          _isLoading = false;
                        });
                      }
                      // NO NAVIGATION — Wrapper will auto-switch
                    }
                  },
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: primaryBlack, strokeWidth: 2),
                        )
                      : Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: buttonFontSize),
                        ),
                ),
              ),
              SizedBox(height: padding),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: TextStyle(color: errorRed, fontSize: labelFontSize),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}