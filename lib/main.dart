import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

// Pastikan URL-nya persis kayak di console, pake https dan akhiri dengan /
final FirebaseDatabase database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL:
      'https://aethera-iot-default-rtdb.asia-southeast1.firebasedatabase.app/',
);

final databaseRef = database.ref('sensor');

Widget _buildMainChart(List<double> dataPoints) {
  return Container(
    height: 200,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: Colors.lightGreenAccent.shade700,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.lightGreenAccent.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Aethera IoT",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        useMaterial3: true,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        toolbarHeight: 80,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(
            Icons.water_drop_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "AETHERA",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  "Device Connected",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.history_rounded),
            tooltip: "Riwayat Data",
          ),
          SizedBox(width: 8),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final rawData =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final data = Map<String, dynamic>.from(rawData);

            final ph = data['ph']?.toString() ?? "0.0";
            final temp = data['temp']?.toString() ?? "0.0";
            final tds = data['tds']?.toString() ?? "0";

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Monitoring",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Tren Kualitas Air (pH)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildMainChart([7.0, 7.2, 7.1, 7.5, 7.3, 8.0, 7.8]),
                  SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildSensorCard(
                        context,
                        title: "pH Air",
                        value: ph,
                        unit: "pH",
                        icon: Icons.science_rounded,
                        color: Colors.blue,
                      ),
                      _buildSensorCard(
                        context,
                        title: "Suhu",
                        value: temp,
                        unit: "°C",
                        icon: Icons.thermostat_rounded,
                        color: Colors.orange,
                      ),
                      _buildSensorCard(
                        context,
                        title: "TDS",
                        value: tds,
                        unit: "ppm",
                        icon: Icons.opacity_rounded,
                        color: Colors.cyan,
                      ),
                      _buildSensorCard(
                        context,
                        title: "Status",
                        value: double.parse(ph) > 8.5 ? "Bahaya" : "Aman",
                        unit: "",
                        icon: Icons.check_circle_rounded,
                        color: double.parse(ph) > 8.5
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Kesalahan ketika mengambil data"));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

Widget _buildSensorCard(
  BuildContext context, {
  required String title,
  required String value,
  required String unit,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 35),
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    ),
  );
}
