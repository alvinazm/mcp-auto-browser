# 卸载mcp-chrome-bridge
- npm uninstall -g mcp-chrome-bridge
- rm -rf /Users/azm/Library/pnpm/global/5/.pnpm/mcp-chrome-bridge@1.0.31_zod@3.25.76
- stdio 服务器：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js`
- 配置文件：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json`

# 扩展ID
- hbdgbgagpkpjffpklnamcljpakneikee
- ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.chromemcp.nativehost.json

# 常见问题
- 如果chrome扩展连接不上，就是扩展ID不匹配
- 如果脚本失效，就是12306被Kill了，但chrome没有自动重试连接，需要手动打开扩展连接