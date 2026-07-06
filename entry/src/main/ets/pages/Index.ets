import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ReaderExtractor } from '../common/ReaderExtractor';
import { Avatar } from '../common/Avatar';
import { ReaderContent } from '../model/ReaderContent';
import { ReadingListStore } from '../model/ReadingListStore';
import { BrowserSession } from '../model/BrowserSession';
import { ArticleContent, ReadingItem } from '../model/Types';
import { ReaderPage } from '../views/ReaderPage';
import { HistoryPage } from '../views/HistoryPage';
import { ReadingListPage } from '../views/ReadingListPage';
import { SettingsPage } from '../views/SettingsPage';

const DOMAIN = 0x0000;

interface IconButtonParams {
  icon: Resource;
  action: () => void;
  enabled: boolean;
  primary: boolean;
}

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private pageStack: NavPathStack = new NavPathStack();

  @StorageLink('mb_addr_text') addressText: string = '';
  @StorageLink('mb_addr_mode') addressMode: boolean = false;
  @State currentUrl: string = '';
  @State currentTitle: string = '';
  @State isLoading: boolean = false;
  @State canBack: boolean = false;
  @State canForward: boolean = false;
  @State showMenu: boolean = false;
  @State barOpen: boolean = false;
  @State recents: ReadingItem[] = [];

  aboutToAppear(): void {
    BrowserSession.setController(this.controller);
    if (this.addressMode) {
      this.recents = ReadingListStore.getInstance().getAll();
    }
  }

  private refreshNav(): void {
    try {
      this.canBack = this.controller.accessBackward();
      this.canForward = this.controller.accessForward();
    } catch (e) {
    }
  }

  private hostLabel(): string {
    const h = Avatar.host(this.currentUrl);
    return h.length > 0 ? h : 'mini browser';
  }

  private normalizeUrl(input: string): string {
    const url = input.trim();
    if (url.length === 0) {
      return '';
    }
    if (url.indexOf('://') >= 0) {
      return url;
    }
    return `https://${url}`;
  }

  private loadAddress(): void {
    const url = this.normalizeUrl(this.addressText);
    if (url.length === 0) {
      return;
    }
    try {
      this.controller.loadUrl(url);
      this.currentUrl = url;
      this.addressMode = false;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'loadUrl failed: %{public}d %{public}s', e.code, e.message);
    }
  }

  private openSearch(): void {
    this.recents = ReadingListStore.getInstance().getAll();

    if (!this.addressMode) {
      this.addressText = '';
    }
    this.addressMode = true;
  }

  private openRecent(item: ReadingItem): void {
    try {
      this.controller.loadUrl(item.url);
      this.currentUrl = item.url;
    } catch (e) {
    }
    this.addressMode = false;
  }

  private goBack(): void {
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
      }
    } catch (e) {
    }
  }

  private goForward(): void {
    try {
      if (this.controller.accessForward()) {
        this.controller.forward();
      }
    } catch (e) {
    }
  }

  private reload(): void {
    try {
      this.controller.refresh();
    } catch (e) {
    }
  }

  private async openReader(): Promise<void> {
    const article: ArticleContent = await ReaderExtractor.extract(this.controller);
    ReaderContent.set(article);
    this.pageStack.pushPath({ name: 'ReaderPage' });
  }

  private async saveCurrent(): Promise<void> {
    try {
      const article: ArticleContent = await ReaderExtractor.extract(this.controller);
      const firstPara: string = article.paragraphs.length > 0 ? article.paragraphs[0] : '';
      const item: ReadingItem = {
        url: article.url.length > 0 ? article.url : this.currentUrl,
        title: article.title.length > 0 ? article.title : this.currentTitle,
        excerpt: firstPara.length > 140 ? firstPara.substring(0, 140) + '…' : firstPara,
        savedAt: Date.now(),
        byline: article.byline,
        paragraphs: article.paragraphs
      };
      if (item.url.length === 0) {
        return;
      }
      await ReadingListStore.getInstance().add(item);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.reader_saved_toast') });
    } catch (err) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.reader_save_failed') });
    }
  }

  @Builder
  iconButton($$: IconButtonParams) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image($$.icon)
        .width(22)
        .height(22)
    }
    .width(48)
    .height(48)
    .backgroundColor($$.primary ? $r('app.color.accent') : $r('app.color.card_background_alt'))
    .opacity($$.enabled ? 1 : 0.32)
    .enabled($$.enabled)
    .onClick($$.action)
  }

  // Top floating host pill — tap to open search.
  @Builder
  TopBar() {
    Column() {
      Row({ space: 7 }) {
        Circle({ width: 8, height: 8 })
          .fill($r('app.color.accent'))
        Text(this.hostLabel())
          .fontFamily('HarmonyOS Sans Mono, monospace')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 200 })
      }
      .padding({
        left: 16,
        right: 16,
        top: 8,
        bottom: 8
      })
      .borderRadius(20)
      .backgroundColor($r('app.color.card_background'))
      .border({ width: 1, color: $r('app.color.surface_border') })
      .onClick(() => this.openSearch())

      if (this.isLoading) {
        Progress({ value: 30, total: 100, type: ProgressType.Linear })
          .width(120)
          .height(3)
          .color($r('app.color.accent'))
          .backgroundColor($r('app.color.surface_border'))
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ top: 18, bottom: 8 })
  }

  @Builder
  BottomBar() {
    Column() {
      if (this.barOpen) {
        Scroll() {
          Row({ space: 9 }) {
            this.iconButton({
              icon: $r('app.media.ic_back'),
              action: () => this.goBack(),
              enabled: this.canBack,
              primary: false
            })
            this.iconButton({
              icon: $r('app.media.ic_forward'),
              action: () => this.goForward(),
              enabled: this.canForward,
              primary: false
            })
            this.iconButton({
              icon: $r('app.media.ic_reload'),
              action: () => this.reload(),
              enabled: true,
              primary: false
            })
            this.iconButton({
              icon: $r('app.media.ic_reader'),
              action: () => {
                this.openReader();
              },
              enabled: true,
              primary: true
            })
            this.iconButton({
              icon: $r('app.media.ic_bookmark'),
              action: () => {
                this.saveCurrent();
              },
              enabled: true,
              primary: false
            })
            this.iconButton({
              icon: $r('app.media.ic_more'),
              action: () => {
                this.showMenu = true;
              },
              enabled: true,
              primary: false
            })
          }
          .padding({ left: 10, right: 10 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .padding({ top: 9, bottom: 9, left: 6, right: 6 })
        .borderRadius(40)
        .backgroundColor($r('app.color.toolbar_background'))
        .border({ width: 1, color: $r('app.color.surface_border') })
        .width('100%')
      }

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image(this.barOpen ? $r('app.media.ic_chevron_down') : $r('app.media.ic_chevron_up'))
          .width(18)
          .height(18)
      }
      .width(this.barOpen ? 32 : 40)
      .height(this.barOpen ? 32 : 40)
      .backgroundColor($r('app.color.card_background'))
      .border({ width: 1, color: $r('app.color.surface_border') })
      .margin({ top: this.barOpen ? 6 : 0 })
      .onClick(() => {
        this.barOpen = !this.barOpen;
      })
    }
    .width('100%')
    .padding({ bottom: 12 })
  }

  @Builder
  menuRow(icon: Resource, label: Resource, action: () => void) {
    Row({ space: 13 }) {
      Image(icon)
        .width(20)
        .height(20)
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.primary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width(236)
    .height(56)
    .padding({ left: 20, right: 18 })
    .borderRadius(28)
    .backgroundColor($r('app.color.card_background'))
    .border({ width: 1, color: $r('app.color.surface_border') })
    .onClick(() => {
      this.showMenu = false;
      action();
    })
  }

  @Builder
  MenuOverlay() {
    Column() {
      Text('MENU')
        .fontFamily('HarmonyOS Sans Mono, monospace')
        .fontSize(12)
        .letterSpacing(3)
        .fontColor($r('app.color.reader_dim_text'))
        .margin({ top: 40, bottom: 12 })

      List({ space: 10 }) {
        ListItem() {
          this.menuRow($r('app.media.ic_book_accent'), $r('app.string.action_reading_list'), () => {
            this.pageStack.pushPath({ name: 'ReadingListPage' });
          })
        }
        ListItem() {
          this.menuRow($r('app.media.ic_clock_accent'), $r('app.string.action_history'), () => {
            this.pageStack.pushPath({ name: 'HistoryPage' });
          })
        }
        ListItem() {
          this.menuRow($r('app.media.ic_gear_accent'), $r('app.string.action_settings'), () => {
            this.pageStack.pushPath({ name: 'SettingsPage' });
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Center)

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.ic_close'))
          .width(18)
          .height(18)
      }
      .width(40)
      .height(40)
      .backgroundColor($r('app.color.card_background_alt'))
      .margin({ top: 6, bottom: 16 })
      .onClick(() => {
        this.showMenu = false;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  // Full-screen search/address layer.
  @Builder
  AddressOverlay() {
    Column() {
      Text('ENTER ADDRESS')
        .fontFamily('HarmonyOS Sans Mono, monospace')
        .fontSize(12)
        .letterSpacing(3)
        .fontColor($r('app.color.reader_dim_text'))
        .margin({ top: 84, bottom: 14 })

      Row({ space: 6 }) {
        TextInput({ text: this.addressText, placeholder: $r('app.string.address_hint') })
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .fontColor($r('app.color.primary_text'))
          .placeholderColor($r('app.color.reader_dim_text'))
          .backgroundColor(Color.Transparent)
          .borderRadius(22)
          .type(InputType.URL)
          .onChange((value: string) => {
            this.addressText = value;
          })
          .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
            this.addressText = event.text;
          })
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_go'))
            .width(18)
            .height(18)
        }
        .width(38)
        .height(38)
        .backgroundColor($r('app.color.accent'))
        .onClick(() => {
          this.loadAddress();
        })
      }
      .width(244)
      .padding({ left: 14, right: 5 })
      .height(50)
      .borderRadius(25)
      .backgroundColor($r('app.color.card_background'))
      .border({ width: 1, color: $r('app.color.surface_border') })

      if (this.recents.length > 0) {
        Text('RECENT')
          .fontFamily('HarmonyOS Sans Mono, monospace')
          .fontSize(11)
          .letterSpacing(2)
          .fontColor($r('app.color.reader_dim_text'))
          .margin({ top: 22, bottom: 10 })

        List({ space: 10 }) {
          ForEach(this.recents, (item: ReadingItem) => {
            ListItem() {
              Row({ space: 12 }) {
                Stack() {
                  Text(Avatar.monogram(item.title.length > 0 ? item.title : item.url))
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#0A0A0A')
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor(Avatar.colorFor(item.url))

                Text(item.title.length > 0 ? item.title : Avatar.host(item.url))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.reader_text'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width(244)
              .height(54)
              .padding({ left: 9, right: 16 })
              .borderRadius(30)
              .backgroundColor($r('app.color.card_background'))
              .border({ width: 1, color: $r('app.color.surface_border') })
              .onClick(() => {
                this.openRecent(item);
              })
            }
          }, (item: ReadingItem) => item.url)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.Center)
      } else {
        Blank()
      }

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_close'))
          .width(18)
          .height(18)
      }
      .width(40)
      .height(40)
      .backgroundColor($r('app.color.card_background_alt'))
      .margin({ bottom: 18 })
      .onClick(() => {
        this.addressMode = false;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  PageMap(name: string) {
    if (name === 'ReaderPage') {
      ReaderPage()
    } else if (name === 'HistoryPage') {
      HistoryPage({ pageStack: this.pageStack })
    } else if (name === 'ReadingListPage') {
      ReadingListPage({ pageStack: this.pageStack })
    } else if (name === 'SettingsPage') {
      SettingsPage()
    }
  }

  build() {
    Navigation(this.pageStack) {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          this.TopBar()

          Web({ src: $rawfile('home.html'), controller: this.controller })
            .geolocationAccess(false)
            .domStorageAccess(true)
            .fileAccess(true)
            .cacheMode(CacheMode.Default)
            .darkMode(WebDarkMode.On)
            .width('100%')
            .layoutWeight(1)
            .focusable(true)
            .defaultFocus(true)
            .focusOnTouch(true)
            .onDigitalCrown((event: CrownEvent) => {
              event.stopPropagation()

              const speed = Math.abs(event.angularVelocity) > 180 ? 3 : 1
              const scrollPx = event.degree * 20 * speed

              this.controller.runJavaScript(
                `window.scrollBy({ top: ${scrollPx}, behavior: 'smooth' })`
              )
            })
            .onPageBegin(() => {
              this.isLoading = true;
            })
            .onPageEnd((event) => {
              this.isLoading = false;
              if (event) {
                this.currentUrl = event.url;
              }
              this.refreshNav();

              if (BrowserSession.hasReaderRequest()) {
                BrowserSession.consumeReaderRequest();
                this.openReader();
              }
            })
            .onTitleReceive((event) => {
              if (event) {
                this.currentTitle = event.title;
              }
            })
            .onLoadIntercept((event) => {
              if (event) {
                const url: string = event.data.getRequestUrl();
                if (url.indexOf('native://') === 0) {
                  try {
                    this.controller.loadUrl(url.substring(9));
                  } catch (e) {
                  }
                  return true;
                }
              }
              return false;
            })

          this.BottomBar()
        }
        .width('100%')
        .height('100%')

        if (this.showMenu) {
          this.MenuOverlay()
        }
        if (this.addressMode) {
          this.AddressOverlay()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}
