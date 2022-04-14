import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'glob.dart' as glob;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Waiting(),
    );
  }
}

class Waiting extends StatefulWidget {
  @override
  State<Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<Waiting> {
  getDate() async {
    final prefs = await SharedPreferences.getInstance();
    glob.pref = prefs;
    glob.login = prefs.getString('login') ?? "";
    glob.password = prefs.getString("password") ?? "";
    glob.register = prefs.getBool("reg") ?? false;
    glob.worker = prefs.getBool("worker") ?? false;
    // glob.login = "";
    // glob.password = "";
    // glob.register = false;
    // glob.worker = false;
    glob.connection = PostgreSQLConnection(
        "ec2-52-212-228-71.eu-west-1.compute.amazonaws.com",
        5432,
        "d3tseo5gv9ovt0",
        username: "fihwdbrsfayccb",
        password:
            "d67b81472a9f6b83e07790e56787b360b2c3d0b1434638c89c3c1e1ea146d20a",
        useSSL: true);
    await glob.connection.open();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => glob.register!
                ? [Workers(), Jobs()][glob.worker! ? 1 : 0]
                : Login()));
    setState(() {});
  }

  @override
  void initState() {
    getDate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class Jobs extends StatefulWidget {
  @override
  State<Jobs> createState() => _JobsState();
}

class _JobsState extends State<Jobs> {
  List<List<dynamic>> jobs = [];

  getData() async {
    jobs = await glob.connection
        .query('SELECT * from jobs where not jobs.finished');
    setState(() {});
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Login()));
          },
        ),
        title: const Text("Работа"),
        automaticallyImplyLeading: false,
      ),
      body: [
        const Center(child: CircularProgressIndicator()),
        ListView.builder(
            itemCount: jobs.length,
            itemBuilder: ((context, index) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.album),
                      title: Text(jobs[index][0]),
                      subtitle: Text(jobs[index][9] ?? "Простой рабочий"),
                    ),
                    Text(jobs[index][5]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        const SizedBox(width: 8),
                        TextButton(
                          child: const Text('Написать'),
                          onPressed: () async {
                            await launch("https://t.me/" + jobs[index][4],
                                forceSafariVC: true);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              );
            }))
      ].elementAt(jobs.isEmpty ? 0 : 1),
    );
  }
}

class Workers extends StatefulWidget {
  @override
  State<Workers> createState() => _WorkersState();
}

class _WorkersState extends State<Workers> {
  List<List<dynamic>> workers = [];

  getData() async {
    workers = await glob.connection.query('SELECT * from "Workers"');

    setState(() {});
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Рабочии",
            style: TextStyle(fontSize: 35),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Login()));
            },
          ),
          automaticallyImplyLeading: false),
      body: [
        const Center(child: CircularProgressIndicator()),
        ListView.builder(
          itemCount: workers.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.album),
                    title: Text(workers[index][4]),
                    subtitle: Text(workers[index][1] ?? "Простой рабочий"),
                  ),
                  Text(workers[index][2]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Написать'),
                        onPressed: () async {
                          await launch("https://t.me/" + workers[index][4],
                              forceSafariVC: true);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ].elementAt(workers.isEmpty ? 0 : 1),
    );
  }
}

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var error = "";
  bool _switchValue = true;
  var password = '';
  var login = '';
  bool isHidden = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Вход",
          style: TextStyle(fontSize: 35),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          margin: const EdgeInsets.all(20),
          child: TextFormField(
              cursorColor: Colors.black,
              autofillHints: const [AutofillHints.password],
              keyboardType: TextInputType.visiblePassword,
              onEditingComplete: () => TextInput.finishAutofillContext(),
              onChanged: (e) {
                login = e;
              },
              decoration: InputDecoration(
                fillColor: Colors.blueAccent,
                iconColor: Colors.blueAccent,
                focusColor: Colors.blueAccent,
                hintText: "Логин телеграма",
                border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                disabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: const Icon(
                  Icons.account_circle_rounded,
                  color: Colors.blueAccent,
                ),
              )),
        ),
        Container(
          margin: const EdgeInsets.all(20),
          child: TextFormField(
              cursorColor: const Color.fromRGBO(243, 167, 65, 1),
              obscureText: isHidden,
              autofillHints: const [AutofillHints.password],
              keyboardType: TextInputType.visiblePassword,
              onEditingComplete: () => TextInput.finishAutofillContext(),
              onChanged: (e) {
                password = e;
              },
              decoration: InputDecoration(
                fillColor: const Color.fromRGBO(243, 167, 65, 1),
                iconColor: const Color.fromRGBO(243, 167, 65, 1),
                focusColor: const Color.fromRGBO(243, 167, 65, 1),
                suffixIcon: IconButton(
                  icon: isHidden
                      ? const Icon(
                          Icons.visibility_off,
                          color: Colors.blueAccent,
                        )
                      : const Icon(
                          Icons.visibility,
                          color: Colors.blueAccent,
                        ),
                  onPressed: togglePasswordVisibility,
                ),
                hintText: "Пароль",
                border: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(255, 20, 154, 221)),
                    borderRadius: BorderRadius.circular(20.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                disabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color.fromRGBO(27, 27, 27, 1)),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Colors.blueAccent,
                ),
              )),
        ),
        Text(
          error,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Исполнитель"),
            CupertinoSwitch(
              value: _switchValue,
              activeColor: Colors.blueAccent,
              onChanged: (value) {
                setState(() {
                  _switchValue = value;
                });
              },
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
          child: ElevatedButton(
            onPressed: () async {
              if (_switchValue) {
                List<List<dynamic>> results = await glob.connection.query(
                    'SELECT * from "Workers" where "Workers".login = @login',
                    substitutionValues: {
                      "login": login,
                    });
                var user = results;
                if (user.isEmpty) {
                  setState(() {
                    error = "нет такого пользователя";
                  });
                } else if (user[0][5] ==
                    sha256.convert(utf8.encode(password)).toString()) {
                  glob.login = login;
                  glob.password =
                      sha256.convert(utf8.encode(password)).toString();
                  glob.register = true;
                  glob.worker = true;
                  await glob.pref.setString('login', login);
                  await glob.pref.setString('password', password);
                  await glob.pref.setBool("reg", true);
                  await glob.pref.setBool("worker", true);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Jobs()));
                } else {
                  setState(() {
                    error = "пароль не верен";
                  });
                }
              } else {
                List<List<dynamic>> results = await glob.connection.query(
                    'SELECT * from "Employers" where "Employers".login = @login',
                    substitutionValues: {
                      "login": login,
                    });
                var user = results;
                if (user.isEmpty) {
                  setState(() {
                    error = "нет такого пользователя";
                  });
                } else if (user[0][3] ==
                    sha256.convert(utf8.encode(password)).toString()) {
                  glob.login = login;
                  glob.password =
                      sha256.convert(utf8.encode(password)).toString();
                  glob.register = true;
                  glob.worker = false;
                  await glob.pref.setString('login', login);
                  await glob.pref.setString('password', password);
                  await glob.pref.setBool("reg", true);
                  await glob.pref.setBool("worker", false);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Workers()));
                } else {
                  setState(() {
                    error = "пароль не верен";
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            ),
            child: const Center(
                child: Text(
              "Вход",
              style: TextStyle(color: Colors.white, fontSize: 30),
            )),
          ),
        )
      ])),
    );
  }

  void togglePasswordVisibility() => setState(() => isHidden = !isHidden);
}
