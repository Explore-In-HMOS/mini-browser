import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BrowserSession } from '../model/BrowserSession';
import { Avatar } from '../common/Avatar';
import { HistoryEntry } from '../model/Types';

const DOMAIN = 0x0000;

@Component
export struct HistoryPage {
  pageStack: NavPathStack = new NavPathStack();
  @State entries: HistoryEntry[] = [];

  aboutToAppear(): void {
    const controller = BrowserSession.getController();
    const list: HistoryEntry[] = [];
    if (controller) {
      try {
        const bfl = controller.getBackForwardEntries();
        for (let i = 0; i < bfl.size; i++) {
          const item = bfl.getItemAtIndex(i);
          list.push({
            index: i,
            url: item.historyUrl,
            title: item.title,
            isCurrent: i === bfl.currentIndex
          });
        }
      } catch (err) {
        const e = err as BusinessError;
        hilog.error(DOMAIN, 'testTag', 'getBackForwardEntries failed: %{public}d %{public}s', e.code, e.message);
      }
    }

    this.entries = list.reverse();
  }

  private open(entry: HistoryEntry): void {
    const controller = BrowserSession.getController();
    if (controller) {
      try {
        controller.loadUrl(entry.url);
      } catch (e) {
      }
    }
    this.pageStack.pop();
  }

  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.history_title'))
          .fontFamily('HarmonyOS Sans Mono, monospace')
          .fontSize($r('app.float.section_label_font_size'))
          .letterSpacing(3)
          .fontColor($r('app.color.reader_dim_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 14 })

        if (this.entries.length === 0) {
          Column({ space: 14 }) {
            Image($r('app.media.ic_clock_dim'))
              .width(40)
              .height(40)
            Text($r('app.string.history_empty'))
              .fontSize($r('app.float.list_sub_font_size'))
              .fontColor($r('app.color.reader_dim_text'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.entries, (entry: HistoryEntry) => {
              ListItem() {
                Row({ space: 12 }) {
                  Stack() {
                    Text(Avatar.monogram(entry.title.length > 0 ? entry.title : entry.url))
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#0A0A0A')
                  }
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(entry.isCurrent ? $r('app.color.accent') : Avatar.colorFor(entry.url))

                  Column({ space: 2 }) {
                    Text(entry.title.length > 0 ? entry.title : entry.url)
                      .fontSize($r('app.float.list_title_font_size'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.primary_text'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    Text(Avatar.host(entry.url))
                      .fontFamily('HarmonyOS Sans Mono, monospace')
                      .fontSize($r('app.float.list_sub_font_size'))
                      .fontColor(entry.isCurrent ? $r('app.color.accent') : $r('app.color.text_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width(236)
                .height(66)
                .padding({ left: 10, right: 16 })
                .borderRadius(30)
                .backgroundColor($r('app.color.card_background'))
                .border({
                  width: entry.isCurrent ? 1.5 : 1,
                  color: entry.isCurrent ? $r('app.color.accent') : $r('app.color.surface_border')
                })
                .onClick(() => {
                  this.open(entry);
                })
              }
            }, (entry: HistoryEntry) => entry.index.toString() + entry.url)
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ top: 4, bottom: 20 })
          .scrollBar(BarState.Off)
          .alignListItem(ListItemAlign.Center)
          .focusable(true)
          .defaultFocus(true)
          .focusOnTouch(true)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
  }
}
