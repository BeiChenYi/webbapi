#!/bin/bash

# 在线表格编辑器更新脚本
# 适用于已通过deploy.sh部署的系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 应用配置
APP_NAME="online-table-editor"
APP_USER="table-editor"
APP_DIR="/opt/$APP_NAME"
GIT_REPO="https://github.com/BeiChenYi/webbapi.git"
BRANCH="main"

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用sudo或以root用户运行此脚本"
        exit 1
    fi
}

# 备份当前数据
backup_data() {
    print_info "备份现有数据..."
    local backup_file="$APP_DIR/data.json.backup.$(date +%Y%m%d_%H%M%S)"
    if [ -f "$APP_DIR/data.json" ]; then
        cp "$APP_DIR/data.json" "$backup_file"
        print_info "数据已备份到: $backup_file"
    else
        print_warn "未找到data.json，跳过备份"
    fi
}

# 拉取最新代码
pull_latest_code() {
    print_info "拉取最新代码..."
    
    # 检查是否git仓库
    if [ ! -d "$APP_DIR/.git" ]; then
        print_error "$APP_DIR 不是git仓库，无法拉取更新"
        print_info "尝试从仓库克隆..."
        cd /tmp
        rm -rf "$APP_NAME-temp"
        git clone "$GIT_REPO" "$APP_NAME-temp"
        rsync -av --exclude='data.json' "$APP_NAME-temp/" "$APP_DIR/"
        rm -rf "$APP_NAME-temp"
        chown -R "$APP_USER:$APP_USER" "$APP_DIR"
        return
    fi
    
    # 进入应用目录
    cd "$APP_DIR"
    
    # 保存当前更改
    if git diff --quiet; then
        print_info "工作区干净，直接拉取"
    else
        print_warn "工作区有未提交的更改，暂存并保存..."
        git stash
    fi
    
    # 拉取最新代码
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    
    # 如果有暂存的更改，尝试应用
    if git stash list | grep -q "stash"; then
        print_info "尝试应用暂存的更改..."
        git stash pop || true
    fi
}

# 安装依赖
install_dependencies() {
    print_info "安装/更新Node.js依赖..."
    cd "$APP_DIR"
    sudo -u "$APP_USER" npm install --production
}

# 重启服务
restart_service() {
    print_info "重启服务..."
    systemctl restart "$APP_NAME"
    
    # 检查服务状态
    sleep 2
    if systemctl is-active --quiet "$APP_NAME"; then
        print_info "服务重启成功!"
    else
        print_error "服务重启失败，请检查日志: journalctl -u $APP_NAME"
        exit 1
    fi
}

# 显示更新信息
show_update_info() {
    local ip_address
    ip_address=$(hostname -I | awk '{print $1}')
    local app_port
    app_port=$(grep -o 'PORT=[0-9]*' "$APP_DIR/server.js" | head -1 | cut -d'=' -f2)
    if [ -z "$app_port" ]; then
        app_port="32577"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}      在线表格编辑器更新完成!          ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "应用名称: ${YELLOW}$APP_NAME${NC}"
    echo -e "运行端口: ${YELLOW}$app_port${NC}"
    echo -e "应用目录: ${YELLOW}$APP_DIR${NC}"
    echo -e "服务状态: ${YELLOW}systemctl status $APP_NAME${NC}"
    echo -e "查看日志: ${YELLOW}journalctl -u $APP_NAME -f${NC}"
    echo ""
    echo -e "访问地址:"
    echo -e "  - 本地: ${YELLOW}http://localhost:$app_port${NC}"
    echo -e "  - 网络: ${YELLOW}http://$ip_address:$app_port${NC}"
    echo ""
    echo -e "更新内容:"
    echo -e "  - 添加删除行和删除列功能"
    echo -e "  - 界面优化"
    echo ""
}

# 主函数
main() {
    print_info "开始更新在线表格编辑器..."
    
    check_root
    backup_data
    pull_latest_code
    install_dependencies
    restart_service
    show_update_info
    
    print_info "更新完成!"
}

# 执行主函数
main "$@"
