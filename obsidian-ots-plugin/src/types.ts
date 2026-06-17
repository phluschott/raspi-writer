export interface CalendarEntry {
  url: string;
  receiptBase64: string;
}

export interface ProofEntry {
  version: number;
  file: string;
  path: string;
  hash: string;
  submittedAt: string;
  status: 'pending' | 'confirmed' | 'failed';
  calendars: CalendarEntry[];
  bitcoinBlock?: number;
  bitcoinTimestamp?: string;
  otsFileBase64?: string;
}

export interface OtsPluginSettings {
  otsFolder: string;
  autoTimestamp: boolean;
  autoTimestampExtensions: string[];
  calendarServers: string[];
}

export const DEFAULT_SETTINGS: OtsPluginSettings = {
  otsFolder: '_ots',
  autoTimestamp: true,
  autoTimestampExtensions: ['md'],
  calendarServers: [
    'https://alice.btc.calendar.opentimestamps.org',
    'https://bob.btc.calendar.opentimestamps.org',
    'https://finney.calendar.eternitywall.com',
  ],
};
