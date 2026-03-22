# DVFA - Vulnerability Solutions and Remediation Guide

This document provides a technical analysis of the vulnerabilities discovered within the **Damn Vulnerable Flutter App (DVFA)**, along with step-by-step exploitation procedures and industry-standard mitigation strategies.

---

<details>
<summary><b>Challenge 1: Insecure Authentication (OWASP M3)</b></summary>

### 1. Analysis
The application implements a 4-digit numeric PIN for authentication but fails to enforce any rate-limiting, exponential backoff, or account lockout mechanisms. While the application compares a SHA-256 hash of the input rather than hardcoding plaintext, the entropy of a 4-digit PIN is insufficient. With only 10,000 possible combinations (0000-9999), the authentication check is vulnerable to an exhaustive search attack.

### 2. Exploitation Steps
1.  **Identify the Target**: Observe the login screen and determine the credential requirements (8-digit Account ID and 4-digit PIN).
2.  **Automate the Attack**: Use a security automation tool or a custom script to iterate through the keyspace. You should target Account ID "88888888" and cycle through all PINs from 0000 to 9999.
3.  **Bypass the Check**: Because the application does not implement a delay after failed attempts, the script can test hundreds of combinations per second until the successful PIN (1234) is identified and the application navigates to the Dashboard.

### 3. Mitigation
The application must implement defensive measures to increase the cost of brute-force attacks. This includes both local UI-level friction and mandatory backend-side enforcement.

**Secure Implementation Strategy:**
Implement a local counter that triggers a time-based lockout after a specific number of failed attempts.

```dart
int _failedAttempts = 0;
DateTime? _lockoutTime;

void _handleLogin() {
  if (_lockoutTime != null && DateTime.now().isBefore(_lockoutTime!)) {
    // Return error: "Too many attempts. Locked for 15 minutes."
    return;
  }

  if (isCorrect) {
    _failedAttempts = 0;
    // Proceed to Dashboard
  } else {
    _failedAttempts++;
    if (_failedAttempts >= 3) {
      _lockoutTime = DateTime.now().add(const Duration(minutes: 15));
    }
  }
}
```
Furthermore, the backend API should enforce strict rate-limiting per Account ID and IP address to prevent distributed attacks.
</details>

---

<details>
<summary><b>Challenge 2: Insecure Local Storage (OWASP M9)</b></summary>

### 1. Analysis
The application utilizes the `shared_preferences` package to persist user credentials. In Flutter, `shared_preferences` stores data in unencrypted XML files on Android and Plist files on iOS within the application's private sandbox. While this sandbox is protected by the operating system's permission model, it is easily bypassed on rooted or jailbroken devices, exposing sensitive data at rest.

### 2. Exploitation Steps
1.  **Gain Filesystem Access**: Use a rooted Android device or emulator and connect via ADB.
2.  **Locate the Sandbox**: Navigate to the application's private data directory:
    `cd /data/data/com.schmiemandev.dvfa/shared_prefs/`
3.  **Extract Credentials**: Read the contents of the preferences file:
    `cat FlutterSharedPreferences.xml`
4.  **Recover Plaintext**: The Account ID and PIN are stored as plaintext string entries in the XML structure and can be recovered immediately.

### 3. Mitigation
Sensitive data must be stored using platform-native encrypted storage mechanisms. For Flutter, the industry standard is the `flutter_secure_storage` package, which leverages **Keychain** on iOS and **AES/KeyStore** on Android.

**Secure Implementation Strategy:**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// Securely persist credentials
await storage.write(key: 'account_id', value: accountId);
await storage.write(key: 'pin', value: pin);

// Retrieve credentials securely
String? securePin = await storage.read(key: 'pin');
```
</details>

---

<details>
<summary><b>Challenge 3: Insecure Communication (OWASP M5)</b></summary>

### 1. Analysis
The application transmits sensitive financial data over unencrypted HTTP. This lack of transport layer security allows attackers in the network path to perform Man-in-the-Middle (MITM) attacks, intercepting traffic to view plaintext data or modifying requests and responses in transit.

### 2. Exploitation Steps
1.  **Configure Interception Proxy**: Setup a tool like Burp Suite or OWASP ZAP to listen on a local proxy port.
2.  **Handle Flutter Proxy Logic**: Since Flutter apps often ignore system proxy settings, use a tool like **reFlutter** to patch the application binary to use a global proxy or a custom Certificate Authority.
3.  **Capture Traffic**: Navigate to the Dashboard. The tool will capture the outgoing GET request to `http://api.dvfa.local/v1/balance`.
4.  **Inspect Payload**: Analyze the intercepted traffic to view the sensitive account balance in plaintext.

### 3. Mitigation
All network communication must be conducted over **HTTPS/TLS**. Additionally, critical applications should implement **SSL Pinning** to ensure the application only trusts specific, known certificates, preventing interception via rogue Certificate Authorities.

