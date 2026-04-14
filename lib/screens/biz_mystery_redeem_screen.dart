import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/services/nabour_functions.dart';

/// Comerciant: validează codul de reducere Mystery Box (`nabourMysteryBoxMerchantValidate`).
class BusinessMysteryRedeemScreen extends StatefulWidget {
  final BusinessProfile profile;

  const BusinessMysteryRedeemScreen({super.key, required this.profile});

  @override
  State<BusinessMysteryRedeemScreen> createState() =>
      _BusinessMysteryRedeemScreenState();
}

class _BusinessMysteryRedeemScreenState
    extends State<BusinessMysteryRedeemScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _codeCtrl.text.trim();
    if (raw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu un cod valid (minim 6 caractere).')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await NabourFunctions.instance
          .httpsCallable('nabourMysteryBoxMerchantValidate')
          .call<Map<String, dynamic>>({'code': raw});
      final title = res.data['offerTitle'] as String? ?? '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty
                ? 'Cod validat cu succes.'
                : 'Cod validat: $title',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _codeCtrl.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Nu s-a putut valida codul.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mystery Box — ${widget.profile.businessName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Introdu sau scanează codul afișat clientului după deschiderea cutiei pe hartă.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Cod reducere',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!_loading) _submit();
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Validează codul'),
            ),
            const SizedBox(height: 24),
            Text(
              'Codul se marchează ca folosit; trebuie să aparțină unei oferte de la locația ta.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
