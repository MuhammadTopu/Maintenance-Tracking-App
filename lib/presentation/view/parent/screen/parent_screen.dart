import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/all_item_list_provider.dart';
import '../../../view_models/item_task_list_provider.dart';
import '../../../view_models/parent_screen_provider.dart';
import '../../../view_models/user_provider.dart';
import '../widget/parent_screen_widget.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.wait([
        context.read<UserProvider>().getUserDetails(),
        context.read<AllItemListProvider>().getAllItem(),
        context.read<ItemTaskListProvider>().getItemTasks(),
      ]);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      top: false,
      bottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Consumer<ParentScreensProvider>(
              builder: (context, parentScreenProvider, child) {
                if (parentScreenProvider.screens.isEmpty ||
                    parentScreenProvider.selectedIndex < 0 ||
                    parentScreenProvider.selectedIndex >= parentScreenProvider.screens.length) {
                  return const Center(child: Text('No screens available'));
                }

                final validScreens = parentScreenProvider.screens
                    .asMap()
                    .entries
                    .where((entry) => entry.value != null)
                    .map((entry) => entry.value)
                    .toList();

                if (validScreens.isEmpty) {
                  return const Center(child: Text('No valid screens available'));
                }

                final adjustedIndex = parentScreenProvider.selectedIndex.clamp(
                  0,
                  validScreens.length - 1,
                );

                return IndexedStack(index: adjustedIndex, children: validScreens);
              },
            ),
            Transform.translate(
              offset: const Offset(0, -15),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const ParentScreenWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}