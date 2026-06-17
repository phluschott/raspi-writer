import { App, Modal, TFile, normalizePath, setIcon } from 'obsidian';
import type OtsPlugin from './main';

export class BulkModal extends Modal {
  private plugin: OtsPlugin;
  private selected: Set<string> = new Set();
  private files: TFile[] = [];
  private progressEl: HTMLElement | null = null;

  constructor(app: App, plugin: OtsPlugin) {
    super(app);
    this.plugin = plugin;
  }

  async onOpen(): Promise<void> {
    const { contentEl } = this;
    contentEl.empty();
    contentEl.addClass('ots-bulk-modal');

    contentEl.createEl('h2', { text: 'Bulk Timestamp Files' });

    const excludeFolder = normalizePath(this.plugin.settings.otsFolder);
    this.files = this.app.vault.getFiles().filter(
      f => !f.path.startsWith(excludeFolder + '/')
    );

    const alreadyStamped = new Set(
      (await this.plugin.proofStore.load()).map(e => e.path)
    );

    // Filter controls
    const filterRow = contentEl.createDiv('ots-filter-row');
    const showAll = filterRow.createEl('input', { type: 'checkbox' });
    showAll.id = 'ots-show-all';
    filterRow.createEl('label', {
      text: ' Show already-timestamped files',
      attr: { for: 'ots-show-all' },
    });

    // Select all / none
    const btnRow = contentEl.createDiv('ots-btn-row');
    const selectAllBtn = btnRow.createEl('button', { text: 'Select all' });
    const selectNoneBtn = btnRow.createEl('button', { text: 'Select none' });
    const countEl = btnRow.createEl('span', { cls: 'ots-count' });

    const updateCount = () => {
      countEl.setText(`${this.selected.size} selected`);
    };

    // File list
    const listEl = contentEl.createDiv('ots-file-list');

    const renderList = (includeStamped: boolean) => {
      listEl.empty();
      this.selected.clear();
      const visible = this.files.filter(
        f => includeStamped || !alreadyStamped.has(f.path)
      );
      for (const file of visible) {
        const stamped = alreadyStamped.has(file.path);
        const row = listEl.createDiv('ots-file-row');
        const cb = row.createEl('input', { type: 'checkbox' });
        cb.disabled = stamped && !includeStamped;
        const icon = row.createSpan('ots-file-icon');
        setIcon(icon, stamped ? 'check-circle' : 'file-text');
        row.createEl('span', { text: file.path, cls: stamped ? 'ots-stamped' : '' });
        cb.addEventListener('change', () => {
          if (cb.checked) this.selected.add(file.path);
          else this.selected.delete(file.path);
          updateCount();
        });
      }
      updateCount();
    };

    renderList(false);

    showAll.addEventListener('change', () => renderList(showAll.checked));

    selectAllBtn.addEventListener('click', () => {
      listEl.querySelectorAll<HTMLInputElement>('input[type=checkbox]').forEach(cb => {
        if (!cb.disabled) {
          cb.checked = true;
          const path = cb.closest('.ots-file-row')?.querySelector('span:last-child')?.textContent;
          if (path) this.selected.add(path);
        }
      });
      updateCount();
    });

    selectNoneBtn.addEventListener('click', () => {
      listEl.querySelectorAll<HTMLInputElement>('input[type=checkbox]').forEach(cb => {
        cb.checked = false;
      });
      this.selected.clear();
      updateCount();
    });

    // Progress and submit
    this.progressEl = contentEl.createDiv('ots-progress');
    this.progressEl.hide();

    const submitBtn = contentEl.createEl('button', {
      text: 'Timestamp selected',
      cls: 'mod-cta',
    });

    submitBtn.addEventListener('click', () => this.runBulk(submitBtn));
  }

  private async runBulk(submitBtn: HTMLButtonElement): Promise<void> {
    if (this.selected.size === 0) return;

    submitBtn.disabled = true;
    this.progressEl?.show();
    const paths = Array.from(this.selected);
    let done = 0;

    for (const path of paths) {
      const file = this.app.vault.getAbstractFileByPath(path);
      if (!(file instanceof TFile)) continue;
      this.progressEl!.setText(`Timestamping ${done + 1}/${paths.length}: ${file.name}`);
      await this.plugin.timestampFile(file);
      done++;
    }

    this.progressEl!.setText(`Done — ${done} file(s) timestamped.`);
    submitBtn.disabled = false;
  }

  onClose(): void {
    this.contentEl.empty();
  }
}
