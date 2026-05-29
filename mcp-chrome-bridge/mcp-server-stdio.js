#!/usr/bin/env node
"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupTools = exports.ensureMcpClient = exports.getStdioMcpServer = void 0;
const index_js_1 = require("@modelcontextprotocol/sdk/server/index.js");
const index_js_2 = require("@modelcontextprotocol/sdk/client/index.js");
const types_js_1 = require("@modelcontextprotocol/sdk/types.js");
const chrome_mcp_shared_1 = require("chrome-mcp-shared");
const stdio_js_1 = require("@modelcontextprotocol/sdk/server/stdio.js");
const streamableHttp_js_1 = require("@modelcontextprotocol/sdk/client/streamableHttp.js");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let stdioMcpServer = null;
let mcpClient = null;
let mcpClientConnecting = false;
// Read configuration from stdio-config.json
const loadConfig = () => {
    try {
        const configPath = path.join(__dirname, 'stdio-config.json');
        const configData = fs.readFileSync(configPath, 'utf8');
        return JSON.parse(configData);
    }
    catch (error) {
        console.error('Failed to load stdio-config.json:', error);
        throw new Error('Configuration file stdio-config.json not found or invalid');
    }
};
const getStdioMcpServer = () => {
    if (stdioMcpServer) {
        return stdioMcpServer;
    }
    stdioMcpServer = new index_js_1.Server({
        name: 'StdioChromeMcpServer',
        version: '1.0.0',
    }, {
        capabilities: {
            tools: {},
            resources: {},
            prompts: {},
        },
    });
    (0, exports.setupTools)(stdioMcpServer);
    return stdioMcpServer;
};
exports.getStdioMcpServer = getStdioMcpServer;
const ensureMcpClient = async () => {
    try {
        // 如果正在连接中，等待连接完成
        if (mcpClientConnecting) {
            // 等待一小段时间后重试
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        // 如果已有有效连接，关闭旧连接后创建新的
        if (mcpClient) {
            try { await mcpClient.close(); } catch (e) {}
            mcpClient = null;
            // 等待连接完全关闭
            await new Promise(resolve => setTimeout(resolve, 500));
        }

        // 设置连接中标志
        mcpClientConnecting = true;

        try {
            const config = loadConfig();
            // 每次都创建新的 Client 实例，避免 Protocol 内部状态问题
            mcpClient = new index_js_2.Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
            const transport = new streamableHttp_js_1.StreamableHTTPClientTransport(new URL(config.url), { healthCheckTimeoutMs: 5000 });
            await mcpClient.connect(transport);
            return mcpClient;
        } finally {
            mcpClientConnecting = false;
        }
    }
    catch (error) {
        mcpClient = null;
        console.error('Failed to connect to MCP server:', error);
        throw error; // 重新抛出错误，让调用者知道连接失败
    }
};
exports.ensureMcpClient = ensureMcpClient;
const setupTools = (server) => {
    // List tools handler
    server.setRequestHandler(types_js_1.ListToolsRequestSchema, async () => ({ tools: chrome_mcp_shared_1.TOOL_SCHEMAS }));
    // Call tool handler
    server.setRequestHandler(types_js_1.CallToolRequestSchema, async (request) => handleToolCall(request.params.name, request.params.arguments || {}));
    // List resources handler - REQUIRED BY MCP PROTOCOL
    server.setRequestHandler(types_js_1.ListResourcesRequestSchema, async () => ({ resources: [] }));
    // List prompts handler - REQUIRED BY MCP PROTOCOL
    server.setRequestHandler(types_js_1.ListPromptsRequestSchema, async () => ({ prompts: [] }));
};
exports.setupTools = setupTools;
const handleToolCall = async (name, args) => {
    let client = null;
    let transport = null;
    try {
        const config = loadConfig();
        // 每次都创建新的 Client 实例，完全独立的连接
        client = new index_js_2.Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
        transport = new streamableHttp_js_1.StreamableHTTPClientTransport(new URL(config.url), { healthCheckTimeoutMs: 5000 });
        await client.connect(transport);

        const DEFAULT_CALL_TIMEOUT_MS = 2 * 60 * 1000;
        const result = await client.callTool({ name, arguments: args }, undefined, {
            timeout: DEFAULT_CALL_TIMEOUT_MS,
        });
        return result;
    }
    catch (error) {
        const errorMsg = typeof error === 'string' ? error : (error.message || '');
        return {
            content: [
                {
                    type: 'text',
                    text: `Error calling tool: ${errorMsg || error}`,
                },
            ],
            isError: true,
        };
    }
    finally {
        if (client) {
            try {
                // 先尝试 terminateSession (HTTP 专用)
                if (transport && typeof transport.terminateSession === 'function') {
                    await transport.terminateSession();
                }
                await client.close();
            } catch (e) {}
        }
    }
};
async function main() {
    const transport = new stdio_js_1.StdioServerTransport();
    await (0, exports.getStdioMcpServer)().connect(transport);
}
main().catch((error) => {
    console.error('Fatal error Chrome MCP Server main():', error);
    process.exit(1);
});
//# sourceMappingURL=mcp-server-stdio.js.map