// import 'package:flutter/material.dart';
//
// class _RouteTemplate {
//   final String templateId;
//   final String driverId;
//   final String name;
//   final String origin;
//   final String destination;
//   final List<String> stops;
//   final String departureTime;
//   final String? returnTime;
//   final List<String> days;
//   final int seats;
//   final int pricePerSeat;
//   final bool isActive;
//   final bool isRoundTrip;
//
//   const _RouteTemplate({
//     required this.templateId,
//     required this.driverId,
//     required this.name,
//     required this.origin,
//     required this.destination,
//     required this.stops,
//     required this.departureTime,
//     required this.returnTime,
//     required this.days,
//     required this.seats,
//     required this.pricePerSeat,
//     required this.isActive,
//     required this.isRoundTrip,
//   });
// }
//
// class CreateRouteScreen extends StatefulWidget {
//   final VoidCallback? onBack;
//   final void Function(_RouteTemplate route)? onSave;
//   final _RouteTemplate? editRoute;
//
//   const CreateRouteScreen({
//     super.key,
//     this.onBack,
//     this.onSave,
//     this.editRoute,
//   });
//
//   @override
//   State<CreateRouteScreen> createState() => _CreateRouteScreenState();
// }
//
// class _CreateRouteScreenState extends State<CreateRouteScreen> {
//   late TextEditingController routeNameController;
//   late TextEditingController originController;
//   late TextEditingController destinationController;
//   late TextEditingController newStopController;
//
//   late List<String> stops;
//   late bool isRoundTrip;
//   late String departureTime;
//   late String returnTime;
//   late List<String> selectedDays;
//   late int seats;
//   late int pricePerSeat;
//   bool showStopInput = false;
//   String newStop = '';
//
//   static const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//
//   @override
//   void initState() {
//     super.initState();
//
//     final edit = widget.editRoute;
//     routeNameController = TextEditingController(text: edit?.name ?? '');
//     originController = TextEditingController(text: edit?.origin ?? '');
//     destinationController = TextEditingController(text: edit?.destination ?? '');
//     newStopController = TextEditingController();
//     stops = edit?.stops ?? [];
//
//     isRoundTrip = edit?.isRoundTrip ?? false;
//     departureTime = edit?.departureTime ?? '08:00';
//     returnTime = edit?.returnTime ?? '18:00';
//     selectedDays = edit?.days ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
//     seats = edit?.seats ?? 3;
//     pricePerSeat = edit?.pricePerSeat ?? 50;
//   }
//
//   @override
//   void dispose() {
//     routeNameController.dispose();
//     originController.dispose();
//     destinationController.dispose();
//     newStopController.dispose();
//     super.dispose();
//   }
//
//   bool get isValid {
//     return originController.text.trim().isNotEmpty &&
//         destinationController.text.trim().isNotEmpty &&
//         selectedDays.isNotEmpty;
//   }
//
//   void toggleDay(String day) {
//     setState(() {
//       if (selectedDays.contains(day)) {
//         selectedDays = selectedDays.where((d) => d != day).toList();
//       } else {
//         selectedDays = [...selectedDays, day];
//       }
//     });
//   }
//
//   void addStop() {
//     final value = newStopController.text.trim();
//     if (value.isEmpty) return;
//     setState(() {
//       stops = [...stops, value];
//       newStopController.clear();
//       showStopInput = false;
//     });
//   }
//
//   void removeStop(int index) {
//     setState(() {
//       // Create a copy of the list and remove the item at the specific index
//       stops = List.from(stops)
//         ..removeAt(index);
//     });
//   }
//
//   void save() {
//     final edit = widget.editRoute;
//     final template = _RouteTemplate(
//       templateId: edit?.templateId ?? DateTime.now().millisecondsSinceEpoch.toString(),
//       driverId: edit?.driverId ?? 'd1',
//       name: routeNameController.text.trim().isNotEmpty
//           ? routeNameController.text.trim()
//           : '${originController.text.trim()} → ${destinationController.text.trim()}',
//       origin: originController.text.trim(),
//       destination: destinationController.text.trim(),
//       stops: stops,
//       departureTime: departureTime,
//       returnTime: isRoundTrip ? returnTime : null,
//       days: selectedDays,
//       seats: seats,
//       pricePerSeat: pricePerSeat,
//       isActive: true,
//       isRoundTrip: isRoundTrip,
//     );
//     widget.onSave?.call(template);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final potentialEarnings = seats * pricePerSeat;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.editRoute == null ? 'Create Route' : 'Edit Route'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: widget.onBack,
//         ),
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextField(
//               controller: routeNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Route Name (Optional)',
//                 hintText: 'e.g., Daily Office Commute',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: originController,
//                     decoration: const InputDecoration(
//                       labelText: 'Pickup Point',
//                       hintText: 'Enter starting location',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   for (int i = 0; i < stops.length; i++) ...[
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: TextEditingController(text: stops[i]),
//                             readOnly: true,
//                             decoration: InputDecoration(
//                               labelText: 'Stop ${i + 1}',
//                               border: const OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         IconButton(
//                           onPressed: () => removeStop(i),
//                           icon: const Icon(Icons.close),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                   showStopInput
//                       ? Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: newStopController,
//                                 autofocus: true,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Enter stop location',
//                                   border: OutlineInputBorder(),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             ElevatedButton(
//                               onPressed: addStop,
//                               child: const Text('Add'),
//                             ),
//                             const SizedBox(width: 8),
//                             IconButton(
//                               onPressed: () {
//                                 setState(() {
//                                   showStopInput = false;
//                                   newStopController.clear();
//                                 });
//                               },
//                               icon: const Icon(Icons.close),
//                             ),
//                           ],
//                         )
//                       : Align(
//                           alignment: Alignment.centerLeft,
//                           child: TextButton.icon(
//                             onPressed: () => setState(() => showStopInput = true),
//                             icon: const Icon(Icons.add),
//                             label: const Text('Add Stop'),
//                           ),
//                         ),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: destinationController,
//                     decoration: const InputDecoration(
//                       labelText: 'Drop-off Point',
//                       hintText: 'Enter destination',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 14),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.repeat, color: Colors.indigo),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: const [
//                             Text('Round Trip', style: TextStyle(fontWeight: FontWeight.w900)),
//                             SizedBox(height: 4),
//                             Text('Include return journey', style: TextStyle(color: Colors.black54, fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                       Switch(
//                         value: isRoundTrip,
//                         onChanged: (v) => setState(() => isRoundTrip = v),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           decoration: const InputDecoration(
//                             labelText: 'Departure',
//                             border: OutlineInputBorder(),
//                           ),
//                           controller: TextEditingController(text: departureTime),
//                           readOnly: true,
//                         ),
//                       ),
//                       if (isRoundTrip) ...[
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             decoration: const InputDecoration(
//                               labelText: 'Return',
//                               border: OutlineInputBorder(),
//                             ),
//                             controller: TextEditingController(text: returnTime),
//                             readOnly: true,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Repeat on',
//                     style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 10),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: daysOfWeek.map((d) {
//                       final selected = selectedDays.contains(d);
//                       return ChoiceChip(
//                         label: Text(d),
//                         selected: selected,
//                         onSelected: (_) => toggleDay(d),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 14),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Capacity & Pricing',
//                     style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
//                   ),
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Available Seats', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 IconButton(
//                                   onPressed: () => setState(() => seats = (seats <= 1 ? 1 : seats - 1)),
//                                   icon: const Icon(Icons.remove_circle_outline),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   '$seats',
//                                   style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 IconButton(
//                                   onPressed: () => setState(() => seats = (seats >= 6 ? 6 : seats + 1)),
//                                   icon: const Icon(Icons.add_circle_outline),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                             labelText: 'Price per Seat (₹)',
//                             border: OutlineInputBorder(),
//                           ),
//                           onChanged: (v) => setState(() => pricePerSeat = int.tryParse(v) ?? pricePerSeat),
//                           controller: TextEditingController(text: '$pricePerSeat'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: Colors.indigo.withOpacity(0.06),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.indigo.withOpacity(0.20)),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Potential earnings per trip',
//                             style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                         Text(
//                           '₹$potentialEarnings',
//                           style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w900, fontSize: 18),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: isValid ? save : null,
//                 child: Text(widget.editRoute == null ? 'Save Route Template' : 'Save Changes'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
