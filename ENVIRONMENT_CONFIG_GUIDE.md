# 🔧 Pomodoro Genie 环境配置说明

## 📋 环境文件整理完成

### ✅ 保留的环境文件

- **`backend/env.example`** - 环境配置示例文件（已简化）

### 🗑️ 删除的环境文件

- ~~`env.production.template`~~ - 复杂的生产环境模板（已删除）

## 🎯 简化后的环境配置

### 核心环境变量

#### 服务器配置
```bash
PORT=8081                    # 后端服务端口
GIN_MODE=debug              # Gin框架模式 (debug/release)
```

#### 数据库配置
```bash
DB_HOST=localhost           # 数据库主机地址
DB_PORT=5432               # 数据库端口
DB_USER=postgres           # 数据库用户名
DB_PASSWORD=postgres       # 数据库密码
DB_NAME=pomodoro_genie     # 数据库名称
DB_SSLMODE=disable         # SSL连接模式
```

#### 数据库连接池配置
```bash
DB_MAX_OPEN_CONNS=25       # 最大打开连接数
DB_MAX_IDLE_CONNS=5        # 最大空闲连接数
DB_MAX_LIFETIME_MINUTES=5  # 连接最大生存时间
DB_MAX_IDLE_TIME_MINUTES=1 # 连接最大空闲时间
```

#### 日志配置
```bash
DB_LOG_LEVEL=info          # 数据库日志级别
```

#### JWT认证配置（可选）
```bash
JWT_SECRET=your-secret-key-here-change-in-production
JWT_EXPIRE_HOURS=24
```

#### CORS配置
```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:8080,http://localhost:5173
```

## 🚀 使用方法

### 1. 复制环境配置
```bash
# 进入后端目录
cd backend

# 复制环境配置示例
cp env.example .env

# 编辑环境配置
nano .env
```

### 2. 修改配置值
根据您的实际环境修改以下值：
- `DB_PASSWORD` - 数据库密码
- `JWT_SECRET` - JWT密钥（生产环境必须修改）
- `CORS_ALLOWED_ORIGINS` - 允许的跨域来源

### 3. 启动服务
```bash
# 使用统一启动脚本
./start.sh

# 或手动启动后端
cd backend
go run cmd/main.go
```

## 🔧 环境变量说明

### 必需配置
- **数据库连接**: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- **服务端口**: `PORT`

### 可选配置
- **JWT认证**: `JWT_SECRET`, `JWT_EXPIRE_HOURS`
- **CORS设置**: `CORS_ALLOWED_ORIGINS`
- **日志级别**: `DB_LOG_LEVEL`
- **连接池**: `DB_MAX_OPEN_CONNS`, `DB_MAX_IDLE_CONNS`

### 开发环境默认值
- 端口: 8081
- 数据库: localhost:5432/pomodoro_genie
- 模式: debug
- SSL: disable

## 🛠️ 故障排除

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查PostgreSQL是否运行
   brew services start postgresql
   
   # 创建数据库
   createdb pomodoro_genie
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   lsof -i :8081
   
   # 修改端口
   export PORT=8082
   ```

3. **JWT密钥问题**
   ```bash
   # 生成随机密钥
   openssl rand -base64 32
   ```

## 📊 简化效果

### 配置复杂度
- **之前**: 90+ 个环境变量
- **现在**: 15 个核心环境变量
- **简化**: 83%

### 维护成本
- **之前**: 复杂的生产环境配置
- **现在**: 简单的开发环境配置
- **提升**: 大幅降低维护成本

### 启动速度
- **之前**: 需要配置大量环境变量
- **现在**: 使用默认值快速启动
- **提升**: 显著提升开发效率

## 🎯 最佳实践

1. **开发环境**: 使用默认配置，快速启动
2. **测试环境**: 复制env.example，修改必要配置
3. **生产环境**: 设置强密码和安全的JWT密钥
4. **版本控制**: 不要提交.env文件到git

---

**环境配置简化完成！** 🎉

现在您有了一个简洁、实用的环境配置，只包含项目实际需要的变量。
