import { webview } from '@kit.ArkWeb';

export class BrowserSession {
  private static controller: webview.WebviewController | null = null;
  private static pendingReaderUrl: string | null = null;

  static setController(controller: webview.WebviewController): void {
    BrowserSession.controller = controller;
  }

  static getController(): webview.WebviewController | null {
    return BrowserSession.controller;
  }

  static requestReader(url: string): void {
    BrowserSession.pendingReaderUrl = url;
  }

  static hasReaderRequest(): boolean {
    return BrowserSession.pendingReaderUrl !== null;
  }

  static consumeReaderRequest(): void {
    BrowserSession.pendingReaderUrl = null;
  }
}
