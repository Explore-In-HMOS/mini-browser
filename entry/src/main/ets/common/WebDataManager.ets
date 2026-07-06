import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

export class WebDataManager {
  static seedDemoCookie(url: string): boolean {
    try {
      webview.WebCookieManager.configCookieSync(url, 'value=test');
      return true;
    } catch (err) {
      WebDataManager.log('seedDemoCookie', err);
      return false;
    }
  }

  static clearCookies(): boolean {
    try {
      webview.WebCookieManager.clearAllCookiesSync();
      return true;
    } catch (err) {
      WebDataManager.log('clearCookies', err);
      return false;
    }
  }

  static clearDomStorage(): boolean {
    try {
      webview.WebStorage.deleteAllData();
      return true;
    } catch (err) {
      WebDataManager.log('clearDomStorage', err);
      return false;
    }
  }

  static clearHistory(controller: webview.WebviewController): boolean {
    try {
      controller.clearHistory();
      return true;
    } catch (err) {
      WebDataManager.log('clearHistory', err);
      return false;
    }
  }

  static clearCache(controller: webview.WebviewController): boolean {
    try {
      controller.removeCache(true);
      return true;
    } catch (err) {
      WebDataManager.log('clearCache', err);
      return false;
    }
  }

  static clearWebDatabase(): boolean {
    try {
      if (webview.WebDataBase.existHttpAuthCredentials()) {
        webview.WebDataBase.deleteHttpAuthCredentials();
      }
      return true;
    } catch (err) {
      WebDataManager.log('clearWebDatabase', err);
      return false;
    }
  }

  private static log(op: string, err: Object): void {
    const e = err as BusinessError;
    hilog.error(DOMAIN, 'testTag', 'WebDataManager %{public}s failed: %{public}d %{public}s', op, e.code, e.message);
  }
}
