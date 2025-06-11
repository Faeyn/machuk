import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class Player {
  String name;
  double score;

  Player({required this.name, this.score = 0});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahjong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 0, 170, 255),
        ),
      ),
      home: const MyHomePage(title: 'Hilfon\'s mahjong app'),
    );
  }
}

Future<(int? modifier, int? loserIdx, bool isBoa)?> _showScoreDialog(
  BuildContext context,
  List<Player> players,
  int currentPlayerIdx,
) async {
  final modifierController = TextEditingController();
  int? selectedLoserIdx;
  bool isBao = false;

  final playerColors = [
    Colors.blue.withAlpha(200),
    Colors.red.withAlpha(200),
    Colors.green.withAlpha(200),
    Colors.yellow.withAlpha(200),
  ];

  return showDialog<(int?, int?, bool)>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: modifierController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    decoration: InputDecoration(labelText: '番'),
                  ),
                  SizedBox(height: 16),
                  Text('Select who loses:'),
                  ...players
                      .asMap()
                      .entries
                      .where(
                        (e) => e.key != currentPlayerIdx,
                      ) // exclude current player
                      .map((entry) {
                        final idx = entry.key;
                        final player = entry.value;
                        return RadioListTile<int>(
                          title: Text(
                            '${player.name} 出冲',
                            style: TextStyle(
                              backgroundColor: playerColors[idx],
                            ),
                          ),
                          value: idx,
                          groupValue: selectedLoserIdx,
                          onChanged: (int? val) {
                            setState(() => selectedLoserIdx = val);
                          },
                        );
                      }),
                  RadioListTile(
                    title: Text('自摸'),
                    value: 4,
                    groupValue: selectedLoserIdx,
                    onChanged: (int? val) {
                      setState(() => selectedLoserIdx = val);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('包 (Cover All)'),
                    value: isBao,
                    onChanged: selectedLoserIdx == 4
                        ? null // disable when 自摸 is selected
                        : (bool? value) {
                            setState(() {
                              isBao = value ?? false;
                            });
                          },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, (null, null, false)),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final mod = int.tryParse(modifierController.text);
                  if (mod != null && selectedLoserIdx != null) {
                    Navigator.pop(context, (mod, selectedLoserIdx, isBao));
                  }
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Player> players = [];
  double betSize = 0;

  void _showNamePrompt() {
    final controllers = List.generate(4, (_) => TextEditingController());
    final betSizeController = TextEditingController(text: betSize.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start new game'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.5, // limit height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                  4,
                  (index) => TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: betSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '€ / 番'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                players = controllers.map((c) => Player(name: c.text)).toList();
                betSize = double.tryParse(betSizeController.text) ?? 0;
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerColors = [
      Colors.blue.withAlpha(200),
      Colors.red.withAlpha(200),
      Colors.green.withAlpha(200),
      Colors.yellow.withAlpha(200),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          SizedBox(height: 25),
          SizedBox(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              padding: const EdgeInsets.all(16),
              children: [
                ...players.asMap().entries.map((entree) {
                  Player player = entree.value;
                  final currentIdx = entree.key;
                  final bgColor =
                      playerColors[currentIdx % playerColors.length];

                  return Card(
                    color: bgColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final results = await _showScoreDialog(
                          context,
                          players,
                          currentIdx,
                        );
                        final modifier = results?.$1;
                        final loserIdx = results?.$2;
                        final isBoa = results?.$3;

                        if (modifier != null &&
                            loserIdx != null &&
                            isBoa != null) {
                          final fullPrice = betSize * pow(2, modifier - 1);
                          final halfPrice =
                              betSize * pow(2, max(0, modifier - 2));

                          if (loserIdx < players.length) {
                            if (!isBoa) {
                              players[currentIdx].score +=
                                  2 * halfPrice + fullPrice;
                              players[loserIdx].score -= fullPrice;

                              for (var entry in players.asMap().entries) {
                                final otherIdx = entry.key;
                                final otherPlayer = entry.value;
                                if (otherIdx != currentIdx &&
                                    otherIdx != loserIdx) {
                                  otherPlayer.score -= halfPrice;
                                }
                              }
                            } else {
                              players[currentIdx].score += fullPrice * 3;
                              players[loserIdx].score -= fullPrice * 3;
                            }
                          } else {
                            players[currentIdx].score += 3 * fullPrice;
                            for (var entry in players.asMap().entries) {
                              final otherIdx = entry.key;
                              final otherPlayer = entry.value;
                              if (otherIdx != currentIdx) {
                                otherPlayer.score -= fullPrice;
                              }
                            }
                          }

                          setState(() => players = players);
                          print(
                            'Tapped on ${player.name} with modifier $modifier, new score: ${player.score}',
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 24.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(player.name, style: TextStyle(fontSize: 28)),
                            Text(
                              '€ ${player.score}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          if (betSize != 0)
            Text('€ $betSize / 番', style: TextStyle(fontSize: 28)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNamePrompt,
        tooltip: 'Enter Names',
        child: const Icon(Icons.add),
      ),
    );
  }
}
