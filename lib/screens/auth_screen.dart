import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/main.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/services/social_auth_service.dart';
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/nametag_helper.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _socialAuthService = SocialAuthService();
  bool _isLogin = true;
  bool _usePhone = false; // Toggle între Email/Parolă și Telefon/OTP
  String _email = '';
  String _password = '';
  String _phone = '';
  String _smsCode = '';
  String? _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSendingOtp = false;
  bool _isSocialLoading = false;

  void _trySubmit() async {
    if (_usePhone) {
      // În modul Telefon/OTP, nu folosim submit-ul standard de email/parolă
      return;
    }
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    if (isValid == null || !isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseFillAllFields),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // ✅ LOGIN FLOW
        final loginCred = await _auth.signInWithEmailAndPassword(
            email: _email.trim(), password: _password.trim());
        // Asigură avatar și wallet dacă user-ul vechi nu are
        if (loginCred.user != null) {
          NabourNametag.ensureAvatar(loginCred.user!.uid);
          TokenService().ensureWalletExists(loginCred.user!.uid);
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeBack),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // ✅ NAVIGHEAZĂ DIRECT CĂTRE AUTHWRAPPER (care va detecta user-ul și merge la MapScreen)
          // Folosim un mic delay pentru a permite SnackBar-ului să se afișeze
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (ctx) => const AuthWrapper()),
            );
          }
        }
      } else {
        // ✅ REGISTRATION FLOW
        final regCred = await _auth.createUserWithEmailAndPassword(
            email: _email.trim(), password: _password.trim());

        // Creează profilul cu avatar Nabour + wallet de tokeni
        if (regCred.user != null) {
          final name = _email.trim().split('@').first;
          await NabourNametag.initUserProfile(
            uid: regCred.user!.uid,
            displayName: name,
            email: _email.trim(),
          );
          await TokenService().ensureWalletExists(regCred.user!.uid);
        }

if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎉 Cont creat cu succes!'),
          Text('📧 Email: ${_email.trim()}'),
          Text(l10n.welcomeToNabour),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
  
  // ✅ NAVIGHEAZĂ DIRECT CĂTRE AUTHWRAPPER (care va detecta user-ul și merge la MapScreen)
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (ctx) => const AuthWrapper())
  );
 }
 return;
} 
    } on FirebaseAuthException catch (e) {
      String message = 'A apărut o eroare.';
      if (e.code == 'user-not-found') {
        message = 'Nu există niciun cont cu această adresă de email.';
      } else if (e.code == 'wrong-password') {
        message = 'Parola introdusă este incorectă.';
      } else if (e.code == 'weak-password') {
        message = 'Parola este prea slabă.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Există deja un cont cu această adresă de email.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresa de email nu este validă.';
      } else if (e.code == 'too-many-requests') {
        message = 'Prea multe încercări eșuate. Încercați din nou mai târziu.';
      } else if (e.message != null) {
        message = e.message!;
        }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error: $e', error: e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unexpectedError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetPassword() async {
    // Validăm email-ul înainte de a trimite cererea
    if (_email.trim().isEmpty || !_email.contains('@')) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseEnterValidEmail),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.debug('Attempting to send password reset email to: ${_email.trim()}');
      
      await _auth.sendPasswordResetEmail(
        email: _email.trim(),
        actionCodeSettings: ActionCodeSettings(
          url: 'https://friendsride-app.firebaseapp.com/__/auth/action',
          androidPackageName: 'com.florin.nabour',
          iOSBundleId: 'com.florin.nabour',
        ),
      );
      
      Logger.debug('Password reset email sent successfully to: ${_email.trim()}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email de resetare trimis la ${_email.trim()}!\n\n'
              'IMPORTANT: Verificați:\n'
              '• Folderul Inbox\n'
              '• Folderul Spam/Junk\n'
              '• Folderul Promoții\n'
              '• Poate dura până la 10 minute să ajungă\n\n'
              'Dacă nu îl găsiți, verificați că adresa este corectă.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 15),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Logger.debug('FirebaseAuthException in password reset: ${e.code} - ${e.message}');
      
      String message = 'A apărut o eroare la trimiterea email-ului de resetare.';
      if (e.code == 'user-not-found') {
        message = 'Nu există niciun cont cu această adresă de email.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresa de email nu este validă.';
      } else if (e.code == 'too-many-requests') {
        message = 'Prea multe cereri de resetare. Încercați din nou mai târziu.';
      } else if (e.message != null) {
        message = e.message!;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      Logger.error('General error in password reset: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.errorResettingPassword);
              },
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startPhoneVerification() async {
    // Validare minimă pentru număr (+40...)
    final trimmed = _phone.trim();
    if (trimmed.isEmpty || trimmed.length < 7) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidPhoneNumber), backgroundColor: Colors.amber),
      );
      return;
    }

    setState(() { _isSendingOtp = true; _verificationId = null; _smsCode = ''; });
    FocusScope.of(context).unfocus();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: trimmed,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.autoAuthCompleted), backgroundColor: Colors.green),
            );
          } catch (e) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorAutoAuth(e.toString())), backgroundColor: Colors.red),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          if (!mounted) return;
          setState(() { _isSendingOtp = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare verificare: ${e.message ?? e.code}'), backgroundColor: Colors.red),
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (!mounted) return;
          setState(() {
            _isSendingOtp = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Codul a fost trimis prin SMS'), backgroundColor: Colors.blue),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSendingOtp = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare trimitere OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _smsCode.trim().length < 4) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterSmsCode), backgroundColor: Colors.amber),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCode.trim(),
      );
      await _auth.signInWithCredential(cred);
      final user = _auth.currentUser;
      if (user != null) {
        // Asigură profilul (nume, telefon, avatar, wallet)
        final phone = user.phoneNumber ?? _phone;
        final name = (user.displayName != null && user.displayName!.isNotEmpty) 
            ? user.displayName! 
            : 'Vecin';
            
        await NabourNametag.initUserProfile(
          uid: user.uid,
          displayName: name,
          phoneNumber: phone,
          email: user.email,
        );
        await NabourNametag.ensureAvatar(user.uid);
        await TokenService().ensureWalletExists(user.uid);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificat prin telefon'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // ✅ NAVIGHEAZĂ DIRECT CĂTRE AUTHWRAPPER (care va detecta user-ul și merge la MapScreen)
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => const AuthWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cod invalid sau expirat: ${e.message ?? e.code}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare verificare OTP: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle Email/Telefon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Email'),
                        selected: !_usePhone,
                        onSelected: (v) {
                          setState(() { _usePhone = false; });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Telefon'),
                        selected: _usePhone,
                        onSelected: (v) {
                          setState(() { _usePhone = true; });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_usePhone) ...[
                    TextFormField(
                      key: const ValueKey('phone'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduceți numărul de telefon.';
                        }
                        return null;
                      },
                      onSaved: (value) => _phone = value ?? '',
                      onChanged: (value) => _phone = value,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefon (ex: +40 7xx xxx xxx)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('otp'),
                            onChanged: (v) => _smsCode = v,
                            decoration: const InputDecoration(labelText: 'Cod SMS'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSendingOtp ? null : _startPhoneVerification,
                          child: _isSendingOtp ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Trimite codul'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading) const CircularProgressIndicator(),
                    if (!_isLoading)
                      ElevatedButton(
                        onPressed: _verifyOtp,
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.verifyAndAuthenticate);
                          },
                        ),
                      ),
                  ] else ...[
                  TextFormField(
                    key: const ValueKey('email'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduceți adresa de email.';
                      }
                      if (!value.contains('@')) {
                        return 'Introduceți o adresă de email validă.';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value ?? '',
                    onChanged: (value) => _email = value,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('password'),
                    validator: (value) {
                      if (value == null || value.length < 7) {
                        return 'Parola trebuie să aibă cel puțin 7 caractere.';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value ?? '',
                    onChanged: (value) => _password = value,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Parolă',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  // Câmpul pentru confirmarea parolei - doar la înregistrare
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('confirmPassword'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirmați parola.';
                        }
                        if (value != _password) {
                          return 'Parolele nu se potrivesc.';
                        }
                        return null;
                      },
                      onSaved: (value) => {},
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirmă Parola',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  if (_isLoading) const CircularProgressIndicator(),
                  if (!_isLoading)
                    ElevatedButton(
                      onPressed: _trySubmit,
                      child: Text(_isLogin ? '🔑 Autentificare' : '🆕 Creează Cont'),
                    ),
                  if (!_isLoading)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          // Resetăm vizibilitatea parolelor când schimbăm modul
                          _isPasswordVisible = false;
                          _isConfirmPasswordVisible = false;
                        });
                      },
                      child: Text(_isLogin
                          ? '🆕 Nu am cont - Înregistrare'
                          : '🔑 Am deja cont - Autentificare'),
                    ),
                  if (!_isLoading && _isLogin)
                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Am uitat parola'),
                    ),
                  
                  // ✅ NOU: Social Login Buttons
                  if (!_isLoading && !_usePhone) ...[
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('SAU'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSocialLoginButtons(),
                  ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        // Google Sign In
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSocialLoading ? null : _signInWithGoogle,
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 20),
            ),
            label: const Text('Continuă cu Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apple Sign In (iOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSocialLoading ? null : _signInWithApple,
              icon: const Icon(Icons.apple, size: 20),
              label: const Text('Continuă cu Apple'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (Theme.of(context).platform == TargetPlatform.iOS) const SizedBox(height: 12),
        // Facebook Sign In
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSocialLoading ? null : _signInWithFacebook,
            icon: const Icon(Icons.facebook, size: 20, color: Color(0xFF1877F2)),
            label: const Text('Continuă cu Facebook'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSocialLoading = true;
    });

    try {
      final userCredential = await _socialAuthService.signInWithGoogle();
      if (userCredential != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.welcomeBack),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (ctx) => const AuthWrapper()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la autentificare Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isSocialLoading = true;
    });

    try {
      final userCredential = await _socialAuthService.signInWithApple();
      if (userCredential != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.welcomeBack),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (ctx) => const AuthWrapper()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la autentificare Apple: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isSocialLoading = true;
    });

    try {
      // Temporar: în loc de login cu Facebook (poate da erori de configurare),
      // deschidem pagina aplicației.
      final url = Environment.facebookPageUrl;
      if (url.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facebook vine curând pentru promovare.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Nu s-a putut deschide $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la autentificare Facebook: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }
}