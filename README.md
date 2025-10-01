# Web3 User Authentication Service

一个基于Solana区块链的Web3用户认证服务，提供安全的用户身份验证和令牌管理功能。

## 🚀 功能特性

- **安全认证**: 基于Solana钱包地址和数字签名的身份验证
- **令牌管理**: AES-256-CBC加密的用户令牌生成和验证
- **余额验证**: 可配置的最小余额要求
- **安全防护**: 集成了速率限制、CORS、Helmet等安全中间件
- **错误处理**: 统一的错误响应格式和详细的错误信息
- **性能监控**: 请求日志记录和响应时间监控

## 📋 API 端点

### 1. 健康检查
```
GET /health
```
返回服务状态和运行时间信息。

### 2. 获取用户ID
```
POST /getUserId
Content-Type: application/json

{
  "address": "solana_wallet_address"
}
```

### 3. 获取用户令牌
```
POST /getUserToken
Content-Type: application/json

{
  "address": "solana_wallet_address",
  "signature": "base58_encoded_signature",
  "uid": "user_id_from_step_2"
}
```

### 4. 通过 Memo 获取用户令牌
```
POST /getUserTokenByMemo
Content-Type: application/json

{
  "address": "solana_wallet_address",
  "uid": "user_id_from_step_2",
  "transaction": "base58_signed_transaction_with_memo_equal_uid"
}
```

- 请求参数说明
  - `address`: 用户的 Solana 钱包地址（base58 字符串）
  - `uid`: 通过 `/getUserId` 获取的用户 ID
  - `transaction`: 已签名且序列化为 base58 的交易字符串，交易内需包含 Memo 指令，其内容必须严格等于 `uid`

- 响应示例
```
200 OK
{
  "result": "encrypted_token"
}
```

- 校验规则
  - 验证交易中签名者列表包含 `address`
  - 解析交易中的 Memo 指令并校验其 UTF-8 内容等于 `uid`
  - 交易必须是已签名的 base58 序列化字符串
  - 使用配置的集群（`CLUSTER`），在服务器端完成解析与验证

- 可能的错误
  - `400 Invalid address`：地址格式不合法
  - `400 Invalid uid`：uid 为空或格式错误
  - `400 Invalid transaction`：交易无法解析或非已签名交易
  - `400 Signature not found`：交易不包含该地址的有效签名
  - `400 Memo mismatch`：交易中的 Memo 内容不等于 `uid`
  - `429 Too Many Requests`：触发速率限制
  - `500 Internal Server Error`：服务器内部错误

- 使用示例
```bash
# 1) 获取 UID
curl -s -X POST 'http://127.0.0.1:4000/getUserId' \
  -H 'Content-Type: application/json' \
  -d '{"address":"<YOUR_ADDRESS>"}'

# 2) 使用 Ledger 生成包含 UID 的 Memo 交易并签名（两种方式）
# 方式 A：交互式工具
node solana/ledger/sign-memo.js "<UID>"

# 方式 B：一键测试程序
cd solana/ledger && ./run-test.sh

# 3) 调用 Memo 接口获取 Token
curl -s -X POST 'http://127.0.0.1:4000/getUserTokenByMemo' \
  -H 'Content-Type: application/json' \
  -d '{"address":"<YOUR_ADDRESS>","uid":"<UID>","transaction":"<BASE58_TX>"}'
```

### 5. 验证用户令牌
```
POST /checkUserToken
Content-Type: application/json

{
  "token": "encrypted_token"
}

# 或者使用 GET 请求
GET /checkUserToken
token: encrypted_token
```

## 🛠️ 安装和配置

### 1. 安装依赖
```bash
cd solana
npm install
```

### 2. 环境配置
复制环境变量模板并配置：
```bash
cp .env.example .env
```

编辑 `.env` 文件，配置以下必需的环境变量：

```env
# 服务器端口
PORT=4000

# 加密盐值
SALT=your_random_salt_here

# AES-256-CBC 加密密钥 (32字节十六进制)
KEY=your_32_byte_hex_key_here

# AES-256-CBC 初始化向量 (16字节十六进制)
IV=your_16_byte_hex_iv_here

# Solana 集群 URL
CLUSTER=https://api.devnet.solana.com

# 最小余额要求 (LAMPORTS)
MIN_BALANCE=1000000

# CORS 允许的源 (逗号分隔)
ALLOWED_ORIGINS=http://localhost:4000
```

### 3. 生成加密密钥
使用以下命令生成安全的密钥：

```bash
# 生成 AES 密钥
node -e "console.log('KEY=' + require('crypto').randomBytes(32).toString('hex'))"

# 生成初始化向量
node -e "console.log('IV=' + require('crypto').randomBytes(16).toString('hex'))"
```

### 4. 启动服务
```bash
# 生产环境
npm start

# 开发环境 (自动重启)
npm run dev
```

## 🔒 安全特性

- **速率限制**: 每15分钟最多100个请求
- **CORS保护**: 可配置的跨域资源共享
- **Helmet安全头**: 自动设置安全HTTP头
- **输入验证**: 严格的参数验证和类型检查
- **错误处理**: 安全的错误信息，不泄露敏感数据
- **环境变量验证**: 启动时检查必需的配置项

## 📊 监控和日志

服务提供以下监控功能：

- **请求日志**: 记录所有HTTP请求的方法、路径、状态码和响应时间
- **错误日志**: 详细的错误堆栈跟踪
- **性能指标**: 响应时间监控
- **健康检查**: 服务状态和运行时间

## 🔧 开发说明

### 代码结构
- 使用ES6模块系统
- 统一的错误处理机制
- 中间件化的输入验证
- 模块化的工具函数

### 主要优化
1. **代码结构**: 移除TypeScript编译代码，使用原生ES6模块
2. **错误处理**: 统一错误响应格式，改进错误信息
3. **安全性**: 添加多层安全防护
4. **性能**: 优化代码重复，提升执行效率
5. **监控**: 添加请求日志和性能监控

## 🚨 注意事项

1. **生产环境**: 确保使用强随机密钥和安全的环境变量
2. **网络安全**: 在生产环境中配置适当的CORS策略
3. **密钥管理**: 定期轮换加密密钥
4. **监控**: 设置适当的日志级别和监控告警

## 📝 许可证

MIT License
