import { ReaderContent } from '../model/ReaderContent';
import { ReadingListStore } from '../model/ReadingListStore';
import { Avatar } from '../common/Avatar';
import { ArticleContent, ReadingItem } from '../model/Types';
import { ArcList, ArcListItem, ArcScrollBar } from '@kit.ArkUI';

@Component
export struct ReaderPage {
  @State article: ArticleContent = {
    url: '',
    title: '',
    byline: '',
    paragraphs: []
  };
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const content = ReaderContent.get();
    if (content) {
      this.article = content;
    }
  }

  private source(): string {
    const h = Avatar.host(this.article.url);
    return h.length > 0 ? h.toUpperCase() : 'READER';
  }

  private async save(): Promise<void> {
    const firstPara: string = this.article.paragraphs.length > 0 ? this.article.paragraphs[0] : '';
    const item: ReadingItem = {
      url: this.article.url,
      title: this.article.title,
      excerpt: firstPara.length > 140 ? firstPara.substring(0, 140) + '…' : firstPara,
      savedAt: Date.now(),
      byline: this.article.byline,
      paragraphs: this.article.paragraphs
    };
    if (item.url.length === 0 && item.title.length === 0) {
      return;
    }
    await ReadingListStore.getInstance().add(item);
    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.reader_saved_toast') });
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Stack({ alignContent: Alignment.End }) {
            ArcList({ initialIndex: 0, scroller: this.scroller }) {
              ArcListItem() {
                Text(this.source())
                  .fontFamily('HarmonyOS Sans Mono, monospace')
                  .fontSize($r('app.float.reader_category_font_size'))
                  .letterSpacing(2)
                  .fontColor($r('app.color.accent'))
                  .width('100%')
                  .margin({ top: 28, bottom: 8 })
              }

              ArcListItem() {
                Text(this.article.title)
                  .fontSize($r('app.float.reader_title_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.reader_text'))
                  .lineHeight(30)
                  .width('100%')
              }

              if (this.article.byline.length > 0) {
                ArcListItem() {
                  Text(this.article.byline)
                    .fontFamily('HarmonyOS Sans Mono, monospace')
                    .fontSize($r('app.float.reader_byline_font_size'))
                    .fontColor($r('app.color.reader_dim_text'))
                    .width('100%')
                    .margin({ top: 10 })
                }
              }

              if (this.article.paragraphs.length === 0) {
                ArcListItem() {
                  Text($r('app.string.reader_empty'))
                    .fontSize($r('app.float.reader_body_font_size'))
                    .fontColor($r('app.color.reader_dim_text'))
                    .width('100%')
                    .margin({ top: 24 })
                }
              } else {
                ForEach(this.article.paragraphs, (item: string) => {
                  ArcListItem() {
                    Text(item)
                      .fontSize($r('app.float.reader_body_font_size'))
                      .fontColor($r('app.color.text_body'))
                      .lineHeight(26)
                      .width('100%')
                      .margin({ top: 14 })
                  }
                }, (item: string, index: number) => item)
              }

              ArcListItem() {
                Text(' ')
                  .height(72)
                  .width('100%')
              }
            }
            .layoutWeight(1)
            .width('100%')
            .padding({ top: 8 })
            .focusable(true)
            .defaultFocus(true)
            .focusOnTouch(true)

            ArcScrollBar({ scroller: this.scroller })
          }
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')

        Button({ type: ButtonType.Capsule }) {
          Row({ space: 8 }) {
            Image($r('app.media.ic_save_dark'))
              .width(18)
              .height(18)
            Text($r('app.string.action_save'))
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.on_accent'))
          }
        }
        .height(44)
        .padding({ left: 20, right: 22 })
        .backgroundColor($r('app.color.accent'))
        .margin({ bottom: 20 })
        .onClick(() => {
          this.save();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.reader_background'))
    }
    .hideTitleBar(true)
  }
}
