import { App, PluginSettingTab, Setting } from 'obsidian';
import type OtsPlugin from './main';

export class OtsSettingTab extends PluginSettingTab {
  plugin: OtsPlugin;

  constructor(app: App, plugin: OtsPlugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();

    containerEl.createEl('h2', { text: 'OpenTimestamps IP Proof' });

    new Setting(containerEl)
      .setName('Proof storage folder')
      .setDesc('Vault folder where .ots proof files and the timestamp log are stored.')
      .addText(text =>
        text
          .setValue(this.plugin.settings.otsFolder)
          .onChange(async val => {
            this.plugin.settings.otsFolder = val.trim() || '_ots';
            await this.plugin.saveSettings();
          })
      );

    new Setting(containerEl)
      .setName('Auto-timestamp on file creation')
      .setDesc('Automatically submit a timestamp when a new file is created in your vault.')
      .addToggle(toggle =>
        toggle
          .setValue(this.plugin.settings.autoTimestamp)
          .onChange(async val => {
            this.plugin.settings.autoTimestamp = val;
            await this.plugin.saveSettings();
          })
      );

    new Setting(containerEl)
      .setName('Auto-timestamp file extensions')
      .setDesc('Comma-separated list of extensions to auto-timestamp (e.g. md,txt).')
      .addText(text =>
        text
          .setValue(this.plugin.settings.autoTimestampExtensions.join(', '))
          .onChange(async val => {
            this.plugin.settings.autoTimestampExtensions = val
              .split(',')
              .map(s => s.trim().replace(/^\./, ''))
              .filter(Boolean);
            await this.plugin.saveSettings();
          })
      );

    containerEl.createEl('h3', { text: 'Calendar servers' });
    containerEl.createEl('p', {
      text: 'OpenTimestamps calendar servers to submit your hashes to. At least one must succeed for a timestamp to be recorded.',
      cls: 'setting-item-description',
    });

    const serverList = containerEl.createDiv('ots-server-list');
    const renderServers = () => {
      serverList.empty();
      this.plugin.settings.calendarServers.forEach((url, i) => {
        new Setting(serverList)
          .addText(text =>
            text.setValue(url).onChange(async val => {
              this.plugin.settings.calendarServers[i] = val.trim();
              await this.plugin.saveSettings();
            })
          )
          .addExtraButton(btn =>
            btn
              .setIcon('trash')
              .setTooltip('Remove')
              .onClick(async () => {
                this.plugin.settings.calendarServers.splice(i, 1);
                await this.plugin.saveSettings();
                renderServers();
              })
          );
      });
    };

    renderServers();

    new Setting(containerEl).addButton(btn =>
      btn.setButtonText('Add calendar server').onClick(async () => {
        this.plugin.settings.calendarServers.push('');
        await this.plugin.saveSettings();
        renderServers();
      })
    );
  }
}
