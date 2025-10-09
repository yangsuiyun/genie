# 🚀 GitHub Actions 部署指南

## 📋 启用步骤

### 1. 推送代码到GitHub
```bash
# 如果使用HTTPS
git remote set-url origin https://github.com/yangsuiyun/genie.git
git push origin master

# 或者使用SSH（需要配置SSH密钥）
git push origin master
```

### 2. 启用GitHub Pages
1. 访问仓库设置：https://github.com/yangsuiyun/genie/settings
2. 滚动到 "Pages" 部分
3. 在 "Source" 下选择 "GitHub Actions"
4. 保存设置

### 3. 配置GitHub Actions
- GitHub Actions配置文件已创建：
  - `.github/workflows/flutter-web.yml` - 完整的CI/CD流程
  - `.github/workflows/deploy.yml` - 简化的部署流程

### 4. 手动触发部署
1. 访问仓库的 "Actions" 标签页
2. 选择 "Deploy Flutter Web App" 工作流
3. 点击 "Run workflow" 按钮
4. 选择分支并运行

## 🎯 工作流说明

### flutter-web.yml
- **测试阶段**: 代码分析、单元测试、构建测试
- **部署阶段**: 生产构建、GitHub Pages部署
- **触发条件**: 推送到master/main分支

### deploy.yml
- **简化流程**: 直接构建和部署
- **触发条件**: 推送到master分支或手动触发

## 📱 部署结果

部署成功后，应用将在以下地址可用：
- **GitHub Pages**: https://yangsuiyun.github.io/genie/
- **自定义域名**: https://pomodoro-genie.yangsuiyun.com/ (如果配置了CNAME)

## 🔧 故障排除

### 常见问题
1. **权限错误**: 确保GitHub Token有足够权限
2. **构建失败**: 检查Flutter版本和依赖
3. **部署失败**: 确认GitHub Pages已启用

### 调试步骤
1. 查看Actions日志
2. 检查构建输出
3. 验证文件路径
4. 测试本地构建

## 📊 项目状态

- **完成度**: 95%
- **Flutter Web**: ✅ 完成
- **GitHub Actions**: ✅ 配置完成
- **部署**: ⏳ 等待推送触发

## 🎉 功能特性

- ✅ 统一交互模式
- ✅ 响应式设计
- ✅ 沉浸式专注模式
- ✅ 白噪音系统
- ✅ 数据可视化
- ✅ 个性化设置
- ✅ 流畅动画

---

**配置完成时间**: 2025-10-09  
**下次更新**: 部署成功后  
**联系方式**: 项目维护团队
