import 'package:canta/applist.dart';
import 'package:canta/kotlin_bind.dart';
import 'package:canta/pair.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:installed_apps/app_info.dart';
import 'package:mobx/mobx.dart';

void main() {
  runApp(const CantaApp());
}

class CantaApp extends StatelessWidget {
  const CantaApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canta',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.orange,
      ),
      home: const HomePage(title: 'Canta'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppList appList = AppList();
  final KotlinBind nativeService = KotlinBind();
  List<Function(Pair<AppInfo, bool>)> filters = [];

  _HomePageState();

  /// Builds the list of apps with checkboxes.
  Future<ListView> _buildAppList() async {
    final List<Row> appStructure = [];
    final List<Pair<AppInfo, bool>> allApps = await appList.apps;

    List<Pair<AppInfo, bool>> filteredApps = allApps.where((appInfo) {
      return filters.every((filter) => filter(appInfo));
    }).toList();

    for (var element in filteredApps) {
      var app = element.left;
      var systemApp = element.right;

      appStructure.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          app.icon!,
                          width: 48,
                          height: 48,
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(app.name!,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                            Text(app.packageName!),
                            getBadgeElement(systemApp),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Observer(
              builder: (_) => Checkbox(
                value: appList.selectedApps.contains(app.packageName!),
                onChanged: (value) => _toggleApp(value, app.packageName!),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(children: appStructure);
  }

  Future<Scaffold> _buildUninstalledAppList() async {
    final List<Row> appStructure = [];
    final List<String> allApps = await nativeService.getUninstalledApps();

    if (allApps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No recoverable uninstalled apps found.",
                style: TextStyle(fontSize: 18)),
          ),
        ),
      );
    }

    for (var packageName in allApps) {
      appStructure.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(packageName,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Observer(
              builder: (_) => Checkbox(
                value: appList.selectedApps.contains(packageName),
                onChanged: (value) => _toggleApp(value, packageName),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: ListView(children: appStructure),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightGreen,
        onPressed: _reinstallApps,
        tooltip: 'Reinstall apps.',
        child: const Icon(
          Icons.install_mobile,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.auto_delete_outlined)),
                Tab(icon: Icon(Icons.delete_forever)),
              ],
            ),
            title: Text(widget.title, style: const TextStyle(fontSize: 24)),
          ),
          body: TabBarView(
            children: [
              Scaffold(
                body: Center(
                  // Center is a layout widget. It takes a single child and positions it
                  // in the middle of the parent.
                  child: FutureBuilder(
                    future: _buildAppList(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data as Widget;
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Loading apps ..."),
                          SizedBox(height: 16.0),
                          CircularProgressIndicator(),
                        ],
                      );
                    },
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: _uninstallApps,
                  tooltip: 'Uninstall',
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ),
              Center(
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: FutureBuilder(
                  future: _buildUninstalledAppList(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data as Widget;
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Loading uninstalled apps... "),
                        SizedBox(height: 16.0),
                        CircularProgressIndicator(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @action
  void _toggleApp(bool? value, String packageName) {
    if (value!) {
      appList.selectedApps.add(packageName);
    } else {
      appList.selectedApps.remove(packageName);
    }
  }

  void _uninstallApps() {
    for (var packageName in appList.selectedApps) {
      nativeService.uninstallApp(packageName);
    }
  }

  void _reinstallApps() {
    for (var packageName in appList.selectedApps) {
      nativeService.reinstallApp(packageName);
    }
  }

  getBadgeElement(bool systemApp) {
    if (systemApp) {
      return Badge(
        label: Row(
          children: const [
            Icon(Icons.android),
            SizedBox(width: 8.0),
            Text("System App"),
          ],
        ),
        backgroundColor: Colors.redAccent,
      );
    } else {
      return const SizedBox();
    }
  }
}
