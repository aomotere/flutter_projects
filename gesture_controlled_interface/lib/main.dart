import 'package:flutter/material.dart';

// Entry point of the Flutter application
void main() {
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp provides basic app structure and theme
    return const MaterialApp(home: GestureHomePage());
  }
}

// Stateful widget because the UI changes when gestures occur
class GestureHomePage extends StatefulWidget {
  const GestureHomePage({super.key});

  @override
  State<GestureHomePage> createState() => _GestureHomePageState();
}

class _GestureHomePageState extends State<GestureHomePage> {
  // Variable to track number of taps
  int tapCount = 0;

  // Text displayed at the top of the screen
  String titleText = "Welcome to University of the Cumberland's";

  // Message displayed inside the container
  String message = "Homepage";

  // Controls whether the image should be shown
  bool showImage = false;

  // Function triggered when the screen is tapped
  void handleTap() {
    setState(() {
      tapCount++; // increase tap counter

      // Change text after first tap
      if (tapCount == 1) {
        titleText = "UC Homepage";
        message = "Press and Hold";
      }
    });
  }

  // Function triggered when user presses and holds the screen
  void handleLongPress() {
    setState(() {
      showImage = true; // display image
    });
  }

  // Function for back arrow button
  void goBack() {
    setState(() {
      // If image is displayed, go back to text screen
      if (showImage) {
        showImage = false;
      }
      // If on UC Homepage, return to welcome screen
      else if (tapCount == 1) {
        tapCount = 0;
        titleText = "Welcome to University of the Cumberland's";
        message = "Homepage";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar displayed at top of screen
      appBar: AppBar(
        title: const Text("UC App"),

        // Back arrow button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack, // calls goBack function
        ),
      ),

      // GestureDetector listens for tap and long press gestures
      body: GestureDetector(
        onTap: handleTap,
        onLongPress: handleLongPress,

        child: Center(
          // Show image if long press occurred
          child: showImage
              ? Image.network(
                  "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                  width: 120,
                  height: 120,
                )
              // Otherwise show text content
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main title text
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Message container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
