import { requestUrl } from 'obsidian';
import type { CalendarEntry } from './types';

// OTS file magic header + version byte (32 bytes total)
const OTS_MAGIC = new Uint8Array([
  0x00, 0x4f, 0x70, 0x65, 0x6e, 0x54, 0x69, 0x6d, 0x65, 0x73, 0x74,
  0x61, 0x6d, 0x70, 0x73, 0x00, 0x00, 0x50, 0x72, 0x6f, 0x6f, 0x66,
  0x00, 0xbf, 0x89, 0xe2, 0xe8, 0x84, 0xe8, 0x92, 0x94,
  0x01, // version
]);

export class OtsClient {
  async hashFile(buffer: ArrayBuffer): Promise<Uint8Array> {
    const digest = await crypto.subtle.digest('SHA-256', buffer);
    return new Uint8Array(digest);
  }

  toHex(bytes: Uint8Array): string {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  async submitToCalendars(
    hash: Uint8Array,
    servers: string[]
  ): Promise<CalendarEntry[]> {
    const results = await Promise.allSettled(
      servers.map(url => this.submitToCalendar(hash, url))
    );

    const entries: CalendarEntry[] = [];
    for (const result of results) {
      if (result.status === 'fulfilled' && result.value) {
        entries.push(result.value);
      }
    }
    return entries;
  }

  private async submitToCalendar(
    hash: Uint8Array,
    server: string
  ): Promise<CalendarEntry> {
    const response = await requestUrl({
      url: `${server}/digest`,
      method: 'POST',
      body: hash.buffer as ArrayBuffer,
      throw: false,
    });

    if (response.status !== 200) {
      throw new Error(`${server} returned ${response.status}`);
    }

    const receiptBytes = new Uint8Array(response.arrayBuffer);
    const receiptBase64 = btoa(String.fromCharCode(...receiptBytes));
    return { url: server, receiptBase64 };
  }

  assembleOtsFile(hash: Uint8Array, receipts: CalendarEntry[]): Uint8Array {
    // OTS file = MAGIC || OP_SHA256 (0x08) || hash || timestamp_tree
    // Timestamp tree for N calendars uses fork markers (0xff) before each non-final branch
    const hashSection = concat(new Uint8Array([0x08]), hash);

    const treeParts: Uint8Array[] = [];
    for (let i = 0; i < receipts.length; i++) {
      if (i < receipts.length - 1) {
        treeParts.push(new Uint8Array([0xff]));
      }
      treeParts.push(base64ToBytes(receipts[i].receiptBase64));
    }

    return concat(OTS_MAGIC, hashSection, ...treeParts);
  }

  async timestamp(
    buffer: ArrayBuffer,
    servers: string[]
  ): Promise<{ hash: string; calendars: CalendarEntry[]; otsBytes: Uint8Array | null }> {
    const hash = await this.hashFile(buffer);
    const calendars = await this.submitToCalendars(hash, servers);

    if (calendars.length === 0) {
      throw new Error('All OpenTimestamps calendar servers failed to respond. Check your internet connection.');
    }

    const otsBytes = this.assembleOtsFile(hash, calendars);
    return { hash: this.toHex(hash), calendars, otsBytes };
  }
}

function concat(...arrays: Uint8Array[]): Uint8Array {
  const total = arrays.reduce((n, a) => n + a.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const a of arrays) {
    out.set(a, offset);
    offset += a.length;
  }
  return out;
}

function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
