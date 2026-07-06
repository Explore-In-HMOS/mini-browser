import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ReadingItem } from './Types';

const DOMAIN = 0x0000;
const STORE_NAME = 'glance_reader_store';
const KEY_ITEMS = 'reading_list';

export class ReadingListStore {
  private static instance: ReadingListStore;
  private store: preferences.Preferences | null = null;
  private items: ReadingItem[] = [];

  private constructor() {
  }

  static getInstance(): ReadingListStore {
    if (!ReadingListStore.instance) {
      ReadingListStore.instance = new ReadingListStore();
    }
    return ReadingListStore.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.store) {
      return;
    }
    try {
      this.store = await preferences.getPreferences(context, { name: STORE_NAME });
      const raw = this.store.getSync(KEY_ITEMS, '[]') as string;
      const parsed = JSON.parse(raw) as ReadingItem[];
      this.items = Array.isArray(parsed) ? parsed : [];
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'ReadingListStore init failed: %{public}d %{public}s', e.code, e.message);
      this.items = [];
    }
  }

  getAll(): ReadingItem[] {
    return this.items.slice();
  }

  has(url: string): boolean {
    return this.items.some((it: ReadingItem) => it.url === url);
  }

  async add(item: ReadingItem): Promise<void> {
    this.items = this.items.filter((it: ReadingItem) => it.url !== item.url);
    this.items.unshift(item);
    await this.persist();
  }

  async remove(url: string): Promise<void> {
    this.items = this.items.filter((it: ReadingItem) => it.url !== url);
    await this.persist();
  }

  private async persist(): Promise<void> {
    if (!this.store) {
      return;
    }
    try {
      await this.store.put(KEY_ITEMS, JSON.stringify(this.items));
      await this.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'ReadingListStore persist failed: %{public}d %{public}s', e.code, e.message);
    }
  }
}
