#!/bin/bash

# 自动生成Web3Auth环境变量脚本
# 生成SALT、KEY、IV三个加密相关的环境变量

echo "🔐 正在生成Web3Auth环境变量..."

# 生成32字节的随机SALT (64个十六进制字符)
SALT=$(openssl rand -hex 32)

# 生成32字节的随机KEY (64个十六进制字符)
KEY=$(openssl rand -hex 32)

# 生成16字节的随机IV (32个十六进制字符)
IV=$(openssl rand -hex 16)

# 默认配置设置
CLUSTER="https://api.devnet.solana.com"
PORT=4000
MIN_BALANCE=0

echo ""
echo "✅ 环境变量生成完成！"
echo ""
echo "请将以下内容复制到您的 .env 文件中："
echo "================================================"
echo "SALT=$SALT"
echo "KEY=$KEY"
echo "IV=$IV"
echo "CLUSTER=$CLUSTER"
echo "PORT=$PORT"
echo "MIN_BALANCE=$MIN_BALANCE"
echo "================================================"
echo ""

# 询问是否直接写入.env文件
read -p "是否直接写入到 .env 文件？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 备份现有的.env文件（如果存在）
    if [ -f ".env" ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        echo "📋 已备份现有 .env 文件"
    fi
    
    # 写入新的环境变量
    cat > .env << EOF
# Web3Auth 环境变量配置
# 自动生成于: $(date)

# 加密盐值 (32字节十六进制)
SALT=$SALT

# 加密密钥 (32字节十六进制)
KEY=$KEY

# 初始化向量 (16字节十六进制)
IV=$IV

# Solana集群配置
CLUSTER=$CLUSTER

# 服务端口
PORT=$PORT

# 最小余额要求
MIN_BALANCE=$MIN_BALANCE

# 可选：允许的来源域名 (用逗号分隔)
# ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
EOF
    
    echo "✅ 环境变量已写入 .env 文件"
    echo "🔒 请确保 .env 文件不要提交到版本控制系统"
else
    echo "📝 请手动将上述环境变量复制到您的 .env 文件中"
fi

echo ""
echo "🛡️  安全提示："
echo "- 这些密钥用于加密用户数据，请妥善保管"
echo "- 不要将 .env 文件提交到 Git 仓库"
echo "- 在生产环境中使用更强的随机源"
echo "- 定期轮换这些密钥以提高安全性"
echo ""
echo "🚀 现在您可以启动Web3Auth服务了！"