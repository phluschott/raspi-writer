import { App, TFile, normalizePath } from 'obsidian';
import type { ProofEntry } from './types';

const DATA_FILE = 'timestamps.json';

export class ProofStore {
  private app: App;
  private folder: string;

  constructor(app: App, folder: string) {
    this.app = app;
    this.folder = folder;
  }

  private dataPath(): string {
    return normalizePath(`${this.folder}/${DATA_FILE}`);
  }

  otsPath(filePath: string): string {
    const safe = filePath.replace(/[/\\]/g, '__').replace(/\s+/g, '_');
    return normalizePath(`${this.folder}/proofs/${safe}.ots`);
  }

  async ensureFolder(): Promise<void> {
    const proofsFolder = normalizePath(`${this.folder}/proofs`);
    if (!this.app.vault.getAbstractFileByPath(normalizePath(this.folder))) {
      await this.app.vault.createFolder(normalizePath(this.folder));
    }
    if (!this.app.vault.getAbstractFileByPath(proofsFolder)) {
      await this.app.vault.createFolder(proofsFolder);
    }
  }

  async load(): Promise<ProofEntry[]> {
    const file = this.app.vault.getAbstractFileByPath(this.dataPath());
    if (!(file instanceof TFile)) return [];
    try {
      const raw = await this.app.vault.read(file);
      return JSON.parse(raw) as ProofEntry[];
    } catch {
      return [];
    }
  }

  async save(entries: ProofEntry[]): Promise<void> {
    await this.ensureFolder();
    const path = this.dataPath();
    const content = JSON.stringify(entries, null, 2);
    const existing = this.app.vault.getAbstractFileByPath(path);
    if (existing instanceof TFile) {
      await this.app.vault.modify(existing, content);
    } else {
      await this.app.vault.create(path, content);
    }
  }

  async add(entry: ProofEntry): Promise<void> {
    const entries = await this.load();
    const idx = entries.findIndex(e => e.path === entry.path);
    if (idx >= 0) {
      entries[idx] = entry;
    } else {
      entries.unshift(entry);
    }
    await this.save(entries);
  }

  async getByPath(filePath: string): Promise<ProofEntry | undefined> {
    const entries = await this.load();
    return entries.find(e => e.path === filePath);
  }

  async saveOtsFile(filePath: string, bytes: Uint8Array): Promise<void> {
    await this.ensureFolder();
    const otsPath = this.otsPath(filePath);
    const existing = this.app.vault.getAbstractFileByPath(otsPath);
    if (existing instanceof TFile) {
      await this.app.vault.modifyBinary(existing, bytes.buffer as ArrayBuffer);
    } else {
      await this.app.vault.createBinary(otsPath, bytes.buffer as ArrayBuffer);
    }
  }
}
