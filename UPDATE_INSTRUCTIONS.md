# 在线表格编辑器 - 服务器更新指南

## 已部署服务器更新步骤

如果您已经通过 `deploy.sh` 脚本在 Ubuntu 服务器上部署了应用，请按照以下步骤更新到最新版本（包含删除行/列功能）。

### 方法一：使用更新脚本（推荐）

1. 将本地的 `update.sh` 脚本上传到服务器：
   ```bash
   scp update.sh user@your-server:/tmp/update.sh
   ```

2. 登录到服务器并执行：
   ```bash
   ssh user@your-server
   sudo bash /tmp/update.sh
   ```

3. 脚本将自动：
   - 备份现有数据
   - 从 GitHub 仓库拉取最新代码
   - 安装依赖
   - 重启服务

### 方法二：手动更新步骤

1. **登录到服务器**
   ```bash
   ssh user@your-server
   ```

2. **切换到应用目录**
   ```bash
   cd /opt/online-table-editor
   ```

3. **备份当前数据（可选但推荐）**
   ```bash
   cp data.json data.json.backup.$(date +%Y%m%d_%H%M%S)
   ```

4. **拉取最新代码**
   - 如果目录是 git 仓库：
     ```bash
     git fetch origin
     git checkout main
     git pull origin main
     ```
   - 如果不是 git 仓库，可以重新克隆：
     ```bash
     cd /tmp
     git clone https://github.com/BeiChenYi/webbapi.git
     rsync -av --exclude='data.json' webbapi/ /opt/online-table-editor/
     rm -rf webbapi
     ```

5. **安装依赖**
   ```bash
   sudo -u table-editor npm install --production
   ```

6. **重启服务**
   ```bash
   sudo systemctl restart online-table-editor
   ```

7. **验证服务状态**
   ```bash
   sudo systemctl status online-table-editor
   ```

8. **检查更新是否成功**
   - 访问 `http://your-server-ip:32577`
   - 确认工具栏出现“删除行”和“删除列”按钮
   - 测试删除功能是否正常

### 更新后验证

1. 打开浏览器访问应用
2. 点击“删除行”按钮应删除最后一行（至少保留一行）
3. 点击“删除列”按钮应删除最后一列（至少保留一列）
4. 数据应自动保存，且 API 端点 `/api/data` 返回正确数据

### 故障排除

- **服务启动失败**：检查日志 `journalctl -u online-table-editor -f`
- **权限问题**：确保 `/opt/online-table-editor` 属于 `table-editor` 用户
- **端口占用**：确认端口 32577 未被其他进程占用

### 回滚步骤

如果更新后出现问题，可以恢复备份的数据并重启服务：

```bash
cd /opt/online-table-editor
cp data.json.backup.* data.json
sudo systemctl restart online-table-editor
```

---

**注意**：更新过程中不会丢失现有表格数据，因为 `data.json` 文件会被保留（除非您手动覆盖）。建议在更新前备份数据。

如需更多帮助，请参考 `deploy.sh` 和 `UBUNTU_DEPLOYMENT.md` 文件。
