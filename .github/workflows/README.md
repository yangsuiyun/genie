# 🚀 GitHub Actions CI/CD Workflows

本项目使用 GitHub Actions 自动构建多平台应用。

## 📋 可用的工作流

### 1. **build-macos.yml** - macOS 专用构建
触发条件：
- 推送到 `main`, `master`, `develop` 分支
- Pull Request 到上述分支
- 手动触发（在 Actions 页面点击 "Run workflow"）

输出产物：
- ✅ `pomodoro_genie.app` - macOS 应用程序
- ✅ `pomodoro_genie.dmg` - macOS 安装器（DMG 格式）

### 2. **build-all-platforms.yml** - 全平台构建
触发条件：
- 推送版本标签（如 `v1.0.0`）
- 手动触发

输出产物：
- 🌐 **Web** - 静态网站文件
- 🤖 **Android** - APK + AAB (Google Play)
- 🍎 **iOS** - IPA (未签名)
- 💻 **macOS** - DMG 安装器
- 🪟 **Windows** - ZIP 压缩包
- 🐧 **Linux** - tar.gz 压缩包

## 🎯 使用方法

### 方法 1: 自动触发（推荐用于 macOS）
```bash
# 推送代码到 main 分支即可自动构建 macOS 版本
git add .
git commit -m "Update code"
git push origin main
```

### 方法 2: 手动触发
1. 访问 GitHub 仓库的 **Actions** 页面
2. 选择工作流：
   - `Build macOS App` - 仅构建 macOS
   - `Build All Platforms` - 构建所有平台
3. 点击 **Run workflow** 按钮
4. 选择分支后点击 **Run workflow**

### 方法 3: 发布版本（构建所有平台）
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# 这会触发全平台构建并自动创建 GitHub Release
```

## 📦 下载构建产物

### 从 Actions 页面下载
1. 访问 **Actions** 标签页
2. 点击任意成功的工作流运行
3. 滚动到底部的 **Artifacts** 部分
4. 下载需要的产物：
   - `pomodoro-genie-macos-app` - macOS 应用
   - `pomodoro-genie-macos-dmg` - macOS 安装器
   - `pomodoro-genie-web` - Web 版本
   - 等等...

### 从 Releases 页面下载（仅版本标签触发）
1. 访问仓库的 **Releases** 页面
2. 选择版本
3. 下载对应平台的文件

## 🔧 工作流配置说明

### macOS 构建流程
```yaml
1. 检出代码
2. 安装 Flutter 3.24.3
3. 启用 macOS 桌面支持
4. 获取依赖
5. 创建 macOS 平台文件
6. 代码分析（可选）
7. 运行测试（可选）
8. 构建 Release 版本
9. 创建 DMG 安装器
10. 上传构建产物
```

### 全平台构建流程
- **并行构建**：所有平台同时构建（节省时间）
- **自动发布**：版本标签触发时自动创建 GitHub Release
- **保留期限**：构建产物保留 30 天

## 🛠️ 本地测试构建命令

如果你有对应的开发环境，可以本地测试：

### macOS
```bash
cd mobile
flutter config --enable-macos-desktop
flutter create --platforms=macos .
flutter build macos --release
```

### Windows
```bash
cd mobile
flutter config --enable-windows-desktop
flutter create --platforms=windows .
flutter build windows --release
```

### Linux
```bash
cd mobile
flutter config --enable-linux-desktop
flutter create --platforms=linux .
flutter build linux --release
```

### Android
```bash
cd mobile
flutter build apk --release          # APK
flutter build appbundle --release    # AAB (Google Play)
```

### iOS
```bash
cd mobile
flutter build ios --release --no-codesign
```

### Web
```bash
cd mobile
flutter build web --release
```

## 📝 注意事项

1. **iOS 签名**：当前构建的 iOS 应用未签名，仅用于测试
2. **macOS 公证**：DMG 安装器未进行 Apple 公证，首次打开需要右键 -> 打开
3. **Android 签名**：生产环境需配置签名密钥（在 GitHub Secrets 中）
4. **依赖项**：确保 `pubspec.yaml` 中的依赖项与构建环境兼容
5. **构建时间**：全平台构建约需 15-30 分钟

## 🔒 安全配置（生产环境）

对于正式发布，需要在 GitHub Secrets 中配置：

- `ANDROID_KEYSTORE` - Android 签名密钥
- `ANDROID_KEYSTORE_PASSWORD` - 密钥密码
- `IOS_CERTIFICATE` - iOS 签名证书
- `IOS_PROVISIONING_PROFILE` - iOS 配置文件
- `MACOS_CERTIFICATE` - macOS 签名证书

## 📊 构建状态

查看构建状态：
- ✅ 绿色勾 = 构建成功
- ❌ 红色叉 = 构建失败
- 🟡 黄色点 = 正在构建

点击状态图标可查看详细日志。

## 🆘 故障排查

### 构建失败常见原因
1. **依赖问题**：检查 `pubspec.yaml` 依赖版本
2. **Flutter 版本**：确保使用 Flutter 3.24.3
3. **平台文件**：首次构建需要 `flutter create --platforms=xxx`
4. **权限问题**：检查 GitHub Actions 权限设置

### 日志查看
1. 进入失败的工作流运行
2. 展开红色的步骤
3. 查看详细错误信息

## 📚 相关文档

- [Flutter 构建文档](https://docs.flutter.dev/deployment)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
