#!/bin/bash

echo "🍅 测试Pomodoro Genie API集成"
echo "================================"
echo

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试后端健康状态
echo -e "${BLUE}1. 测试后端健康状态...${NC}"
HEALTH=$(curl -s http://localhost:8081/health)
if [[ $HEALTH == *"healthy"* ]]; then
    echo -e "${GREEN}✓ 后端服务正常${NC}"
    echo "  响应: $HEALTH"
else
    echo -e "${RED}✗ 后端服务异常${NC}"
    exit 1
fi
echo

# 测试创建项目
echo -e "${BLUE}2. 测试创建项目...${NC}"
PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8081/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试项目-'$(date +%s)'",
    "icon": "📁",
    "color": "#6c757d"
  }')

if [[ $PROJECT_RESPONSE == *"id"* ]]; then
    echo -e "${GREEN}✓ 项目创建成功${NC}"
    PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "  项目ID: $PROJECT_ID"
else
    echo -e "${RED}✗ 项目创建失败${NC}"
    echo "  响应: $PROJECT_RESPONSE"
fi
echo

# 测试获取项目列表
echo -e "${BLUE}3. 测试获取项目列表...${NC}"
PROJECTS=$(curl -s http://localhost:8081/api/projects)
if [[ $PROJECTS == "["* ]]; then
    echo -e "${GREEN}✓ 获取项目列表成功${NC}"
    PROJECT_COUNT=$(echo $PROJECTS | grep -o '"id"' | wc -l)
    echo "  项目数量: $PROJECT_COUNT"
else
    echo -e "${RED}✗ 获取项目列表失败${NC}"
fi
echo

# 测试创建任务
echo -e "${BLUE}4. 测试创建任务...${NC}"
TASK_RESPONSE=$(curl -s -X POST http://localhost:8081/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "测试任务-'$(date +%s)'",
    "description": "这是一个测试任务",
    "project_id": "inbox",
    "priority": "medium",
    "planned_pomodoros": 4
  }')

if [[ $TASK_RESPONSE == *"id"* ]]; then
    echo -e "${GREEN}✓ 任务创建成功${NC}"
    TASK_ID=$(echo $TASK_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "  任务ID: $TASK_ID"
else
    echo -e "${RED}✗ 任务创建失败${NC}"
    echo "  响应: $TASK_RESPONSE"
fi
echo

# 测试获取任务列表
echo -e "${BLUE}5. 测试获取任务列表...${NC}"
TASKS=$(curl -s http://localhost:8081/api/tasks)
if [[ $TASKS == "["* ]]; then
    echo -e "${GREEN}✓ 获取任务列表成功${NC}"
    TASK_COUNT=$(echo $TASKS | grep -o '"id"' | wc -l)
    echo "  任务数量: $TASK_COUNT"
else
    echo -e "${RED}✗ 获取任务列表失败${NC}"
fi
echo

# 测试更新任务
if [ ! -z "$TASK_ID" ]; then
    echo -e "${BLUE}6. 测试更新任务...${NC}"
    UPDATE_RESPONSE=$(curl -s -X PUT http://localhost:8081/api/tasks/$TASK_ID \
      -H "Content-Type: application/json" \
      -d '{
        "title": "更新后的测试任务",
        "description": "已更新",
        "is_completed": true
      }')
    
    if [[ $UPDATE_RESPONSE == *"id"* ]]; then
        echo -e "${GREEN}✓ 任务更新成功${NC}"
    else
        echo -e "${RED}✗ 任务更新失败${NC}"
    fi
    echo
fi

echo "================================"
echo -e "${GREEN}✅ API集成测试完成！${NC}"
echo
echo "📱 现在可以启动Flutter应用测试完整流程："
echo "   cd mobile && flutter run"
echo
echo "🔍 查看后端日志："
echo "   docker logs -f pomodoro-backend"
echo

