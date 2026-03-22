# DVFA - Damn Vulnerable Flutter App (FinTech Edition)

Welcome to the **Damn Vulnerable Flutter App (DVFA)**. This is a modern FinTech-themed mobile application intentionally designed with security vulnerabilities to educate developers and security researchers on mobile security principles.

The vulnerabilities in this application are mapped to the **OWASP MASVS (Mobile Application Security Verification Standard)** and the **OWASP Top 10 Mobile Risks**.

## Disclaimer
This application is for educational purposes ONLY. Never use the insecure patterns shown here in production applications.

## How to Play
There are two ways to assess this application:

*   **Black-Box Experience**: Download the compiled APK from the Releases tab and test the application blindly without looking at the source code.
*   **White-Box Experience**: Review the source code for static analysis practice or use it as a reference if you get stuck during your Black-Box assessment.

## Building from Source
If you want to compile the application from the source code, you can execute the following command after cloning the repo and installing flutter:

```bash
flutter build apk --release
```

Note regarding Challenge 7 (Reverse Engineering): To ensure the effectiveness of reverse-engineering tools like blutter or reFlutter, the application should be compiled without the `--obfuscate` flag. This ensures that the Dart string pools and class structures remain recoverable during analysis and avoids unnecessary work.

### iOS Support
Due to Apple's code-signing requirements, a pre-compiled .ipa is not provided. To assess the iOS version, clone the repository on a macOS machine and build via Xcode:

```bash
flutter build ios --no-codesign
```

Note: Challenge 7 (AOT Reverse Engineering) on iOS requires a decrypted binary from a jailbroken device to extract the App framework for analysis.

---

## Challenge List

**Difficulty Level Criteria**
*   **Beginner**: Requires basic OS observation and manual interaction.
*   **Intermediate**: Requires interception proxies (e.g., Burp Suite) or basic script creation.
*   **Advanced**: Requires reverse-engineering compiled binaries or dynamic instrumentation (e.g., Frida).

| ID | OWASP Category | Challenge Name | Difficulty |
|:---|:---|:---|:---|
| 1 | M3: Insecure Auth | Insecure Authentication | `Intermediate` |
| 2 | M9: Local Storage | Insecure Local Storage | `Beginner` |
| 3 | M5: Communication | Insecure Communication | `Intermediate` |
| 4 | M4: Injection | Client-Side SQL Injection | `Intermediate` |
| 5 | M1: Platform Usage | Improper Platform Usage | `Advanced` |
| 6 | M8: Misconfiguration | Security Misconfiguration | `Advanced` |
| 7 | M10: Cryptography | Insufficient Cryptography | `Advanced` |
| 8 | M6: Privacy Controls | Inadequate Privacy Controls | `Beginner` |
| 9 | M7: Authorization | Insecure Authorization | `Intermediate` |
| 10 | M2/M6: Leakage | Insecure Data Leakage | `Beginner` |

---

## Detailed Objectives

### Challenge 1: Insecure Authentication
**Objective:** Bypass the login screen by brute-forcing the 4-digit PIN for Account ID "88888888".

### Challenge 2: Insecure Local Storage
**Objective:** Find where the application stores user credentials locally and extract the plaintext Account ID and PIN after a successful login.

### Challenge 3: Insecure Communication
**Objective:** Intercept the network traffic between the mobile application and the backend API to view the plaintext balance request from the dashboard. 

*Note: To simulate this challenge locally, start the mock backend using Docker: `docker compose up -d`.*

### Challenge 4: Client-Side SQL Injection
**Objective:** Exploit the search feature in the "Secure Notes" screen to bypass the query filter and reveal hidden administrator notes.

### Challenge 5: Improper Platform Usage
**Objective:** Craft a malicious deep link that, when clicked, forces the application to automatically execute a fund transfer without user confirmation.

### Challenge 6: Security Misconfiguration
**Objective:** Discover and access the hidden "Developer Menu" left behind in the production build to extract the staging API keys.

### Challenge 7: Insufficient Cryptography
**Objective:** Export the encrypted bank statement from the dashboard, reverse-engineer the compiled Flutter engine binary (libapp.so) to extract the hardcoded AES key, and decrypt the statement.

### Challenge 8: Inadequate Privacy Controls
**Objective:** Monitor the device's system logs during runtime to intercept sensitive user credentials and transaction data leaked by the application.

### Challenge 9: Insecure Authorization
**Objective:** Elevate your privileges to access the "Platinum Card Application" by manipulating the application's local authorization state.

### Challenge 10: Insecure Data Leakage
**Objective:** Exploit the application's lifecycle management by sending the app to the background and extracting the cached OS screenshot containing sensitive financial data. Note for White-Box analysis: There is no explicitly vulnerable code snippet here; the flaw is the architectural failure to implement lifecycle management hooks to obscure the screen.

---

## Learning Resources
For a detailed analysis of each vulnerability, exploitation methods, and secure implementation strategies, please refer to the [SOLUTIONS.md](SOLUTIONS.md) file.