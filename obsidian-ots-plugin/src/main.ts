import { Menu, Notice, Plugin, TAbstractFile, TFile, normalizePath } from 'obsidian';
import { OtsClient } from './ots-client';
import { ProofStore } from './proof-store';
import { LogManager } from './log-manager';
import { BulkModal } from './bulk-modal';
import { OtsSettingTab } from './settings-tab';
import { DEFAULT_SETTINGS, OtsPluginSettings, ProofEntry } from './types';

export default class OtsPlugin extends Plugin {
  settings: OtsPluginSettings;
  otsClient: OtsClient;
  proofStore: ProofStore;
  logManager: LogManager;

  async onload(): Promise<void> {
    await this.loadSettings();

    this.otsClient = new OtsClient();
    this.proofStore = new ProofStore(this.app, this.settings.otsFolder);
    this.logManager = new LogManager(this.app, this.settings.otsFolder);

    // Auto-timestamp new files
    this.registerEvent(
      this.app.vault.on('create', (file: TAbstractFile) => {
        if (!this.settings.autoTimestamp) return;
        if (!(file instanceof TFile)) return;
        if (!this.settings.autoTimestampExtensions.includes(file.extension)) return;
        if (file.path.startsWith(normalizePath(this.settings.otsFolder) + '/')) return;
        // Delay to ensure the file is fully written before reading
        setTimeout(() => this.timestampFile(file), 3000);
      })
    );

    // File explorer right-click menu
    this.registerEvent(
      this.app.workspace.on('file-menu', (menu: Menu, file: TAbstractFile) => {
        if (!(file instanceof TFile)) return;
        if (file.path.startsWith(normalizePath(this.settings.otsFolder) + '/')) return;
        menu.addItem(item =>
          item
            .setTitle('Get Timestamp (OTS)')
            .setIcon('clock')
            .setSection('action')
            .onClick(() => this.timestampFile(file))
        );
      })
    );

    // Editor right-click menu
    this.registerEvent(
      this.app.workspace.on('editor-menu', (menu: Menu) => {
        const file = this.app.workspace.getActiveFile();
        if (!file) return;
        menu.addItem(item =>
          item
            .setTitle('Get Timestamp (OTS)')
            .setIcon('clock')
            .setSection('action')
            .onClick(() => this.timestampFile(file))
        );
      })
    );

    this.addCommand({
      id: 'timestamp-current-file',
      name: 'Timestamp current file',
      checkCallback: (checking: boolean) => {
        const file = this.app.workspace.getActiveFile();
        if (!file) return false;
        if (!checking) this.timestampFile(file);
        return true;
      },
    });

    this.addCommand({
      id: 'bulk-timestamp',
      name: 'Bulk timestamp files',
      callback: () => new BulkModal(this.app, this).open(),
    });

    this.addCommand({
      id: 'open-timestamp-log',
      name: 'Open timestamp log',
      callback: () => this.logManager.openLog(),
    });

    this.addSettingTab(new OtsSettingTab(this.app, this));
  }

  async timestampFile(file: TFile): Promise<void> {
    const notice = new Notice(`⏳ Timestamping ${file.name}…`, 0);
    try {
      const buffer = await this.app.vault.readBinary(file);
      const { hash, calendars, otsBytes } = await this.otsClient.timestamp(
        buffer,
        this.settings.calendarServers
      );

      const otsFileBase64 = otsBytes
        ? btoa(String.fromCharCode(...otsBytes))
        : undefined;

      const entry: ProofEntry = {
        version: 1,
        file: file.name,
        path: file.path,
        hash,
        submittedAt: new Date().toISOString(),
        status: 'pending',
        calendars,
        otsFileBase64,
      };

      await this.proofStore.add(entry);

      if (otsBytes) {
        await this.proofStore.saveOtsFile(file.path, otsBytes);
      }

      const allEntries = await this.proofStore.load();
      await this.logManager.updateLog(allEntries);

      notice.hide();
      new Notice(`✅ Timestamped: ${file.name}\nSHA-256: ${hash.slice(0, 16)}…`);
    } catch (err) {
      notice.hide();
      new Notice(`❌ Timestamp failed for ${file.name}:\n${(err as Error).message}`);
      console.error('[OTS]', err);
    }
  }

  async loadSettings(): Promise<void> {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
  }

  async saveSettings(): Promise<void> {
    await this.saveData(this.settings);
  }
}
