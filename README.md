# AuthApp1

AuthApp1 is a Flutter authentication client that integrates with AWS Cognito through Amplify.  
This document captures the steps required to stand up the Amplify environment and wire the app to your Cognito user pool.

## Prerequisites
- Flutter 3.7.0 or newer (`flutter --version` to confirm)
- Node.js 20+ (aligns with the latest Amplify CLI overrides tooling)
- AWS CLI configured with an IAM user/role that can create Cognito resources (`aws configure`)
- Amplify CLI (`npm install -g @aws-amplify/cli`)
- Xcode (for iOS) and/or Android Studio SDK/NDK (for Android)

## 1. Clone & bootstrap the repo
```bash
git clone <repo-url>
cd authapp1
flutter pub get
```

## 2. Configure Amplify backend
1. Initialize Amplify in the project root:
   ```bash
   amplify init
   ```
   - Choose **Flutter** as the default editor, enable iOS/Android (and Web if needed), then pick your AWS profile.

2. Add the Cognito auth resource:
   ```bash
   amplify add auth
   ```
   - Select **Walkthrough all the auth configurations** so you can set email + phone sign-in and update password policy/MFA as needed. The custom attributes will be added in the console after the initial push.

3. Deploy the baseline backend:
   ```bash
   amplify push
   ```
   - This provisions the Cognito User Pool/Identity Pool and uploads the generated configuration to S3.

4. Add the required custom profile attributes via the Cognito console:
   - Open the Amplify-generated user pool (Console → Cognito → User pools → select your pool).
   - Under **Attributes → Add custom attribute**, create `title` and `organization` (String, mutable, required to match the app form, max length 256).
   - Save and confirm the pool now lists `custom:title` and `custom:organization`.

5. Authorize the app clients to use the attributes:
   - Still in the Cognito console, edit each app client (native and web if present).
   - Under **Attribute read and write permissions**, ensure `custom:title` and `custom:organization` are checked for both readable and writable lists, alongside `email`, `phone_number`, `given_name`, and `family_name`.
   - Save the app client changes.

6. Pull the updated backend metadata locally:
   ```bash
   amplify pull
   ```
   - This refreshes `amplify/backend/auth/*/cli-inputs.json`, `parameters.json`, and `team-provider-info.json` so the repo reflects the console changes.

## 3. Update the Flutter config
1. Copy the generated values from `amplify/team-provider-info.json` or `amplify/backend/amplify-meta.json` into `lib/amplifyconfiguration.dart`.  
   Replace the placeholder strings:
   ```json
   "PoolId": "us-east-1_XXXXXXXXX",
   "AppClientId": "XXXXXXXXXXXXXXXXXXXXXXXXXX",
   "Region": "us-east-1",
   "cognito_identity_pool_id": "us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   ```
2. For apps with an App Client secret disabled (recommended for native apps), remove the `AppClientSecret` property completely.
3. Verify that the `authapp1` app clients in Cognito expose `custom:title` and `custom:organization`; if you make changes later, rerun `amplify pull` and update this file again.

## 4. Platform-specific setup
### iOS
- In `ios/Runner/Info.plist` add the following keys if missing:
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>Used to enable biometric sign-in.</string>
  <key>NSUserTrackingUsageDescription</key>
  <string>Used for authentication analytics.</string>
  ```
- Run `cd ios && pod install && cd ..` after any dependency changes.

### Android
- Ensure `android/app/build.gradle.kts` sets `minSdk = 23` (required by `local_auth` and Amplify).
- If using biometric auth, confirm `android/app/src/main/AndroidManifest.xml` includes:
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC" />
  <uses-permission android:name="android.permission.USE_FINGERPRINT" />
  ```

## 5. Run the app
```bash
flutter run
```
- The splash screen calls Amplify configuration automatically; on success, you should land on the login screen and be able to sign up / sign in against your Cognito user pool.

## 6. Managing environments
- Use `amplify env add` to create additional AWS environments (e.g., dev/stage/prod).
- Pull backend updates from teammates with `amplify pull`.
- After backend changes, confirm `lib/amplifyconfiguration.dart` reflects the latest values.

## 7. Runtime configuration
- Authentication rules (email/phone regex, password length, default Remember Me) are centralized in `lib/config/app_environment.dart`.
- Select an environment at runtime with `--dart-define APP_ENV=<dev|staging|prod>`, e.g.:
  ```bash
  flutter run --dart-define APP_ENV=staging
  ```
  Each environment overrides the `AuthConfig` provided through Riverpod so future apps can tailor policies without touching UI code.

## 8. Useful commands
| Command | Description |
| --- | --- |
| `amplify status` | Shows categories to be deployed |
| `amplify console auth` | Opens the Cognito console in a browser |
| `amplify push` | Deploys the local backend changes |
| `amplify pull --restore` | Restores backend environment configuration |

## 9. Troubleshooting
- **Amplify not configured**: Ensure `_AmplifyBootstrapper.ensureConfigured()` runs before `runApp` (already handled in `lib/main.dart`).
- **`AmplifyAlreadyConfiguredException`**: Safe to ignore; the app protects against double configuration.
- **Biometric sign-in fails**: Check that `local_auth` is correctly configured per platform and that the device supports biometrics.
- **Widgets tests failing**: Update or remove the default `widget_test.dart`; it still references the counter template.
- **`NotAuthorizedException: attempted to write unauthorized attribute`**: Confirm the Cognito app client allows read/write access to `custom:title` and `custom:organization`, then run `amplify pull` so local configs stay in sync.

- **Styling tweaks**: Update `lib/theme/app_theme.dart` for shared colors, typography, and spacing. Auth screens reuse `AuthScaffold` (`lib/theme/layout/auth_layout.dart`) so downstream apps can swap themes without rewriting forms.
- **CI/CD templates**: Use the provided workflows:
  - `.github/workflows/ci.yml` – main branch validation (format, analyze, test, Android release build).
  - `.github/workflows/cd-android.yml` – manual deploy template with keystore + Play Store placeholders.
  - `.github/workflows/cd-ios.yml` – manual deploy template with signing asset placeholders.

For deeper customization, review the official docs:
- [Amplify Flutter Auth Guide](https://docs.amplify.aws/flutter/build-a-backend/auth/)
- [AWS Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)

With Amplify and Cognito configured, continue iterating on the UI, state management, and API integrations as needed. Happy building!
