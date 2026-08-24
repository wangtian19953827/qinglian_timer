# 轻练 · 语音健身计时器

面向 iPhone 的语音健身计时器，薄荷与青绿浅色系设计，带毛玻璃和蕾丝纹样。计时只在 App 前台运行时听语音，退出、锁屏、后台都不监听。

## 功能

- 语音命令：开始、停止、分段、重置
- 组间休息倒计时：停止后自动开始，可选关闭 / 30 / 45 / 60 / 90 / 120 秒
- 训练历史：本地保存，包含总时长、分段时长和日期
- 计时时屏幕常亮

## 语音命令

| 命令 | 效果 |
| --- | --- |
| 开始 | 开始计时；已暂停时继续，并取消休息倒计时 |
| 停止 | 暂停计时；如果设置了组间休息，自动开始倒计时 |
| 分段 | 记录当前这一段时长，计时继续 |
| 重置 | 把本次训练保存进历史，然后清零 |

首次安装打开后，系统会请求麦克风和语音识别权限，需要允许。普通话识别使用 iPhone 自带的端上语音识别，不依赖第三方服务。

## 免费构建 IPA（无需 Apple 开发者账号）

这个仓库在 Windows 上写代码，用 GitHub Actions 的免费 macOS 机器完成 iOS 编译：

1. 把 `qinglian_timer` 目录里的所有内容上传到 GitHub 仓库根目录：`.github`、`lib`、`pubspec.yaml` 等直接放在根目录，不要保留 `qinglian_timer` 这层外层文件夹。GitHub 只读取仓库根目录下的 `.github/workflows/build-ios.yml`，放错层级 Actions 页面就不会显示这个工作流。
2. 打开仓库的 Actions 页面，选择 **Build iOS IPA**，点击 **Run workflow**。
3. 等待约 10 分钟，下载 `qinglian_timer-ipa` 产物里的 `qinglian_timer.ipa`。
4. 用 Sideloadly 或 AltStore 配合免费 Apple ID 签名安装到 iPhone。

### 免费签名注意事项

- 没有 TestFlight，应用每 7 天需要重新签名一次。AltStore 在电脑开着时可以在后台自动续签；Sideloadly 需要手动重签。
- 一个免费 Apple ID 最多注册 3 台测试设备。
- 如果 Sideloadly 提示 Bundle ID 冲突，把它改成自己的格式，例如 `com.你的名字.qinglian.timer`。
- 首次使用语音功能时，请确认 iPhone 的“设置 > 隐私 > 语音识别”和“麦克风”都已允许本 App。

## 本地开发

Windows 上也可以先把界面跑在浏览器里做预览：

```bash
flutter pub get
flutter create --platforms=web .
flutter run -d chrome
```

真机语音识别需要安装到 iPhone 后才能完整验证。GitHub Actions 每次构建都会自动生成 iOS 工程文件，并把本仓库 `.github/ios/Info.plist` 里的语音权限配置写进项目。

## 目录

```text
lib/main.dart             入口
lib/theme.dart            配色与主题
lib/models/               训练记录模型
lib/services/            语音服务、历史存储
lib/screens/              计时主页、历史页
lib/widgets/              毛玻璃卡片、蕾丝背景
.github/workflows/        macOS 云构建
.github/ios/Info.plist    iOS 语音权限配置
```