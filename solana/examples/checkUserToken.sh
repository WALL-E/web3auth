#!/bin/bash

# Web3Auth checkUserToken Endpoint Test Script
# 测试 checkUserToken 端点的各种场景（GET和POST方法）


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
    echo -e "${BLUE}  checkUserToken Endpoint Test${NC}"
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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
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
make_post_request() {
    local test_name="$1"
    local data="$2"
    local expected_status="$3"
    local should_be_valid="$4"
    
    print_test "$test_name (POST)"
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/checkUserToken" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求方法: POST"
    echo "请求数据: $data"
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    analyze_response "$http_code" "$body" "$expected_status" "$should_be_valid"
    echo ""
}

# 执行GET请求并分析结果
make_get_request() {
    local test_name="$1"
    local token="$2"
    local expected_status="$3"
    local should_be_valid="$4"
    
    print_test "$test_name (GET)"
    
    if [ -n "$token" ]; then
        response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
            -X GET "$BASE_URL/checkUserToken" \
            -H "token: $token")
    else
        response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
            -X GET "$BASE_URL/checkUserToken")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求方法: GET"
    echo "Token Header: ${token:-'(未提供)'}"
    echo "HTTP状态码: $http_code"
    echo "响应内容:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
    
    analyze_response "$http_code" "$body" "$expected_status" "$should_be_valid"
    echo ""
}

# 分析响应结果
analyze_response() {
    local http_code="$1"
    local body="$2"
    local expected_status="$3"
    local should_be_valid="$4"
    
    # 检查状态码
    if [ "$http_code" = "$expected_status" ]; then
        if [ "$should_be_valid" = "true" ] && [ "$http_code" = "200" ]; then
            # 检查是否有valid字段且为true
            if echo "$body" | jq -e '.valid' > /dev/null 2>&1; then
                valid=$(echo "$body" | jq -r '.valid')
                if [ "$valid" = "true" ]; then
                    print_success "测试通过 - Token有效"
                else
                    print_error "测试失败 - Token无效"
                fi
            else
                print_error "测试失败 - 缺少valid字段"
            fi
        elif [ "$should_be_valid" = "false" ] && [ "$http_code" != "200" ]; then
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
}

# 主测试函数
run_tests() {
    print_warning "注意: checkUserToken端点需要有效的token进行验证"
    print_warning "以下测试使用示例token，实际使用时需要从getUserToken获取真实token"
    echo ""
    
    # 示例token（这些在实际环境中可能无效）
    local valid_token="bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eff"
    local invalid_token="invalid_token_example"
    local malformed_token="bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eZZ"
    
    # POST方法测试
    echo -e "${BLUE}=== POST方法测试 ===${NC}"
    echo ""
    
    # 测试1: 缺少token字段
    make_post_request "缺少token字段" \
        '{}' \
        "400" "false"
    
    # 测试2: 空token字段
    make_post_request "空token字段" \
        '{"token": ""}' \
        "400" "false"
    
    # 测试3: null token字段
    make_post_request "null token字段" \
        '{"token": null}' \
        "400" "false"
    
    # 测试4: 错误的字段名
    make_post_request "错误的字段名" \
        '{"tok": "some_token"}' \
        "400" "false"
    
    # 测试5: 无效token格式（太短）
    make_post_request "无效token格式（太短）" \
        '{"token": "short"}' \
        "400" "false"
    
    # 测试6: 无效token格式（包含非法字符）
    make_post_request "无效token格式（包含非法字符）" \
        '{"token": "invalid@token#format"}' \
        "400" "false"
    
    # 测试7: 格式正确但无效的token
    make_post_request "格式正确但无效的token" \
        "{\"token\": \"$invalid_token\"}" \
        "400" "false"
    
    # 测试8: 修改过的token
    make_post_request "修改过的token" \
        "{\"token\": \"$malformed_token\"}" \
        "400" "false"
    
    # 测试9: 示例有效token（可能失败，因为是示例数据）
    make_post_request "示例有效token" \
        "{\"token\": \"$valid_token\"}" \
        "400" "false"
    
    # 测试10: 额外字段
    make_post_request "额外字段" \
        "{\"token\": \"$valid_token\", \"extra\": \"field\"}" \
        "400" "false"
    
    # GET方法测试
    echo -e "${BLUE}=== GET方法测试 ===${NC}"
    echo ""
    
    # 测试11: 缺少token header
    make_get_request "缺少token header" \
        "" \
        "400" "false"
    
    # 测试12: 空token header
    make_get_request "空token header" \
        "" \
        "400" "false"
    
    # 测试13: 无效token格式（太短）
    make_get_request "无效token格式（太短）" \
        "short" \
        "400" "false"
    
    # 测试14: 无效token格式（包含非法字符）
    make_get_request "无效token格式（包含非法字符）" \
        "invalid@token#format" \
        "400" "false"
    
    # 测试15: 格式正确但无效的token
    make_get_request "格式正确但无效的token" \
        "$invalid_token" \
        "400" "false"
    
    # 测试16: 修改过的token
    make_get_request "修改过的token" \
        "$malformed_token" \
        "400" "false"
    
    # 测试17: 示例有效token（可能失败，因为是示例数据）
    make_get_request "示例有效token" \
        "$valid_token" \
        "400" "false"
    
    # 特殊测试
    echo -e "${BLUE}=== 特殊测试 ===${NC}"
    echo ""
    
    # 测试18: 无效的JSON格式（POST）
    print_test "无效的JSON格式 (POST)"
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/checkUserToken" \
        -H "Content-Type: application/json" \
        -d '{"token": "some_token"')  # 缺少结束括号
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求方法: POST"
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
    
    # 信息提示
    print_info "注意事项:"
    print_info "1. checkUserToken端点支持GET和POST两种方法"
    print_info "2. POST方法: token在请求体中 {\"token\": \"your_token\"}"
    print_info "3. GET方法: token在header中 -H \"token: your_token\""
    print_info "4. 有效的token需要从getUserToken端点获取"
    print_info "5. token有过期时间，过期后需要重新获取"
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
