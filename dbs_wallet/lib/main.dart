import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

//Local
// const hostName = "http://localhost:3000";
// const hostNameLocal = "http://localhost:3000";

//Prod
const hostName = "https://sleepy-stream-22657.herokuapp.com/proxy";
const hostNameLocal = "https://sleepy-stream-22657.herokuapp.com";

class Reward {
  final String customer;
  final String point;

  Reward({required this.customer, required this.point});

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      customer: json['customer'],
      point: json['point'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['customer'] = customer;
    data['point'] = point;
    return data;
  }
}

class Redeem {
  final String point;
  final String voucher;
  final String customer;

  Redeem({required this.voucher, required this.point, required this.customer});

  factory Redeem.fromJson(Map<String, dynamic> json) {
    return Redeem(
      voucher: json['voucher'],
      point: json['point'],
      customer: json['customer'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['voucher'] = voucher;
    data['point'] = point;
    data['customer'] = customer;
    return data;
  }
}

class Voucher {
  final String name;
  final String point;

  Voucher({required this.name, required this.point});

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      name: json['name'],
      point: json['point'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['point'] = this.point;
    return data;
  }
}

Future<List<Voucher>> fetchVouchers() async {
  final response = await http.get(Uri.parse('$hostNameLocal/vouchers'));
  if (response.statusCode >= 200 && response.statusCode < 300) {
    var responseJson = json.decode(response.body);
    return (responseJson as List).map((p) => Voucher.fromJson(p)).toList();
  } else {
    throw Exception('Failed to load album');
  }
}

Future<List<Redeem>> fetchRedemption(String customer) async {
  final response = await http
      .get(Uri.parse('$hostName/getRedemptionState?customer=$customer'));
  if (response.statusCode >= 200 && response.statusCode < 300) {
    var responseJson = json.decode(response.body);
    return (responseJson as List)
        .map((p) => Redeem.fromJson(p))
        .where((element) => element.customer == customer)
        .toList();
  } else {
    throw Exception('Failed to load album');
  }
}

Future<Reward> createIssue(String customer, String point) async {
  final response = await http.get(
    Uri.parse('$hostName/issue?customer=$customer&point=$point'),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // then parse the JSON.
    return Reward(customer: customer, point: point);
  } else {
    throw Exception('Failed to create album.');
  }
}

Future<Voucher> createVoucher(String name, String point) async {
  print("$name, $point");
  final response = await http.post(
      Uri.parse('$hostNameLocal/vouchers?customer=$name&point=$point'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'point': point,
      }));

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // then parse the JSON.
    return Voucher(name: name, point: point);
  } else {
    throw Exception('Failed to create album.');
  }
}

Future<Reward> createRedeem(
    String customer, String point, String voucher) async {
  final response = await http.get(
    Uri.parse(
        '$hostName/redeem?voucher=$voucher&customer=$customer&point=$point'),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // then parse the JSON.
    return Reward(customer: customer, point: point);
  } else {
    throw Exception('Failed to create album.');
  }
}

Future<List<Reward>> fetchRewards(String customer) async {
  final response =
      await http.get(Uri.parse('$hostName/getRewardState?customer=$customer'));

  if (response.statusCode >= 200 && response.statusCode < 300) {
    var responseJson = json.decode(response.body);
    return (responseJson as List)
        .map((p) => Reward.fromJson(p))
        .where((element) => element.customer == customer)
        .toList();
  } else {
    throw Exception('Failed to load album');
  }
}

class TransactionScreen extends StatefulWidget {
  final String username;
  const TransactionScreen({Key? key, required this.username}) : super(key: key);

  @override
  _TransactionScreen createState() => _TransactionScreen();
}

@immutable
class _TransactionScreen extends State<TransactionScreen> {
  late Future<List<Redeem>> futureRedeems;
  @override
  void initState() {
    super.initState();
    futureRedeems = fetchRedemption(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Transctions'),
        ),
        body: Center(
            child: FutureBuilder<List<Redeem>>(
          future: futureRedeems,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text("${snapshot.error}");
            if (snapshot.hasData) {
              List<Redeem> items = (snapshot.data as List<Redeem>);
              return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index].voucher),
                      subtitle: Text("Points: ${items[index].point}"),
                    );
                  });
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        )));
  }
}

