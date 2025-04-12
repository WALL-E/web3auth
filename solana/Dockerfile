# 使用 Node.js 官方镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 将 package.json 和 package-lock.json 复制到工作目录
COPY package.json ./
COPY ./app.js ./
COPY ./.env ./

# 安装依赖
RUN npm install

# 启动 Express 应用的命令
CMD [ "node", "app.js" ]
