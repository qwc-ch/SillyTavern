#!/data/data/com.termux/files/usr/bin/bash

# SillyTavern一键安装脚本 for Termux
# 作者：基于SillyTavern官方文档
# 版本：1.5
# 修复：NPM配置错误，简化依赖安装

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # 无颜色

# 全局变量
INSTALL_DIR="$HOME/SillyTavern"
VERSION="1.5"
REQUIRED_NODE_VERSION="18"

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 函数：显示标题
show_header() {
    clear
    print_message "╔════════════════════════════════════════╗" "$CYAN"
    print_message "║    SillyTavern Termux 一键安装脚本    ║" "$CYAN"
    print_message "║             版本: $VERSION             ║" "$CYAN"
    print_message "╚════════════════════════════════════════╝" "$CYAN"
    echo ""
}

# 函数：检查Node.js版本
check_node_version() {
    if ! command -v node &> /dev/null; then
        print_message "Node.js 未安装，将自动安装 Node.js LTS" "$YELLOW"
        return 1
    fi
    
    local node_version
    node_version=$(node --version | sed 's/v//')
    local major_version
    major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [ "$major_version" -lt "$REQUIRED_NODE_VERSION" ]; then
        print_message "当前 Node.js 版本 ($node_version) 低于要求 ($REQUIRED_NODE_VERSION+)" "$YELLOW"
        return 1
    fi
    
    print_message "✓ Node.js 版本检查通过: $node_version" "$GREEN"
    return 0
}

# 函数：配置Termux清华源
configure_termux_mirror() {
    print_message "正在配置 Termux 清华源..." "$BLUE"
    
    # 备份原有源
    if [ -f "$PREFIX/etc/apt/sources.list" ]; then
        cp "$PREFIX/etc/apt/sources.list" "$PREFIX/etc/apt/sources.list.bak"
        print_message "已备份原有源文件" "$YELLOW"
    fi
    
    # 写入清华源
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
    
    # 更新软件包列表
    print_message "更新软件包列表..." "$BLUE"
    pkg update -y 2>&1 | grep -v "termux-change-repo" || true
    
    print_message "✓ Termux 清华源配置完成" "$GREEN"
}

# 函数：配置NPM清华源
configure_npm_mirror() {
    print_message "正在配置 NPM 清华源..." "$BLUE"
    
    # 设置npm清华源（使用正确的配置）
    npm config set registry https://registry.npmmirror.com
    
    # 清理npm缓存
    print_message "清理 NPM 缓存..." "$BLUE"
    npm cache clean --force
    
    # 验证配置
    local current_registry
    current_registry=$(npm config get registry)
    
    if [[ "$current_registry" == *"npmmirror.com"* ]]; then
        print_message "✓ NPM 镜像源配置完成: $current_registry" "$GREEN"
    else
        print_message "⚠ NPM 镜像源配置可能失败" "$YELLOW"
    fi
}

# 函数：安装Node.js（如果未安装）
install_nodejs() {
    print_message "正在安装 Node.js LTS..." "$BLUE"
    
    # 更新包列表
    pkg update -y
    
    # 安装Node.js LTS
    if pkg install nodejs-lts -y; then
        print_message "✓ Node.js LTS 安装完成" "$GREEN"
        
        # 验证安装
        local node_version
        node_version=$(node --version)
        print_message "当前 Node.js 版本: $node_version" "$CYAN"
        
        # 更新npm到最新版本
        print_message "更新 npm 到最新版本..." "$BLUE"
        npm install -g npm@latest
        
        return 0
    else
        print_message "✗ Node.js 安装失败" "$RED"
        return 1
    fi
}

