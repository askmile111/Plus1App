import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '+1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          labelStyle: TextStyle(color: Colors.blue),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
      ),
      home: HomePage(),
    );
  }
}

class Activity {
  String name;
  int targetCount;
  int currentCount;
  bool isCompleted;

  Activity({
    required this.name,
    required this.targetCount,
    this.currentCount = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'isCompleted': isCompleted,
      };

  Activity.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        targetCount = json['targetCount'],
        currentCount = json['currentCount'],
        isCompleted = json['isCompleted'];
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Activity> activities = [];
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? activitiesJson = prefs.getString('activities');
    if (activitiesJson != null) {
      Iterable jsonList = json.decode(activitiesJson);
      activities = List<Activity>.from(jsonList.map((model) => Activity.fromJson(model)));
    }
    setState(() {});
  }

  Future<void> saveActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String activitiesJson = json.encode(activities);
    prefs.setString('activities', activitiesJson);
  }

  Future<void> clearActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('activities');
    setState(() {
      activities = [];
    });
  }

  void addActivity() {
    String name = _nameController.text;
    int targetCount = int.tryParse(_targetController.text) ?? 0;
    if (name.isNotEmpty && targetCount > 0) {
      setState(() {
        activities.add(Activity(name: name, targetCount: targetCount));
        _nameController.clear();
        _targetController.clear();
      });
      saveActivities();
    }
  }

  void incrementCount(int index) {
    setState(() {
      if (!activities[index].isCompleted) {
        activities[index].currentCount++;
        if (activities[index].currentCount >= activities[index].targetCount) {
          activities[index].isCompleted = true;
          showCompletionDialog(index);
        }
      }
      saveActivities();
    });
  }

  void decrementCount(int index) {
    setState(() {
      if (!activities[index].isCompleted && activities[index].currentCount > 0) {
        activities[index].currentCount--;
      }
      saveActivities();
    });
  }

  void showCompletionDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('恭喜！'),
          content: Text('你完成了目标！🍏'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () {
                setState(() {
                  activities[index].currentCount--;
                  activities[index].isCompleted = false;
                });
                saveActivities();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Activity> incompleteActivities = activities.where((a) => !a.isCompleted).toList();
    List<Activity> completedActivities = activities.where((a) => a.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '+1',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: clearActivities,
            tooltip: '清除所有活动',
          ),
        ],
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '活动名称',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _targetController,
                        decoration: InputDecoration(
                          labelText: '目标次数',
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.blue),
                    onPressed: addActivity,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...incompleteActivities.map((activity) => ListTile(
                  title: Row(
                    children: [
                      Text('${activity.name} - ${activity.currentCount}/${activity.targetCount}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.red),
                        onPressed: () => decrementCount(activities.indexOf(activity)),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () => incrementCount(activities.indexOf(activity)),
                      ),
                    ],
                  ),
                )),
                ...completedActivities.map((activity) => ListTile(
                  title: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.apple, color: Colors.green),
                      ),
                      Text('${activity.name} - ${activity.currentCount}/${activity.targetCount}'),
                    ],
                  ),
                  trailing: SizedBox(),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
