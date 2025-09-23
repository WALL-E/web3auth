#!/bin/bash

# Web3Auth API 综合测试套件
# 运行所有测试脚本并生成详细报告


# 配置
BASE_URL="http://127.0.0.1:4000"
TIMEOUT=10
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/test-logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$LOG_DIR/test_report_$TIMESTAMP.txt"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 测试统计
TOTAL_SCRIPTS=0
PASSED_SCRIPTS=0
FAILED_SCRIPTS=0
SKIPPED_SCRIPTS=0

# 工具函数
print_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Web3Auth API 测试套件                     ║${NC}"
    echo -e "${CYAN}║                      综合测试报告                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}$(printf '%.0s─' {1..60})${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_skip() {
    echo -e "${YELLOW}⏭️  $1${NC}"
}

# 检查依赖
check_dependencies() {
    print_section "检查依赖"
    
    local missing_deps=()
    
    # 检查必需的命令
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq 未安装，JSON输出将不会格式化"
    fi
    
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少必需的依赖: ${missing_deps[*]}"
        print_info "请安装缺少的依赖后重新运行测试"
        exit 1
    fi
    
    print_success "所有依赖检查通过"
    echo ""
}

# 检查服务器状态
check_server() {
    print_section "检查服务器状态"
    
    print_info "检查服务器连接 $BASE_URL ..."
    
    if curl -s --connect-timeout $TIMEOUT "$BASE_URL" > /dev/null 2>&1; then
        print_success "服务器连接正常"
        
        # 获取服务器信息
        local health_response=$(curl -s --connect-timeout $TIMEOUT "$BASE_URL/health" 2>/dev/null || echo "")
        if [ -n "$health_response" ]; then
            print_info "健康检查响应: $health_response"
        fi
        
        return 0
    else
        print_error "无法连接到服务器 $BASE_URL"
        print_info "请确保服务器正在运行:"
        print_info "  cd /Users/zhangzheng/web3auth/solana"
        print_info "  npm start"
        print_info ""
        print_info "或者使用以下命令启动服务器:"
        print_info "  npm run dev"
        return 1
    fi
}

# 创建日志目录
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        print_info "创建日志目录: $LOG_DIR"
    fi
    
    # 清理旧日志（保留最近10个）
    if [ -d "$LOG_DIR" ]; then
        ls -t "$LOG_DIR"/test_report_*.txt 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
}

# 运行单个测试脚本
run_test_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local log_file="$LOG_DIR/${script_name%.sh}_$TIMESTAMP.log"
    
    ((TOTAL_SCRIPTS++))
    
    print_info "运行测试脚本: $script_name"
    
    # 检查脚本是否存在
    if [ ! -f "$script_path" ]; then
        print_error "脚本不存在: $script_path"
        ((FAILED_SCRIPTS++))
        echo "❌ $script_name - 脚本不存在" >> "$REPORT_FILE"
        return 1
    fi
    
    # 检查脚本是否可执行
    if [ ! -x "$script_path" ]; then
        print_info "设置脚本执行权限: $script_name"
        chmod +x "$script_path"
    fi
    
    # 运行脚本并捕获输出
    local start_time=$(date +%s)
    if bash "$script_path" > "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "$script_name 测试通过 (${duration}s)"
        ((PASSED_SCRIPTS++))
        echo "✅ $script_name - 通过 (${duration}s)" >> "$REPORT_FILE"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_error "$script_name 测试失败 (${duration}s)"
        ((FAILED_SCRIPTS++))
        echo "❌ $script_name - 失败 (${duration}s)" >> "$REPORT_FILE"
        
        # 显示错误信息的最后几行
        print_info "错误信息 (最后10行):"
        tail -n 10 "$log_file" | sed 's/^/  /'
        
        return 1
    fi
}

# 运行所有测试
run_all_tests() {
    print_section "运行测试脚本"
    
    # 测试脚本列表（按执行顺序）
    local test_scripts=(
        "health.sh"
        "getUserId.sh"
        "getUserToken.sh"
        "checkUserToken.sh"
    )
    
    echo "开始时间: $(date)" >> "$REPORT_FILE"
    echo "服务器地址: $BASE_URL" >> "$REPORT_FILE"
    echo "测试脚本目录: $SCRIPT_DIR" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    for script in "${test_scripts[@]}"; do
        echo ""
        run_test_script "$script"
        
        # 在测试之间添加短暂延迟
        sleep 1
    done
}

