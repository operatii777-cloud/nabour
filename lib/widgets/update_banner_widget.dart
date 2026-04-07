import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nabour_app/services/app_update_service.dart';

/// Banner compact afișat în AppBar sau header când există un update disponibil.
/// Tapând pe el, se deschide dialogul de update.
class UpdateBannerWidget extends StatelessWidget {
  const UpdateBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppUpdateService>(
      builder: (context, svc, _) {
        if (!svc.updateAvailable) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _showUpdateDialog(context, svc),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3682F3), Color(0xFF1A4CB0)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3682F3).withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.system_update_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update disponibil v${svc.updateInfo?.latestVersion}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white70, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialog / Bottom Sheet complet cu detalii update + buton descărcare.
void showUpdateDialog(BuildContext context) {
  final svc = context.read<AppUpdateService>();
  _showUpdateDialog(context, svc);
}

void _showUpdateDialog(BuildContext context, AppUpdateService svc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: svc,
      child: const _UpdateSheet(),
    ),
  );
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Consumer<AppUpdateService>(
      builder: (context, svc, _) {
        final info = svc.updateInfo;
        final isDownloading = svc.downloadState == UpdateDownloadState.downloading;
        final isInstalling = svc.downloadState == UpdateDownloadState.installing;
        final hasError = svc.downloadState == UpdateDownloadState.error;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icoană update
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3682F3), Color(0xFF1A4CB0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3682F3).withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.system_update_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),

              Text(
                'Nabour ${info?.latestVersion ?? ''} disponibil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Versiunea ta: ${svc.currentVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withAlpha(120),
                    ),
              ),
              const SizedBox(height: 20),

              // Changelog
              if (info?.changelog != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colors.primary.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.new_releases_rounded,
                              size: 16, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Ce este nou',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        info!.changelog,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: colors.onSurface.withAlpha(180),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Eroare
              if (hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: colors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          svc.errorMessage ?? 'Eroare necunoscută.',
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Progress bar
              if (isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Se descarcă...',
                            style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '${(svc.downloadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: svc.downloadProgress,
                        minHeight: 8,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Buton principal
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isDownloading || isInstalling
                      ? null
                      : () {
                          if (hasError) {
                            svc.resetError();
                          }
                          svc.downloadAndInstall();
                        },
                  icon: isInstalling
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    isInstalling
                        ? 'Se instalează...'
                        : hasError
                            ? 'Încearcă din nou'
                            : 'Descarcă și instalează',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    backgroundColor: isDownloading ? colors.primary.withAlpha(120) : null,
                  ),
                ),
              ),

              // Buton „mai târziu" (nu apare dacă update e forțat)
              if (!(info?.forceUpdate ?? false)) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mai târziu'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget mic pentru Settings / Profile page — afișează starea versiunii.
class AppVersionTile extends StatelessWidget {
  const AppVersionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Consumer<AppUpdateService>(
      builder: (context, svc, _) {
        return ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: svc.updateAvailable
                  ? colors.primary.withAlpha(20)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              svc.updateAvailable
                  ? Icons.system_update_rounded
                  : Icons.check_circle_rounded,
              color: svc.updateAvailable ? colors.primary : Colors.green,
              size: 22,
            ),
          ),
          title: Text(
            svc.updateAvailable
                ? 'Update disponibil'
                : 'Aplicația este la zi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: svc.updateAvailable ? colors.primary : null,
            ),
          ),
          subtitle: Text(
            svc.updateAvailable
                ? 'v${svc.updateInfo?.latestVersion} • Versiunea ta: ${svc.currentVersion}'
                : 'Versiunea ${svc.currentVersion}',
            style: TextStyle(fontSize: 12, color: colors.onSurface.withAlpha(150)),
          ),
          trailing: svc.updateAvailable
              ? FilledButton.tonal(
                  onPressed: () => _showUpdateDialog(context, svc),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Update'),
                )
              : null,
        );
      },
    );
  }
}
