# walk_pet

歩数連動型のペット育成習慣化アプリ（Flutter製）

## Overview

walk_pet は、日々の歩数と連動してペットを育てる健康習慣サポートアプリです。  
Flutter で開発しており、まずは TestFlight で自己運用しながら改善していく想定です。

## iOS セットアップ

### HealthKit Capability

Xcode でプロジェクトを開き、以下を確認・有効化する。

1. **Runner.xcworkspace** を Xcode で開く
2. Runner ターゲット → **Signing & Capabilities** タブ
3. **+ Capability** → **HealthKit** を追加（既に追加済みなら不要）
4. HealthKit の **Clinical Health Records** チェックは不要（歩数のみ使用）

> `ios/Runner/Runner.entitlements` に `com.apple.developer.healthkit` と  
> `com.apple.developer.healthkit.access` が存在していれば OK。

### Info.plist 必須キー

| キー | 用途 |
|------|------|
| `NSHealthShareUsageDescription` | HealthKit 歩数読み取り許可ダイアログの説明文 |
| `NSHealthUpdateUsageDescription` | HealthKit 書き込み許可ダイアログの説明文 |
| `NSUserTrackingUsageDescription` | ATT (App Tracking Transparency) ダイアログの説明文 |
| `GADApplicationIdentifier` | AdMob アプリ ID |

### entitlements 確認

`ios/Runner/Runner.entitlements` に以下が含まれていること:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

## アプリアイコン更新

アイコン画像を差し替えたい場合:

1. `assets/icons/icon.png` を新しい画像に置き換える（1024×1024px 推奨）
2. 以下コマンドでアイコンを再生成:

```bash
dart run flutter_launcher_icons
```

設定は `pubspec.yaml` の `flutter_launcher_icons:` セクションで管理。

## 広告動作確認

TestFlight モード（`AppMode.testFlight`）では広告は OFF です。  
広告の動作確認には **release モード** でビルドし、以下を確認してください:

1. 初回起動 → ATT 事前説明 → OS の ATT ダイアログが順に表示される
2. Home 画面にバナー広告が表示される
3. Inventory 画面でリワード広告が再生可能
4. 広告読み込み失敗時もアプリが落ちない（リワードは自動再試行1回）

モード切替: `lib/core/config/debug_config.dart` の `currentMode` を変更。