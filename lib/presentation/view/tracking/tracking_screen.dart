// import 'package:business_service/cors/routes/routes_name.dart';
// import 'package:business_service/modelview/item_task/item_task_list.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
//
// import '../../../modelview/item_task/item_task_list_by_item_id.dart';
// import '../../widget/custom_app_bar.dart';
// import '../../widget/custom_task_card.dart';
//
// class TrackingScreen extends StatefulWidget {
//   const TrackingScreen({super.key});
//
//   @override
//   State<TrackingScreen> createState() => _TrackingScreenState();
// }
//
// class _TrackingScreenState extends State<TrackingScreen> {
//   String dropdownValue = 'Most Recent';
//   final ScrollController _scrollController = ScrollController();
//   bool _isFabVisible = true;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Delayed provider call to avoid calling notifyListeners during build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ItemTaskListProvider>().getAllTaskList();
//     });
//
//     // Listen to scroll to toggle FAB visibility
//     _scrollController.addListener(() {
//       final direction = _scrollController.position.userScrollDirection;
//
//       // Debug
//       // print('Scroll direction: $direction');
//
//       if (direction == ScrollDirection.reverse && _isFabVisible) {
//         setState(() => _isFabVisible = false);
//       } else if (direction == ScrollDirection.forward && !_isFabVisible) {
//         setState(() => _isFabVisible = true);
//       }
//
//       // Show FAB again when scrolled to top
//       if (_scrollController.position.pixels <= 0 && !_isFabVisible) {
//         setState(() => _isFabVisible = true);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffFFFFFF),
//       floatingActionButton: AnimatedSlide(
//         offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         child: AnimatedOpacity(
//           opacity: _isFabVisible ? 1 : 0,
//           duration: const Duration(milliseconds: 250),
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 110, right: 10),
//             child: FloatingActionButton(
//               backgroundColor: const Color(0xff589DC4),
//               onPressed: () {
//                 debugPrint("Floating action button pressed");
//                 Navigator.pushNamed(context, RouteName.addItemScreen);
//               },
//               child: Icon(Icons.add, size: 24.sp, color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.all(16.w),
//           child: Column(
//             children: [
//               const CustomAppBar(),
//               SizedBox(height: 40.h),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 10.w),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Task List",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
//                       decoration: BoxDecoration(
//                         color: const Color(0xffF6F8FA),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: DropdownButton<String>(
//                         value: dropdownValue,
//                         onChanged: (String? newValue) {
//                           if (newValue != null) {
//                             setState(() {
//                               dropdownValue = newValue;
//                             });
//                             context.read<ItemTaskListProvider>().filterTasks(newValue);
//                           }
//                         },
//                         icon: const Icon(
//                           Icons.keyboard_arrow_down,
//                           color: Color(0xffA5A5AB),
//                         ),
//                         underline: const SizedBox(),
//                         dropdownColor: const Color(0xffF6F8FA),
//                         borderRadius: BorderRadius.circular(12.r),
//                         items: <String>[
//                           'Most Recent',
//                           'Pending',
//                           'Completed',
//                           'Cancelled',
//                         ].map<DropdownMenuItem<String>>((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Row(
//                               children: [
//                                 const Icon(
//                                   Icons.calendar_month_rounded,
//                                   size: 20,
//                                   color: Colors.grey,
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Text(
//                                   value,
//                                   style: const TextStyle(
//                                     color: Color(0xff4A4C56),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 10.h),
//               Expanded(
//                 child: Consumer<ItemTaskListProvider>(
//                   builder: (_, taskListProvider, __) {
//                     if (taskListProvider.pLoading) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//
//                     if (taskListProvider.filteredTaskListResponse?.tasks.isEmpty ?? true) {
//                       return const Center(
//                         child: Text(
//                           "No tasks available",
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                       );
//                     }
//
//                     return ListView.builder(
//                       controller: _scrollController, // <-- Very Important!
//                       padding: EdgeInsets.all(10.0),
//                       itemCount: taskListProvider.filteredTaskListResponse?.tasks.length ?? 0,
//                       itemBuilder: (BuildContext context, int index) {
//                         final task = taskListProvider.filteredTaskListResponse?.tasks[index];
//                         return CustomTaskCard(
//                           index: index + 1,
//                           upcomingTask: task?.upcomingTask ?? "",
//                           itemName: task?.itemName ?? "",
//                           status: task?.status ?? "",
//                           lastDate: task?.lastDate ?? "",
//                           taskId: task?.taskId ?? '',
//                           isLoading: taskListProvider.filteredTaskListResponse == null ||
//                               (taskListProvider.filteredTaskListResponse?.tasks.isEmpty ?? true),
//                           onTap: () async {
//                             context.read<ItemTaskListByItemIdProvider>().setLoader(true, task?.taskId ?? '');
//                             context.read<ItemTaskListByItemIdProvider>().setItemId(task?.itemId ?? '');
//                             await context.read<ItemTaskListByItemIdProvider>().setTaskId(task?.taskId ?? '', task?.itemId ?? '');
//                             Navigator.pushNamed(context, RouteName.trackingDetailScreen);
//                             context.read<ItemTaskListByItemIdProvider>().setLoader(false, task?.taskId ?? '');
//                           },
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: 60.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
