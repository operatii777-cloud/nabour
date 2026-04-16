import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/screens/help_article_screen.dart';
import 'package:nabour_app/screens/report_form_screen.dart';
import 'package:nabour_app/screens/career_screen.dart';
import 'package:nabour_app/screens/about_screen.dart';
import 'package:nabour_app/screens/legal_screen.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';

class HelpScreen extends StatefulWidget {
  final bool isPassengerMode;

  const HelpScreen({super.key, this.isPassengerMode = true});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Widget> _buildHelpArticle(String title, AppLocalizations l10n) {
    switch (title) {
      case 'cannotRequestRide':
      case 'Nu pot solicita o cursă': {
        return [
          Text(
            'Dacă întâmpinați probleme la solicitarea unei curse, încercați următoarele soluții:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('• Verificați conexiunea la internet (Wi-Fi sau date mobile).'),
          const Text('• Asigurați-vă că locația GPS este activată.'),
          const Text('• Încercați să restartați aplicația.'),
          Text(l10n.contactSupportIfPersists),
        ];
      }
      case 'rideDidNotHappen':
      case 'Cursa nu a avut loc': {
        return [
          Text(
            l10n.rideDidNotHappenContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.rideStatusInApp),
          Text(l10n.messagesFromDriver),
          Text(l10n.correctLocation),
          const SizedBox(height: 16),
          Text(
            l10n.contactSupportForRefund,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];
      }
      case 'lostItems':
      case 'Obiecte pierdute': {
        return [
          Text(
            l10n.lostItemsContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.contactDriverImmediately),
          Text(l10n.describeLostItem),
          Text(l10n.arrangePickup),
          Text(l10n.reportToSupport),
          const SizedBox(height: 16),
          Text(
            l10n.returnFeeNote,
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
          ),
        ];
      }
      case 'howToUseChat':
      case 'Cum folosești chatul': {
        return [
          Text(
            l10n.helpChatGuideTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helpChatGuideIntro,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpChatWhoSeesTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpChatWhoSeesBody),
          const SizedBox(height: 16),
          Text(
            l10n.helpChatCoverageTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpChatCoverageBody),
          const SizedBox(height: 16),
          Text(
            l10n.helpChatPersistenceTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpChatPersistenceBody),
          const SizedBox(height: 16),
          Text(
            l10n.helpChatPrivacyTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpChatPrivacyBody),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.helpChatTipOMW,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      case 'emergencyAssistanceUsage':
      case 'Utilizarea asistenței de urgență': {
        return [
          Text(
            l10n.emergencyAssistanceUsageContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.call112Quickly),
          Text(l10n.sendLocationToEmergencyContact),
          Text(l10n.reportIncidentToSafetyTeam),
          const SizedBox(height: 16),
          Text(
            l10n.useOnlyRealEmergencies,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ];
      }
      case 'reportAccidentOrUnpleasantEvent':
      case 'Raportează accident sau eveniment neplăcut': {
        return [
          Text(
            l10n.toReportIncident,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.ensureYourSafety),
          Text(l10n.useEmergencyFunctionInApp),
          Text(l10n.describeInDetail),
          Text(l10n.addPhotosIfPossible),
          Text(l10n.cooperateWithInvestigationTeam),
          const SizedBox(height: 16),
          Text(
            l10n.falseReportsCanLead,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
        ];
      }
      case 'howToActivateDriverMode':
      case 'Cum devin șofer?':
      case 'Cum ofer curse vecinilor?': {
        return [
          Text(
            'Pentru a începe să oferi curse voluntare vecinilor tăi, urmează acești pași:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '1. Verifică condițiile',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Trebuie să ai un permis de conducere valabil și o mașină sigură pentru transport.'),
          const SizedBox(height: 12),
          Text(
            '2. Completează profilul',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Asigură-te că ai o poză de profil clară și detaliile mașinii completate.'),
          const SizedBox(height: 12),
          Text(
            '3. Verificarea identității',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Echipa noastră va verifica documentele transmise pentru siguranța comunității.'),
          const SizedBox(height: 12),
          Text(
            '4. Activează modul Șofer',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Odată aprobat, poți activa modul de șofer de pe ecranul principal și poți începe să ajuți vecinii!'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Importante:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 4),
                Text(
                  'Toate cursele Nabour sunt voluntare. Nu se acceptă plăți sau recompense financiare de la pasageri.',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ];
      }
      case 'rideSharing':
      case 'Ride Sharing':
      case 'Curse Partajate': {
        return [
          Text(
            'Curse Partajate Nabour',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Nabour încurajează partajarea curselor între vecini pentru a reduce traficul și a proteja mediul. Această funcție permite sistemului să cupleze mai mulți pasageri care merg în aceeași direcție.'),
          const SizedBox(height: 16),
          Text(
            'Cum funcționează?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text('• Activează opțiunea de partajare la solicitarea cursei.'),
          Text('• Sistemul te va notifica dacă găsește un alt vecin care se alătură călătoriei.'),
          Text('• Traseul poate fi ușor optimizat pentru a prelua toți participanții.'),
          const SizedBox(height: 16),
          Text(
            'Beneficii:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text('• Socializare cu vecinii din comunitate.'),
          Text('• Reducerea numărului de mașini pe drum.'),
          Text('• Zero costuri - spirit de întrajutorare.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Text(
              'Notă: Deoarece Nabour este o platformă voluntară, disponibilitatea curselor partajate depinde de vecinii din zonă.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ),
        ];
      }
      case 'lowDataMode':
      case 'Mod date reduse':
      case 'Low data mode': {
        return [
          Text(
            l10n.lowDataModeHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.lowDataModeHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpGoToMenu),
          Text(l10n.lowDataModeHelpTapToggle),
          Text(l10n.lowDataModeHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpWhatItDoes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpReducesImages),
          Text(l10n.lowDataModeHelpLimitsAnimations),
          Text(l10n.lowDataModeHelpOptimizesMaps),
          Text(l10n.lowDataModeHelpReducesSync),
          const SizedBox(height: 16),
          Text(
            l10n.lowDataModeHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.lowDataModeHelpSavesData),
          Text(l10n.lowDataModeHelpFasterLoading),
          Text(l10n.lowDataModeHelpBatteryLife),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              l10n.lowDataModeHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ),
        ];
      }
      case 'highContrastUI':
      case 'Interfață contrast ridicat':
      case 'High-contrast UI': {
        return [
          Text(
            l10n.highContrastUIHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.highContrastUIHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpGoToMenu),
          Text(l10n.highContrastUIHelpTapToggle),
          Text(l10n.highContrastUIHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpWhatItDoes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpIncreasesContrast),
          Text(l10n.highContrastUIHelpBolderText),
          Text(l10n.highContrastUIHelpClearerIcons),
          Text(l10n.highContrastUIHelpBetterVisibility),
          const SizedBox(height: 16),
          Text(
            l10n.highContrastUIHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.highContrastUIHelpAccessibility),
          Text(l10n.highContrastUIHelpReadability),
          Text(l10n.highContrastUIHelpOutdoorUse),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              l10n.highContrastUIHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
            ),
          ),
        ];
      }
      case 'assistantStatusOverlay':
      case 'Suprapunere status asistent':
      case 'Assistant status overlay': {
        return [
          Text(
            l10n.assistantStatusOverlayHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.assistantStatusOverlayHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpGoToMenu),
          Text(l10n.assistantStatusOverlayHelpTapToggle),
          Text(l10n.assistantStatusOverlayHelpActivate),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpWhatItShows,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpWorking),
          Text(l10n.assistantStatusOverlayHelpWaiting),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpLocation,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpTopRight),
          Text(l10n.assistantStatusOverlayHelpNonIntrusive),
          const SizedBox(height: 16),
          Text(
            l10n.assistantStatusOverlayHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.assistantStatusOverlayHelpVisualFeedback),
          Text(l10n.assistantStatusOverlayHelpDebugging),
          Text(l10n.assistantStatusOverlayHelpTransparency),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              l10n.assistantStatusOverlayHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ),
        ];
      }
      case 'weekInReviewStorage':
      case 'Week in Review și istoricul locațiilor': {
        return [
          Text(
            l10n.helpWeekReviewHeader,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.helpWeekReviewIntro,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpWeekReviewDataSourceTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpWeekReviewDataSourceBody),
          const SizedBox(height: 20),
          Text(
            l10n.helpWeekReviewStorageTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpWeekReviewStorageBody),
          const SizedBox(height: 20),
          Text(
            l10n.helpWeekReviewDeleteTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpWeekReviewDeleteBody),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.helpWeekReviewPrivacyNote,
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      case 'lassoTool':
      case 'Instrumentul Lasso':
      case 'Lasso Tool': {
        return [
          Text(
            l10n.helpLassoTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helpLassoBody,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpLassoHowToTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpLassoHowToBody),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.helpLassoTip,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      case 'radarScan':
      case 'Butonul Scanează (radar vecini)':
      case 'Scan button (neighbor radar)': {
        return [
          Text(
            l10n.helpRadarTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helpRadarBody,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpRadarWhatTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpRadarWhatBody, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 20),
          Text(
            l10n.helpRadarResultsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpRadarResultsBody, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 20),
          Text(
            l10n.helpRadarNextTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpRadarNextBody, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.helpRadarTip,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      case 'mapDrops':
      case 'Interactive Map Drops': {
        return [
          Text(
            l10n.helpMapDropsTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helpMapDropsBody,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpMapDropsFlyTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpMapDropsFlyBody),
          const SizedBox(height: 16),
          Text(
            l10n.helpMapDropsPinsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(l10n.helpMapDropsPinsBody),
        ];
      }
      case 'mysteryBoxesGuide':
      case 'Cutii pe hartă și tokeni':
      case 'Map boxes & tokens': {
        return [
          Text(
            l10n.helpBoxesPurposeTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.helpBoxesPurposeBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesTokensTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesTokensBody,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesCommunityStepsTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesCommunityStepsBody,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesBusinessStepsTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesBusinessStepsBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesActivityScreenTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesActivityScreenBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesPrivacyRulesTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesPrivacyRulesBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesWhoTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesWhoBody,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpBoxesNotesTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.helpBoxesNotesBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_rounded, color: Color(0xFF0D9488)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.helpBoxesTip,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      case 'tokenPeerTransferHelp':
      case 'Transfer de tokeni între utilizatori':
      case 'Token transfers between users': {
        return [
          Text(
            l10n.helpTransfersP2PTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.helpTransfersP2PAboutBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpTransfersP2PWalletTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTransfersP2PWalletBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpTransfersP2PDirectTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTransfersP2PDirectBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpTransfersP2PRequestTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTransfersP2PRequestBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpTransfersP2PRequestsTabTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTransfersP2PRequestsTabBody,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpTransfersP2PHistoryTabTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTransfersP2PHistoryTabBody,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF0D9488)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.helpTransfersP2PTip,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
      default:
        return [
          Text(
            l10n.contentComingSoon,
            style: const TextStyle(fontSize: 16),
          ),
        ];
    }
  }

  void _showDriverActivationProcedure(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.howToActivateDriverMode),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.toBecomeDriverPartner,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStep('1', l10n.helpDriverActivationStepCheckConditions,
                l10n.helpDriverActivationStepCheckConditionsBody),
              _buildStep('2', l10n.helpDriverActivationStepPrepareDocs,
                l10n.helpDriverActivationStepPrepareDocsBody),
              _buildStep('3', l10n.helpDriverActivationStepCompleteApp,
                l10n.helpDriverActivationStepCompleteAppBody),
              _buildStep('4', l10n.helpDriverActivationStepSubmitDocs,
                l10n.helpDriverActivationStepSubmitDocsBody),
              _buildStep('5', l10n.helpDriverActivationStepVerification,
                l10n.helpDriverActivationStepVerificationBody),
              _buildStep('6', l10n.helpDriverActivationStepReceiveCode,
                l10n.helpDriverActivationStepReceiveCodeBody),
              _buildStep('7', l10n.helpDriverActivationStepActivateAccount,
                l10n.helpDriverActivationStepActivateAccountBody),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpDriverActivationTipHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.helpDriverActivationTipBody,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CareerScreen())
              );
            },
            child: Text(l10n.applyNow),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHelpTopic(BuildContext context, String title) {
    // --- MODIFICARE: Am eliminat 'Taxă curățenie sau daune' din lista specială ---
    const reportTopics = [
      'Obiecte pierdute',
      'Raportează accident sau eveniment neplăcut',
    ];

    if (reportTopics.contains(title)) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => ReportFormScreen(reportType: title)));
    } else if (title == 'Cum activez modul șofer partener Nabour') {
      _showDriverActivationProcedure(context);
    } else {
      final l10n = AppLocalizations.of(context)!;
      final content = _buildHelpArticle(title, l10n);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) =>
                  HelpArticleScreen(articleTitle: title, contentWidgets: content)));
    }
  }

  void _showPasswordResetDialog() {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resetare Parolă'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Introduceți adresa de email asociată contului dumneavoastră.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Introduceți o adresă de email validă.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final String email = emailController.text.trim();
                  
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); 
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Se trimite emailul de resetare...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Un email de resetare a parolei a fost trimis. Verificați-vă inbox-ul (inclusiv folderul Spam)!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 8),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String message = 'A apărut o eroare la trimiterea email-ului de resetare.';
                    if (e.code == 'user-not-found') {
                      message = 'Nu există niciun cont cu această adresă de email.';
                    } else if (e.message != null) {
                      message = e.message!;
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    Logger.error('Error sending password reset email from HelpScreen: $e', error: e);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('A apărut o eroare neașteptată.'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Resetează Parola'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpTopic(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    // Filtrare live
    if (_searchQuery.isNotEmpty &&
        !title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) { onTap(); } else { _navigateToHelpTopic(context, title); }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory({
    required String title,
    required IconData headerIcon,
    required Color headerColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: headerColor.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(headerIcon, color: headerColor, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(l10n.helpCenter),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Search Bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.helpSearchHint,
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchController.clear(); HapticFeedback.lightImpact(); },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
          ),

          // ── Categorie: Probleme de cursă ────────────────────────────────────
          _buildCategory(
            title: l10n.helpCategoryRideIssues,
            headerIcon: Icons.directions_car_rounded,
            headerColor: Colors.orange,
            children: [
              _buildHelpTopic(context, icon: Icons.block_rounded,         title: l10n.cannotRequestRide,     iconColor: Colors.orange),
              _buildHelpTopic(context, icon: Icons.cancel_outlined,        title: l10n.rideDidNotHappen,       iconColor: Colors.red),
              _buildHelpTopic(context, icon: Icons.work_outline,           title: l10n.lostItems,              iconColor: Colors.brown),
            ],
          ),

          // ── Categorie: Siguranță & SOS ─────────────────────────────────────
          _buildCategory(
            title: l10n.helpCategorySafetySOS,
            headerIcon: Icons.shield_outlined,
            headerColor: Colors.red,
            children: [
              _buildHelpTopic(context, icon: Icons.warning_amber_rounded,          title: l10n.emergencyAssistanceUsage,   iconColor: Colors.red),
              _buildHelpTopic(context, icon: Icons.report_gmailerrorred_outlined,  title: l10n.reportIncidentTitle,        iconColor: Colors.red.shade700),
            ],
          ),

          // ── Categorie: Funcții Nabour ───────────────────────────────────────
          _buildCategory(
            title: l10n.helpCategoryNabourFeatures,
            headerIcon: Icons.star_outline_rounded,
            headerColor: const Color(0xFF7C3AED),
            children: [
              _buildHelpTopic(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: l10n.helpChatGuideTitle,
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  final content = _buildHelpArticle('howToUseChat', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.helpChatGuideTitle, contentWidgets: content)));
                },
              ),
              /*
              _buildHelpTopic(
                context,
                icon: Icons.auto_fix_high_rounded,
                title: l10n.helpLassoTitle,
                iconColor: Colors.deepPurple,
                onTap: () {
                  final content = _buildHelpArticle('lassoTool', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(
                      articleTitle: l10n.helpLassoTitle,
                      contentWidgets: content)));
                },
              ),
              */
              _buildHelpTopic(
                context,
                icon: Icons.radar,
                title: l10n.helpRadarTitle,
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  final content = _buildHelpArticle('radarScan', l10n);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: l10n.helpRadarTitle,
                        contentWidgets: content,
                      ),
                    ),
                  );
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.location_on_outlined,
                title: l10n.helpMapDropsTitle,
                iconColor: Colors.blue,
                onTap: () {
                  final content = _buildHelpArticle('mapDrops', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.helpMapDropsTitle, contentWidgets: content)));
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.inventory_2_outlined,
                title: l10n.helpBoxesPurposeTitle,
                iconColor: const Color(0xFF0D9488),
                onTap: () {
                  final content = _buildHelpArticle('mysteryBoxesGuide', l10n);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: l10n.helpBoxesPurposeTitle,
                        contentWidgets: content,
                      ),
                    ),
                  );
                },
              ),
              _buildHelpTopic(context, icon: Icons.timeline_rounded, title: l10n.helpWeekReviewTitle, iconColor: Colors.teal,
                onTap: () {
                  final content = _buildHelpArticle('weekInReviewStorage', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.helpWeekReviewTitle, contentWidgets: content)));
                }),
            ],
          ),

          // ── Categorie: Comunitate ──────────────────────────────────────────
          _buildCategory(
            title: "Comunitate & Voluntariat",
            headerIcon: Icons.volunteer_activism_rounded,
            headerColor: Colors.deepPurple,
            children: [
              _buildHelpTopic(context, icon: Icons.people_outline,        title: "Despre Nabour",             iconColor: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AboutScreen()))),
              _buildHelpTopic(context, icon: Icons.handshake_outlined,     title: "Cum pot ajuta?",            iconColor: Colors.purple,
                onTap: () {
                  final content = _buildHelpArticle('howToActivateDriverMode', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: "Implică-te în comunitate", contentWidgets: content)));
                }),
              _buildHelpTopic(context, icon: Icons.gavel_rounded,          title: l10n.legalInformation,       iconColor: Colors.blueGrey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const LegalScreen()))),
            ],
          ),

          // ── Categorie: Comunitate & Tokeni ─────────────────────────────────
          _buildCategory(
            title: "Comunitate & Tokeni",
            headerIcon: Icons.people_outline_rounded,
            headerColor: Colors.teal,
            children: [
              _buildHelpTopic(context, icon: Icons.share_rounded,           title: l10n.helpRideSharingTitle,     iconColor: Colors.lightGreen),
              _buildHelpTopic(
                context,
                icon: Icons.swap_horiz_rounded,
                title: l10n.helpTransfersP2PTitle,
                iconColor: const Color(0xFF0D9488),
                onTap: () {
                  final content = _buildHelpArticle('tokenPeerTransferHelp', l10n);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: l10n.helpTransfersP2PTitle,
                        contentWidgets: content,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Categorie: Setări & Cont ───────────────────────────────────────
          _buildCategory(
            title: l10n.helpCategorySettingsAccount,
            headerIcon: Icons.settings_outlined,
            headerColor: Colors.grey.shade700,
            children: [
              _buildHelpTopic(context, icon: Icons.bug_report_outlined,   title: l10n.appFunctioningProblems, iconColor: Colors.red),
              _buildHelpTopic(context, icon: Icons.data_saver_on_outlined, title: l10n.lowDataMode,           iconColor: Colors.blue,
                onTap: () {
                  final content = _buildHelpArticle('lowDataMode', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.lowDataModeHelpTitle, contentWidgets: content)));
                }),
              _buildHelpTopic(context, icon: Icons.contrast_outlined,     title: l10n.highContrastUI,         iconColor: Colors.blueGrey,
                onTap: () {
                  final content = _buildHelpArticle('highContrastUI', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.highContrastUIHelpTitle, contentWidgets: content)));
                }),
              _buildHelpTopic(context, icon: Icons.assistant_outlined,    title: l10n.assistantStatusOverlay, iconColor: Colors.purple,
                onTap: () {
                  final content = _buildHelpArticle('assistantStatusOverlay', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: l10n.assistantStatusOverlayHelpTitle, contentWidgets: content)));
                }),
              _buildHelpTopic(context, icon: Icons.lock_reset_outlined,   title: l10n.forgotPassword,         iconColor: Colors.deepOrange,
                onTap: _showPasswordResetDialog),
              _buildHelpTopic(context, icon: Icons.drive_eta_rounded,   title: "Cum devin Șofer?", iconColor: Colors.indigo),
            ],
          ),

          const SizedBox(height: 24),

          // ── Footer contact ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F5FF1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.helpStillNeedHelp,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          l10n.helpContactSupport,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen(reportType: 'general')));
                    },
                    style: TextButton.styleFrom(backgroundColor: Colors.white.withAlpha(40), foregroundColor: Colors.white),
                    child: Text(l10n.helpContactButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
