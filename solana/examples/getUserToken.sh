#!/bin/bash

# Web3Auth getUserToken Endpoint Test Script
# 测试 getUserToken 端点的各种场景


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
    echo -e "${BLUE}  getUserToken Endpoint Test${NC}"
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
make_request() {
    local test_name="$1"
    local data="$2"
    local expected_status="$3"
    local should_have_token="$4"
    
    print_test "$test_name"
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/getUserToken" \
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
        if [ "$should_have_token" = "true" ] && [ "$http_code" = "200" ]; then
            # 检查是否有token字段
            if echo "$body" | jq -e '.token' > /dev/null 2>&1; then
                token=$(echo "$body" | jq -r '.token')
                print_success "测试通过 - 获得token: ${token:0:20}..."
            else
                print_error "测试失败 - 缺少token字段"
            fi
        elif [ "$should_have_token" = "false" ] && [ "$http_code" != "200" ]; then
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
    print_warning "注意: getUserToken端点需要有效的签名验证"
    print_warning "以下测试使用示例数据，实际使用时需要真实的签名"
    echo ""
    
    # 测试1: 缺少所有必需参数
    make_request "缺少所有必需参数" \
        '{}' \
        "400" "false"
    
    # 测试2: 只有address参数
    make_request "只有address参数" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"}' \
        "400" "false"
    
    # 测试3: 缺少signature参数
    make_request "缺少signature参数" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c"}' \
        "400" "false"
    
    # 测试4: 缺少uid参数
    make_request "缺少uid参数" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"}' \
        "400" "false"
    
    # 测试5: 无效的address格式
    make_request "无效的address格式" \
        '{"address": "invalid_address", "uid": "c9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"}' \
        "400" "false"
    
    # 测试6: 无效的signature格式（太短）
    make_request "无效的signature格式（太短）" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c", "signature": "short"}' \
        "400" "false"
    
    # 测试7: 无效的uid格式（太短）
    make_request "无效的uid格式（太短）" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "123", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"}' \
        "400" "false"
    
    # 测试8: 空字符串参数
    make_request "空字符串参数" \
        '{"address": "", "uid": "", "signature": ""}' \
        "400" "false"
    
    # 测试9: null参数
    make_request "null参数" \
        '{"address": null, "uid": null, "signature": null}' \
        "400" "false"
    
    # 测试10: 有效格式但无效签名（期望失败）
    make_request "有效格式但无效签名" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8INVALID"}' \
        "400" "false"
    
    # 测试11: 修改过的地址（签名不匹配）
    make_request "修改过的地址（签名不匹配）" \
        '{"address": "11111111111111111111111111111112", "uid": "c9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"}' \
        "400" "false"
    
    # 测试12: 修改过的uid（签名不匹配）
    make_request "修改过的uid（签名不匹配）" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "d9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"}' \
        "400" "false"
    
    # 测试13: 修改过的签名
    make_request "修改过的签名" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VZZ"}' \
        "400" "false"
    
    # 测试14: 额外的字段
    make_request "额外的字段" \
        '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c", "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5", "extra": "field"}' \
        "400" "false"
    
    # 测试15: 无效的JSON格式
    print_test "无效的JSON格式"
    response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT \
        -X POST "$BASE_URL/getUserToken" \
        -H "Content-Type: application/json" \
        -d '{"address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV", "uid": "c9fe7bf01a33e35c"')  # 缺少结束
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "请求数据: 无效JSON（缺少结束）"
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
    print_info "1. getUserToken端点需要有效的Solana签名验证"
    print_info "2. 签名必须是使用私钥对 'uid' 进行签名的结果"
    print_info "3. 地址必须与签名的公钥匹配"
    print_info "4. 在实际使用中，需要使用Solana钱包生成真实的签名"
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