# 函数：克隆SillyTavern仓库
clone_sillytavern() {
    local install_dir="$INSTALL_DIR"
    
    if [ -d "$install_dir" ]; then
        print_message "检测到已存在的 SillyTavern 目录" "$YELLOW"
        print_message "目录位置: $install_dir" "$CYAN"
        
        local choice
        read -p "是否删除并重新安装？ (y/N): " -n 1 -r choice
        echo
        
        if [[ $choice =~ ^[Yy]$ ]]; then
            # 备份现有数据
            if [ -d "$install_dir/public/characters" ] || [ -d "$install_dir/public/chats" ]; then
                local backup_dir="$HOME/SillyTavern_backup_$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$backup_dir"
                
                [ -d "$install_dir/public/characters" ] && cp -r "$install_dir/public/characters" "$backup_dir/" 2>/dev/null || true
                [ -d "$install_dir/public/chats" ] && cp -r "$install_dir/public/chats" "$backup_dir/" 2>/dev/null || true
                [ -f "$install_dir/config.yaml" ] && cp "$install_dir/config.yaml" "$backup_dir/" 2>/dev/null || true
                [ -f "$install_dir/config.conf" ] && cp "$install_dir/config.conf" "$backup_dir/" 2>/dev/null || true
                
                print_message "✓ 数据已备份到: $backup_dir" "$GREEN"
            fi
            
            rm -rf "$install_dir"
            print_message "已删除旧目录" "$YELLOW"
        else
            print_message "跳过克隆，使用现有目录" "$YELLOW"
            return 0
        fi
    fi
    
    print_message "正在克隆 SillyTavern 仓库..." "$BLUE"
    print_message "分支: release" "$CYAN"
    
    # 尝试多个源（使用更稳定的源）
    local sources=(
        "https://github.com/SillyTavern/SillyTavern"
        "https://gitee.com/mirrors/SillyTavern"
        "https://kgithub.com/SillyTavern/SillyTavern"
    )
    
    local clone_success=false
    
    for source in "${sources[@]}"; do
        print_message "尝试源: $source" "$YELLOW"
        
        if timeout 120 git clone "$source" -b release "$install_dir" 2>&1 | grep -v "warning:"; then
            clone_success=true
            print_message "✓ SillyTavern 克隆完成" "$GREEN"
            break
        else
            print_message "克隆失败，尝试下一个源..." "$YELLOW"
            [ -d "$install_dir" ] && rm -rf "$install_dir"
            sleep 1
        fi
    done
    
    if [ "$clone_success" = false ]; then
        print_message "✗ 所有源都克隆失败" "$RED"
        print_message "你可以尝试以下方法:" "$YELLOW"
        echo "1. 手动下载: https://github.com/SillyTavern/SillyTavern/archive/refs/heads/release.zip"
        echo "2. 解压到: $install_dir"
        echo "3. 然后运行: cd $install_dir && npm install"
        exit 1
    fi
    
    return 0
}

# 函数：安装SillyTavern依赖
install_sillytavern_deps() {
    local install_dir="$INSTALL_DIR"
    
    if [ ! -d "$install_dir" ]; then
        print_message "✗ SillyTavern 目录不存在" "$RED"
        return 1
    fi
    
    cd "$install_dir" || {
        print_message "✗ 无法进入目录: $install_dir" "$RED"
        return 1
    }
    
    print_message "正在安装 SillyTavern 依赖..." "$BLUE"
    print_message "这可能需要几分钟，请耐心等待..." "$YELLOW"
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        print_message "✗ 未找到 package.json 文件" "$RED"
        return 1
    fi
    
    # 先配置npm镜像源
    configure_npm_mirror
    
    # 安装依赖
    print_message "开始安装依赖..." "$BLUE"
    
    # 清理可能的旧依赖
    rm -rf node_modules package-lock.json 2>/dev/null || true
    
    # 安装依赖
    if npm install --loglevel=error; then
        print_message "✓ 依赖安装完成" "$GREEN"
    else
        print_message "普通安装失败，尝试使用 --legacy-peer-deps..." "$YELLOW"
        
        if npm install --legacy-peer-deps --loglevel=error; then
            print_message "✓ 依赖安装完成 (使用 --legacy-peer-deps)" "$GREEN"
        else
            print_message "尝试使用 --force..." "$YELLOW"
            
            if npm install --force --loglevel=error; then
                print_message "✓ 依赖安装完成 (使用 --force)" "$GREEN"
            else
                print_message "✗ 依赖安装失败" "$RED"
                print_message "请尝试手动安装:" "$YELLOW"
                echo "cd $install_dir"
                echo "npm cache clean --force"
                echo "npm install"
                return 1
            fi
        fi
    fi
    
    return 0
}

