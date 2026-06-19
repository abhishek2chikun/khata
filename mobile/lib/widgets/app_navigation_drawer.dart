import 'package:flutter/material.dart';

enum AppDestination {
  inventory('Inventory', Icons.inventory_2_outlined),
  customers('Customers/Khata', Icons.people_outline),
  buyers('Buyers', Icons.storefront_outlined),
  invoices('Invoices', Icons.receipt_long_outlined),
  analytics('Analytics', Icons.bar_chart_outlined),
  companyProfile('Company profile', Icons.business_outlined);

  const AppDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
    this.showSyncCatalog = false,
    this.onSyncCatalog,
    this.isSyncing = false,
  });

  final AppDestination selected;
  final ValueChanged<AppDestination> onSelect;
  final Future<void> Function() onLogout;
  final bool showSyncCatalog;
  final Future<void> Function()? onSyncCatalog;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Internal Billing',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text('Local business workspace'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                children: [
                  ...AppDestination.values.map(
                    (destination) => ListTile(
                      dense: true,
                      leading: Icon(destination.icon),
                      title: Text(destination.label),
                      selected: destination == selected,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      selectedColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(destination);
                      },
                    ),
                  ),
                  if (showSyncCatalog) ...<Widget>[
                    const Divider(),
                    ListTile(
                      dense: true,
                      leading: isSyncing
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.sync),
                      title: const Text('Sync catalog'),
                      enabled: !isSyncing && onSyncCatalog != null,
                      onTap: isSyncing || onSyncCatalog == null
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await onSyncCatalog!();
                            },
                    ),
                  ],
                  const Divider(),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await onLogout();
                    },
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
