import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Root of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Multi Screen App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

////////////////////////////////////////////////////
/// SCREEN 1 : HOME SCREEN
////////////////////////////////////////////////////

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController nameController = TextEditingController();

  String returnedMessage = "";

  /// Navigate to second screen and receive returned data
  void goToSecondScreen() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondScreen(name: nameController.text),
      ),
    );

    if (result != null) {
      setState(() {
        returnedMessage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 80, color: Colors.blue),

            const SizedBox(height: 20),

            const Text("Enter Your Name", style: TextStyle(fontSize: 20)),

            const SizedBox(height: 10),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type your name",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: goToSecondScreen,
              child: const Text("next"),
            ),

            const SizedBox(height: 20),

            Text(
              returnedMessage,
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// SCREEN 2 : SECOND SCREEN
////////////////////////////////////////////////////

class SecondScreen extends StatelessWidget {
  final String name;

  const SecondScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("previous")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.orange),

            const SizedBox(height: 20),

            Text("Hello $name", style: const TextStyle(fontSize: 24)),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text("next"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThirdScreen(name: name),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// SCREEN 3 : THIRD SCREEN
////////////////////////////////////////////////////

class ThirdScreen extends StatefulWidget {
  final String name;

  const ThirdScreen({super.key, required this.name});

  @override
  State<ThirdScreen> createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  int counter = 0;

  void increaseCounter() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("previous")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 80, color: Colors.purple),

            const SizedBox(height: 20),

            Text(
              "${widget.name}, tap the button!",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 20),

            Text("Counter: $counter", style: const TextStyle(fontSize: 28)),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: increaseCounter,
              child: const Text("Tap"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  "Thanks ${widget.name}! You tapped $counter times.",
                );
              },
              child: const Text("Return to Welcome Page"),
            ),
          ],
        ),
      ),
    );
  }
}
