# Ledger Memo Token Test

这个测试程序演示了完整的 Ledger 钱包 Memo Token 获取流程。

## 功能

1. 连接 Ledger 硬件钱包
2. 获取钱包地址
3. 调用 `/getUserId` API 获取 UID
4. 使用 UID 作为 Memo 内容创建并签名交易
5. 调用 `/getUserTokenByMemo` API 获取 Token

## 文件说明

- `test-memo-token.js` - 主测试程序
- `run-test.sh` - 运行脚本
- `README.md` - 使用说明

## 使用前准备

1. **确保服务器运行**
   ```bash
   cd /Users/zhangzheng/web3auth/solana
   node app.js
   ```

2. **准备 Ledger 设备**
   - 连接 Ledger 设备到电脑
   - 解锁 Ledger 设备
   - 打开 Solana 应用
   - 如果需要，启用盲签名（Blind Signing）

## 运行测试

### 方法 1: 使用运行脚本（推荐）
```bash
cd /Users/zhangzheng/web3auth/solana/ledger
./run-test.sh
```

### 方法 2: 直接运行
```bash
cd /Users/zhangzheng/web3auth/solana/ledger
node test-memo-token.js
```

## 环境变量配置

可以通过环境变量自定义配置：

```bash
# Solana 集群 URL
export CLUSTER="https://api.devnet.solana.com"

# API 服务器地址
export API_BASE="http://127.0.0.1:4000"

# Ledger 派生路径
export DERIVATION_PATH="44'/501'/0'/0'"
```

## 测试流程

1. **连接 Ledger**: 程序会尝试连接 Ledger 设备
2. **获取地址**: 从指定派生路径获取钱包地址
3. **获取 UID**: 调用 `/getUserId` API 获取该地址的 UID
4. **创建交易**: 创建包含 UID 的 Memo 交易
5. **签名确认**: 在 Ledger 设备上确认并签名交易
6. **获取 Token**: 使用签名交易调用 `/getUserTokenByMemo` 获取 Token

## 输出示例

```
🔗 Ledger Memo Token Test
Cluster: https://api.devnet.solana.com
API Base: http://127.0.0.1:4000
Derivation Path: 44'/501'/0'/0'

Connecting to Ledger device...
Ensure the Solana app is open on your Ledger.
Getting address from path: 44'/501'/0'/0'
Ledger address: 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM

📋 Getting user ID...
📡 POST http://127.0.0.1:4000/getUserId
Response status: 200
✅ User ID: user_123456

✍️ Creating and signing memo transaction...
Getting recent blockhash...
Memo content: "user_123456"
Transaction created, requesting signature from Ledger...
Please confirm the transaction on your Ledger...
Transaction signed successfully

🎫 Getting user token by memo...
📡 POST http://127.0.0.1:4000/getUserTokenByMemo
Response status: 200
✅ Token received: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

🎉 Test completed successfully!

📊 Summary:
Address: 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
UID: user_123456
Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 故障排除

### 常见问题

1. **Ledger 连接失败**
   - 确保 Ledger 设备已连接并解锁
   - 确保 Solana 应用已打开
   - 检查 USB 连接

2. **签名失败**
   - 确保在 Ledger 上确认交易
   - 如果是复杂交易，可能需要启用盲签名

3. **API 调用失败**
   - 确保服务器正在运行（`curl http://127.0.0.1:4000/health`）
   - 检查网络连接

4. **权限错误**
   - 确保脚本有执行权限：`chmod +x run-test.sh`

### 调试模式

如果需要更详细的调试信息，可以设置环境变量：

```bash
export DEBUG=1
node test-memo-token.js
```

## 注意事项

- 这是测试程序，使用的是 Devnet 环境
- 请确保 Ledger 设备的安全
- 不要在生产环境中使用测试密钥或地址
- 签名交易前请仔细确认交易内容