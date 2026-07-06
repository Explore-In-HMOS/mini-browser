import { ReadingListStore } from '../model/ReadingListStore';
import { BrowserSession } from '../model/BrowserSession';
import { ReaderContent } from '../model/ReaderContent';
import { Avatar } from '../common/Avatar';
import { ArticleContent, ReadingItem } from '../model/Types';

@Component
export struct ReadingListPage {
  pageStack: NavPathStack = new NavPathStack();
  @State items: ReadingItem[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.items = ReadingListStore.getInstance().getAll();
  }

  private open(item: ReadingItem): void {

    if (item.paragraphs && item.paragraphs.length > 0) {
      const article: ArticleContent = {
        url: item.url,
        title: item.title,
        byline: item.byline ?? '',
        paragraphs: item.paragraphs
      };
      ReaderContent.set(article);
      this.pageStack.pushPath({ name: 'ReaderPage' });
      return;
    }

    const controller = BrowserSession.getController();
    if (controller) {
      BrowserSession.requestReader(item.url);
      try {
        controller.loadUrl(item.url);
      } catch (e) {
        BrowserSession.consumeReaderRequest();
      }
    }
    this.pageStack.pop();
  }

  private async remove(url: string): Promise<void> {
    await ReadingListStore.getInstance().remove(url);
    this.reload();
  }

  @Builder
  deleteButton(url: string) {
    Column() {
      Image($r('app.media.ic_trash_white'))
        .width(24)
        .height(24)
    }
    .width(60)
    .height(66)
    .justifyContent(FlexAlign.Center)
    .borderRadius(26)
    .backgroundColor($r('app.color.destructive'))
    .margin({ left: 8 })
    .onClick(() => {
      this.remove(url);
    })
  }

  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.reading_list_title'))
          .fontFamily('HarmonyOS Sans Mono, monospace')
          .fontSize($r('app.float.section_label_font_size'))
          .letterSpacing(3)
          .fontColor($r('app.color.reader_dim_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 14 })

        if (this.items.length === 0) {
          Column({ space: 14 }) {
            Image($r('app.media.ic_book_dim'))
              .width(40)
              .height(40)
            Text($r('app.string.reading_list_empty'))
              .fontSize($r('app.float.list_sub_font_size'))
              .fontColor($r('app.color.reader_dim_text'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.items, (item: ReadingItem) => {
              ListItem() {
                Row({ space: 12 }) {
                  Stack() {
                    Text(Avatar.monogram(item.title.length > 0 ? item.title : item.url))
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#0A0A0A')
                  }
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(Avatar.colorFor(item.url))

                  Column({ space: 2 }) {
                    Text(item.title.length > 0 ? item.title : item.url)
                      .fontSize($r('app.float.list_title_font_size'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.primary_text'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    Text(item.excerpt.length > 0 ? item.excerpt : Avatar.host(item.url))
                      .fontFamily(item.excerpt.length > 0 ? '' : 'HarmonyOS Sans Mono, monospace')
                      .fontSize($r('app.float.list_sub_font_size'))
                      .fontColor($r('app.color.text_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if (item.paragraphs && item.paragraphs.length > 0) {
                    Image($r('app.media.ic_offline'))
                      .width(18)
                      .height(18)
                      .flexShrink(0)
                  }
                }
                .width(236)
                .height(66)
                .padding({ left: 10, right: 16 })
                .borderRadius(30)
                .backgroundColor($r('app.color.card_background'))
                .border({ width: 1, color: $r('app.color.surface_border') })
                .onClick(() => {
                  this.open(item);
                })
              }
              .swipeAction({ end: this.deleteButton(item.url) })
            }, (item: ReadingItem) => item.url)
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
    .onShown(() => {
      this.reload();
    })
  }
}