**Secure Implementation Strategy:**

```dart
// 1. Enforce HTTPS
final uri = Uri.parse('https://api.dvfa.local/v1/balance');

// 2. Implement Certificate Pinning
import 'dart:io';

SecurityContext context = SecurityContext(withTrustedRoots: true);
context.setTrustedCertificatesBytes(certBytes); // Root CA Certificate

HttpClient client = HttpClient(context: context);
```
</details>

---

<details>
<summary><b>Challenge 4: Client-Side SQL Injection (OWASP M4)</b></summary>

### 1. Analysis
The Secure Notes feature utilizes the `sqflite` package but builds its search query using raw string concatenation. By embedding user-supplied input directly into the SQL string, the application fails to distinguish between data and executable code, allowing an attacker to manipulate the query's logic.

### 2. Exploitation Steps
1.  **Identify Search Functionality**: Open the Secure Notes screen.
2.  **Inject Malicious Payload**: Enter the following payload into the search field:
    `' OR 1=1 --`
3.  **Analyze Query Transformation**: The resulting query executed by the database becomes:
    `SELECT * FROM notes WHERE is_hidden = 0 AND title LIKE '%' OR 1=1 --%'`
4.  **Exfiltrate Data**: The `OR 1=1` condition is always true, and the `--` characters comment out the remainder of the query. This bypasses the `is_hidden = 0` filter, causing the application to display all notes, including the hidden administrator secret.

### 3. Mitigation
Developers must use **parameterized queries** (prepared statements) provided by the `sqflite` package. This separates the query structure from the user-supplied data, neutralizing the injection.

**Secure Implementation Strategy:**

```dart
// Use the whereArgs property for parameterization
final List<Map<String, dynamic>> secureNotes = await db.query(
  'notes',
  where: 'title LIKE ? AND is_hidden = 0',
  whereArgs: ['%$searchInput%'],
);
```
</details>

---

<details>
<summary><b>Challenge 5: Improper Platform Usage (OWASP M1)</b></summary>

### 1. Analysis
The application registers a custom URI scheme (`dvfa://`) and implements a deep link listener that performs sensitive state-changing actions (fund transfers) without user confirmation. This trust in the intent source allows malicious third-party applications or websites to force the application to perform unauthorized actions on behalf of the user.

### 2. Exploitation Steps
1.  **Craft the Malicious URI**: Construct a deep link containing the desired transfer parameters:
    `dvfa://app/transfer?to=Attacker_1337&amount=9999`
2.  **Trigger the Intent**: Use the Android Debug Bridge (ADB) to simulate an external link activation:
    `adb shell am start -W -a android.intent.action.VIEW -d "'dvfa://app/transfer?to=Attacker_1337&amount=9999'"`
3.  **Verify Execution**: Observe the application launching, navigating to the transfer screen, and automatically executing the transfer with the attacker's parameters without any user interaction.

### 3. Mitigation
Deep links should never be used to execute state-changing actions directly. They should only be used for navigation or to pre-fill forms.

**Secure Implementation Strategy:**
The application must require a manual "Confirm" action or re-authentication (PIN/Biometrics) before the transfer is finalized.

```dart
void _handleDeepLink(Uri uri) {
  if (uri.path.contains('transfer')) {
    final String? to = uri.queryParameters['to'];
    final String? amount = uri.queryParameters['amount'];

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => TransferScreen(
          recipient: to,
          amount: amount,
          autoExecute: false, // MANDATORY: Ensure user must press the button
        ),
      ),
    );
  }
}
```
</details>

---

<details>
<summary><b>Challenge 7: Insufficient Cryptography (OWASP M10)</b></summary>

### 1. Analysis
The application attempts to protect sensitive bank statements using AES-256 encryption in CBC mode. However, it relies on a hardcoded, static cryptographic key and Initialization Vector (IV) embedded directly within the application's source code. While Flutter compiles Dart code into a native AOT binary (`libapp.so`), this process does not provide obfuscation for string constants. Hardcoding keys and IVs makes the encryption trivial to break, as any attacker with access to the binary can recover the secrets.

### 2. Exploitation Steps
1.  **Extract the Binary**: Unzip the compiled Android APK and navigate to the `lib/` directory. Locate the `libapp.so` file for the target architecture (e.g., `lib/arm64-v8a/libapp.so`).
2.  **Analyze String Pools**: Use a Flutter-specific reverse-engineering tool like **blutter** or a general-purpose strings utility to dump the string pool from the binary.
3.  **Identify Cryptographic Secrets**: Search for the hardcoded identifiers. A researcher would quickly locate `DVFA_STATIC_KEY_8899001122334455` and `DVFA_STATIC_IV__`.
4.  **Decrypt the Payload**: Copy the Base64-encoded encrypted statement from the application. Use a tool like **CyberChef** or a custom script with the extracted AES key and IV to decrypt the statement and recover the plaintext account details and balance.

