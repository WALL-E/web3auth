#!/bin/bash

# Web3Auth Health Check Script
# 测试服务器健康状态和基本端点


# 配置
BASE_URL="http://127.0.0.1:4000"
TIMEOUT=10

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工具函数
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Web3Auth Health Check Test${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}🧪 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查服务器是否运行
check_server() {
    print_test "检查服务器连接..."
    if curl -s --connect-timeout $TIMEOUT "$BASE_URL" > /dev/null 2>&1; then
        print_success "服务器连接正常"
        return 0
    else
        print_error "无法连接到服务器 $BASE_URL"
        print_info "请确保服务器正在运行: npm start"
        exit 1
    fi
}

# 测试根端点
test_root_endpoint() {
    print_test "测试根端点 (GET /)..."
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT "$BASE_URL/")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    if [ "$http_code" = "200" ]; then
        print_success "根端点测试通过"
    else
        print_error "根端点测试失败 (状态码: $http_code)"
    fi
    echo ""
}

# 测试健康检查端点
test_health_endpoint() {
    print_test "测试健康检查端点 (GET /health)..."
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT "$BASE_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    if [ "$http_code" = "200" ]; then
        # 检查响应是否包含预期字段
        if echo "$body" | jq -e '.status' > /dev/null 2>&1; then
            status=$(echo "$body" | jq -r '.status')
            if [ "$status" = "ok" ]; then
                print_success "健康检查测试通过 - 服务状态正常"
            else
                print_error "健康检查测试失败 - 服务状态异常: $status"
            fi
        else
            print_error "健康检查测试失败 - 响应格式不正确"
        fi
    else
        print_error "健康检查测试失败 (状态码: $http_code)"
    fi
    echo ""
}

# 测试404端点
test_404_endpoint() {
    print_test "测试404端点 (GET /nonexistent)..."
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT "$BASE_URL/nonexistent")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    if [ "$http_code" = "404" ]; then
        print_success "404端点测试通过"
    else
        print_error "404端点测试失败 (期望404，实际: $http_code)"
    fi
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查依赖
    if ! command -v curl &> /dev/null; then
        print_error "curl 未安装，请先安装 curl"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_info "jq 未安装，JSON输出将不会格式化"
    fi
    
    # 运行测试
    check_server
    echo ""
    
    test_root_endpoint
    test_health_endpoint
    test_404_endpoint
    
    print_info "健康检查测试完成！"
}

# 运行主函数
main "$@"
