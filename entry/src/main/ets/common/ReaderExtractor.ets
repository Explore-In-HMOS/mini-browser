import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ArticleContent } from '../model/Types';

const DOMAIN = 0x0000;

const EXTRACT_JS: string = `(function () {
  function clean(s) { return (s || '').replace(/\\s+/g, ' ').trim(); }
  let root = document.querySelector('article') || document.querySelector('main') || document.body;
  let title = clean(document.title);
  let h1 = document.querySelector('h1');
  if (h1 && clean(h1.innerText)) { title = clean(h1.innerText); }
  let byline = '';
  let by = document.querySelector('[rel="author"], .byline, .author, [itemprop="author"]');
  if (by) { byline = clean(by.innerText); }
  let ps = [];
  let nodes = root.querySelectorAll('p, h2, h3, li, blockquote');
  for (let i = 0; i < nodes.length; i++) {
    let n = nodes[i];
    if (n.closest && n.closest('nav, aside, footer, header, .nav, .menu, .sidebar, .comments')) { continue; }
    let t = clean(n.innerText);
    if (t.length >= 25) { ps.push(t); }
  }
  if (ps.length === 0) {
    let body = clean(root.innerText || '');
    if (body) {
      ps = body.split('. ').map(function (x) { return clean(x); }).filter(function (x) { return x.length > 0; });
    }
  }
  ps = ps.slice(0, 200);
  return JSON.stringify({ url: location.href, title: title, byline: byline, paragraphs: ps });
})();`;

export class ReaderExtractor {
  static async extract(controller: webview.WebviewController): Promise<ArticleContent> {
    try {
      const raw: string = await controller.runJavaScript(EXTRACT_JS);
      const article: ArticleContent | null = ReaderExtractor.parse(raw);
      if (article && article.paragraphs.length > 0) {
        return article;
      }
      return ReaderExtractor.fallback(controller, article);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Reader extract failed: %{public}d %{public}s', e.code, e.message);
      return ReaderExtractor.fallback(controller, null);
    }
  }

  private static parse(raw: string): ArticleContent | null {
    if (!raw) {
      return null;
    }
    let jsonStr: string = raw;
    if (jsonStr.length >= 2 && jsonStr.charAt(0) === '"') {
      try {
        jsonStr = JSON.parse(jsonStr) as string;
      } catch (e) {
      }
    }
    try {
      const obj = JSON.parse(jsonStr) as ArticleContent;
      const paragraphs: string[] = Array.isArray(obj.paragraphs) ? obj.paragraphs : [];
      return {
        url: obj.url ?? '',
        title: obj.title ?? '',
        byline: obj.byline ?? '',
        paragraphs: paragraphs
      };
    } catch (e) {
      return null;
    }
  }

  private static fallback(controller: webview.WebviewController, partial: ArticleContent | null): ArticleContent {
    let url = '';
    let title = '';
    try {
      url = controller.getUrl();
      title = controller.getTitle();
    } catch (e) {
    }
    return {
      url: partial?.url ? partial.url : url,
      title: partial?.title ? partial.title : title,
      byline: partial?.byline ?? '',
      paragraphs: partial?.paragraphs ?? []
    };
  }
}
