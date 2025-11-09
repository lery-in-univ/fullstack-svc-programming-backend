export class LspUriTransformer {
  /**
   * Transforms client URIs (file:///workspace/...) to container URIs (file:///lsp-files/{sessionId}/...)
   * Parses LSP protocol messages (Content-Length header + JSON-RPC body)
   */
  static transformMessage(messageStr: string, workspaceRoot: string): string {
    try {
      // Parse LSP protocol message (Content-Length header format)
      const separatorIndex = messageStr.indexOf('\r\n\r\n');
      if (separatorIndex === -1) {
        return messageStr;
      }

      const header = messageStr.substring(0, separatorIndex + 4);
      const contentPart = messageStr.substring(separatorIndex + 4);

      if (!contentPart) {
        return messageStr;
      }

      const json = JSON.parse(contentPart);

      // Transform URIs in the JSON-RPC message
      const transformed = this.transformUris(json, workspaceRoot);

      // Rebuild LSP message with new Content-Length
      const newContent = JSON.stringify(transformed);
      return `Content-Length: ${newContent.length}\r\n\r\n${newContent}`;
    } catch (error) {
      // If parsing fails, return original message
      return messageStr;
    }
  }

  /**
   * Recursively transforms URIs in LSP message object
   */
  private static transformUris(obj: any, workspaceRoot: string): any {
    if (obj === null || obj === undefined) {
      return obj;
    }

    if (typeof obj === 'string') {
      // Transform file:///workspace/* to file://{workspaceRoot}/*
      if (obj.startsWith('file:///workspace/')) {
        return obj.replace('file:///workspace/', `file://${workspaceRoot}/`);
      } else if (obj === 'file:///workspace') {
        return `file://${workspaceRoot}`;
      }
      return obj;
    }

    if (Array.isArray(obj)) {
      return obj.map((item) => this.transformUris(item, workspaceRoot));
    }

    if (typeof obj === 'object') {
      const transformed: any = {};
      for (const [key, value] of Object.entries(obj)) {
        transformed[key] = this.transformUris(value, workspaceRoot);
      }
      return transformed;
    }

    return obj;
  }

  /**
   * Transforms container URIs back to client URIs (for responses)
   */
  static transformResponseMessage(
    messageStr: string,
    workspaceRoot: string,
  ): string {
    try {
      const separatorIndex = messageStr.indexOf('\r\n\r\n');
      if (separatorIndex === -1) {
        return messageStr;
      }

      const header = messageStr.substring(0, separatorIndex + 4);
      const contentPart = messageStr.substring(separatorIndex + 4);

      if (!contentPart) {
        return messageStr;
      }

      const json = JSON.parse(contentPart);

      // Transform URIs back to client format
      const transformed = this.transformResponseUris(json, workspaceRoot);

      const newContent = JSON.stringify(transformed);
      return `Content-Length: ${newContent.length}\r\n\r\n${newContent}`;
    } catch (error) {
      return messageStr;
    }
  }

  private static transformResponseUris(obj: any, workspaceRoot: string): any {
    if (obj === null || obj === undefined) {
      return obj;
    }

    if (typeof obj === 'string') {
      // Transform file://{workspaceRoot}/* back to file:///workspace/*
      if (obj.startsWith(`file://${workspaceRoot}/`)) {
        return obj.replace(`file://${workspaceRoot}/`, 'file:///workspace/');
      } else if (obj === `file://${workspaceRoot}`) {
        return 'file:///workspace';
      }
      return obj;
    }

    if (Array.isArray(obj)) {
      return obj.map((item) => this.transformResponseUris(item, workspaceRoot));
    }

    if (typeof obj === 'object') {
      const transformed: any = {};
      for (const [key, value] of Object.entries(obj)) {
        transformed[key] = this.transformResponseUris(value, workspaceRoot);
      }
      return transformed;
    }

    return obj;
  }
}
