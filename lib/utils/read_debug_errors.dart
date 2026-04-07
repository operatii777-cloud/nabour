/// 📖 CITITOR DE ERORI DIN CONSOLĂ
/// 
/// Acest script citește erorile salvate de DebugConsoleInterceptor
/// și le afișează pentru analiză.
library;

import 'package:nabour_app/services/debug_console_interceptor.dart';

/// Citește și afișează erorile din consolă
Future<void> main() async {
  print('🔍 CITITOR DE ERORI DIN CONSOLĂ');
  print('=' * 60);
  
  final interceptor = DebugConsoleInterceptor();
  
  // Obține raportul de erori
  final report = await interceptor.getErrorReport();
  
  print('\n📊 STATISTICI:');
  print('-' * 60);
  final stats = report['statistics'] as Map<String, dynamic>;
  print('Total mesaje: ${stats['total_messages']}');
  print('Total erori: ${stats['total_errors']}');
  print('Total warning-uri: ${stats['total_warnings']}');
  print('Erori în ultimul minut: ${stats['recent_errors_1min']}');
  print('Warning-uri în ultimul minut: ${stats['recent_warnings_1min']}');
  
  if (report['has_critical_issues'] == true) {
    print('\n🚨 PROBLEME CRITICE DETECTATE!');
  }
  
  // Afișează erorile recente
  final errors = report['recent_errors'] as List;
  if (errors.isNotEmpty) {
    print('\n\n❌ ERORI RECENTE (${errors.length}):');
    print('-' * 60);
    for (var i = 0; i < errors.length; i++) {
      final error = errors[i] as Map<String, dynamic>;
      print('\n[${i + 1}] ${error['timestamp']}');
      print('Source: ${error['source'] ?? 'N/A'}');
      print('Message: ${error['message']}');
    }
  }
  
  // Afișează warning-urile recente
  final warnings = report['recent_warnings'] as List;
  if (warnings.isNotEmpty) {
    print('\n\n⚠️ WARNING-URI RECENTE (${warnings.length}):');
    print('-' * 60);
    for (var i = 0; i < warnings.length; i++) {
      final warning = warnings[i] as Map<String, dynamic>;
      print('\n[${i + 1}] ${warning['timestamp']}');
      print('Source: ${warning['source'] ?? 'N/A'}');
      print('Message: ${warning['message']}');
    }
  }
  
  // Afișează calea fișierului de log
  final logPath = report['log_file_path'] as String?;
  if (logPath != null) {
    print('\n\n📁 FIȘIER LOG:');
    print('-' * 60);
    print('Path: $logPath');
    
    // Citește ultimele linii din log
    final logContent = report['last_100_log_lines'] as String?;
    if (logContent != null && logContent.isNotEmpty) {
      print('\n📝 ULTIMELE 100 LINII DIN LOG:');
      print('-' * 60);
      print(logContent);
    }
  }
  
  print('\n\n✅ RAPORT COMPLET!');
  print('=' * 60);
}

