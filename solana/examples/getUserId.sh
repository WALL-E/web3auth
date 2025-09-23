#!/bin/bash

# Web3Auth getUserId Endpoint Test Script
# 测试 getUserId 端点的各种场景

# 配置
BASE_URL="http://127.0.0.1:4000"
TIMEOUT=10

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0

# 工具函数
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  getUserId Endpoint Test${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}🧪 测试 $((++TOTAL_TESTS)): $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_summary() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  测试总结${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "总测试数: $TOTAL_TESTS"
    echo -e "通过测试: $PASSED_TESTS"
    echo -e "失败测试: $((TOTAL_TESTS - PASSED_TESTS))"
    
    if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
        echo -e "${GREEN}🎉 所有测试通过！${NC}"
        exit 0
    else
        echo -e "${RED}❌ 有测试失败${NC}"
        exit 1
    fi
}

# 检查服务器是否运行
check_server() {
    print_info "检查服务器连接..."
    if curl -s --connect-timeout $TIMEOUT "$BASE_URL" > /dev/null 2>&1; then
        print_info "服务器连接正常"
        return 0
    else
        print_error "无法连接到服务器 $BASE_URL"
        print_info "请确保服务器正在运行: npm start"
        exit 1
    fi
}

# 执行POST请求并分析结果
make_request() {
    local test_name="$1"
    local data="$2"
    local expected_status="$3"
    local should_have_result="$4"
    
    print_test "$test_name"
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/getUserId" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求数据: $data"
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    # 检查状态码
    if [ "$http_code" = "$expected_status" ]; then
        if [ "$should_have_result" = "true" ] && [ "$http_code" = "200" ]; then
            # 检查是否有result字段
            if echo "$body" | jq -e '.result' > /dev/null 2>&1; then
                result=$(echo "$body" | jq -r '.result')
                print_success "测试通过 - 获得用户ID: $result"
            else
                print_error "测试失败 - 缺少result字段"
            fi
        elif [ "$should_have_result" = "false" ] && [ "$http_code" != "200" ]; then
            # 检查错误响应格式
            if echo "$body" | jq -e '.error' > /dev/null 2>&1; then
                error=$(echo "$body" | jq -r '.error')
                print_success "测试通过 - 正确返回错误: $error"
            else
                print_error "测试失败 - 错误响应格式不正确"
            fi
        else
            print_success "测试通过 - 状态码正确"
        fi
    else
        print_error "测试失败 - 期望状态码 $expected_status，实际 $http_code"
    fi
    
    echo ""
}

# 主测试函数
run_tests() {
    # 测试1: 有效的Solana地址
    make_request "有效的Solana地址" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"}' \
        "200" "true"
    
    # 测试2: 系统程序地址（不在ed25519曲线上）
    make_request "系统程序地址（不在ed25519曲线上）" \
        '{"address": "11111111111111111111111111111112"}' \
        "400" "false"
    
    # 测试3: 无效的地址（包含非base58字符）
    make_request "无效地址（包含非base58字符）" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqZ0"}' \
        "400" "false"
    
    # 测试4: 无效的地址（太短）
    make_request "无效地址（太短）" \
        '{"address": "123"}' \
        "400" "false"
    
    # 测试5: 无效的地址（太长）
    make_request "无效地址（太长）" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"}' \
        "400" "false"
    
    # 测试6: 缺少address字段
    make_request "缺少address字段" \
        '{"addr": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"}' \
        "400" "false"
    
    # 测试7: 空的address字段
    make_request "空的address字段" \
        '{"address": ""}' \
        "400" "false"
    
    # 测试8: null的address字段
    make_request "null的address字段" \
        '{"address": null}' \
        "400" "false"
    
    # 测试9: 完全空的请求体
    make_request "空的请求体" \
        '{}' \
        "400" "false"
    
    # 测试10: 无效的JSON
    print_test "无效的JSON格式"
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/getUserId" \
        -H "Content-Type: application/json" \
        -d '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"')  # 缺少结束括号
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求数据: 无效JSON（缺少结束括号）"
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    if [ "$http_code" = "400" ]; then
        print_success "测试通过 - 正确处理无效JSON"
    else
        print_error "测试失败 - 期望状态码 400，实际 $http_code"
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
    
    # 检查服务器并运行测试
    check_server
    echo ""
    
    run_tests
    print_summary
}

# 运行主函数
main "$@"
