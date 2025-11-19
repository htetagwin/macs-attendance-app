import 'package:flutter/material.dart';
import 'package:simple_attendance_app/services/auth_service.dart';
import 'package:simple_attendance_app/shared/loading.dart';
import 'package:simple_attendance_app/constants.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  const Register({super.key, required this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String name = '';
  String role = 'student'; // Default: student
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: backgroundWhite,
            appBar: AppBar(
              backgroundColor: primaryBlack,
              elevation: 0,
              title: Text(
                'Register',
                style: TextStyle(color: accentGold, fontWeight: FontWeight.bold),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Sign In',
                    style: TextStyle(color: accentGold),
                  ),
                  onPressed: () => widget.toggleView(),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // NAME
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: TextStyle(color: primaryBlack.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: accentGold, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: primaryBlack),
                        validator: (val) => val!.trim().isEmpty ? 'Enter your name' : null,
                        onChanged: (val) => name = val.trim(),
                      ),
                      const SizedBox(height: 16.0),

                      // EMAIL
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: primaryBlack.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: accentGold, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: primaryBlack),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => val!.trim().isEmpty ? 'Enter an email' : null,
                        onChanged: (val) => email = val.trim(),
                      ),
                      const SizedBox(height: 16.0),

                      // PASSWORD
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: primaryBlack.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: primaryBlack),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: accentGold, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: primaryBlack),
                        obscureText: true,
                        validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                        onChanged: (val) => password = val,
                      ),
                      const SizedBox(height: 20.0),

                      // USER TYPE: Student / Faculty
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentGold.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I am a...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryBlack,
                              ),
                            ),
                            RadioListTile<String>(
                              title: Text('Student'),
                              value: 'student',
                              groupValue: role,
                              onChanged: (val) => setState(() => role = val!),
                              activeColor: accentGold,
                              secondary: Icon(Icons.school, color: accentGold),
                            ),
                            RadioListTile<String>(
                              title: Text('Faculty'),
                              value: 'faculty',
                              groupValue: role,
                              onChanged: (val) => setState(() => role = val!),
                              activeColor: accentGold,
                              secondary: Icon(Icons.person, color: accentGold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24.0),

                      // REGISTER BUTTON
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
                          foregroundColor: primaryBlack,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          elevation: 2.0,
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => loading = true);
                            final result = await _auth.registerWithEmailAndPassword(
                              email: email,
                              password: password,
                              name: name,
                              role: role, // 'student' or 'faculty'
                            );
                            setState(() {
                              loading = false;
                              error = result ?? 'Registration successful';
                            });

                            // NO NAVIGATION — Wrapper will auto-switch
                          }
                        },
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // ERROR / SUCCESS MESSAGE
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            error,
                            style: TextStyle(
                              color: error.contains('successful') ? successGreen : errorRed,
                              fontSize: 14.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}