class RedeemScreen extends StatefulWidget {
  final String username;
  const RedeemScreen({Key? key, required this.username}) : super(key: key);

  @override
  _RedeemScreen createState() => _RedeemScreen();
}

@immutable
class _RedeemScreen extends State<RedeemScreen> {
  late Future<List<Voucher>> futureVoucher;
  @override
  void initState() {
    super.initState();
    futureVoucher = fetchVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Readem Vouchers"),
        ),
        body: FutureBuilder<List<Voucher>>(
          future: futureVoucher,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text("${snapshot.error}");
            if (snapshot.hasData) {
              List<Voucher> items = (snapshot.data as List<Voucher>);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  Voucher voucher = items[index];
                  return Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Image.asset("images/paylah_log.png"),
                          title: Text(voucher.name),
                          subtitle: Text("Points: ${voucher.point}"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text('REDEEM'),
                              onPressed: () {
                                createRedeem(
                                  widget.username,
                                  voucher.point,
                                  voucher.name,
                                )
                                    .then((value) => {
                                          showDialog<String>(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                    title:
                                                        const Text('Redeem OK'),
                                                    content: Text(
                                                        'Your transaction has been completed successfully!',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        )),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context,
                                                                'Cancel'),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, 'OK'),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  )).then((value) => {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TransactionScreen(
                                                      username: widget.username,
                                                    ),
                                                  ),
                                                )
                                              })
                                        })
                                    .catchError((e) {
                                  showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: const Text('Server Error'),
                                            content: Text('${e}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red)),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'Cancel'),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'OK'),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ));
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}

class User {
  final String username;
  const User(
    this.username,
  );
}

@immutable
class RewardBoxList extends StatelessWidget {
  final List<Reward> items;
  final String username;
  const RewardBoxList({Key? key, required this.items, required this.username})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final points = items.fold<int>(0, (t, e) => t + int.parse(e.point));
    List<String> images = [
      "images/gift_vouchers.png",
      "images/shopping.png",
      "images/transactions.png"
    ];
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: CircleAvatar(
              backgroundImage: AssetImage("images/user_logo.png"),
              child: Text(username),
              radius: 80,
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(
                text: 'Welcome back! ',
                style: const TextStyle(fontSize: 18, color: Color(0xff444444)),
                children: <TextSpan>[
                  TextSpan(
                      text: username,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ', You have total '),
                  TextSpan(
                      text: "$points",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' points.'),
                ],
              ),
            )),
        Expanded(
            child: GridView.count(
          primary: false,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          crossAxisCount: 2,
          children: <Widget>[
            ...images.map((image) => Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: Colors.indigo[400],
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      if (image.contains("gift")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RedeemScreen(
                              username: username,
                            ),
                          ),
                        );
                      } else if (image.contains("transactions")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionScreen(
                              username: username,
                            ),
                          ),
                        );
                      }
                    },
                    child: Image.asset(
                      image,
                      fit: BoxFit.fill,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.all(10),
                )),
          ],
        ))
      ],
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState!.validate()) {
                  // Process data.
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _HomePageSate createState() => _HomePageSate();
}

class _HomePageSate extends State<HomePage> {
  late Future<List<Reward>> futureRewards;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  static const _actionTitles = ['Create Post', 'Upload Photo', 'Upload Video'];
  Map<String, TextEditingController> controllers = {
    "username": TextEditingController(),
    "point": TextEditingController()
  };
  void _onRefresh() async {
    setState(() {
      futureRewards = fetchRewards(widget.user.username);
    });
    _refreshController.refreshCompleted();
  }

  @override
  void initState() {
    super.initState();
    futureRewards = fetchRewards(widget.user.username);
  }

