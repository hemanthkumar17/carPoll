import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' hide TextStyle;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: DashBoard(),
    );
  }
}

class DashBoard extends StatefulWidget {
  DashBoard({Key key}) : super(key: key);

  @override
  _DashBoardState createState() => _DashBoardState();
}

class ChartData {
  double efficiency;
  DateTime date;
  ChartData(this.efficiency, this.date);
}

class CarData {
  String regNo;
  String carName;
  List<ChartData> data;
  CarData(this.regNo, this.carName, this.data);
  factory CarData.fromJson(Map<String, dynamic> json) {
    List<ChartData> cdata = [];
    json["journeyData"].forEach((e) {
      cdata = cdata +
          [
            ChartData(
                e["emissionAvg"].toDouble(), DateTime.parse(e["startTime"]))
          ];
    });
    return CarData(
      '1234',
      'Audi',
      cdata,
    );
  }
}

class _DashBoardState extends State<DashBoard> {
  List<CarData> cars;
  CarData current;
  List<ListTile> drawerFragments = [];
  int i = 0;
  List<String> text = ["Time Plot", "Bar Graph"];
  List<Series<dynamic, String>> series1 = [];
  List<Series<dynamic, DateTime>> series2 = [];
  List<Widget> chartList = [];
  final _formKey = GlobalKey<FormState>();
  String deviceId;
  final _deviceIdController = TextEditingController();

  void initState() {
    super.initState();
    fetchData();
  }

  storeId(text) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('_deviceId', text);
  }

  getId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      deviceId = prefs.getString('_deviceId') ?? "testid69";
    });
  }

  fetchData() async {
    getId();
    if (deviceId == null) deviceId = "testid69";
    cars = [
      null,
      new CarData('TN11AA1111', 'Audi A6', [
        ChartData(10, DateTime.now()),
        ChartData(20, DateTime.now().add(Duration(days: 4)))
      ]),
    ];

    Map<String, String> qParams = {
      "deviceId": deviceId,
      "startTime": DateTime.now()
          .add(Duration(days: -2 * 365))
          .toString()
          .substring(0, 10),
      "endTime": DateTime.now().toString().substring(0, 10),
    };

    final invokeEventUrl = "carspoll.azurewebsites.net";
    final eventUrl = Uri.https(invokeEventUrl, '/getdata', qParams);
    print(eventUrl);

    final r =
        await get(eventUrl, headers: {"Content-Type": "application/json"});

    cars[0] = CarData.fromJson(json.decode(r.body));
    current = cars[0];

    series1 = [
      new Series<ChartData, String>(
        id: 'Efficiency',
        domainFn: (ChartData chartData, _) => chartData.date.day.toString(),
        measureFn: (ChartData chartData, _) => chartData.efficiency,
        data: current.data,
      )
    ];
    
    series2 = [
      new Series<ChartData, DateTime>(
        id: 'Efficiency',
        domainFn: (ChartData chartData, _) => chartData.date,
        measureFn: (ChartData chartData, _) => chartData.efficiency,
        data: current.data,
      )
    ];
    chartList = [
      BarChart(series1, animate: true),
      TimeSeriesChart(series2, animate: true)
    ];

    setState(() {
      for (CarData c in cars) {
        drawerFragments.add(
          ListTile(
            title: Text(c.carName),
            onTap: () {
              setState(() {
                current = c;
                series1 = [
                  new Series<ChartData, String>(
                    id: 'Efficiency',
                    domainFn: (ChartData chartData, _) =>
                        chartData.date.day.toString(),
                    measureFn: (ChartData chartData, _) => chartData.efficiency,
                    colorFn: (ChartData chartData, _) =>
                        MaterialPalette.blue.shadeDefault,
                    data: current.data,
                  )
                ];
                series2 = [
                  new Series<ChartData, DateTime>(
                    id: 'Efficiency',
                    domainFn: (ChartData chartData, _) => chartData.date,
                    measureFn: (ChartData chartData, _) => chartData.efficiency,
                    colorFn: (ChartData chartData, _) =>
                        MaterialPalette.blue.shadeDefault,
                    data: current.data,
                  )
                ];
              });
              chartList = [
                BarChart(series1, animate: true),
                TimeSeriesChart(series2, animate: true)
              ];
              Navigator.pop(context);
            },
          ),
        );
      }
    });
  }

  void getDeviceId() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                Positioned(
                  right: -40.0,
                  top: -40.0,
                  child: InkResponse(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      child: Icon(Icons.close),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: TextFormField(
                            validator: (value) {
                              if (value.isEmpty) return 'Enter the device ID';
                              return null;
                            },
                            controller: _deviceIdController,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.vpn_key),
                              hintText: 'Enter your Device Id',
                              labelText: 'Device ID',
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          child: Text("Submit"),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              Navigator.pop(context);
                              storeId(_deviceIdController.text);
                              setState(() {
                                fetchData();
                              });
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    if (cars == null)
      return Container(
          color: Colors.white,
          child: Center(
            child: CircularProgressIndicator(),
          ));

    return Scaffold(
        appBar: AppBar(
          title: Text(current.carName),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.settings), onPressed: () => getDeviceId())
          ],
        ),
        drawer: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
                Container(
                    height: 100,
                    child: DrawerHeader(
                      child: Text(
                        'Vehicles',
                        style: TextStyle(fontSize: 25),
                        textAlign: TextAlign.center,
                      ),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          gradient: LinearGradient(
                              colors: [Colors.lightBlue, Colors.white])),
                    )),
                Padding(padding: EdgeInsets.all(10))
              ] +
              drawerFragments,
        )),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Container(child: Image.asset('assets/images/car_icon.jpg')),
            Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            Center(
                child: Text(
              current.carName,
              style: TextStyle(fontSize: 40),
            )),
            Center(child: Text(current.regNo)),
            RaisedButton(
              onPressed: () {
                setState(() {
                  (i == 0) ? i = 1 : i = 0;
                });
              },
              textColor: Colors.white,
              padding: const EdgeInsets.all(0.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(text[i], style: TextStyle(fontSize: 20)),
                decoration: BoxDecoration(color: Colors.blue),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(32.0),
              child: SizedBox(
                height: 200.0,
                child: chartList[i],
              ),
            )
          ],
        )));
  }
}
