import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NearFixChatService {
  // Use 3.1-flash-lite which replaced the older flash models in March 2026
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: '',
    systemInstruction: Content.system(
        "You are the NearFix Assistant. Help users with Plumbing, Electrical, "
            "Cleaning, Carpenter, and AC Repair in Ahmedabad. Be brief."
    ),
  );

  Future<String> getResponse(String userPrompt) async {
    try {
      final response = await model.generateContent([Content.text(userPrompt)]);
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      debugPrint("TECHNICAL ERROR: $e");

      // Detailed error breakdown
      if (e.toString().contains("503")) {
        return "AI is busy (High Demand). Please try again in 10 seconds.";
      } else if (e.toString().contains("403")) {
        return "API Key Error. Please generate a NEW key in AI Studio.";
      } else if (e.toString().contains("404")) {
        return "Model not found. Updating to gemini-3.1-flash-lite-preview...";
      }

      return "Connection error. Please check your internet or VPN.";
    }
  }
}