# 函数：安装SillyTavern
install_sillytavern() {
    show_header
    
    print_message "开始安装 SillyTavern..." "$CYAN"
    print_message "安装目录: $INSTALL_DIR" "$CYAN"
    echo ""
    
    # 步骤1: 检查环境
    if ! check_node_version; then
        install_nodejs
    fi
    
    # 步骤2: 安装Git（如果未安装）
    print_message "检查 Git..." "$BLUE"
    if ! command -v git &> /dev/null; then
        print_message "安装 Git..." "$BLUE"
        pkg install git -y
        print_message "✓ Git 已安装" "$GREEN"
    else
        print_message "✓ Git 已安装" "$GREEN"
    fi
    
    # 步骤3: 配置Termux源
    print_message "配置 Termux 源..." "$PURPLE"
    configure_termux_mirror
    
    # 步骤4: 克隆仓库
    print_message "克隆 SillyTavern 仓库..." "$PURPLE"
    clone_sillytavern
    
    # 步骤5: 安装依赖
    print_message "安装依赖..." "$PURPLE"
    install_sillytavern_deps
    
    print_message "╔════════════════════════════════════════╗" "$CYAN"
    print_message "║         🎉 安装完成！                ║" "$GREEN"
    print_message "╚════════════════════════════════════════╝" "$CYAN"
    echo ""
    
    print_message "📋 使用说明:" "$YELLOW"
    echo ""
    print_message "1. 启动命令:" "$CYAN"
    echo "   cd ~/SillyTavern"
    echo "   bash start.sh"
    echo ""
    
    print_message "2. 访问地址:" "$CYAN"
    echo "   http://localhost:8000"
    echo "   在浏览器中打开以上地址"
    echo ""
    
    print_message "3. 重要目录:" "$CYAN"
    echo "   安装目录: ~/SillyTavern"
    echo "   角色数据: ~/SillyTavern/public/characters"
    echo "   对话记录: ~/SillyTavern/public/chats"
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# 主菜单
main_menu() {
    while true; do
        show_header
        
        print_message "主菜单" "$CYAN"
        echo ""
        
        print_message "1. 📦 安装 SillyTavern (完整安装)" "$GREEN"
        print_message "2. 🔄 更新 SillyTavern" "$GREEN"
        print_message "3. ⚙️  配置 NPM 镜像源" "$GREEN"
        print_message "4. 🚀 启动 SillyTavern" "$GREEN"
        print_message "5. 📖 查看帮助信息" "$GREEN"
        print_message "6. ❌ 退出脚本" "$GREEN"
        echo ""
        
        local choice
        read -p "请选择操作 (1-6): " choice
        
        case $choice in
            1)
                install_sillytavern
                ;;
            2)
                update_sillytavern
                ;;
            3)
                configure_npm_mirror
                read -p "按回车键返回主菜单..."
                ;;
            4)
                start_sillytavern
                ;;
            5)
                show_help
                ;;
            6)
                print_message "感谢使用，再见！ 👋" "$CYAN"
                echo ""
                exit 0
                ;;
            *)
                print_message "无效选项，请重新输入" "$RED"
                sleep 1
                ;;
        esac
    done
}

