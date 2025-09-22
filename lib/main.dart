import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart'; // لعرض التاريخ بشكل مرتب

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Seat Booking',
      theme: ThemeData(primarySwatch: Colors.green),
      home:  SeatBookingScreen(),
    );
  }
}

class SeatBookingScreen extends StatefulWidget {
  const SeatBookingScreen({super.key});

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  DateTime selectedDate = DateTime.now();

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  Future<void> reserveSeat(int seatNumber, String? status, String? docId) async {
    final seatsRef = FirebaseFirestore.instance
        .collection('seats')
        .doc(formattedDate)
        .collection('daySeats');

    if (status == null || status == "available") {
      if (docId != null) {
        await seatsRef.doc(docId).update({
          "status": "reserved",
          "reservedBy": "guest_${DateTime.now().millisecondsSinceEpoch}"
        });
      } else {
        await seatsRef.add({
          "seatId": seatNumber,
          "status": "reserved",
          "reservedBy": "guest_${DateTime.now().millisecondsSinceEpoch}"
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(today);

    return Scaffold(
      appBar: AppBar(title: const Text("احجز كرسيك")),
      body: Column(
        children: [
          // 🔹 شريط التاريخ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: isToday
                      ? null // مينفعش نرجع عن النهاردة
                      : () {
                    setState(() {
                      selectedDate =
                          selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Next button
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),

          // 🔹 الكراسي
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('seats')
                  .doc(formattedDate)
                  .collection('daySeats')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final seatDocs = snapshot.data!.docs;
                final Map<int, Map<String, dynamic>> seatsMap = {
                  for (var doc in seatDocs)
                    (doc['seatId'] as int): {
                      "status": doc['status'],
                      "docId": doc.id,
                    }
                };

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: 60,
                  itemBuilder: (context, index) {
                    final seatNumber = index + 1;
                    final seatData = seatsMap[seatNumber];
                    final status = seatData?['status'] ?? "available";
                    final docId = seatData?['docId'];

                    Color color;
                    if (status == "available") color = Colors.grey;
                    else if (status == "reserved") color = Colors.red;
                    else color = Colors.blue;

                    return GestureDetector(
                      onTap: () {
                        if (status == "available") {
                          reserveSeat(seatNumber, status, docId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("الكرسي محجوز بالفعل")),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            seatNumber.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
