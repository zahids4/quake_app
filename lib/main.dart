import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() async => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quake App',
      home: Scaffold(
        appBar: AppBar(
          title: Text("Quakes"),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: FutureBuilder<List<Quake>>(
            future: _fetchQuakes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return createQuakesListView(context, snapshot);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }
}


Widget createQuakesListView(BuildContext context, AsyncSnapshot snapshot) {
  final _data = snapshot.data;
  return ListView.builder(
                  itemCount: _data.length,
                  padding: const EdgeInsets.all(10.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                            children: <Widget>[
                                Divider(height: 13.4),
                                ListTile(
                                  title: Text("${_data[index].time}", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  subtitle: Text("${_data[index].location}", style: TextStyle(fontSize: 17.0)),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.green,
                                    child: Text("${_data[index].magnitude}", style: TextStyle(color: Colors.white, fontSize: 25.0)),
                                  ),
                                  onTap: () => showTapMessage(context, _data[index].alertText),
                                )
                              ]
                            );
                  },
                );
}

void showTapMessage(BuildContext context, String message) {
  var alertDialog = new AlertDialog(
    title: Text("Quakes"),
    content: Text(message),
    actions: <Widget>[
      FlatButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text("Okay"),
      )
    ],
  );
  showDialog(context: context, builder: (context) {
    return alertDialog;
  });
}


Future<List<Quake>> _fetchQuakes() async {
  final response = await http.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson');
  var quakesData = List<Quake>();

  if (response.statusCode == 200) {
    final decodedBody = json.decode(response.body);
    List features = decodedBody["features"];
    for(var i = 0; i < features.length; i++){
        quakesData.add(new Quake.buildObject(features[i]));
    }

    return quakesData;
  } else {
    throw Exception('Failed to load post');
  }
}


class Quake {
  final String time;
  final String location;
  final String magnitude;
  final String alertText;

  Quake({this.time, this.location, this.magnitude, this.alertText});

  factory Quake.buildObject(Map<String, dynamic> fullObject) {
    final properties = fullObject["properties"];

    RegExp locationExp = new RegExp(r"\-(.*)");
    Match locationMatch = locationExp.firstMatch(properties['title']);

    RegExp magintudeExp = new RegExp(r"\M(.*?)\-");
    Match magnitudeMatch = magintudeExp.firstMatch(properties['title']);

    final time = new DateTime.fromMillisecondsSinceEpoch(properties['time']);
    String formattedDate = DateFormat.yMMMMd("en_US").add_jm().format(time);

    return Quake(
      time: formattedDate,
      location: locationMatch[1],
      magnitude: magnitudeMatch[1],
      alertText: properties["title"]
    );
  }
}
