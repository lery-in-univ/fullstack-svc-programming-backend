import { EventEmitter } from 'events';

export class LspResponseBuffer extends EventEmitter {
  private buffer: Buffer = Buffer.alloc(0);

  onData(chunk: Buffer) {
    this.buffer = Buffer.concat([this.buffer, chunk]);

    while (true) {
      const headerEnd = this.buffer.indexOf('\r\n\r\n');
      if (headerEnd === -1) break; // 헤더가 아직 다 안 온 상태

      const headerPart = this.buffer.slice(0, headerEnd).toString('utf8');
      const headerLines = headerPart.split('\r\n');

      let contentLength: number | null = null;
      for (const line of headerLines) {
        const m = /^Content-Length:\s*(\d+)\s*$/i.exec(line);
        if (m) {
          contentLength = parseInt(m[1], 10);
          break;
        }
      }

      if (contentLength == null) {
        throw new Error('Content-Length header not found');
      }

      const bodyStart = headerEnd + 4; // "\r\n\r\n" 길이
      const frameLength = bodyStart + contentLength;

      if (this.buffer.length < frameLength) break;

      const raw = this.buffer.slice(0, frameLength);
      this.buffer = this.buffer.slice(frameLength);

      this.emit('message', raw);
    }
  }
}
