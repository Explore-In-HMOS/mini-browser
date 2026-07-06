import { ArticleContent } from './Types';

export class ReaderContent {
  private static current: ArticleContent | null = null;

  static set(content: ArticleContent): void {
    ReaderContent.current = content;
  }

  static get(): ArticleContent | null {
    return ReaderContent.current;
  }

  static clear(): void {
    ReaderContent.current = null;
  }
}