# 生成测试报告
generate_report() {
    print_section "测试报告"
    
    echo "" >> "$REPORT_FILE"
    echo "结束时间: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "测试统计:" >> "$REPORT_FILE"
    echo "  总脚本数: $TOTAL_SCRIPTS" >> "$REPORT_FILE"
    echo "  通过脚本: $PASSED_SCRIPTS" >> "$REPORT_FILE"
    echo "  失败脚本: $FAILED_SCRIPTS" >> "$REPORT_FILE"
    echo "  跳过脚本: $SKIPPED_SCRIPTS" >> "$REPORT_FILE"
    
    # 计算成功率
    local success_rate=0
    if [ $TOTAL_SCRIPTS -gt 0 ]; then
        success_rate=$((PASSED_SCRIPTS * 100 / TOTAL_SCRIPTS))
    fi
    
    echo "  成功率: ${success_rate}%" >> "$REPORT_FILE"
    
    # 显示统计信息
    echo ""
    echo -e "${PURPLE}📊 测试统计${NC}"
    echo -e "总脚本数: $TOTAL_SCRIPTS"
    echo -e "通过脚本: ${GREEN}$PASSED_SCRIPTS${NC}"
    echo -e "失败脚本: ${RED}$FAILED_SCRIPTS${NC}"
    echo -e "跳过脚本: ${YELLOW}$SKIPPED_SCRIPTS${NC}"
    echo -e "成功率: ${success_rate}%"
    echo ""
    
    # 显示报告文件位置
    print_info "详细报告已保存到: $REPORT_FILE"
    
    # 显示日志文件位置
    if [ -d "$LOG_DIR" ]; then
        local log_count=$(ls "$LOG_DIR"/*_$TIMESTAMP.log 2>/dev/null | wc -l)
        if [ $log_count -gt 0 ]; then
            print_info "测试日志已保存到: $LOG_DIR (*_$TIMESTAMP.log)"
        fi
    fi
    
    # 根据结果返回适当的退出码
    if [ $FAILED_SCRIPTS -eq 0 ]; then
        echo ""
        print_success "🎉 所有测试通过！"
        return 0
    else
        echo ""
        print_error "❌ 有测试失败，请检查日志文件"
        return 1
    fi
}

# 显示使用帮助
show_help() {
    echo "Web3Auth API 综合测试套件"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -s, --server   仅检查服务器状态"
    echo "  -c, --clean    清理旧的日志文件"
    echo "  -v, --verbose  显示详细输出"
    echo ""
    echo "示例:"
    echo "  $0              # 运行所有测试"
    echo "  $0 --server     # 仅检查服务器状态"
    echo "  $0 --clean      # 清理旧日志文件"
    echo ""
}

# 清理日志文件
clean_logs() {
    print_section "清理日志文件"
    
    if [ -d "$LOG_DIR" ]; then
        local log_count=$(ls "$LOG_DIR"/*.log "$LOG_DIR"/*.txt 2>/dev/null | wc -l)
        if [ $log_count -gt 0 ]; then
            rm -f "$LOG_DIR"/*.log "$LOG_DIR"/*.txt
            print_success "已清理 $log_count 个日志文件"
        else
            print_info "没有找到需要清理的日志文件"
        fi
    else
        print_info "日志目录不存在"
    fi
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--server)
                print_banner
                check_dependencies
                check_server
                exit $?
                ;;
            -c|--clean)
                clean_logs
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示横幅
    print_banner
    
    # 设置日志
    setup_logging
    
    # 检查依赖
    check_dependencies
    
    # 检查服务器
    if ! check_server; then
        print_error "服务器检查失败，无法继续测试"
        exit 1
    fi
    
    echo ""
    
    # 运行测试
    run_all_tests
    
    echo ""
    
    # 生成报告
    generate_report
}

# 运行主函数
main "$@"
