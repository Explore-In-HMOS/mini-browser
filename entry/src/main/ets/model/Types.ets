export interface ReadingItem {
  url: string;
  title: string;
  excerpt: string;
  savedAt: number;
  byline?: string;
  paragraphs?: string[];
}

export interface ArticleContent {
  url: string;
  title: string;
  byline: string;
  paragraphs: string[];
}

export interface HistoryEntry {
  index: number;
  url: string;
  title: string;
  isCurrent: boolean;
}
