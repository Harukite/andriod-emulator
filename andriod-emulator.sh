好的，以下是优化后的完整代码：

```bash
#!/bin/bash

# 自动查找Android SDK路径
find_android_sdk() {
    local possible_paths=(
        "$HOME/Library/Android/sdk"           # MacOS 可能的路径
        "$HOME/Android/Sdk"                  # Linux 可能的路径
        "$HOME/AndroidSDK"                   # 其他路径
        "/mnt/c/Users/$USER/AppData/Local/Android/Sdk"  # Windows WSL 可能的路径
        "$HOME/.android"                     # Android Studio 默认路径
        "$ANDROID_HOME"                      # 环境变量
        "$ANDROID_SDK_ROOT"                  # 环境变量
    )

    # 检查Android Studio配置文件
    local studio_properties="$HOME/.AndroidStudio*/config/options/android-sdk.xml"
    if [ -f "$studio_properties" ]; then
        local sdk_path=$(grep -oP '(?<=<component name="AndroidSdkProvider"><sdk android-sdk-path=").*(?="/>)' "$studio_properties")
        possible_paths=("${possible_paths[@]}" "$sdk_path")
    fi

    # 遍历所有可能的路径
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ] && [ -d "$path/platform-tools" ]; then
            echo "$path"
            return 0
        fi
    done

    echo "错误: 无法找到 Android SDK 路径"
    exit 1
}

# 通用工具查找函数
find_tool() {
    local tool_name="$1"
    shift
    local tool_paths=("$@")
    for path in "${tool_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    echo "错误: 无法找到 $tool_name"
    exit 1
}

# 查找模拟器程序
find_emulator() {
    local sdk_path="$1"
    find_tool "模拟器" "$sdk_path/emulator/emulator" "$sdk_path/tools/emulator" "$(which emulator)"
}

# 查找 adb
find_adb() {
    local sdk_path="$1"
    find_tool "adb" "$sdk_path/platform-tools/adb" "$(which adb)"
}

# 检查必要的环境
check_environment() {
    # 查找 Android SDK
    ANDROID_SDK=$(find_android_sdk)
    echo "找到 Android SDK: $ANDROID_SDK"

    # 查找模拟器
    EMULATOR=$(find_emulator "$ANDROID_SDK")
    echo "找到模拟器程序: $EMULATOR"

    # 查找 adb
    ADB=$(find_adb "$ANDROID_SDK")
    echo "找到 adb: $ADB"
}

# 获取所有可用模拟器列表
list_avds() {
    echo "可用的模拟器列表："
    "$EMULATOR" -list-avds | while read -r avd; do
        echo "$avd"
    done
}

# 启动指定模拟器
start_avd() {
    local avd_name="$1"
    if [ -z "$avd_name" ]; then
        echo "可用的模拟器："
        list_avds
        echo "请输入要启动的模拟器名称："
        read -r avd_name
    fi

    if [ -z "$avd_name" ]; then
        echo "错误: 未指定模拟器名称"
        return 1
    fi

    # 检查模拟器是否存在
    if ! "$EMULATOR" -list-avds | grep -q "^$avd_name$"; then
        echo "错误: 模拟器 '$avd_name' 不存在"
        list_avds
        return 1
    fi

    echo "正在启动模拟器: $avd_name"
    # 后台运行模拟器
    "$EMULATOR" "@$avd_name" -no-snapshot-load &

    # 等待模拟器启动
    echo "等待模拟器启动..."
    local timeout=60  # 60秒超时
    local count=0
    while ! "$ADB" devices | grep -qE "emulator-[0-9]+[[:space:]]+device"; do
        sleep 2
        count=$((count + 2))
        if [ $count -ge $timeout ]; then
            echo "错误: 模拟器启动超时。是否重试？（y/n）"
            read -r retry
            if [[ "$retry" =~ ^[Yy]$ ]]; then
                echo "正在重试..."
                "$EMULATOR" "@$avd_name" -no-snapshot-load &
                count=0
            else
                return 1
            fi
        fi
        echo -n "."
    done
    echo -e "\n模拟器已启动"
}

# 关闭所有模拟器
stop_avds() {
    echo "正在关闭所有模拟器..."
    "$ADB" devices | grep emulator | cut -f1 | while read -r line; do
        "$ADB" -s "$line" emu kill
    done
    echo "已关闭所有模拟器"
}

# 检查模拟器状态
check_status() {
    echo "当前运行的模拟器："
    "$ADB" devices | grep "emulator"
}

# 显示帮助信息
show_help() {
    echo "Android模拟器控制脚本"
    echo "用法："
    echo "  $0 list          # 显示所有可用模拟器"
    echo "  $0 start [name]  # 启动指定模拟器"
    echo "  $0 stop          # 关闭所有模拟器"
    echo "  $0 status        # 显示运行中的模拟器"
    echo "  $0 help          # 显示此帮助信息"
}

# 主程序入口
main() {
    # 检查环境
    check_environment

    # 处理命令
    case "$1" in
        "list")
            list_avds
            ;;
        "start")
            start_avd "$2"
            ;;
        "stop")
            stop_avds
            ;;
        "status")
            check_status
            ;;
        "help"|"")
            show_help
            ;;
        *)
            echo "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"
```

### 优化内容：
1. **通用的工具查找函数** `find_tool`：减少了 `find_emulator` 和 `find_adb` 中的代码重复。
2. **修复了路径扩展问题**：`possible_paths` 数组的扩展方式修正为适配 Bash 的方式。
3. **增强错误处理**：对找不到工具时提供更明确的错误消息，并通过 `exit 1` 退出程序，确保脚本不继续执行。
4. **模拟器启动时重试机制**：添加了启动模拟器时的重试机制，在启动超时后询问用户是否重试。
5. **过滤 adb 设备输出**：通过正则表达式来精确匹配模拟器设备，避免误判其他设备。

### 使用方法：
1. 保存并添加执行权限：
   ```bash
   chmod +x emulator.sh
   ```

2. 运行脚本：
   ```bash
   # 显示所有模拟器
   ./emulator.sh list

   # 启动模拟器（会提示选择）
   ./emulator.sh start

   # 启动指定模拟器
   ./emulator.sh start Pixel_4_API_30

   # 查看状态
   ./emulator.sh status

   # 停止所有模拟器
   ./emulator.sh stop
   ```

这些改进使脚本更简洁、健壮和用户友好。如果有更多问题，随时告诉我！