# 函数：更新SillyTavern
update_sillytavern() {
    show_header
    
    if [ ! -d "$INSTALL_DIR" ]; then
        print_message "✗ 未找到 SillyTavern 目录" "$RED"
        print_message "请先安装 SillyTavern" "$YELLOW"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    print_message "更新 SillyTavern..." "$CYAN"
    echo ""
    
    cd "$INSTALL_DIR" || {
        print_message "✗ 无法进入目录" "$RED"
        read -p "按回车键返回主菜单..."
        return
    }
    
    # 备份数据
    print_message "备份数据..." "$BLUE"
    local backup_dir="$HOME/SillyTavern_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    [ -d "public/characters" ] && cp -r "public/characters" "$backup_dir/" 2>/dev/null || true
    [ -d "public/chats" ] && cp -r "public/chats" "$backup_dir/" 2>/dev/null || true
    [ -f "config.yaml" ] && cp "config.yaml" "$backup_dir/" 2>/dev/null || true
    
    print_message "✓ 数据已备份到: $backup_dir" "$GREEN"
    
    # 拉取更新
    print_message "拉取更新..." "$BLUE"
    if git pull; then
        print_message "✓ 代码更新完成" "$GREEN"
    else
        print_message "✗ 更新失败" "$RED"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 更新依赖
    print_message "更新依赖..." "$BLUE"
    configure_npm_mirror
    
    if npm install; then
        print_message "✓ 依赖更新完成" "$GREEN"
    else
        if npm install --legacy-peer-deps; then
            print_message "✓ 依赖更新完成 (使用 --legacy-peer-deps)" "$GREEN"
        else
            print_message "✗ 依赖更新失败" "$RED"
        fi
    fi
    
    print_message "✅ 更新完成！" "$GREEN"
    print_message "备份目录: $backup_dir (可手动清理)" "$YELLOW"
    
    read -p "按回车键返回主菜单..."
}

# 函数：启动SillyTavern
start_sillytavern() {
    show_header
    
    if [ ! -d "$INSTALL_DIR" ]; then
        print_message "✗ 未找到 SillyTavern 目录" "$RED"
        print_message "请先安装 SillyTavern" "$YELLOW"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    print_message "启动 SillyTavern..." "$CYAN"
    echo ""
    
    cd "$INSTALL_DIR" || {
        print_message "✗ 无法进入目录" "$RED"
        read -p "按回车键返回主菜单..."
        return
    }
    
    print_message "启动选项:" "$YELLOW"
    print_message "1. 正常启动" "$GREEN"
    print_message "2. 后台运行" "$GREEN"
    print_message "3. 返回菜单" "$GREEN"
    echo ""
    
    local choice
    read -p "请选择 (1-3): " choice
    
    case $choice in
        1)
            print_message "正在启动..." "$BLUE"
            echo "按 Ctrl+C 停止"
            echo "访问: http://localhost:8000"
            echo ""
            bash start.sh
            ;;
        2)
            print_message "后台启动中..." "$BLUE"
            nohup bash start.sh > "$HOME/sillytavern.log" 2>&1 &
            local pid=$!
            echo $pid > "$HOME/sillytavern.pid"
            print_message "✓ 已在后台运行" "$GREEN"
            print_message "PID: $pid" "$CYAN"
            print_message "日志: ~/sillytavern.log" "$CYAN"
            print_message "停止: kill $pid" "$CYAN"
            sleep 2
            read -p "按回车键返回主菜单..."
            ;;
        3)
            return
            ;;
        *)
            print_message "无效选项，返回菜单" "$YELLOW"
            ;;
    esac
}

# 函数：显示帮助信息
show_help() {
    show_header
    
    print_message "帮助信息" "$CYAN"
    echo ""
    
    print_message "常见问题:" "$YELLOW"
    echo ""
    
    print_message "1. 安装失败:" "$GREEN"
    echo "   • 检查网络连接"
    echo "   • 确保有足够存储空间"
    echo "   • 重启Termux后重试"
    echo ""
    
    print_message "2. 启动失败:" "$GREEN"
    echo "   • 检查端口8000是否被占用"
    echo "   • 确保依赖安装完成"
    echo "   • 查看日志: cat ~/sillytavern.log"
    echo ""
    
    print_message "3. 更新失败:" "$GREEN"
    echo "   • 备份数据后重新安装"
    echo "   • 检查网络连接"
    echo ""
    
    print_message "4. 获取帮助:" "$GREEN"
    echo "   • GitHub: https://github.com/SillyTavern/SillyTavern"
    echo "   • Discord: https://discord.gg/elysianhorizon"
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# 主函数
main() {
    # 检查Termux环境
    if [ ! -d "/data/data/com.termux/files/usr" ]; then
        echo "错误: 此脚本仅适用于 Termux 环境"
        exit 1
    fi
    
    # 请求存储权限
    if [ ! -d "$HOME/storage" ]; then
        echo "请求存储权限..."
        termux-setup-storage
        sleep 2
    fi
    
    # 进入主菜单
    main_menu
}

# 运行主函数
main "$@"