import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/screens/help_article_screen.dart';
import 'package:nabour_app/screens/report_form_screen.dart';
import 'package:nabour_app/screens/career_screen.dart';
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
            l10n.cannotRequestRideContent,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.checkInternetConnection),
          Text(l10n.ensureGpsEnabled),
          Text(l10n.restartApp),
          Text(l10n.checkValidPayment),
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
          const Text(
            'Ghid utilizare Chat Cartier',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chat-ul de cartier este conceput să te conecteze instantaneu cu vecinii aflați în proximitatea ta.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cine vede mesajele?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mesajele trimise sunt vizibile pentru toți utilizatorii care se află în aceeași zonă geografică cu tine în momentul utilizării.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Raza și Aria de acoperire',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sistemul împarte orașul în hexagoane cu latura de aproximativ 3.2 km (o suprafață de circa 36 km²). Este o zonă vastă, ideală pentru a acoperi un cartier întreg sau un sector.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Persistența mesajelor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pentru a păstra conversațiile proaspete și relevante, mesajele dispar automat după 30 de minute. Nu există un istoric permanent, chat-ul fiind destinat interacțiunilor imediate.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Confidențialitate și Siguranță',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accesul la chat este validat pe baza locației tale GPS actuale. Dacă te muți într-o altă parte a orașului, aplicația te va conecta automat la chat-ul specific acelei zone.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Color(0xFF7C3AED)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sfat: Folosește butonul OMW pentru a anunța rapid vecinii că ești în drum spre ei sau ești disponibil în zonă.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
      case 'cleaningOrDamageFee':
      case 'Taxă curățenie sau daune': {
        return [
          Text(
            l10n.cleaningFeeTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.cleaningFeeIntro,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.whenFeeApplied,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(l10n.spillingLiquids),
          Text(l10n.soilingSeatsOrFloor),
          Text(l10n.vomitingInVehicle),
          Text(l10n.smokingInVehicle),
          Text(l10n.damagingVehicleElements),
          Text(l10n.leavingFoodOrTrash),
          Text(l10n.persistentOdors),
          const SizedBox(height: 20),
          Text(
            l10n.howFeeProcessWorks,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(l10n.driverDocumentsDamage),
          Text(l10n.driverReportsIncident),
          Text(l10n.teamAnalyzesReport),
          Text(l10n.ifFeeJustified),
          Text(l10n.feeChargedAutomatically),
          Text(l10n.passengerCanContest),
          const SizedBox(height: 20),
          Text(
            l10n.feeAmounts,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lightCleaning,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.wipingAndVacuuming),
                Text(l10n.removingSmallStains),
                const SizedBox(height: 12),
                Text(
                  l10n.intensiveCleaning,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.professionalCleaning),
                Text(l10n.deodorizationAndSpecialTreatments),
                const SizedBox(height: 12),
                Text(
                  l10n.repairsAndReplacements,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(l10n.replacingDamagedSeatCovers),
                Text(l10n.repairingDamagedComponents),
                Text(l10n.costsDependOnSeverity),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.yourRightsAsPassenger,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rightToReceivePhotos,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.canContestFee,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rightToObjectiveInvestigation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.ifContestationJustified,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.howToAvoidFee,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(l10n.doNotConsumeFood),
          Text(l10n.checkShoesNotDirty),
          Text(l10n.notifyDriverIfFeelingUnwell),
          Text(l10n.doNotSmokeInVehicle),
          Text(l10n.treatVehicleWithRespect),
          Text(l10n.takeTrashWithYou),
          const SizedBox(height: 20),
          Text(
            l10n.contestationProcess,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(l10n.accessRideHistory),
          Text(l10n.selectRideForContestation),
          Text(l10n.pressContestFee),
          Text(l10n.addRelevantEvidence),
          Text(l10n.teamWillReanalyze),
          Text(l10n.receiveDetailedResponse),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.haveQuestionsOrNeedAssistance,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                ),
                const SizedBox(height: 12),
                Text(l10n.emailSupport),
                Text(l10n.phoneSupport),
                Text(l10n.chatInApp),
                Text(l10n.scheduleSupport),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importantToRemember,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.feeOnlyAppliedWithClearEvidence,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
          ),
        ];
      }
      case 'howToActivateDriverMode':
      case 'Cum activez modul șofer partener Nabour': {
        return [
          Text(
            l10n.toBecomeDriverPartner,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.checkConditions,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.validLicenseRequired),
          const SizedBox(height: 12),
          Text(
            l10n.prepareDocuments,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.documentsNeeded),
          const SizedBox(height: 12),
          Text(
            l10n.completeApplication,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.accessCareerSection),
          const SizedBox(height: 12),
          Text(
            l10n.submitDocuments,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.uploadClearPhotos),
          const SizedBox(height: 12),
          Text(
            l10n.applicationVerification,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.teamWillVerify),
          const SizedBox(height: 12),
          Text(
            l10n.receiveActivationCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.afterApproval),
          const SizedBox(height: 12),
          Text(
            l10n.activateAccount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(l10n.enterCodeInApp),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usefulTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ensureDocumentsValid,
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ];
      }
      case 'ratesAndPayments':
      case 'Tarife și plăți': {
        return [
          Text(
            l10n.ratesAndPaymentsInfo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.ratesCalculatedAutomatically),
          Text(l10n.paymentMadeAutomatically),
          Text(l10n.canSeeRateDetails),
          Text(l10n.inCaseOfPaymentProblems),
          const SizedBox(height: 16),
          Text(
            l10n.forCurrentRatesDetails,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ];
      }
      case 'appFunctioningProblems':
      case 'Probleme de funcționare a aplicației': {
        return [
          Text(
            l10n.ifAppNotWorkingCorrectly,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.restartApp),
          Text(l10n.checkInternetConnection),
          Text(l10n.updateAppToLatest),
          Text(l10n.restartPhone),
          Text(l10n.reinstallAppIfPersists),
          const SizedBox(height: 16),
          Text(
            l10n.ifProblemContinues,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];
      }
      case 'paymentMethods':
      case 'Metode de plată': {
        return [
          Text(
            l10n.paymentMethodsHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.addingPaymentMethod,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.goToWalletSection),
          Text(l10n.tapAddPaymentMethod),
          Text(l10n.selectCardOrCash),
          Text(l10n.enterCardDetails),
          Text(l10n.savePaymentMethod),
          const SizedBox(height: 16),
          Text(
            l10n.managingPaymentMethods,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.viewAllMethodsInWallet),
          Text(l10n.editOrDeleteMethods),
          Text(l10n.setDefaultPaymentMethod),
          const SizedBox(height: 16),
          Text(
            l10n.paymentMethodsTypes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.creditDebitCards),
          Text(l10n.cashPayment),
          Text(l10n.walletBalance),
          const SizedBox(height: 16),
          Text(
            l10n.paymentSecurity,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.allPaymentsSecure),
          Text(l10n.cardDetailsEncrypted),
          Text(l10n.pciCompliant),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentMethodTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.youCanSendToContact,
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ];
      }
      case 'vouchers':
      case 'Vouchere': {
        return [
          Text(
            l10n.vouchersHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.addingVoucher,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.goToWalletSection),
          Text(l10n.tapVouchersSection),
          Text(l10n.tapAddVoucherCode),
          Text(l10n.enterVoucherCode),
          Text(l10n.applyVoucher),
          const SizedBox(height: 16),
          Text(
            l10n.usingVouchers,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.vouchersAppliedAutomatically),
          Text(l10n.checkVoucherStatus),
          Text(l10n.voucherExpiryInfo),
          const SizedBox(height: 16),
          Text(
            l10n.voucherTypes,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.percentageDiscount),
          Text(l10n.fixedAmountDiscount),
          Text(l10n.freeRideVoucher),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voucherTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.oneVoucherPerRide,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
        ];
      }
      case 'wallet':
      case 'Portofel': {
        return [
          Text(
            l10n.walletHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.walletOverview,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.walletOverviewInfo),
          const SizedBox(height: 16),
          Text(
            l10n.friendsRideCash,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.friendsRideCashInfo),
          Text(l10n.addFundsToWallet),
          Text(l10n.useWalletForPayments),
          const SizedBox(height: 16),
          Text(
            l10n.walletSections,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.paymentMethodsSection),
          Text(l10n.vouchersSection),
          Text(l10n.rideProfilesSection),
          Text(l10n.promotionsSection),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletTip,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.walletBalanceNeverExpires,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ];
      }
      case 'subscriptions':
      case 'Abonamente și Promoții':
      case 'Subscriptions and Promotions': {
        return [
          Text(
            l10n.subscriptionsHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.subscriptionsHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpPlans,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpBasic),
          Text(l10n.subscriptionsHelpPlus),
          Text(l10n.subscriptionsHelpPremium),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpHowToSubscribe,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpGoToMenu),
          Text(l10n.subscriptionsHelpTapSubscriptions),
          Text(l10n.subscriptionsHelpSelectPlan),
          Text(l10n.subscriptionsHelpCompletePayment),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpPromotions,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpPromotionsInfo),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionsHelpReferral,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.subscriptionsHelpReferralInfo),
        ];
      }
      case 'splitPayment':
      case 'Split Payment':
      case 'Împărțirea Costului': {
        return [
          Text(
            l10n.splitPaymentHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.splitPaymentHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.splitPaymentHelpHowToCreate,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.splitPaymentHelpAfterRide),
          Text(l10n.splitPaymentHelpSelectPeople),
          Text(l10n.splitPaymentHelpShareLink),
          Text(l10n.splitPaymentHelpParticipantsAccept),
          const SizedBox(height: 16),
          Text(
            l10n.splitPaymentHelpHowToAccept,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.splitPaymentHelpReceiveLink),
          Text(l10n.splitPaymentHelpTapAccept),
          Text(l10n.splitPaymentHelpSelectPayment),
          Text(l10n.splitPaymentHelpCompletePayment),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              l10n.splitPaymentHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ),
        ];
      }
      case 'rideSharing':
      case 'Ride Sharing':
      case 'Curse Partajate': {
        return [
          Text(
            l10n.rideSharingHelpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.rideSharingHelpOverview),
          const SizedBox(height: 16),
          Text(
            l10n.rideSharingHelpHowToEnable,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.rideSharingHelpDuringRequest),
          Text(l10n.rideSharingHelpSystemMatches),
          Text(l10n.rideSharingHelpIfMatchFound),
          const SizedBox(height: 16),
          Text(
            l10n.rideSharingHelpBenefits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(l10n.rideSharingHelpCostReduction),
          Text(l10n.rideSharingHelpEcoFriendly),
          Text(l10n.rideSharingHelpSocial),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              l10n.rideSharingHelpNote,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
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
        final isEn = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';
        return [
          Text(
            isEn ? 'Lasso Tool (Magic Wand)' : 'Instrumentul Lasso (Bagheta Magică)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isEn 
              ? 'The Lasso tool allows you to select multiple neighbors on the map by drawing a circle around them.'
              : 'Instrumentul Lasso îți permite să selectezi mai mulți vecini de pe hartă dintr-o singură mișcare, prin încercuirea lor.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'How to use it?' : 'Cum se folosește?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
              ? '1. Tap the "Magic Wand" icon in the top right of the map.\n2. Draw a circle around the neighbors you want to contact.\n3. A menu will appear showing the captured group and options to send a broadcast request.'
              : '1. Apasă pe pictograma "Baghetă Magică" din colțul dreapta-sus al hărții.\n2. Desenează un cerc cu degetul în jurul vecinilor pe care vrei să îi contactezi.\n3. Se va deschide un meniu cu grupul capturat și opțiuni pentru a le trimite o cerere de tip "Broadcast".',
          ),
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
                    isEn 
                      ? 'Tip: Use Lasso to quickly find a neighbor team for a common activity or a shared ride request!'
                      : 'Sfat: Folosește Lasso pentru a găsi rapid o echipă de vecini pentru o activitate comună sau o cerere de transport partajat!',
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
        final isEn = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';
        return [
          Text(
            isEn ? 'Scan button (neighbor radar)' : 'Butonul Scanează (radar vecini)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isEn
                ? 'The Scan button runs the radar overlay for about 5 seconds, then closes automatically. During this time you cannot resize the circle.'
                : 'Butonul Scanează pornește scanarea în overlay-ul radar timp de aproximativ 5 secunde, apoi se închide automat. În acest interval nu poți redimensiona cercul.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'What does it scan?' : 'Ce „scanează”?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'It does not scan Bluetooth, Wi‑Fi, or new devices. It lists neighbors who are already shown on the map and whose position falls inside your radar circle (distance is computed from the circle center and radius).'
                : 'Nu este scanare Bluetooth, Wi‑Fi sau de dispozitive noi. Aplicația listează vecinii care sunt deja afișați pe hartă și se află în interiorul cercului radar (distanța se calculează față de centrul și raza cercului).',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Where do results appear?' : 'Unde apar rezultatele?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'If at least one neighbor is in the circle, a bottom sheet opens with the list. If there is no one, you will see a short message that no neighbors were found in the radar.'
                : 'Dacă există cel puțin un vecin în cerc, se deschide o foaie de jos cu lista. Dacă nu e nimeni, vei vedea un mesaj scurt că nu s-a găsit niciun vecin în radar.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'What can you do next?' : 'Ce poți face după?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'From the sheet you can use the group action (e.g. broadcast request) when that feature is fully enabled; until then the app may show a notice that it is being rolled out.'
                : 'Din foaia de jos poți folosi acțiunea de grup (ex. cerere broadcast) când funcția este complet activă; până atunci aplicația poate afișa un mesaj că este în curs de activare.',
            style: const TextStyle(fontSize: 15),
          ),
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
                    isEn
                        ? 'Tip: Move or resize the circle before tapping Scan so it covers the area you care about—only neighbors already visible on the map can appear in the results.'
                        : 'Sfat: Mută sau mărește cercul înainte de Scanează, ca să acoperi zona care te interesează—în rezultate pot apărea doar vecinii deja vizibili pe hartă.',
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
        final isEn = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';
        return [
          Text(
            isEn ? 'Interactive Map Drops' : 'Interactive Map Drops (Locații în Chat)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isEn 
              ? 'Map Drops are special location markers shared in the neighborhood chat that let you travel through the map instantly.'
              : 'Map Drops sunt marcaje de locație partajate în chat-ul de cartier, care îți permit să călătorești instantaneu pe hartă.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'The "FlyTo" Animation' : 'Animația Cinematică "FlyTo"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
              ? 'When a neighbor shares a location, tap on the interactive card in the chat. The app will close the chat and perform a cinematic flight directly to that exact spot on the map.'
              : 'Atunci când un vecin partajează o locație, apasă pe cardul interactiv din chat. Aplicația va închide chat-ul și va executa un zbor cinematic direct către acel punct exact pe hartă.',
          ),
          const SizedBox(height: 16),
          Text(
            isEn ? 'Transient Pins' : 'Pini Temporari',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
              ? 'After the flight, you will see a pulsing pin on the map. This helps you identify exactly where the "drop" was made, providing precise visual context for the neighbor\'s message.'
              : 'După finalizarea zborului, vei vedea un pin pulsatoriu pe hartă. Acesta te ajută să identifici exact locul unde a fost făcut "drop-ul", oferind context vizual precis pentru mesajul vecinului.',
          ),
        ];
      }
      case 'mysteryBoxesGuide':
      case 'Cutii pe hartă și tokeni':
      case 'Map boxes & tokens': {
        final isEn = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';
        return [
          Text(
            isEn ? 'Purpose' : 'La ce servesc',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isEn
                ? 'On the map you can use two related features tied to Nabour tokens: (1) boxes at business offers — the merchant can set an optional limit; you open them near the store and get tokens plus a discount code for the shop. (2) Community boxes — any user can place a box at their current location; someone else opens it on the spot and gets tokens; the placer is notified when it is opened.'
                : 'Pe hartă există două tipuri de cutii legate de tokenii Nabour: (1) cutii la oferte business — comerciantul poate seta un plafon opțional; le deschizi lângă magazin și primești tokeni plus un cod de reducere la acel magazin. (2) cutii comunitare — orice utilizator poate plasa o cutie la locația sa curentă; altcineva o deschide la fața locului și primește tokeni; plasatorul este informat când cutia e deschisă.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Tokens — how they move' : 'Tokeni — cum se colectează și cheltuiesc',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? '• Placing a community box: 50 tokens are reserved via the server (stake) and recorded in your wallet history.\n'
                    '• Opening a community box (as another user, within about 100 m): you receive 50 tokens; the box is marked as opened.\n'
                    '• Opening a business-offer box: you receive 50 tokens and a discount code, subject to daily-per-store rules and any cap the merchant set.\n'
                    '• Amounts may follow app settings; if server policy blocks crediting until payments are enabled, opening may fail with that message.'
                : '• Plasare cutie comunitară: 50 de tokeni sunt reținuți prin server (garanție) și apar în istoricul portofelului.\n'
                    '• Deschidere cutie comunitară (alt utilizator, la aprox. 100 m): primești 50 de tokeni; cutia este marcată deschisă.\n'
                    '• Deschidere cutie la ofertă business: primești 50 de tokeni și un cod de reducere, cu respectarea regulii o deschidere pe zi per magazin și a plafonului setat de comerciant.\n'
                    '• Dacă politica serverului blochează creditarea până la integrarea plăților, deschiderea poate eșua cu mesajul corespunzător.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Community boxes — user flow' : 'Cutii comunitare — pașii',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? '1) From the map, place a box at your current position (you need enough tokens). Up to 20 active boxes per account.\n'
                    '2) Nearby users see community boxes on the map; your own boxes are not shown to you as boxes to open.\n'
                    '3) Tap a box, get close (~100 m), confirm — the server checks distance and identity.\n'
                    '4) The placer receives an in-app notification entry and a push when someone opens their box.\n'
                    '5) Under Menu → “Box activity” you can see summaries, your placed boxes, your opens, and opens of your boxes.'
                : '1) De pe hartă, plasezi o cutie la poziția curentă (ai nevoie de tokeni suficienți). Limită: până la 20 de cutii active per cont.\n'
                    '2) Utilizatorii din apropiere văd cutiile pe hartă; propriile tale cutii nu îți apar ca să le deschizi tu.\n'
                    '3) Apeși pe cutie, te apropii (aprox. 100 m), confirmi — serverul verifică distanța și identitatea.\n'
                    '4) Plasatorul primește înregistrare în notificări și o notificare push când cineva deschide cutia.\n'
                    '5) Din meniu → „Activitate cutii” vezi rezumatul, cutiile plasate, deschiderile tale și deschiderile la cutiile tale.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Business-offer boxes — user & merchant flow' : 'Cutii la oferte business — utilizator și comerciant',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'The merchant publishes an offer and may attach a mystery-box cap (extra token cost when creating or increasing the cap). You open the box from the map near the location; you get tokens and a redemption code. At the store, the merchant opens the business panel and uses “Validate box code” so the code is marked used. Codes are stored securely; only cloud functions create or validate them.'
                : 'Comerciantul publică o ofertă și poate atașa un plafon de cutii (cost suplimentar în tokeni la publicare sau la mărirea plafonului). Deschizi cutia de pe hartă, lângă locație; primești tokeni și un cod de reducere. În magazin, comerciantul deschide panoul business și folosește „Validează cod” astfel încât codul să fie marcat folosit. Codurile sunt păstrate securizat; doar funcțiile cloud le creează sau validează.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Activity screen (menu)' : 'Ecranul „Activitate cutii” (meniu)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Tabs: Summary (estimated tokens from opens and stake from placements), Placed community boxes, Your opens (community + business log), Notifications when others open your community boxes. Redemption codes are shown masked for safety.'
                : 'File: Rezumat (estimări tokeni din deschideri și din plasări), Plasate (comunitate), Deschise de tine (comunitate + business), Deschideri la cutiile tale (notificări). Codurile de reducere sunt afișate parțial mascate.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Privacy & rules' : 'Confidențialitate și reguli',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Sensitive collections (redemption codes, box writes) are handled on the server. Firestore rules prevent clients from forging opens or codes; reads follow authentication rules.'
                : 'Operațiile sensibile (coduri de reducere, deschideri) se fac pe server. Regulile Firestore împiedică falsificarea din aplicație; citirile respectă autentificarea.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Who does what' : 'Cine ce face',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? '• Any user: browse the map, place community boxes if they have tokens, open community or business boxes when conditions are met, review “Box activity”.\n'
                    '• Placer: gets notified when a community box is opened.\n'
                    '• Merchant: configures offers and caps, validates discount codes after a customer opens a box.'
                : '• Orice utilizator: hartă, plasare cutii comunitare dacă are tokeni, deschidere cutii când distanța și regulile permit, meniul „Activitate cutii”.\n'
                    '• Plasator: primește notificări la deschiderea cutiilor comunitare.\n'
                    '• Comerciant: configurează oferte și plafon, validează codurile după ce clientul a deschis cutia.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Notes' : 'Note',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Listing many boxes around you is optimized for moderate scale; very large usage may need stronger geo indexing later. Automatic refund or expiry of community stakes if nobody opens a box is not described here and may be added later.'
                : 'Listarea cutiilor din jur este potrivită pentru volum moderat; la scară foarte mare poate fi nevoie de indexare geografică mai strictă. Expirarea sau returnarea automată a garanției dacă nimeni nu deschide o cutie comunitară nu este inclusă aici și poate fi adăugată ulterior.',
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
                    isEn
                        ? 'Tip: If opening fails, check GPS accuracy, internet, wallet balance, and whether credits are enabled on the server for your environment.'
                        : 'Sfat: Dacă deschiderea eșuează, verifică precizia GPS, conexiunea, soldul tokenilor și dacă creditarea este activă pe server în mediul tău.',
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
        final isEn =
            (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';
        return [
          Text(
            isEn ? 'What it is' : 'Despre funcție',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isEn
                ? 'From the side menu, open “Token transfer” to move Nabour tokens to another account or to ask someone to send you tokens. Balances and ledger entries are updated on the server; you need the other person’s user ID (Firebase UID).'
                : 'Din meniul lateral, deschide „Transfer tokeni” pentru a trimite tokeni Nabour către alt cont sau pentru a cere cuiva să îți trimită tokeni. Soldurile și înregistrările din jurnal sunt actualizate pe server; ai nevoie de ID-ul de utilizator al celeilalte persoane (UID Firebase).',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Transferable wallet' : 'Portofel transferabil',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'This screen shows the transferable token balance (not the same view as the monthly usage bar at the top of the menu). If the wallet is frozen or missing, transfers and requests will be blocked until the account is eligible.'
                : 'Acest ecran arată soldul de tokeni transferabili (nu este același indicator ca bara de utilizare lunară din partea de sus a meniului). Dacă portofelul lipsește sau este înghețat, transferurile și cererile sunt blocate până când contul este eligibil.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Direct transfer' : 'Transfer direct',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'You send tokens immediately to the recipient’s user ID. You cannot transfer to yourself. Amounts must be a whole number of tokens within the allowed range. An optional note can be attached.'
                : 'Trimite tokeni imediat către ID-ul destinatarului. Nu poți transfera către propriul cont. Suma trebuie să fie un număr întreg de tokeni, în intervalul permis. Poți adăuga o notă opțională.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Payment request' : 'Cerere de plată',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'You ask another user (the payer) to send you tokens. They receive a pending request and can accept or decline. If they accept, tokens move from their transferable wallet to yours. Requests expire after a limited time if not answered.'
                : 'Ceri altui utilizator (plătitorul) să îți trimită tokeni. Acesta primește o cerere în așteptare și poate accepta sau refuza. La acceptare, tokenii se mută din portofelul său transferabil în al tău. Cererile pot expira dacă nu primesc răspuns la timp.',
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Requests tab' : 'Filă „Cereri”',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? '• As payer: you can accept or decline incoming requests; you may add an optional reason when declining.\n'
                    '• As requester: you can cancel a request you created while it is still pending.'
                : '• Ca plătitor: poți accepta sau refuza cererile primite; la refuz poți adăuga un motiv opțional.\n'
                    '• Ca inițiator al cererii: poți anula o cerere creată de tine cât timp este în așteptare.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'History tab' : 'Filă „Istoric”',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'Shows recent direct transfers and resolved payment requests. Pull down to refresh.'
                : 'Afișează transferurile directe recente și cererile de plată rezolvate. Trage în jos pentru reîmprospătare.',
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
                    isEn
                        ? 'Only share your user ID with people you trust. Double-check the ID before confirming a transfer or request.'
                        : 'Distribuie ID-ul de utilizator doar persoanelor în care ai încredere. Verifică din nou ID-ul înainte de a confirma un transfer sau o cerere.',
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cum activez modul șofer partener Nabour'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pentru a deveni șofer partener Nabour, urmează acești pași:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStep('1', 'Verifică condițiile',
                'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.'),
              _buildStep('2', 'Pregătește documentele',
                'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.'),
              _buildStep('3', 'Completează aplicația',
                'Accesează secțiunea "Carieră" din meniul principal și completează formularul online cu datele tale.'),
              _buildStep('4', 'Transmite documentele',
                'Încarcă fotografii clare cu toate documentele necesare prin platforma online.'),
              _buildStep('5', 'Verificarea aplicației',
                'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.'),
              _buildStep('6', 'Primește codul de activare',
                'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.'),
              _buildStep('7', 'Activează contul',
                'Introdu codul în aplicație și începe să câștigi bani conducând!'),
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
                      '💡 Sfat util:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.',
                      style: TextStyle(color: Colors.blue),
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
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CareerScreen())
              );
            },
            child: const Text('Aplică acum'),
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
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.grey.shade50,
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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
    final isEn = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ro') == 'en';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
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
                hintText: isEn ? 'Search help articles...' : 'Caută în articole...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchController.clear(); HapticFeedback.lightImpact(); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
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
            title: isEn ? 'Ride Issues' : 'Probleme de cursă',
            headerIcon: Icons.directions_car_rounded,
            headerColor: Colors.orange,
            children: [
              _buildHelpTopic(context, icon: Icons.block_rounded,         title: isEn ? 'Cannot request a ride' : l10n.cannotRequestRide,     iconColor: Colors.orange),
              _buildHelpTopic(context, icon: Icons.cancel_outlined,        title: isEn ? 'Ride did not happen'   : l10n.rideDidNotHappen,       iconColor: Colors.red),
              _buildHelpTopic(context, icon: Icons.work_outline,           title: isEn ? 'Lost items'            : l10n.lostItems,              iconColor: Colors.brown),
              _buildHelpTopic(context, icon: Icons.cleaning_services_outlined, title: isEn ? 'Cleaning or damage fee' : l10n.cleaningOrDamageFee, iconColor: Colors.deepOrange),
            ],
          ),

          // ── Categorie: Siguranță & SOS ─────────────────────────────────────
          _buildCategory(
            title: isEn ? 'Safety & SOS' : 'Siguranță & SOS',
            headerIcon: Icons.shield_outlined,
            headerColor: Colors.red,
            children: [
              _buildHelpTopic(context, icon: Icons.warning_amber_rounded,          title: l10n.emergencyAssistanceUsage,   iconColor: Colors.red),
              _buildHelpTopic(context, icon: Icons.report_gmailerrorred_outlined,  title: l10n.reportIncidentTitle,        iconColor: Colors.red.shade700),
            ],
          ),

          // ── Categorie: Funcții Nabour ───────────────────────────────────────
          _buildCategory(
            title: isEn ? 'Nabour Features' : 'Funcții Nabour',
            headerIcon: Icons.star_outline_rounded,
            headerColor: const Color(0xFF7C3AED),
            children: [
              _buildHelpTopic(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Cum folosești chatul',
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  final content = _buildHelpArticle('howToUseChat', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: 'Cum folosești chatul', contentWidgets: content)));
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.auto_fix_high_rounded,
                title: isEn ? 'Lasso Tool (Magic Wand)' : 'Instrumentul Lasso (Bagheta Magică)',
                iconColor: Colors.deepPurple,
                onTap: () {
                  final content = _buildHelpArticle('lassoTool', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(
                      articleTitle: isEn ? 'Lasso Tool' : 'Instrumentul Lasso',
                      contentWidgets: content)));
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.radar,
                title: isEn ? 'Scan button (neighbor radar)' : 'Butonul Scanează (radar vecini)',
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  final content = _buildHelpArticle('radarScan', l10n);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: isEn ? 'Scan button (neighbor radar)' : 'Butonul Scanează (radar vecini)',
                        contentWidgets: content,
                      ),
                    ),
                  );
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.location_on_outlined,
                title: 'Interactive Map Drops',
                iconColor: Colors.blue,
                onTap: () {
                  final content = _buildHelpArticle('mapDrops', l10n);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => HelpArticleScreen(articleTitle: 'Interactive Map Drops', contentWidgets: content)));
                },
              ),
              _buildHelpTopic(
                context,
                icon: Icons.inventory_2_outlined,
                title: isEn ? 'Map boxes & tokens' : 'Cutii pe hartă și tokeni',
                iconColor: const Color(0xFF0D9488),
                onTap: () {
                  final content = _buildHelpArticle('mysteryBoxesGuide', l10n);
                  final articleTitle = isEn ? 'Map boxes & tokens' : 'Cutii pe hartă și tokeni';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: articleTitle,
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

          // ── Categorie: Plăți & Portofel ────────────────────────────────────
          _buildCategory(
            title: isEn ? 'Payments & Wallet' : 'Plăți & Portofel',
            headerIcon: Icons.account_balance_wallet_outlined,
            headerColor: Colors.green,
            children: [
              _buildHelpTopic(context, icon: Icons.credit_card_rounded,    title: isEn ? 'Payment methods' : l10n.paymentMethods,  iconColor: Colors.green),
              _buildHelpTopic(context, icon: Icons.redeem_rounded,          title: isEn ? 'Vouchers'        : l10n.vouchers,        iconColor: Colors.orange),
              _buildHelpTopic(context, icon: Icons.wallet_rounded,          title: isEn ? 'Wallet'          : l10n.wallet,          iconColor: Colors.teal),
              _buildHelpTopic(context, icon: Icons.sell_outlined,           title: isEn ? 'Rates & Payments': l10n.ratesAndPayments,iconColor: Colors.blue),
              _buildHelpTopic(context, icon: Icons.subscriptions_rounded,   title: isEn ? 'Subscriptions'   : l10n.subscriptions,   iconColor: Colors.indigo),
              _buildHelpTopic(context, icon: Icons.group_outlined,          title: isEn ? 'Split Payment'   : l10n.splitPayment,    iconColor: Colors.cyan),
              _buildHelpTopic(context, icon: Icons.share_rounded,           title: isEn ? 'Ride Sharing'    : 'Curse Partajate',     iconColor: Colors.lightGreen),
              _buildHelpTopic(
                context,
                icon: Icons.swap_horiz_rounded,
                title: isEn ? 'Token transfers between users' : 'Transfer de tokeni între utilizatori',
                iconColor: const Color(0xFF0D9488),
                onTap: () {
                  final content = _buildHelpArticle('tokenPeerTransferHelp', l10n);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => HelpArticleScreen(
                        articleTitle: isEn
                            ? 'Token transfers between users'
                            : 'Transfer de tokeni între utilizatori',
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
            title: isEn ? 'Settings & Account' : 'Setări & Cont',
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
              if (widget.isPassengerMode)
                _buildHelpTopic(context, icon: Icons.drive_eta_rounded,   title: l10n.howToActivateDriverMode, iconColor: Colors.indigo),
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
                          isEn ? 'Still need help?' : 'Ai nevoie de ajutor?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          isEn ? 'Contact our support team' : 'Contactează echipa de suport',
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
                    child: Text(isEn ? 'Contact' : 'Contactează'),
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
