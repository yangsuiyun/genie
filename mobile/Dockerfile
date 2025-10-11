# 🍅 Pomodoro Genie Frontend Dockerfile
# 多阶段构建，优化镜像大小

# 构建阶段
FROM node:18-alpine AS build

# 设置工作目录
WORKDIR /app

# 安装Flutter
RUN apk add --no-cache curl unzip && \
    curl -o flutter.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz && \
    unzip flutter.zip && \
    mv flutter /opt/flutter && \
    rm flutter.zip

# 设置Flutter环境变量
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 复制项目文件
COPY mobile/ .

# 获取依赖
RUN flutter pub get

# 构建Web应用
RUN flutter build web --release --web-renderer html

# 运行阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=build /app/build/web /usr/share/nginx/html

# 复制nginx配置
COPY docker/nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
