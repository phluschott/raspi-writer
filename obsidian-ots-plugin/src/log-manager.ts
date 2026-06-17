import { App, TFile, normalizePath } from 'obsidian';
import type { ProofEntry } from './types';

export class LogManager {
  private app: App;
  private folder: string;

  constructor(app: App, folder: string) {
    this.app = app;
    this.folder = folder;
  }

  private logPath(): string {
    return normalizePath(`${this.folder}/README.md`);
  }

  async updateLog(entries: ProofEntry[]): Promise<void> {
    const content = this.buildLog(entries);
    const path = this.logPath();
    const existing = this.app.vault.getAbstractFileByPath(path);
    if (existing instanceof TFile) {
      await this.app.vault.modify(existing, content);
    } else {
      await this.app.vault.create(path, content);
    }
  }

  async openLog(): Promise<void> {
    const path = this.logPath();
    const file = this.app.vault.getAbstractFileByPath(path);
    if (file instanceof TFile) {
      await this.app.workspace.getLeaf(false).openFile(file);
    }
  }

  private buildLog(entries: ProofEntry[]): string {
    const lines: string[] = [
      '# OpenTimestamps IP Proof Log',
      '',
      '> Timestamps are anchored to the Bitcoin blockchain via [OpenTimestamps](https://opentimestamps.org). Each `.ots` file in `proofs/` is your cryptographic proof of existence.',
      '',
      '## How to verify',
      '',
      '1. Install the [OTS CLI](https://github.com/opentimestamps/opentimestamps-client) or use the [web verifier](https://opentimestamps.org)',
      '2. Run: `ots upgrade <file>.ots` (once per month until confirmed on Bitcoin)',
      '3. Run: `ots verify <file>.ots` with the original file',
      '',
      `*Last updated: ${new Date().toISOString()}*`,
      '',
      '---',
      '',
      '| File | SHA-256 | Submitted | Status | Calendars |',
      '|------|---------|-----------|--------|-----------|',
    ];

    for (const e of entries) {
      const shortHash = `\`${e.hash.slice(0, 12)}…\``;
      const date = e.submittedAt.slice(0, 10);
      const status = statusIcon(e.status);
      const cals = e.calendars.map(c => calendarShortName(c.url)).join(', ');
      lines.push(`| [[${e.path}\\|${e.file}]] | ${shortHash} | ${date} | ${status} | ${cals} |`);
    }

    if (entries.length === 0) {
      lines.push('| *(none yet)* | | | | |');
    }

    return lines.join('\n') + '\n';
  }
}

function statusIcon(status: ProofEntry['status']): string {
  switch (status) {
    case 'pending':   return '⏳ Pending';
    case 'confirmed': return '✅ Confirmed';
    case 'failed':    return '❌ Failed';
  }
}

function calendarShortName(url: string): string {
  try {
    return new URL(url).hostname.split('.')[0];
  } catch {
    return url;
  }
}
