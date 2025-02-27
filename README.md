### 启动andriod studio 安装的模拟器，不用每次都要打开开发工具启动模拟器

使用方法：
保存并添加执行权限：

```bash
chmod +x andriod-emulator.sh
```
运行脚本：

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
