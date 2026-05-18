# 我的 iOS App（Codemagic 云端构建）

## 开发环境
- **本地**：Windows + Flutter SDK
- **iOS 构建**：Codemagic 云端（无需 Mac）

## 快速开始

### 1. 安装 Flutter SDK
从 https://docs.flutter.dev/get-started/install/windows 下载安装。

### 2. 初始化项目
```bash
flutter pub get
```

### 3. 本地运行（Android 模拟器调试）
```bash
flutter run
```

### 4. iOS 云端构建（Codemagic）

#### 前置准备
1. 注册 [Apple Developer 账号](https://developer.apple.com)（$99/年）
2. 注册 [Codemagic 账号](https://codemagic.io)（免费）
3. 将此项目推送到 GitHub/GitLab/Bitbucket

#### 配置步骤
1. 登录 Codemagic，添加你的 Git 仓库
2. 在 Codemagic 设置中上传你的 Apple 证书：
   - **签名证书**（.p12 文件）
   - **Provisioning Profile**（.mobileprovision 文件）
3. 修改 `codemagic.yaml` 中的：
   - `bundle_identifier`：你的 App Bundle ID
   - `recipients`：你的邮箱
4. 推送代码，Codemagic 自动构建
5. 构建完成后，IPA 文件会发送到你的邮箱

#### 获取 Apple 证书的方法
1. 登录 https://developer.apple.com
2. 进入 Certificates, Identifiers & Profiles
3. 创建 iOS Distribution Certificate → 下载 .p12
4. 创建 Ad Hoc Provisioning Profile（绑定你的设备 UDID）→ 下载 .mobileprovision

### 5. 安装到 iPhone
- 使用 AltStore 或 Apple Configurator 安装 IPA
- 或通过 Codemagic 的分发链接直接安装

## 项目结构
```
├── codemagic.yaml      # Codemagic CI/CD 配置
├── pubspec.yaml        # Flutter 依赖管理
├── lib/
│   └── main.dart       # App 入口
├── ios/                # iOS 平台代码（flutter create 后生成）
└── android/            # Android 平台代码
```

## 注意事项
- 需要先运行 `flutter create .` 生成 ios/ 和 android/ 平台目录
- Apple 证书有效期为 1 年，需定期更新
- Ad Hoc 分发最多支持 100 台设备
