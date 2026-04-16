import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/layout_text_scale.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Două tab-uri: Termeni și Confidențialitate
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.termsConditionsTitle),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: const Icon(Icons.gavel_rounded), text: AppLocalizations.of(context)!.termsConditions),
              Tab(icon: const Icon(Icons.shield_outlined), text: AppLocalizations.of(context)!.privacy),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Conținutul pentru primul tab (Termeni și Condiții)
            _buildTermsAndConditionsTab(context),
            
            // Conținutul pentru al doilea tab (Confidențialitate)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.privacyPolicyContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pentru construirea conținutului din primul tab
  Widget _buildTermsAndConditionsTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ls = layoutScaleFactor(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.termsConditionsTitle,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildLegalSection(
              context,
              title: AppLocalizations.of(context)!.generalProvisions,
              content: AppLocalizations.of(context)!.generalProvisionsText,
            ),

            _buildLegalSection(
              context,
              title: AppLocalizations.of(context)!.standardWaitTime,
              content: AppLocalizations.of(context)!.standardWaitTimeText,
            ),

            const SizedBox(height: 16),
             // ── Disclaimer plăți & Sustenabilitate ──────────────────────
             Container(
               padding: scaledFromLTRB(16, 16, 16, 16, ls),
               decoration: BoxDecoration(
                 color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                 borderRadius: BorderRadius.circular(16 * ls),
                 border: Border.all(
                   color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                   width: 1.5,
                 ),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(
                         Icons.info_outline_rounded,
                         color: const Color(0xFF7C3AED),
                         size: MediaQuery.textScalerOf(context).scale(20),
                       ),
                       SizedBox(width: 8 * ls),
                       Text(
                         'Modelul de sustenabilitate Nabour',
                         style: textTheme.titleSmall?.copyWith(
                           fontWeight: FontWeight.w800,
                           color: const Color(0xFF7C3AED),
                         ),
                       ),
                     ],
                   ),
                   SizedBox(height: 10 * ls),
                   Text(
                     'Trial gratuit și suport pentru comunitate',
                     style: textTheme.bodyMedium?.copyWith(
                       fontWeight: FontWeight.w700,
                     ),
                   ),
                   SizedBox(height: 6 * ls),
                    Text(
                      'Nabour oferă o perioadă de testare gratuită de 7 zile pentru toți utilizatorii noi. '
                      'Ulterior, pentru a asigura mentenanța și sustenabilitatea platformei, este necesară '
                      'plata unei sume modice de 10 RON/lună (persoane fizice) sau 15 RON/lună (firme/comercianți). Această sumă reprezintă un abonament prin care '
                      'utilizatorul primește pachetul de tokeni necesari pentru funcționarea serviciilor în luna respectivă.\n\n'
                      'Important: Aplicația NU intermediază plăți pentru curse între utilizatori. '
                      'Nabour rămâne o platformă de ajutor reciproc unde vecinii se ajută dezinteresat.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                 ],
               ),
             ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context, {required String title, required String content}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, 
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75), 
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

}