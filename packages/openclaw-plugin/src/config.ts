export interface NewsmcpConfig {
  apiBaseUrl: string;
}

export interface PluginApi {
  pluginConfig?: Record<string, unknown>;
  logger: {
    info: (msg: string) => void;
    warn: (msg: string) => void;
    error: (msg: string) => void;
  };
  registerTool: (tool: ToolDefinition) => void;
}

export interface ToolDefinition {
  name: string;
  description: string;
  parameters: {
    type: "object";
    properties: Record<string, unknown>;
    required?: string[];
  };
  execute: (
    id: string,
    params: Record<string, unknown>,
  ) => Promise<{
    content: Array<{ type: string; text: string }>;
    isError?: boolean;
  }>;
}

export function resolveConfig(api: PluginApi): NewsmcpConfig {
  const raw = (api.pluginConfig ?? {}) as Record<string, unknown>;
  return {
    apiBaseUrl: String(raw.apiBaseUrl ?? "https://newsmcp.io/v1").replace(
      /\/$/,
      "",
    ),
  };
}
