import 'package:flutter/material.dart';

enum AppDestination {
  inventory('Inventory', Icons.inventory_2_outlined),
  customers('Customers/Khata', Icons.people_outline),
  buyers('Buyers', Icons.storefront_outlined),
  invoices('Invoices', Icons.receipt_long_outlined),
  analytics('Analytics', Icons.bar_chart_outlined),
  companyProfile('Company profile', Icons.business_outlined),
  backup('Backup & Restore', Icons.backup_outlined);

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
    this.showLocalBackup = false,
  });

  final AppDestination selected;
  final ValueChanged<AppDestination> onSelect;
  final Future<void> Function() onLogout;
  final bool showLocalBackup;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Internal Billing',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ..._destinations.map(
                    (destination) => ListTile(
                      leading: Icon(destination.icon),
                      title: Text(destination.label),
                      selected: destination == selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(destination);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
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

  List<AppDestination> get _destinations {
    if (showLocalBackup) {
      return AppDestination.values;
    }
    return AppDestination.values
        .where((destination) => destination != AppDestination.backup)
        .toList();
  }
}