  _displayDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
            body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Issue Points',
                  style: TextStyle(color: Colors.black26, fontSize: 18),
                ),
                TextField(
                  controller: controllers["username"],
                  decoration: InputDecoration(
                    hintText: widget.user.username.contains("bank")
                        ? 'Enter Username'
                        : "Enter Voucher Code",
                  ),
                ),
                TextField(
                  controller: controllers["point"],
                  decoration: const InputDecoration(
                    hintText: 'Enter Points',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (widget.user.username.contains("bank")) {
                      createIssue(controllers["username"]?.text ?? "deepak",
                              controllers["point"]?.text ?? "100")
                          .then((value) => {Navigator.of(context).pop()});
                    } else {
                      createVoucher(
                              controllers["username"]?.text ?? "DBSSHOP30",
                              controllers["point"]?.text ?? "100")
                          .then((value) => {Navigator.of(context).pop()});
                    }
                  },
                  child: Text(
                    "Issue",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ));
      },
    ).then((val) {
      setState(() {
        futureRewards = fetchRewards(widget.user.username);
      });
    });
  }

  void _showAction(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(_actionTitles[index]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.account_circle_rounded),
        title: const Text('Rewards'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
            ),
            tooltip: "Logout",
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: WaterDropHeader(),
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = Text("pull up load");
            } else {
              body = Text("");
            }
            return Container(
              height: 55.0,
              child: Center(child: body),
            );
          },
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: Center(
          child: FutureBuilder<List<Reward>>(
            future: futureRewards,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("${snapshot.error}");
              if (snapshot.hasData) {
                List<Reward> items = (snapshot.data as List<Reward>);
                return RewardBoxList(
                  items: items,
                  username: widget.user.username,
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add your onPressed code here!
          _displayDialog(context);
        },
        label: Text(widget.user.username.contains("bank")
            ? 'Issue'
            : widget.user.username.contains("dbs")
                ? "Vouchers"
                : "Redeem"),
        icon: Icon(widget.user.username.contains("bank")
            ? Icons.edit
            : widget.user.username.contains("dbs")
                ? Icons.edit
                : Icons.shopping_cart),
        backgroundColor: Colors.pink,
      ),

      // ExpandableFab(
      //   distance: 112.0,
      //   children: [
      //     ActionButton(
      //       onPressed: () => {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const RedeemScreen()),
      //         )
      //       },
      //       icon: const Icon(Icons.add_shopping_cart),
      //     ),
      //     ActionButton(
      //       onPressed: () => _showAction(context, 1),
      //       icon: const Icon(Icons.view_list),
      //     ),
      //     ActionButton(
      //       onPressed: () => _showAction(context, 2),
      //       icon: const Icon(Icons.account_balance_wallet),
      //     ),
      //   ],
      // ),
    );
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    Key? key,
    this.initialOpen,
    required this.distance,
    required this.children,
  }) : super(key: key);

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.create),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    Key? key,
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  }) : super(key: key);

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.accentColor,
      elevation: 4.0,
      child: IconTheme.merge(
        data: theme.accentIconTheme,
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginDemoState createState() => _LoginDemoState();
}

class _LoginDemoState extends State<LoginScreen> {
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Center(
                child: Container(
                    width: 200,
                    height: 150,
                    /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                    child: Image.asset('images/dbs_logo.png')),
              ),
            ),
            Padding(
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: myController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'User Name',
                    hintText: 'Enter your username'),
              ),
            ),
            const Padding(
              padding:
                  EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter secure password'),
              ),
            ),
            TextButton(
              onPressed: () {
                //TODO FORGOT PASSWORD SCREEN GOES HERE
              },
              child: const Text(
                'Forgot Password',
                style: TextStyle(color: Colors.blue, fontSize: 15),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomePage(user: User(myController.text)),
                    ),
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 130,
            ),
            const Text('New User? Create Account')
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryTextTheme: Typography(platform: TargetPlatform.iOS).black,
        textTheme: Typography(platform: TargetPlatform.iOS).black,
        primarySwatch: Colors.red,
      ),
      home: const LoginScreen(),
    );
  }
}
