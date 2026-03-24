import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'vault_page.dart';

class VaultLockPage extends StatefulWidget {
  const VaultLockPage({super.key});

  @override
  State<VaultLockPage> createState() => _VaultLockPageState();
}

class _VaultLockPageState extends State<VaultLockPage> {
  final LocalAuthentication _auth = LocalAuthentication();

  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  static String? _savedPin;

  bool _isFirstTime = false;
  bool _showPinSetup = false;
  bool _biometricAvailable = true;

  String _error = "";

  @override
  void initState() {
    super.initState();
    _isFirstTime = _savedPin == null;
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      _biometricAvailable = await _auth.canCheckBiometrics;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _authenticateBiometric() async {
    final success = await _auth.authenticate(
      localizedReason: "Unlock your private vault",
      options: const AuthenticationOptions(biometricOnly: true),
    );
    if (success && mounted) _openVault();
  }

  void _submitPin() {
    final pin = _pinController.text.trim();

    if (pin.length < 6) {
      setState(() => _error = "PIN must be 6 digits");
      return;
    }

    if (_isFirstTime) {
      if (pin != _confirmPinController.text.trim()) {
        setState(() => _error = "PINs do not match");
        return;
      }
      _savedPin = pin;
      _openVault();
    } else {
      if (pin == _savedPin) {
        _openVault();
      } else {
        setState(() => _error = "Incorrect PIN");
      }
    }
  }

  void _openVault() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildCard(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme) {
    return Container(
      key: ValueKey(_showPinSetup),
      width: 420,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(blurRadius: 40, color: Colors.black.withOpacity(.08)),
        ],
      ),
      child: _isFirstTime
          ? (_showPinSetup ? _buildSetPin(theme) : _buildIntro(theme))
          : _buildUnlock(theme),
    );
  }

  // --------------------------------------------------
  // INTRO (FIRST TIME)
  // --------------------------------------------------
  Widget _buildIntro(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _vaultIcon(theme),
        const SizedBox(height: 24),
        Text(
          "Private Vault",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _featureRow(Icons.lock, "End-to-end file protection"),
        _featureRow(Icons.fingerprint, "PIN & biometric security"),
        _featureRow(Icons.visibility_off, "Hidden from gallery & apps"),
        const SizedBox(height: 32),
        _primaryButton("Get Started", () {
          setState(() => _showPinSetup = true);
        }),
      ],
    );
  }

  // --------------------------------------------------
  // SET PIN
  // --------------------------------------------------
  Widget _buildSetPin(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _vaultIcon(theme),
        const SizedBox(height: 20),
        Text(
          "Set Vault PIN",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _pinBox(_pinController, "Enter PIN"),
        const SizedBox(height: 16),
        _pinBox(_confirmPinController, "Confirm PIN", error: _error),
        const SizedBox(height: 28),
        _primaryButton("Secure Vault", _submitPin),
      ],
    );
  }

  // --------------------------------------------------
  // UNLOCK
  // --------------------------------------------------
  Widget _buildUnlock(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _vaultIcon(theme),
        const SizedBox(height: 20),
        Text(
          "Unlock Vault",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _pinBox(_pinController, "Enter PIN", error: _error),
        const SizedBox(height: 24),
        _primaryButton("Unlock", _submitPin),
        if (_biometricAvailable) ...[
          const SizedBox(height: 20),
          Text("or", style: theme.textTheme.bodySmall),
          IconButton(
            onPressed: _authenticateBiometric,
            icon: const Icon(Icons.fingerprint),
            iconSize: 48,
            color: theme.primaryColor,
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------
  // UI PARTS
  // --------------------------------------------------
  Widget _vaultIcon(ThemeData theme) {
    return Container(
      height: 90,
      width: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(.2),
            theme.primaryColor.withOpacity(.05),
          ],
        ),
      ),
      child: Icon(Icons.lock_outline, size: 42, color: theme.primaryColor),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _pinBox(
    TextEditingController controller,
    String label, {
    String? error,
  }) {
    return TextField(
      controller: controller,
      maxLength: 6,
      keyboardType: TextInputType.number,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(letterSpacing: 8, fontSize: 22),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        errorText: error?.isEmpty ?? true ? null : error,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
