# 在termux上安装SillyTavern（酒馆）

## 1.换源（清华源）:
```
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && apt update && apt upgrade
```
或直接写入
```
echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main" > $PREFIX/etc/apt/sources.list
pkg update && pkg upgrade -y
```

## 2.安装必要软件
```
pkg install git nodejs-lts -y
```
git用于拉取源码,nodejs是酒馆用的核心技术是必须的依赖


## 3.拉取酒馆源码
```
git clone https://github.com/SillyTavern/SillyTavern -b release
```
如因网络问题无法拉取,则使用以下命令拉取镜像站的酒馆源码
```
git clone https://ghfast.top/https://github.com/SillyTavern/SillyTavern -b release
```


## 4.运行酒馆
```
cd ~/SillyTavern
bash start.sh
```
另外第一次运行时酒馆用使用nodejs自带的包管理npm下载依赖,有时会因网络原因下载缓慢或失败可以使用以下命令换npm的镜像源(清华源)
```
# 设置新源
npm config set registry https://registry.npmmirror.com

# 验证是否设置成功
npm config get registry
# 应该显示：https://registry.npmmirror.com
```


## 5. 更新酒馆
```
cd ~/SillyTavern
git pull --rebase --autostash
```

## 项目仓库及中文社区
酒馆项目仓库(https://github.com/SillyTavern/SillyTavern)
中文社区
旅程:(https://discord.gg/elysianhorizon)
类脑:(https://discord.gg/odysseia)