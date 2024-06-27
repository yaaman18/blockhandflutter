import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mnemonic_generator.dart';
import 'package:bs58/bs58.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Hand Bitcoin',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _providedCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mnemonicPhrase = '';
  String _error = '';
  bool _isLoading = false;
  bool _isButtonEnabled = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _providedCodeController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _providedCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    final providedCode = _providedCodeController.text;
    final password = _passwordController.text;

    bool isValid = providedCode.length >= 16 &&
        password.length >= 8 &&
        _isBase58(providedCode) &&
        _isBase58(password);

    setState(() {
      _isButtonEnabled = isValid;
    });
  }

  bool _isBase58(String input) {
    try {
      base58.decode(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _generateMnemonic() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _mnemonicPhrase = '';
      _isCopied = false;
    });

    try {
      final mnemonic = await generateMnemonicPhrase(
        _providedCodeController.text,
        _passwordController.text,
      );
      setState(() {
        _mnemonicPhrase = mnemonic;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonicPhrase)).then((_) {
      setState(() {
        _isCopied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mnemonic phrase copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Hand Bitcoin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Let\'s start using the Bitcoin mnemonic phrase generator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is an app that generates mnemonic phrases for cryptocurrencies. You can regenerate the mnemonic phrase by entering the same providedCode and passwordString. Please use these two strings to store your cryptocurrency.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'هذا تطبيق يقوم بإنشاء عبارات تذكيرية للعملات المشفرة. يمكنك إعادة إنشاء العبارة التذكيرية عن طريق إدخال نفس الرمز المقدم وكلمة المرور. يرجى استخدام هذين السلسلتين لتخزين عملتك المشفرة.',
              style: TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enter a password using characters other than +, /, 0 (zero), O (uppercase \'o\'), I (uppercase \'i\'), and l (lowercase \'L\'). The providedCode must be at least 16 characters long, and the passwordString must be at least 8 characters long.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'الرجاء إدخال كلمة مرور باستخدام أحرف بخلاف +، /، 0 (صفر)، O (حرف \'o\' كبير)، I (حرف \'i\' كبير)، و l (حرف \'L\' صغير). يجب أن يكون الرمز المقدم 16 حرفًا على الأقل، ويجب أن تكون كلمة المرور 8 أحرف على الأقل.',
              style: TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _providedCodeController,
              decoration: const InputDecoration(
                labelText: 'Input code inside ring',
                hintText: 'At least 16 characters, Base58 format',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Input password',
                hintText: 'At least 8 characters, Base58 format',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  (_isButtonEnabled && !_isLoading) ? _generateMnemonic : null,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Keys'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_mnemonicPhrase.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mnemonic Phrase:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_mnemonicPhrase),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: Icon(_isCopied ? Icons.check : Icons.copy),
                      label: Text(_isCopied ? 'Copied' : 'Copy to Clipboard'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
