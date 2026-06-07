# 直播间录音功能设计文档

## 概述

在 BiliLive 直播间页面添加音频录制功能，使用 FFmpeg 录制直播流音频并保存为 MP3 文件。

## 需求

1. 录制直播流的纯音频（不录屏）
2. 输出格式：MP3（libmp3lame 编码）
3. 保存方式：用户通过 FilePicker 选择保存路径
4. 入口位置：直播间底部操作栏（关注/刷新/分享 同一行）
5. 防误触：点击"录音"弹出确认对话框，确认后才开始录制
6. 录制中：按钮切换为"停止录音"，点击直接停止（无需确认）
7. 断流处理：FFmpeg 自动重连，录制不中断

## 技术方案

### 依赖

- `ffmpeg_kit_flutter_new_min_gpl: ^2.1.1`

原版 `ffmpeg_kit_flutter_min_gpl` 已停用，`_new_` 分支是活跃维护的 fork，API 完全兼容。

### FFmpeg 录制命令

```bash
-y \
-reconnect 1 -reconnect_streamed 1 -reconnect_at_eof 1 \
-reconnect_on_network_error 1 -reconnect_delay_max 5 \
-max_reconnect_attempts 0 -timeout 10000000 \
-i "<streamUrl>" \
-c:a libmp3lame -b:a 128k \
-f mp3 "<outputPath>"
```

核心参数说明：
| 参数 | 作用 |
|------|------|
| `-reconnect_at_eof 1` | 流结束时自动重连（应对主播下播/卡顿） |
| `-reconnect_on_network_error 1` | 网络错误自动重连 |
| `-max_reconnect_attempts 0` | 无限重连 |
| `-timeout 10000000` | 10秒超时检测死连接 |
| `-c:a libmp3lame` | MP3 编码器 |
| `-b:a 128k` | 恒定比特率 128kbps |

### 状态管理

在 `LiveRoomController` 中新增：

```dart
enum RecordingState { idle, recording, stopping }
Rx<RecordingState> recordingState = RecordingState.idle.obs;
Rx<Duration> recordingDuration = Duration.zero.obs;

int? _recordingSessionId;  // FFmpeg session ID
Timer? _recordingTimer;     // 计时器
```

### 核心方法

```
toggleRecording()
├── 当前为 recording → 停止录制
│   ├── 调用 FFmpegKit.cancel(_recordingSessionId)
│   ├── 取消计时器
│   └── 重置状态为 idle
└── 当前为 idle → 开始录制
    ├── 检查直播状态（未开播则提示）
    ├── 弹出确认对话框
    ├── 用户确认后 FilePicker 选择保存路径
    ├── 用户取消则结束
    ├── 执行 FFmpeg 命令（异步）
    └── 启动录制计时器
```

### UI 变更

#### 底部操作栏（`buildBottomActions`）

在"分享"按钮右侧新增第4个 `Expanded` 按钮：

- **未录制时**：图标 `Remix.mic_line`，文字"录音"，点击弹出确认对话框
- **录制中**：图标 `Remix.stop_circle_line` + 红色，文字"停止录音 00:00"，点击直接停止
- **停止中**：禁用状态

#### AppBar 录制指示器

标题旁显示红点 + 录制时长（同上，双重提示）

## 错误处理

| 场景 | 处理 |
|------|------|
| 直播流卡顿 | FFmpeg 自动重连，录制不中断 |
| 主播下播 | FFmpeg 无限重连等待；用户可手动停止 |
| 用户切房间 | `resetRoom()` 中停止录制 |
| 用户离开页面 | `onClose()` 中停止录制 |
| FFmpeg 异常 | 回调中显示错误 Toast |
| 用户取消保存路径 | 直接结束，无操作 |

## 文件变更清单

| 文件 | 操作 |
|------|------|
| `simple_live_app/pubspec.yaml` | 添加 `ffmpeg_kit_flutter_new_min_gpl` 依赖 |
| `simple_live_app/lib/modules/live_room/live_room_controller.dart` | 新增录音状态、toggleRecording、FFmpeg 生命周期 |
| `simple_live_app/lib/modules/live_room/live_room_page.dart` | 底部栏新增按钮、AppBar 录制指示器 |
