# screenshot

# 一键安装截图和mediainfo、bdinfo指令
## X86版本：
```bash
curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/bash-ss.sh | tr -d '\r' | bash
```
## Arm版本：
```bash
curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bash-ss.sh | tr -d '\r' | bash
```
安装后使用方法：

## 一、截图：

ss.sh "/视频所在文件目录"

运行之后会在/home/screenshot文件夹下生成6张原尺寸截图和mediainfo信息。运行界面如下：（三种输入方式，视频路径最好加引号，有些目录名为空格时不加引号会出错）

- 1）运行指令+视频目录：
```bash
ss.sh "/home/downloads/XXXXXXXX"
```
- 2）指令+视频：
```bash
ss.sh "/home/downloads/XXXXXXX/YYYYYY.mkv"
```
- 3）直接输入指令，按提示输入目录或视频：
```bash
ss.sh
```
接着再输入视频目录：
```bash
/home/downloads/XXXXXXXX
```
## 二、BDinfo获取方法：

扫描光盘并输出报告到光盘路径（交互式选择播放列表按序号选择，按q结束）

适用于光盘目录（非 ISO 文件），报告将生成在光盘路径下：
```bash
bd.sh 'BD_PATH'   #BD_PATH为光盘目录路径
```
若 BD_PATH 是 ISO 文件，则必须输入至完成的文件名。
```bash
bd.sh 'BD_PATH/XXX.iso'
```
