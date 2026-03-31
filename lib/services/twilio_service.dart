import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class TwilioService {
  String get _accountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  String get _authToken => dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  String get _twilioNumber => dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

  Future<bool> sendOtp(String phoneNumber, String otp) async {
    if (_accountSid.isEmpty || _authToken.isEmpty || _twilioNumber.isEmpty) {
      debugPrint('Twilio configuration missing in .env');
      return false; // Not configured
    }

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json');
    final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': phoneNumber,
          'From': _twilioNumber,
          'Body': 'Your CareerIQ verification code is: $otp',
        },
      );

      if (response.statusCode == 201) {
        return true;
      }
      debugPrint('Twilio Error: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Twilio Exception: $e');
      return false;
    }
  }
}
