import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Gamble',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DiceGamble(),
    );
  }
}

class DiceGamble extends StatefulWidget {
  @override
  _DiceGambleState createState() => _DiceGambleState();
}

class _DiceGambleState extends State<DiceGamble> with SingleTickerProviderStateMixin {
  double walletBalance = 10.0;
  final TextEditingController wagerController = TextEditingController();
  String selectedGameType = "2 Alike";
  late TabController _tabController;

  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }


  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();


    setState(() {
      walletBalance = prefs.getDouble('walletBalance') ?? 10.0;
    });


    setState(() {
      history = prefs.getStringList('history') ?? [];
    });
  }


  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();


    await prefs.setDouble('walletBalance', walletBalance);


    await prefs.setStringList('history', history);
  }


  double maxWager(String gameType) {
    if (gameType == "2 Alike") return walletBalance / 2;
    if (gameType == "3 Alike") return walletBalance / 3;
    if (gameType == "4 Alike") return walletBalance / 4;
    return 0;
  }


  List<int> rollDice() {
    return List.generate(4, (_) => (1 + Random().nextInt(6)));
  }


  bool checkWin(List<int> rolls) {
    int count = rolls.where((x) => x == rolls[0]).length;
    if (selectedGameType == "2 Alike" && count >= 2) return true;
    if (selectedGameType == "3 Alike" && count >= 3) return true;
    if (selectedGameType == "4 Alike" && count >= 4) return true;
    return false;
  }


  void updateWallet(bool win, double wager) {
    setState(() {
      if (win) {
        walletBalance += wager * (selectedGameType == "2 Alike"
            ? 2
            : selectedGameType == "3 Alike"
            ? 3
            : 4);
      } else {
        walletBalance -= wager;
      }
    });


    _saveData();
  }


  bool isWagerValid(double wager) {
    return wager > 0 && wager <= maxWager(selectedGameType) && wager <= walletBalance;
  }


  void addHistory(double wager, List<int> rolls, bool win) {
    String result = "Wager: \$${wager.toStringAsFixed(2)} | Dice: $rolls | ${win ? "You Win" : "You Lose 🙃"} | Balance: \$${walletBalance.toStringAsFixed(2)}";
    setState(() {
      history.insert(0, result);
    });


    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dice Gamble"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Game'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Stack(
            children: [

              Positioned.fill(
                child: Image.asset(
                  'assets/background_image.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      "Wallet Balance: \$${walletBalance.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    TextField(
                      controller: wagerController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: "Enter wager",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                      ),
                      child: DropdownButton<String>(
                        value: selectedGameType,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGameType = newValue!;
                          });
                        },
                        items: <String>['2 Alike', '3 Alike', '4 Alike']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        style: TextStyle(color: Colors.black),
                        dropdownColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {

                        ScaffoldMessenger.of(context).clearSnackBars();

                        double wager = double.tryParse(wagerController.text) ?? 0;

                        if (wager <= 0 || wagerController.text.isEmpty) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Please enter a valid wager amount."),
                              backgroundColor: Colors.red,
                            ),);
                        } else if (isWagerValid(wager)) {
                          List<int> rolls = rollDice();
                          bool win = checkWin(rolls);
                          updateWallet(win, wager);
                          addHistory(wager, rolls, win);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Dice: $rolls | ${win ? "You Win" : "You Lose 🙃"}! New Balance: \$${walletBalance.toStringAsFixed(2)}"),
                          ),);

                          wagerController.clear();
                        } else {

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Wager exceeds available balance or max limit."),
                            backgroundColor: Colors.red,
                          ),);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      ),
                      child: Text("Go", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    history[index],
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
