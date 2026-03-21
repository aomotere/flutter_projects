import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Main application widget.
// This is a StatelessWidget because the overall app configuration does not change.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp provides basic app structure such as themes and navigation
    return const MaterialApp(
      home: MyHomePage(), // Loads the main home page of the app
    );
  }
}

// MyHomePage is a StatefulWidget because the greeting text changes
// when the user enters their name and presses the button.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// State class that manages dynamic data for MyHomePage
class _MyHomePageState extends State<MyHomePage> {
  // Controller used to read the text entered in the TextField
  final TextEditingController nameController = TextEditingController();

  // Variable that stores the greeting message displayed on the screen
  String greeting = "";

  // Function that updates the greeting when the button is pressed
  void showGreeting() {
    setState(() {
      // setState notifies Flutter to rebuild the UI with the updated greeting
      greeting = "Hello ${nameController.text}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar displayed at the top of the screen
      appBar: AppBar(title: const Text("Home Page")),

      // Padding adds space around the content inside the page
      body: Padding(
        padding: const EdgeInsets.all(20),

        // Column arranges widgets vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displays a welcome message (static UI)
            const WelcomeText(),

            const SizedBox(height: 20), // Adds vertical spacing
            // Text input field where the user enters their name
            NameInputField(controller: nameController),

            const SizedBox(height: 20),

            // Button that triggers greeting update when pressed
            ElevatedButton(
              onPressed: showGreeting,
              child: const Text("Submit"),
            ),

            const SizedBox(height: 20),

            // Displays the greeting message dynamically
            GreetingDisplay(greeting: greeting),
          ],
        ),
      ),
    );
  }
}

// Stateless widget that displays a fixed welcome message
class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Welcome to University of The Cumberland’s",
      style: TextStyle(fontSize: 24),
    );
  }
}

// Stateless widget for the text input field
// Receives a controller from the parent Stateful widget
class NameInputField extends StatelessWidget {
  final TextEditingController controller;

  const NameInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Connects the TextField to the controller
      decoration: const InputDecoration(
        labelText: "Enter your name",
        border: OutlineInputBorder(),
      ),
    );
  }
}

// Stateless widget that displays the greeting message
// The greeting value is passed from the Stateful parent widget
class GreetingDisplay extends StatelessWidget {
  final String greeting;

  const GreetingDisplay({super.key, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Text(greeting, style: const TextStyle(fontSize: 20));
  }
}