### 3. Mitigation
Cryptographic keys and IVs must never be hardcoded or stored in plaintext within the application source code.

**Secure Implementation Strategy:**
1.  **Dynamic Key Generation**: Generate a cryptographically secure random key at runtime using a CSPRNG.
2.  **Secure Key Storage**: Persist the generated key within the device's secure hardware enclave (**Android KeyStore** or **iOS Keychain**) using a package like `flutter_secure_storage`.
3.  **Unique IVs**: Ensure that a unique, random IV is generated for every encryption operation and prepended to the ciphertext.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;

// Generate and store a secure key
final storage = FlutterSecureStorage();
final key = enc.Key.fromSecureRandom(32);
await storage.write(key: 'stmt_encryption_key', value: key.base64);

// Encrypt with a random IV
final iv = enc.IV.fromSecureRandom(16);
final encrypter = enc.Encrypter(enc.AES(key));
final encrypted = encrypter.encrypt(plainText, iv: iv);
// Result = IV + Ciphertext
final finalPayload = iv.base64 + encrypted.base64;
```
</details>

---

<details>
<summary><b>Challenge 8: Inadequate Privacy Controls (OWASP M6)</b></summary>

### 1. Analysis
The application leaks sensitive information, including plaintext PINs and fund transfer details, to the system's log console during runtime. In Flutter, the standard `print()` statement is not automatically stripped from release builds and is redirected to the platform's system logger (Logcat on Android, Console.app on iOS). Logging Personally Identifiable Information (PII) or authentication credentials violates global privacy compliance standards (such as GDPR or HIPAA) and exposes sensitive data to any user or local process with the ability to read system logs.

### 2. Exploitation Steps
1.  **Establish Device Connection**: Connect the target Android device or emulator to a workstation via ADB.
2.  **Monitor System Logs**: Execute the following command to filter the logs for the specific debug tag:
    `adb logcat | grep "DEBUG"`
3.  **Trigger the Leakage**: Navigate through the application and perform sensitive actions:
    - Attempt a login on the Login screen.
    - Perform a fund transfer on the Transfer screen.
4.  **Capture Sensitive Data**: Observe the terminal output to capture the leaked Account ID, plaintext PIN, and transaction details (amount and recipient) in real-time.

### 3. Mitigation
Developers must strictly prohibit the logging of sensitive data. For debugging non-sensitive information, logging should only be active during the development phase and must be entirely excluded from the production binary.

**Secure Implementation Strategy:**
Leverage the `kDebugMode` constant from the `foundation` package to conditionally include logs only in debug builds.

```dart
import 'package:flutter/foundation.dart';

// Conditionally print log only in debug mode
if (kDebugMode) {
  print('Safe debug information');
}

// Alternatively, use debugPrint() which can be overridden or handled centrally
debugPrint('Non-sensitive diagnostic message');
```

For more advanced logging requirements, use a dedicated logging package that allows for central configuration of log levels based on the build environment.
</details>

---

<details>
<summary><b>Challenge 9: Insecure Authorization (OWASP M7)</b></summary>

### 1. Analysis
The application implements an authorization check for its "Platinum Card Application" feature by reading a local boolean flag (`is_vip`) from `SharedPreferences`. In mobile security, authorization decisions must be made and enforced by the server. Relying on client-side state is a severe architectural flaw because the local environment (including the filesystem and application sandbox) is entirely under the user's control. A user can easily modify local configuration files to grant themselves unauthorized privileges.

### 2. Exploitation Steps
1.  **Identify the Target**: Open the application and click the "Credit Card" icon on the Dashboard. Observe the "Access Denied" message.
2.  **Extract Local State**: Connect a rooted device or emulator via ADB and pull the application's preference file:
    `adb pull /data/data/com.schmiemandev.dvfa/shared_prefs/FlutterSharedPreferences.xml`
3.  **Modify the Authorization Flag**: Open the XML file in a text editor and add the following entry inside the `<map>` tag:
    `<boolean name="flutter.is_vip" value="true" />`
4.  **Inject the Modified State**: Push the file back to the device's sandbox:
    `adb push FlutterSharedPreferences.xml /data/data/com.schmiemandev.dvfa/shared_prefs/`
5.  **Bypass the Restriction**: Force close and restart the application. Click the "Credit Card" icon again. The application now reads the `is_vip` flag as `true` and grants access to the Platinum Lounge.

### 3. Mitigation
Authorization must be enforced on the backend. The mobile application's UI should only reflect the user's permissions based on a validated server-side token (e.g., a JWT containing roles).

**Secure Implementation Strategy:**
Ensure that all sensitive data and features are protected by server-side checks. The client-side code should merely be a view of what the server has authorized.

```dart
// The application should fetch the user's profile/roles from a secure API
final response = await http.get(
  Uri.parse('https://api.dvfa.local/v1/user/profile'),
  headers: {'Authorization': 'Bearer $jwtToken'},
);

