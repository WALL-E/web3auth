# 钱包签名

```
// 使用浏览器钱包 Phantom 签名消息
const script = document.createElement('script');
script.src = 'https://cdn.jsdelivr.net/npm/base-58@0.0.1/Base58.min.js';
script.onload = async () => {
    console.log('bs58 库已加载！');

    // 检查 Phantom 钱包是否存在
    if (!window.solana) {
        console.error('请安装 Phantom 钱包！');
        return;
    }

    try {
        // 连接 Phantom 钱包
        await window.solana.connect();
        console.log('已连接钱包：', window.solana.publicKey.toString());

        // 签名消息
        const message = `ad139b17cdc842d5`;
        const encodedMessage = new TextEncoder().encode(message);
        const signedMessage = await window.solana.signMessage(encodedMessage, "utf8");

        // 使用 bs58 将签名转换为 Base58 字符串
        const signatureBase58 = Base58.encode(signedMessage.signature);
        console.log('Signed Message (Base58):', signatureBase58);
    } catch (error) {
        console.error('Error signing message:', error);
    }
};
document.head.appendChild(script);
```