// The backend must validate the JWT and ensure the user has the 'VIP' role
// before returning the sensitive Platinum Lounge data.
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (data['is_vip'] == true) {
    _showPlatinumLounge(data['lounge_details']);
  }
}
```
</details>

---

<details>
<summary><b>Challenge 10: Insecure Data Leakage (OWASP M2 / M6)</b></summary>

### 1. Analysis
Mobile operating systems (Android and iOS) automatically capture a snapshot of an application's current state when it is moved to the background. This snapshot is stored on the device's persistent storage to populate the "Recent Apps" or "App Switcher" carousel. If an application contains sensitive Personally Identifiable Information (PII) or financial data and fails to obscure the screen before this transition, it leaks that data to the local storage. This cached image is accessible to anyone with physical access to the unlocked device and can be extracted via forensic analysis of a rooted/jailbroken device.

### 2. Exploitation Steps
1.  **Prepare the State**: Authenticate as the target user and navigate to the Dashboard where the account balance and Account ID are visible.
2.  **Trigger the Lifecycle Change**: Press the Home button or use a gesture to send the application to the background.
3.  **Inspect the Switcher**: Immediately open the "Recent Apps" carousel. Observe that the preview for the DVFA application clearly displays the sensitive balance and account information in plaintext.
4.  **Forensic Extraction (Rooted Android)**: On a rooted device or emulator, navigate to the system snapshot directory (e.g., `/data/system/users/0/snapshots/` or `/data/system_ce/0/snapshots/`). Locate the image file associated with the application's package name and open it to verify the persistent leakage of the data.

### 3. Mitigation
Applications must actively manage their lifecycle to prevent the exposure of sensitive data during backgrounding.

**Secure Implementation Strategy:**
1.  **Lifecycle Monitoring**: Implement a `WidgetsBindingObserver` to detect when the application enters the `AppLifecycleState.inactive` or `AppLifecycleState.paused` states.
2.  **UI Obfuscation**: When a background transition is detected, overlay the UI with a solid color, a logo, or a blur filter.
3.  **Window Manager Flags (Android)**: Use the `flutter_windowmanager` package to set the `FLAG_SECURE` flag, which prevents the OS from taking screenshots or recording the screen entirely.

```dart
// Example using WidgetsBindingObserver to obscure the UI
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
    setState(() {
      _isScreenObscured = true;
    });
  } else if (state == AppLifecycleState.resumed) {
    setState(() {
      _isScreenObscured = false;
    });
  }
}

// Example using flutter_windowmanager for Android-specific protection
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

Future<void> secureScreen() async {
  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
}
```
</details>




---

<details>
<summary><b>Challenge 6: Security Misconfiguration (OWASP M8)</b></summary>

### 1. Analysis
The application contains a hidden "Developer Menu" that is accessible through an undocumented gesture (5 rapid taps on the account balance). This is a classic example of **Security by Obscurity**, where developers assume that administrative or debugging features are safe as long as they are hidden from the standard UI flow. In a production environment, this misconfiguration allows unauthorized users to access sensitive information, such as API keys, environment variables, or administrative actions like wiping the local database.

### 2. Exploitation Steps
1.  **Perform Static Analysis**: A security researcher would use a Flutter reverse-engineering tool like **blutter** to dump the application's Dart metadata, including strings, classes, and method names.
2.  **Identify Hidden Features**: Searching for keywords such as "Dev", "Admin", or "Secret" within the dumped metadata would reveal the existence of the `DevMenuScreen` class.
3.  **Trace Code Logic**: By analyzing the `DashboardScreen` logic, the researcher can identify the `_handleDevMenuTap` method and its associated 5-tap counter, revealing the exact trigger for the hidden menu.
4.  **Extract Sensitive Data**: Trigger the gesture within the application to access the Developer Menu and extract the "Debug API Key" and environment information.

### 3. Mitigation
Debugging and administrative tools must be entirely excluded from release builds. Developers should use compile-time constants provided by the Flutter framework, such as `kDebugMode` from the `foundation` package, to conditionally include these features.

**Secure Implementation Strategy:**

```dart
import 'package:flutter/foundation.dart';

// Use kDebugMode to ensure the gesture detector is only active in debug builds
Widget buildBalance() {
  final Text balanceWidget = Text(_balance);

  if (kDebugMode) {
    return GestureDetector(
      onTap: _handleDevMenuTap,
      child: balanceWidget,
    );
  }

  return balanceWidget;
}
```
Furthermore, sensitive configuration data like API keys should never be hardcoded in the source code; they should be managed through secure environment variables and obfuscated during the build process.
</details>

